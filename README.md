# Telco Churn Dashboard

통신사 고객 이탈(Churn) 데이터 분석 파이프라인 및 대시보드

---

## 파일 구조

```
.
├── README.md
├── create_schema.sql # DB 스키마·테이블·인덱스·트리거 정의
├── analysis_views.sql # 뷰 정의 (tenure, gender, contract, service, charge_group)
├── analysis_procedures.sql # 프로시저 정의 (getChurnByContract, getChurnByPayment)
├── elt.py # ETL 스크립트 (CSV → MySQL)
├── app.py # Flask API 서버 (View/Proc → JSON)
├── templates/
│ └── index.html # Chart.js 대시보드 UI
└── dataset.csv # 원본 데이터 (Telco 고객 이탈)

```

---
## 데이터 구조
```
erDiagram
    CUSTOMERS {
        VARCHAR customerID PK "고객 ID"
        ENUM    gender
        TINYINT SeniorCitizen
        ENUM    Partner
        ENUM    Dependents
        INT     tenure "가입 개월수"
        ENUM    InternetService
        ENUM    Contract
        ENUM    PaperlessBilling
        VARCHAR PaymentMethod
        DECIMAL MonthlyCharges
        DECIMAL TotalCharges
        ENUM    Churn "이탈 여부"
    }
    SERVICES {
        INT     serviceID PK "서비스 ID"
        VARCHAR service_name "서비스명"
    }
    CUSTOMER_SERVICES {
        VARCHAR customerID FK "고객 ID"
        INT     serviceID  FK "서비스 ID"
    }
    CHURN_SUMMARY {
        DATE  summary_date PK "집계 날짜"
        INT   total_customers
        INT   total_churned
    }

    %% 관계 정의
    CUSTOMERS ||--o{ CUSTOMER_SERVICES : "enrolled in"
    SERVICES  ||--o{ CUSTOMER_SERVICES : "offered by"
```

## 설치 및 실행



### 1. Python 가상환경 및 패키지 설치

python -m venv venv

Windows
venv\Scripts\activate

macOS/Linux
source venv/bin/activate

pip install --upgrade pip
pip install flask pandas mysql-connector-python


### 2. MySQL 유저 및 권한 설정

MySQL 콘솔 또는 Workbench에서 다음 쿼리 실행

CREATE DATABASE IF NOT EXISTS telco_churn;
CREATE USER 'churn_user'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON telco_churn.* TO 'churn_user'@'localhost';
FLUSH PRIVILEGES;


`app.py`의 DB_CONF를 위 계정 정보로 수정

### 3. 스키마, 뷰, 프로시저 생성

mysql -u churn_user -p1234 < create_schema.sql
mysql -u churn_user -p1234 < analysis_views.sql
mysql -u churn_user -p1234 < analysis_procedures.sql


또는 Workbench에서 각 SQL 파일을 열어 실행

### 4. ETL 데이터 적재

python elt.py

- dataset.csv로부터 customers, services, customer_services 테이블을 채움

### 5. 웹 서버 실행

python app.py

- 브라우저에서 http://127.0.0.1:5000 접속

---

## 코드 설명

- **elt.py**
  - get_connection(): MySQL 연결 생성 및 예외 로깅
  - load_services(): 서비스 목록을 services 테이블에 삽입
  - load_customers(): dataset.csv → customers (TotalCharges 공백→0 처리)
  - load_customer_services(): Y/N 컬럼 기반 M:N customer_services 테이블 적재

- **analysis_views.sql**
  - churn_rate_by_tenure: 가입 개월수별 이탈률
  - churn_by_gender: 성별별 이탈률
  - churn_by_contract: 계약 유형별 이탈률
  - churn_by_service: 서비스별 이탈률
  - churn_by_charge_group: 요금 구간별(10단위) 이탈률

- **analysis_procedures.sql**
  - getChurnByContract(contractType): 계약별 이탈률 및 고객 수 반환
  - getChurnByPayment(payMethod): 결제 방식별 이탈률 및 고객 수 반환

- **app.py**
  - VIEW_SQL / PROC_MAP: 뷰 조회 또는 프로시저 호출 매핑
  - /data API: { labels:[], values:[] } JSON 반환
  - 에러 핸들링, 간단 캐싱, 로딩 인디케이터 포함

- **templates/index.html**
  - Chart.js 기반 막대차트
  - View/Proc 모드 토글, 파라미터 드롭다운
  - 로딩 스피너, 반응형 모바일 대응

---

## 향후 아이디어

- 예측 모델(로지스틱 회귀) 연동
- 사용자 인증/권한 관리

---

## 참고

- https://github.com/Shin26448/3-1-database-project