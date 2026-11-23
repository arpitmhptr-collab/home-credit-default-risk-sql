SELECT 'application_train' AS tbl, COUNT(*) AS n, 307511 AS expected FROM raw.application_train      UNION ALL
SELECT 'application_test',     COUNT(*), 48744    FROM raw.application_test       UNION ALL
SELECT 'bureau',               COUNT(*), 1716428  FROM raw.bureau                 UNION ALL
SELECT 'bureau_balance',       COUNT(*), 27299925 FROM raw.bureau_balance         UNION ALL
SELECT 'previous_application', COUNT(*), 1670214  FROM raw.previous_application   UNION ALL
SELECT 'pos_cash_balance',     COUNT(*), 10001358 FROM raw.pos_cash_balance       UNION ALL
SELECT 'credit_card_balance',  COUNT(*), 3840312  FROM raw.credit_card_balance    UNION ALL
SELECT 'installments_payments',COUNT(*), 13605401 FROM raw.installments_payments;
