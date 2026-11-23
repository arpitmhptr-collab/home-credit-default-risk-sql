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
base AS (SELECT AVG(target) r FROM mart.customer_mart)
SELECT 'late_rate' AS driver, late_rate_band AS band, COUNT(*) AS customers, ROUND(100*AVG(target),2) AS default_pct, ROUND(AVG(target)/(SELECT r FROM base),2) AS lift FROM b GROUP BY 2
UNION ALL SELECT 'late_last6',   last6_band,       COUNT(*), ROUND(100*AVG(target),2), ROUND(AVG(target)/(SELECT r FROM base),2) FROM b GROUP BY 2
UNION ALL SELECT 'bureau_dpd',   bureau_dpd_band,  COUNT(*), ROUND(100*AVG(target),2), ROUND(AVG(target)/(SELECT r FROM base),2) FROM b GROUP BY 2
UNION ALL SELECT 'bureau_util',  bureau_util_band, COUNT(*), ROUND(100*AVG(target),2), ROUND(AVG(target)/(SELECT r FROM base),2) FROM b GROUP BY 2
UNION ALL SELECT 'cc_util',      cc_util_band,     COUNT(*), ROUND(100*AVG(target),2), ROUND(AVG(target)/(SELECT r FROM base),2) FROM b GROUP BY 2
ORDER BY 1, 2;

-- Headline insight: recent late payments AND recent bureau delinquency
WITH f AS (
  SELECT target,
    (COALESCE(late_rate_last6, 0) > 0 AND COALESCE(dpd_months_last12m, 0) > 0) AS high_risk
  FROM mart.customer_mart
)
SELECT high_risk,
  COUNT(*)                                                        AS customers,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)              AS pct_of_customers,
  SUM(target)                                                     AS defaulters,
  ROUND(100.0 * SUM(target) / SUM(SUM(target)) OVER (), 1)        AS pct_of_all_defaults,
  ROUND(100 * AVG(target), 2)                                     AS default_pct
FROM f GROUP BY 1 ORDER BY 1;
