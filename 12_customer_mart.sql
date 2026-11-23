CREATE OR REPLACE TABLE mart.customer_mart AS
SELECT
  a.sk_id_curr, a.target,
  a.name_contract_type, a.code_gender, a.name_income_type, a.name_education_type,
  a.amt_income_total, a.amt_credit, a.amt_annuity, a.amt_goods_price,
  ROUND(-a.days_birth / 365.25, 1)                              AS age_years,
  CASE WHEN a.days_employed = 365243 THEN NULL ELSE a.days_employed END AS days_employed_clean,
  (a.days_employed = 365243)                                    AS emp_placeholder_flag,
  ROUND(a.amt_credit / NULLIF(a.amt_income_total, 0), 2)        AS credit_to_income,
  a.ext_source_1, a.ext_source_2, a.ext_source_3,
  (i.sk_id_curr IS NOT NULL) AS has_instalments,
  (b.sk_id_curr IS NOT NULL) AS has_bureau,
  (p.sk_id_curr IS NOT NULL) AS has_prev,
  (c.sk_id_curr IS NOT NULL) AS has_cc,
  i.* EXCLUDE (sk_id_curr),
  b.* EXCLUDE (sk_id_curr),
  p.* EXCLUDE (sk_id_curr),
  c.* EXCLUDE (sk_id_curr)
FROM raw.application_train a
LEFT JOIN mart.feat_installments i ON a.sk_id_curr = i.sk_id_curr
LEFT JOIN mart.feat_bureau       b ON a.sk_id_curr = b.sk_id_curr
LEFT JOIN mart.feat_prev         p ON a.sk_id_curr = p.sk_id_curr
LEFT JOIN mart.feat_cc           c ON a.sk_id_curr = c.sk_id_curr;
