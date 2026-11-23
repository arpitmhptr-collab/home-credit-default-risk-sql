-- Dashboard data layer: all numbers the dashboard shows come from these two tables.

-- 1) Default rate by behaviour band (same bands as 14_default_drivers.sql)
CREATE OR REPLACE TABLE mart.driver_bands AS
WITH b AS (
  SELECT target,
    CASE WHEN NOT has_instalments THEN '0 no history'
         WHEN late_rate = 0       THEN '1 never late'
         WHEN late_rate <= 0.05   THEN '2 late <=5% of instalments'
         WHEN late_rate <= 0.15   THEN '3 late 5-15%'
         ELSE                          '4 late >15%' END AS late_rate_band,
    CASE WHEN NOT has_instalments    THEN '0 no history'
         WHEN late_rate_last6 = 0    THEN '1 none of last 6 late'
         WHEN late_rate_last6 <= 0.34 THEN '2 up to 1/3 late'
         ELSE                             '3 over 1/3 late' END AS last6_band,
    CASE WHEN NOT has_bureau              THEN '0 no bureau record'
         WHEN dpd_months_last12m = 0      THEN '1 no delinquency (12m)'
         WHEN dpd_months_last12m <= 3     THEN '2 1-3 delinquent months'
         ELSE                                  '3 4+ delinquent months' END AS bureau_dpd_band,
    CASE WHEN NOT has_bureau              THEN '0 no bureau record'
         WHEN bureau_utilisation IS NULL  THEN '1 no active debt'
         WHEN bureau_utilisation <= 0.3   THEN '2 utilisation <=30%'
         WHEN bureau_utilisation <= 0.7   THEN '3 utilisation 30-70%'
         ELSE                                  '4 utilisation >70%' END AS bureau_util_band,
    CASE WHEN NOT has_cc                  THEN '0 no credit card'
         WHEN cc_util_avg <= 0.3          THEN '1 card util <=30%'
         WHEN cc_util_avg <= 0.7          THEN '2 card util 30-70%'
         ELSE                                  '3 card util >70%' END AS cc_util_band
  FROM mart.customer_mart
),
base AS (SELECT AVG(target) AS r FROM mart.customer_mart)
SELECT driver, band, customers, defaulters, default_pct, ROUND(default_pct / 100 / (SELECT r FROM base), 2) AS lift
FROM (
  SELECT 'late_last6'  AS driver, last6_band       AS band, COUNT(*) AS customers, SUM(target) AS defaulters, ROUND(100 * AVG(target), 2) AS default_pct FROM b GROUP BY 2
  UNION ALL SELECT 'late_rate',   late_rate_band,   COUNT(*), SUM(target), ROUND(100 * AVG(target), 2) FROM b GROUP BY 2
  UNION ALL SELECT 'bureau_dpd',  bureau_dpd_band,  COUNT(*), SUM(target), ROUND(100 * AVG(target), 2) FROM b GROUP BY 2
  UNION ALL SELECT 'bureau_util', bureau_util_band, COUNT(*), SUM(target), ROUND(100 * AVG(target), 2) FROM b GROUP BY 2
  UNION ALL SELECT 'cc_util',     cc_util_band,     COUNT(*), SUM(target), ROUND(100 * AVG(target), 2) FROM b GROUP BY 2
);

-- 2) One-row headline + data-quality numbers
CREATE OR REPLACE TABLE mart.headline AS
SELECT
  (SELECT COUNT(*) FROM mart.customer_mart)                       AS customers,
  (SELECT SUM(target) FROM mart.customer_mart)                    AS defaulters,
  (SELECT ROUND(100 * AVG(target), 2) FROM mart.customer_mart)    AS default_pct,
  -- any late payment in the last 6 instalments
  (SELECT COUNT(*) FROM mart.customer_mart WHERE COALESCE(late_rate_last6, 0) > 0)               AS recent_late_customers,
  (SELECT SUM(target) FROM mart.customer_mart WHERE COALESCE(late_rate_last6, 0) > 0)            AS recent_late_defaulters,
  -- watchlist flag: recent late payment AND bureau delinquency in the last 12 months
  (SELECT COUNT(*) FROM mart.customer_mart WHERE COALESCE(late_rate_last6, 0) > 0 AND COALESCE(dpd_months_last12m, 0) > 0)    AS flag_customers,
  (SELECT SUM(target) FROM mart.customer_mart WHERE COALESCE(late_rate_last6, 0) > 0 AND COALESCE(dpd_months_last12m, 0) > 0) AS flag_defaulters,
  -- data quality
  (SELECT COUNT(*) FROM raw.application_train WHERE days_employed = 365243)                        AS placeholder_n,
  (SELECT COUNT(*) FROM raw.application_train)                                                     AS app_rows,
  (SELECT ROUND(100 * AVG(target), 2) FROM raw.application_train WHERE days_employed = 365243)     AS placeholder_default_pct,
  (SELECT ROUND(100 * AVG(target), 2) FROM raw.application_train WHERE days_employed <> 365243)    AS other_default_pct,
  (SELECT COUNT(*) FROM raw.installments_payments) - (SELECT COUNT(*) FROM mart.installments_dedup) AS dup_instalment_rows,
  (SELECT COUNT(*) FROM raw.bureau_balance WHERE sk_id_bureau NOT IN (SELECT sk_id_bureau FROM raw.bureau)) AS orphan_bb_rows,
  (SELECT COUNT(*) FROM raw.bureau_balance)                                                        AS bb_rows;
