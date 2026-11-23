CREATE SCHEMA IF NOT EXISTS mart;

-- 1) Collapse partial payments: one row per instalment
CREATE OR REPLACE TABLE mart.installments_dedup AS
SELECT sk_id_curr, sk_id_prev, num_instalment_version, num_instalment_number,
       MAX(days_instalment)     AS days_instalment,   -- due date (days relative to application)
       MAX(amt_instalment)      AS amt_instalment,
       SUM(amt_payment)         AS amt_paid,
       MAX(days_entry_payment)  AS last_pay_day,
       COUNT(*)                 AS n_payment_rows
FROM raw.installments_payments
GROUP BY sk_id_curr, sk_id_prev, num_instalment_version, num_instalment_number;

-- 2) Score each instalment (unpaid = NULL, not "on time")
CREATE OR REPLACE TABLE mart.installments_scored AS
SELECT *,
  last_pay_day - days_instalment AS days_late,   -- >0 means paid after due date
  CASE WHEN last_pay_day IS NULL THEN NULL
       WHEN last_pay_day > days_instalment THEN 1 ELSE 0 END AS late_flag,
  GREATEST(amt_instalment - COALESCE(amt_paid, 0), 0) AS shortfall
FROM mart.installments_dedup;

-- 3) Window functions (days are negative: more negative = older)
CREATE OR REPLACE TABLE mart.installments_win AS
SELECT *,
  ROW_NUMBER() OVER w_desc AS recency_rank,        -- 1 = most recent instalment
  LAG(late_flag) OVER w_asc AS prev_late_flag,     -- previous instalment's status
  AVG(late_flag) OVER w6    AS roll6_late_rate     -- rolling 6-instalment late rate
FROM mart.installments_scored
WINDOW
  w_asc  AS (PARTITION BY sk_id_curr ORDER BY days_instalment, sk_id_prev, num_instalment_number),
  w6     AS (PARTITION BY sk_id_curr ORDER BY days_instalment, sk_id_prev, num_instalment_number
             ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),
  w_desc AS (PARTITION BY sk_id_curr ORDER BY days_instalment DESC, sk_id_prev DESC, num_instalment_number DESC);

-- 4) One row per customer
CREATE OR REPLACE TABLE mart.feat_installments AS
SELECT sk_id_curr,
  COUNT(*)                                                    AS n_instalments,
  ROUND(AVG(late_flag), 4)                                    AS late_rate,
  ROUND(AVG(days_late) FILTER (WHERE days_late > 0), 2)       AS avg_days_late_when_late,
  MAX(days_late)                                              AS max_days_late,
  MAX(roll6_late_rate) FILTER (WHERE recency_rank = 1)        AS late_rate_last6,
  SUM(CASE WHEN late_flag = 1 AND prev_late_flag = 0 THEN 1 ELSE 0 END) AS n_slips,
  ROUND(SUM(shortfall) / NULLIF(SUM(amt_instalment), 0), 4)   AS shortfall_ratio
FROM mart.installments_win
GROUP BY sk_id_curr;
