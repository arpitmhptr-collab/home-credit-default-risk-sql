SELECT chk, actual, expected, ABS(actual - expected) < 1 AS ok FROM (
  SELECT 'bureau rows after join' chk, (SELECT COUNT(*) FROM mart.bureau_enriched)::DOUBLE actual, (SELECT COUNT(*) FROM raw.bureau)::DOUBLE expected
  UNION ALL SELECT 'credit amount preserved', (SELECT ROUND(SUM(amt_credit_sum)) FROM mart.bureau_enriched)::DOUBLE, (SELECT ROUND(SUM(amt_credit_sum)) FROM raw.bureau)::DOUBLE
  UNION ALL SELECT 'bb months reachable via bureau', (SELECT SUM(n_months) FROM mart.bureau_enriched)::DOUBLE, (SELECT COUNT(*) FROM raw.bureau_balance WHERE sk_id_bureau IN (SELECT sk_id_bureau FROM raw.bureau))::DOUBLE
  UNION ALL SELECT 'orphan bb rows (not in bureau)', (SELECT COUNT(*) FROM raw.bureau_balance WHERE sk_id_bureau NOT IN (SELECT sk_id_bureau FROM raw.bureau))::DOUBLE, (27299925 - (SELECT SUM(n_months) FROM mart.bureau_enriched))::DOUBLE
  UNION ALL SELECT 'customers (mart vs raw)', (SELECT COUNT(*) FROM mart.feat_bureau)::DOUBLE, (SELECT COUNT(DISTINCT sk_id_curr) FROM raw.bureau)::DOUBLE
  UNION ALL SELECT 'loans summed in mart', (SELECT SUM(n_bureau_loans) FROM mart.feat_bureau)::DOUBLE, (SELECT COUNT(*) FROM raw.bureau)::DOUBLE
);
SELECT * FROM mart.feat_bureau ORDER BY n_bureau_loans DESC LIMIT 5;
