USE telco_churn;

-- 기존 프로시저가 있으면 삭제
DROP PROCEDURE IF EXISTS getChurnByContract;
DROP PROCEDURE IF EXISTS getChurnByPayment;

DELIMITER $$

-- ① 계약 유형별 이탈 프로시저
CREATE PROCEDURE getChurnByContract(IN contractType VARCHAR(50))
BEGIN
  SELECT
    Contract           AS label,
    ROUND( AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END), 3 ) AS churn_rate,
    COUNT(*)           AS cnt
  FROM customers
  WHERE Contract = contractType
  GROUP BY Contract;
END $$

-- ② 결제 방식별 이탈 프로시저
CREATE PROCEDURE getChurnByPayment(IN payMethod VARCHAR(50))
BEGIN
  SELECT
    PaymentMethod      AS label,
    ROUND( AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END), 3 ) AS churn_rate,
    COUNT(*)           AS cnt
  FROM customers
  WHERE PaymentMethod = payMethod
  GROUP BY PaymentMethod;
END $$

DELIMITER ;
