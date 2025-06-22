-- 1) 데이터베이스 생성 (없다면)
CREATE DATABASE IF NOT EXISTS telco_churn DEFAULT CHARACTER SET utf8mb4;
USE telco_churn;

-- 2) 테이블 정의
DROP TABLE IF EXISTS customer_services;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customerID        VARCHAR(20)      PRIMARY KEY,
    gender            ENUM('Male','Female'),
    SeniorCitizen     TINYINT(1),
    Partner           ENUM('Yes','No'),
    Dependents        ENUM('Yes','No'),
    tenure            INT,
    InternetService   ENUM('DSL','Fiber optic','No'),
    Contract          ENUM('Month-to-month','One year','Two year'),
    PaperlessBilling  ENUM('Yes','No'),
    PaymentMethod     VARCHAR(50),
    MonthlyCharges    DECIMAL(8,2),
    TotalCharges      DECIMAL(10,2),
    Churn             ENUM('Yes','No')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE services (
    serviceID    INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(50)         UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE customer_services (
    customerID VARCHAR(20),
    serviceID  INT,
    PRIMARY KEY (customerID, serviceID),
    FOREIGN KEY (customerID) REFERENCES customers(customerID),
    FOREIGN KEY (serviceID)  REFERENCES services(serviceID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3) 인덱스
CREATE INDEX idx_customers_tenure   ON customers(tenure);
CREATE INDEX idx_customers_contract ON customers(Contract);

-- 4) 뷰: 월별(in tenure) 이탈률
CREATE OR REPLACE VIEW churn_rate_by_tenure AS
SELECT
  tenure,
  ROUND( AVG( CASE WHEN Churn='Yes' THEN 1 ELSE 0 END ), 3 ) AS churn_rate
FROM customers
GROUP BY tenure;

-- 5) 저장 프로시저: 계약 유형별 이탈 통계
DELIMITER $$
CREATE PROCEDURE getChurnByContract(IN contractType VARCHAR(20))
BEGIN
  SELECT
    Contract,
    COUNT(*)                                   AS total_customers,
    SUM( CASE WHEN Churn='Yes' THEN 1 ELSE 0 END ) AS churned,
    ROUND( SUM( CASE WHEN Churn='Yes' THEN 1 ELSE 0 END )/COUNT(*) ,3) AS churn_rate
  FROM customers
  WHERE Contract = contractType
  GROUP BY Contract;
END $$
DELIMITER ;

-- 6) 요약 테이블 & 트리거: 실시간 이탈 집계
CREATE TABLE IF NOT EXISTS churn_summary (
  summary_date   DATE        PRIMARY KEY,
  total_customers INT,
  total_churned   INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 초기 데이터 삽입
INSERT INTO churn_summary
SELECT CURRENT_DATE(), COUNT(*), SUM( CASE WHEN Churn='Yes' THEN 1 ELSE 0 END )
FROM customers
ON DUPLICATE KEY UPDATE 
  total_customers=VALUES(total_customers),
  total_churned  =VALUES(total_churned);

DELIMITER $$
CREATE TRIGGER after_customer_insert
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
  INSERT INTO churn_summary 
    (summary_date, total_customers, total_churned)
  VALUES
    (CURRENT_DATE(), 1, CASE WHEN NEW.Churn='Yes' THEN 1 ELSE 0 END)
  ON DUPLICATE KEY UPDATE
    total_customers = total_customers + 1,
    total_churned   = total_churned   + (CASE WHEN NEW.Churn='Yes' THEN 1 ELSE 0 END);
END $$
DELIMITER ;
