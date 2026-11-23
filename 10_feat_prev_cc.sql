CREATE OR REPLACE TABLE mart.feat_prev AS
SELECT sk_id_curr,
  COUNT(*)                                                         AS n_prev_apps,
  SUM(CASE WHEN name_contract_status = 'Approved'     THEN 1 ELSE 0 END) AS n_approved,
  SUM(CASE WHEN name_contract_status = 'Refused'      THEN 1 ELSE 0 END) AS n_refused,
  SUM(CASE WHEN name_contract_status = 'Canceled'     THEN 1 ELSE 0 END) AS n_canceled,
  SUM(CASE WHEN name_contract_status = 'Unused offer' THEN 1 ELSE 0 END) AS n_unused,
  ROUND(AVG(CASE WHEN name_contract_status = 'Refused' THEN 1.0 ELSE 0 END), 4) AS refusal_rate,
  SUM(amt_application)                                             AS total_amt_applied,
  -MAX(days_decision)                                              AS days_since_last_decision,
  arg_max(name_contract_status, days_decision)                     AS last_decision_status
FROM raw.previous_application
GROUP BY sk_id_curr;

CREATE OR REPLACE TABLE mart.feat_cc AS
WITH m AS (
  SELECT sk_id_curr, sk_id_prev, months_balance, sk_dpd,
         GREATEST(amt_balance, 0) / NULLIF(amt_credit_limit_actual, 0) AS util
  FROM raw.credit_card_balance
)
SELECT sk_id_curr,
  COUNT(DISTINCT sk_id_prev)                              AS n_cards,
  COUNT(*)                                                AS n_cc_months,
  ROUND(AVG(util), 4)                                     AS cc_util_avg,
  ROUND(MAX(util), 4)                                     AS cc_util_max,
  ROUND(AVG(util) FILTER (WHERE months_balance >= -3), 4) AS cc_util_last3m,
  ROUND(AVG(CASE WHEN sk_dpd > 0 THEN 1.0 ELSE 0 END), 4) AS cc_dpd_month_rate,
  MAX(sk_dpd)                                             AS cc_max_dpd
FROM m
GROUP BY sk_id_curr;
