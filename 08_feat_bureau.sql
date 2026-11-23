-- Level 1: monthly status -> one row per bureau loan
-- STATUS: C=closed, X=unknown, 0=no delay, 1..5 = delay buckets (5 = 120+ days / written off)
CREATE OR REPLACE TABLE mart.bb_agg AS
SELECT sk_id_bureau,
  COUNT(*) AS n_months,
  SUM(CASE WHEN status IN ('1','2','3','4','5') THEN 1 ELSE 0 END) AS n_dpd_months,
  MAX(CASE WHEN status IN ('1','2','3','4','5') THEN CAST(status AS INTEGER) END) AS worst_dpd_bucket,
  SUM(CASE WHEN status IN ('1','2','3','4','5') AND months_balance >= -12 THEN 1 ELSE 0 END) AS n_dpd_last12m
FROM raw.bureau_balance
GROUP BY sk_id_bureau;

-- Join is 1:1 now (bb_agg has one row per loan), so no fan-out
CREATE OR REPLACE TABLE mart.bureau_enriched AS
SELECT b.*,
  COALESCE(a.n_months, 0)      AS n_months,
  COALESCE(a.n_dpd_months, 0)  AS n_dpd_months,
  a.worst_dpd_bucket,
  COALESCE(a.n_dpd_last12m, 0) AS n_dpd_last12m
FROM raw.bureau b
LEFT JOIN mart.bb_agg a ON b.sk_id_bureau = a.sk_id_bureau;

-- Level 2: loan -> one row per customer
CREATE OR REPLACE TABLE mart.feat_bureau AS
SELECT sk_id_curr,
  COUNT(*)                                                          AS n_bureau_loans,
  SUM(CASE WHEN credit_active = 'Active' THEN 1 ELSE 0 END)         AS n_active_loans,
  ROUND(AVG(CASE WHEN credit_day_overdue > 0 THEN 1.0 ELSE 0 END), 4) AS share_loans_overdue,
  MAX(credit_day_overdue)                                           AS max_days_overdue,
  SUM(n_dpd_months)                                                 AS total_dpd_months,
  SUM(n_dpd_last12m)                                                AS dpd_months_last12m,
  MAX(worst_dpd_bucket)                                             AS worst_dpd_bucket,
  ROUND(SUM(GREATEST(amt_credit_sum_debt, 0)) FILTER (WHERE credit_active = 'Active')
        / NULLIF(SUM(amt_credit_sum) FILTER (WHERE credit_active = 'Active'), 0), 4) AS bureau_utilisation,
  -MIN(days_credit)                                                 AS days_since_oldest_credit,
  -MAX(days_credit)                                                 AS days_since_latest_credit
FROM mart.bureau_enriched
GROUP BY sk_id_curr;
