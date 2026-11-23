-- Top null columns in the main table
SELECT column_name, column_type, null_percentage, approx_unique, min, max
FROM (SUMMARIZE raw.application_train)
WHERE null_percentage > 0 ORDER BY null_percentage DESC LIMIT 10;

-- The famous DAYS_EMPLOYED = 365243 placeholder
SELECT days_employed = 365243 AS is_placeholder,
       COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
       ROUND(100 * AVG(target), 2) AS default_rate_pct
FROM raw.application_train GROUP BY 1;

-- Other odd values
SELECT 'gender = XNA' chk, COUNT(*) n FROM raw.application_train WHERE code_gender = 'XNA'
UNION ALL SELECT 'org_type = XNA', COUNT(*) FROM raw.application_train WHERE organization_type = 'XNA'
UNION ALL SELECT 'income > 10M', COUNT(*) FROM raw.application_train WHERE amt_income_total > 10000000
UNION ALL SELECT 'prev_app 365243 (days_first_drawing)', COUNT(*) FROM raw.previous_application WHERE days_first_drawing = 365243
UNION ALL SELECT 'installments null days_entry_payment', COUNT(*) FROM raw.installments_payments WHERE days_entry_payment IS NULL
UNION ALL SELECT 'installments paid = 0', COUNT(*) FROM raw.installments_payments WHERE amt_payment = 0;
