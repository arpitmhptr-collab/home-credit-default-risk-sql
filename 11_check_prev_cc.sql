SELECT chk, actual, expected, ABS(actual - expected) < 1 AS ok FROM (
  SELECT 'prev: customers' chk, (SELECT COUNT(*) FROM mart.feat_prev)::DOUBLE actual, (SELECT COUNT(DISTINCT sk_id_curr) FROM raw.previous_application)::DOUBLE expected
  UNION ALL SELECT 'prev: applications summed', (SELECT SUM(n_prev_apps) FROM mart.feat_prev)::DOUBLE, (SELECT COUNT(*) FROM raw.previous_application)::DOUBLE
  UNION ALL SELECT 'prev: 4 statuses cover all apps', (SELECT SUM(n_approved + n_refused + n_canceled + n_unused) FROM mart.feat_prev)::DOUBLE, (SELECT SUM(n_prev_apps) FROM mart.feat_prev)::DOUBLE
  UNION ALL SELECT 'prev: amount applied preserved', (SELECT ROUND(SUM(total_amt_applied)) FROM mart.feat_prev)::DOUBLE, (SELECT ROUND(SUM(amt_application)) FROM raw.previous_application)::DOUBLE
  UNION ALL SELECT 'cc: customers', (SELECT COUNT(*) FROM mart.feat_cc)::DOUBLE, (SELECT COUNT(DISTINCT sk_id_curr) FROM raw.credit_card_balance)::DOUBLE
  UNION ALL SELECT 'cc: months summed', (SELECT SUM(n_cc_months) FROM mart.feat_cc)::DOUBLE, (SELECT COUNT(*) FROM raw.credit_card_balance)::DOUBLE
  UNION ALL SELECT 'cc: cards summed (1 card = 1 customer)', (SELECT SUM(n_cards) FROM mart.feat_cc)::DOUBLE, (SELECT COUNT(DISTINCT sk_id_prev) FROM raw.credit_card_balance)::DOUBLE
);
SELECT * FROM mart.feat_prev ORDER BY n_prev_apps DESC LIMIT 3;
SELECT * FROM mart.feat_cc ORDER BY n_cc_months DESC LIMIT 3;
