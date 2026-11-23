SELECT chk, actual, expected, actual = expected AS ok FROM (
  SELECT 'instalment rows after dedup' chk, (SELECT COUNT(*) FROM mart.installments_dedup)::DOUBLE actual, 12951918::DOUBLE expected
  UNION ALL SELECT 'raw payment rows preserved', (SELECT SUM(n_payment_rows) FROM mart.installments_dedup)::DOUBLE, 13605401::DOUBLE
  UNION ALL SELECT 'total amount paid preserved', (SELECT ROUND(SUM(amt_paid)) FROM mart.installments_dedup)::DOUBLE, (SELECT ROUND(SUM(amt_payment)) FROM raw.installments_payments)::DOUBLE
  UNION ALL SELECT 'customers (mart vs raw)', (SELECT COUNT(*) FROM mart.feat_installments)::DOUBLE, (SELECT COUNT(DISTINCT sk_id_curr) FROM raw.installments_payments)::DOUBLE
  UNION ALL SELECT 'instalments summed in mart', (SELECT SUM(n_instalments) FROM mart.feat_installments)::DOUBLE, (SELECT COUNT(*) FROM mart.installments_dedup)::DOUBLE
  UNION ALL SELECT 'mart customers not in application', (SELECT COUNT(*) FROM mart.feat_installments WHERE sk_id_curr NOT IN (SELECT sk_id_curr FROM raw.application_train UNION ALL SELECT sk_id_curr FROM raw.application_test))::DOUBLE, 0::DOUBLE
);
SELECT * FROM mart.feat_installments ORDER BY n_instalments DESC LIMIT 5;
