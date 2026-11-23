WITH apps AS (SELECT sk_id_curr FROM raw.application_train UNION ALL SELECT sk_id_curr FROM raw.application_test),
b   AS (SELECT sk_id_curr k, COUNT(*) c FROM raw.bureau GROUP BY 1),
bb  AS (SELECT sk_id_bureau k, COUNT(*) c FROM raw.bureau_balance GROUP BY 1),
pa  AS (SELECT sk_id_curr k, COUNT(*) c FROM raw.previous_application GROUP BY 1),
pos AS (SELECT sk_id_prev k, COUNT(*) c FROM raw.pos_cash_balance GROUP BY 1),
cc  AS (SELECT sk_id_prev k, COUNT(*) c FROM raw.credit_card_balance GROUP BY 1),
ip  AS (SELECT sk_id_prev k, COUNT(*) c FROM raw.installments_payments GROUP BY 1)
SELECT 'bureau -> application' rel, COUNT(*) parents_with_kids, SUM(c) child_rows, MAX(c) max_per_parent, ROUND(AVG(c),1) avg_per_parent,
       COUNT(*) FILTER (WHERE k NOT IN (SELECT sk_id_curr FROM apps)) orphan_keys FROM b
UNION ALL SELECT 'previous_application -> application', COUNT(*), SUM(c), MAX(c), ROUND(AVG(c),1),
       COUNT(*) FILTER (WHERE k NOT IN (SELECT sk_id_curr FROM apps)) FROM pa
UNION ALL SELECT 'bureau_balance -> bureau', COUNT(*), SUM(c), MAX(c), ROUND(AVG(c),1),
       COUNT(*) FILTER (WHERE k NOT IN (SELECT sk_id_bureau FROM raw.bureau)) FROM bb
UNION ALL SELECT 'pos_cash -> previous_application', COUNT(*), SUM(c), MAX(c), ROUND(AVG(c),1),
       COUNT(*) FILTER (WHERE k NOT IN (SELECT sk_id_prev FROM raw.previous_application)) FROM pos
UNION ALL SELECT 'credit_card -> previous_application', COUNT(*), SUM(c), MAX(c), ROUND(AVG(c),1),
       COUNT(*) FILTER (WHERE k NOT IN (SELECT sk_id_prev FROM raw.previous_application)) FROM cc
UNION ALL SELECT 'installments -> previous_application', COUNT(*), SUM(c), MAX(c), ROUND(AVG(c),1),
       COUNT(*) FILTER (WHERE k NOT IN (SELECT sk_id_prev FROM raw.previous_application)) FROM ip;

-- Why does installments have duplicate instalments? Look at a few.
SELECT sk_id_prev, num_instalment_version, num_instalment_number, days_instalment, days_entry_payment, amt_instalment, amt_payment
FROM raw.installments_payments
QUALIFY COUNT(*) OVER (PARTITION BY sk_id_prev, num_instalment_number, num_instalment_version) > 1
ORDER BY sk_id_prev, num_instalment_number LIMIT 8;
