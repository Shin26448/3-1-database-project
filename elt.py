import pandas as pd
import mysql.connector
import logging
from mysql.connector import Error

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s'
)

DB_CONF = {
    'host': 'localhost',
    'user': 'root',
    'password': '1234',
    'database': 'telco_churn',
    'auth_plugin': 'mysql_native_password'
}

SERVICES = ["StreamingTV", "StreamingMovies", "OnlineSecurity", "OnlineBackup", 
            "DeviceProtection", "TechSupport", "PaperlessBilling", "MultipleLines"]

def get_connection():
    try:
        return mysql.connector.connect(**DB_CONF)
    except Error as e:
        logging.error("DB 연결 실패: %s", e)
        raise

def load_services(cursor):
    try:
        cursor.executemany(
            "INSERT IGNORE INTO services (service_name) VALUES (%s)",
            [(s,) for s in SERVICES]
        )
        logging.info("services 테이블 로드 완료")
    except Error as e:
        logging.error("services 삽입 실패: %s", e)
        raise

def load_customers(cursor):
    df = pd.read_csv('dataset.csv')
    df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce').fillna(0)
    cust_cols = ['customerID','gender','SeniorCitizen','Partner','Dependents',
                 'tenure','InternetService','Contract','PaperlessBilling',
                 'PaymentMethod','MonthlyCharges','TotalCharges','Churn']
    vals = df[cust_cols].values.tolist()
    try:
        cursor.executemany(
            """INSERT IGNORE INTO customers 
               (customerID,gender,SeniorCitizen,Partner,Dependents,
                tenure,InternetService,Contract,PaperlessBilling,
                PaymentMethod,MonthlyCharges,TotalCharges,Churn)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
            vals
        )
        logging.info("customers 테이블 로드 완료")
    except Error as e:
        logging.error("customers 삽입 실패: %s", e)
        raise

def load_customer_services(cursor):
    df = pd.read_csv('dataset.csv')
    pairs = []
    for s in SERVICES:
        pairs += [
            (row['customerID'], s)
            for _, row in df[df[s]=='Yes'].iterrows()
        ]
    try:
        cursor.executemany(
            """INSERT IGNORE INTO customer_services (customerID, serviceID)
               SELECT %s, serviceID FROM services WHERE service_name=%s""",
            pairs
        )
        logging.info("customer_services 테이블 로드 완료")
    except Error as e:
        logging.error("customer_services 삽입 실패: %s", e)
        raise

def main():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        load_services(cursor)
        load_customers(cursor)
        load_customer_services(cursor)
        conn.commit()
        logging.info("ETL 완료")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    main()
