USE telco_churn;

-- 1) Tenure별 이탈률
DROP VIEW IF EXISTS churn_rate_by_tenure;
CREATE OR REPLACE VIEW churn_rate_by_tenure AS
SELECT
  tenure,
  ROUND( AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END), 3 ) AS churn_rate
FROM customers
GROUP BY tenure;

-- 2) 성별 이탈률
DROP VIEW IF EXISTS churn_by_gender;
CREATE OR REPLACE VIEW churn_by_gender AS
SELECT
  gender     AS label,
  ROUND( AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END), 3 ) AS churn_rate
FROM customers
GROUP BY gender;

-- 3) 계약 유형별 이탈률
DROP VIEW IF EXISTS churn_by_contract;
CREATE OR REPLACE VIEW churn_by_contract AS
SELECT
  Contract   AS label,
  ROUND( AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END), 3 ) AS churn_rate
FROM customers
GROUP BY Contract;

-- 4) 서비스별 이탈률
DROP VIEW IF EXISTS churn_by_service;
CREATE OR REPLACE VIEW churn_by_service AS
SELECT
  s.service_name AS label,
  ROUND( AVG(CASE WHEN c.Churn='Yes' THEN 1 ELSE 0 END), 3 ) AS churn_rate
FROM services s
LEFT JOIN customer_services cs ON s.serviceID = cs.serviceID
LEFT JOIN customers c           ON cs.customerID = c.customerID
GROUP BY s.service_name;

-- 5) 요금 구간별 이탈률 (10단위)
DROP VIEW IF EXISTS churn_by_charge_group;
CREATE OR REPLACE VIEW churn_by_charge_group AS
SELECT
  CONCAT(
    FLOOR(MonthlyCharges/10)*10, '-',
    FLOOR(MonthlyCharges/10)*10 + 9
  ) AS label,
  ROUND(
    SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)
    / COUNT(*)
  ,3) AS churn_rate
FROM customers
GROUP BY
  CONCAT(
    FLOOR(MonthlyCharges/10)*10, '-',
    FLOOR(MonthlyCharges/10)*10 + 9
  )
ORDER BY
  CONCAT(
    FLOOR(MonthlyCharges/10)*10, '-',
    FLOOR(MonthlyCharges/10)*10 + 9
  );
