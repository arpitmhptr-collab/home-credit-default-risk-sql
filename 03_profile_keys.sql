-- Is the assumed grain (key) really unique? dup_rows > 0 means it is not.
SELECT tbl, n_rows, n_keys, n_rows - n_keys AS dup_rows FROM (
  SELECT 'application_train (sk_id_curr)' tbl,
    (SELECT COUNT(*) FROM raw.application_train) n_rows,
    (SELECT COUNT(DISTINCT sk_id_curr) FROM raw.application_train) n_keys
  UNION ALL SELECT 'application_test (sk_id_curr)',
    (SELECT COUNT(*) FROM raw.application_test),
    (SELECT COUNT(DISTINCT sk_id_curr) FROM raw.application_test)
  UNION ALL SELECT 'bureau (sk_id_bureau)',
    (SELECT COUNT(*) FROM raw.bureau),
    (SELECT COUNT(DISTINCT sk_id_bureau) FROM raw.bureau)
  UNION ALL SELECT 'bureau_balance (sk_id_bureau, months_balance)',
    (SELECT COUNT(*) FROM raw.bureau_balance),
    (SELECT COUNT(*) FROM (SELECT 1 FROM raw.bureau_balance GROUP BY sk_id_bureau, months_balance))
  UNION ALL SELECT 'previous_application (sk_id_prev)',
    (SELECT COUNT(*) FROM raw.previous_application),
    (SELECT COUNT(DISTINCT sk_id_prev) FROM raw.previous_application)
  UNION ALL SELECT 'pos_cash_balance (sk_id_prev, months_balance)',
    (SELECT COUNT(*) FROM raw.pos_cash_balance),
    (SELECT COUNT(*) FROM (SELECT 1 FROM raw.pos_cash_balance GROUP BY sk_id_prev, months_balance))
  UNION ALL SELECT 'credit_card_balance (sk_id_prev, months_balance)',
    (SELECT COUNT(*) FROM raw.credit_card_balance),
    (SELECT COUNT(*) FROM (SELECT 1 FROM raw.credit_card_balance GROUP BY sk_id_prev, months_balance))
  UNION ALL SELECT 'installments (sk_id_prev, num_instalment_number, num_instalment_version)',
    (SELECT COUNT(*) FROM raw.installments_payments),
    (SELECT COUNT(*) FROM (SELECT 1 FROM raw.installments_payments GROUP BY sk_id_prev, num_instalment_number, num_instalment_version))
);
