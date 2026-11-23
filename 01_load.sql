CREATE SCHEMA IF NOT EXISTS raw;

CREATE OR REPLACE TABLE raw.application_train     AS SELECT * FROM read_csv('data/raw/application_train.csv',     sample_size=-1);
CREATE OR REPLACE TABLE raw.application_test      AS SELECT * FROM read_csv('data/raw/application_test.csv',      sample_size=-1);
CREATE OR REPLACE TABLE raw.bureau                AS SELECT * FROM read_csv('data/raw/bureau.csv',                sample_size=-1);
CREATE OR REPLACE TABLE raw.bureau_balance        AS SELECT * FROM read_csv('data/raw/bureau_balance.csv',        sample_size=-1);
CREATE OR REPLACE TABLE raw.previous_application  AS SELECT * FROM read_csv('data/raw/previous_application.csv',  sample_size=-1);
CREATE OR REPLACE TABLE raw.pos_cash_balance      AS SELECT * FROM read_csv('data/raw/POS_CASH_balance.csv',      sample_size=-1);
CREATE OR REPLACE TABLE raw.credit_card_balance   AS SELECT * FROM read_csv('data/raw/credit_card_balance.csv',   sample_size=-1);
CREATE OR REPLACE TABLE raw.installments_payments AS SELECT * FROM read_csv('data/raw/installments_payments.csv', sample_size=-1);
