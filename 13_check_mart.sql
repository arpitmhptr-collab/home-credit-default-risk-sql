SELECT chk, actual, expected, ABS(actual - expected) < 1 AS ok FROM (
  -- per-join fan-out test: row count must stay 307,511
  SELECT 'join +installments: rows' chk, (SELECT COUNT(*) FROM raw.application_train a LEFT JOIN mart.feat_installments f ON a.sk_id_curr = f.sk_id_curr)::DOUBLE actual, 307511::DOUBLE expected
  UNION ALL SELECT 'join +bureau: rows',  (SELECT COUNT(*) FROM raw.application_train a LEFT JOIN mart.feat_bureau f ON a.sk_id_curr = f.sk_id_curr)::DOUBLE, 307511::DOUBLE
  UNION ALL SELECT 'join +prev: rows',    (SELECT COUNT(*) FROM raw.application_train a LEFT JOIN mart.feat_prev f ON a.sk_id_curr = f.sk_id_curr)::DOUBLE, 307511::DOUBLE
  UNION ALL SELECT 'join +cc: rows',      (SELECT COUNT(*) FROM raw.application_train a LEFT JOIN mart.feat_cc f ON a.sk_id_curr = f.sk_id_curr)::DOUBLE, 307511::DOUBLE
  -- final mart vs source: rows and sums before vs after
  UNION ALL SELECT 'mart: rows', (SELECT COUNT(*) FROM mart.customer_mart)::DOUBLE, (SELECT COUNT(*) FROM raw.application_train)::DOUBLE
  UNION ALL SELECT 'mart: distinct customers', (SELECT COUNT(DISTINCT sk_id_curr) FROM mart.customer_mart)::DOUBLE, (SELECT COUNT(*) FROM raw.application_train)::DOUBLE
  UNION ALL SELECT 'mart: sum(target)', (SELECT SUM(target) FROM mart.customer_mart)::DOUBLE, (SELECT SUM(target) FROM raw.application_train)::DOUBLE
  UNION ALL SELECT 'mart: sum(amt_credit)', (SELECT ROUND(SUM(amt_credit)) FROM mart.customer_mart)::DOUBLE, (SELECT ROUND(SUM(amt_credit)) FROM raw.application_train)::DOUBLE
  UNION ALL SELECT 'mart: sum(amt_income_total)', (SELECT ROUND(SUM(amt_income_total)) FROM mart.customer_mart)::DOUBLE, (SELECT ROUND(SUM(amt_income_total)) FROM raw.application_train)::DOUBLE
  -- features carried through the join without loss or duplication (train customers only)
  UNION ALL SELECT 'carried: bureau loans', (SELECT SUM(n_bureau_loans) FROM mart.customer_mart)::DOUBLE, (SELECT SUM(n_bureau_loans) FROM mart.feat_bureau WHERE sk_id_curr IN (SELECT sk_id_curr FROM raw.application_train))::DOUBLE
  UNION ALL SELECT 'carried: previous apps', (SELECT SUM(n_prev_apps) FROM mart.customer_mart)::DOUBLE, (SELECT SUM(n_prev_apps) FROM mart.feat_prev WHERE sk_id_curr IN (SELECT sk_id_curr FROM raw.application_train))::DOUBLE
  UNION ALL SELECT 'carried: instalments', (SELECT SUM(n_instalments) FROM mart.customer_mart)::DOUBLE, (SELECT SUM(n_instalments) FROM mart.feat_installments WHERE sk_id_curr IN (SELECT sk_id_curr FROM raw.application_train))::DOUBLE
  UNION ALL SELECT 'carried: cc months', (SELECT SUM(n_cc_months) FROM mart.customer_mart)::DOUBLE, (SELECT SUM(n_cc_months) FROM mart.feat_cc WHERE sk_id_curr IN (SELECT sk_id_curr FROM raw.application_train))::DOUBLE
);

-- Coverage: what % of customers have each history?
SELECT ROUND(100 * AVG(has_instalments::INT), 1) AS pct_instalments,
       ROUND(100 * AVG(has_bureau::INT), 1)       AS pct_bureau,
       ROUND(100 * AVG(has_prev::INT), 1)         AS pct_prev,
       ROUND(100 * AVG(has_cc::INT), 1)           AS pct_cc,
       ROUND(100 * AVG(target), 2)                AS default_rate_pct
FROM mart.customer_mart;
