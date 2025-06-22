from flask import Flask, render_template, request, jsonify
import mysql.connector, logging
from functools import lru_cache
from mysql.connector import Error

logging.basicConfig(level=logging.INFO,
                    format='[%(asctime)s] %(levelname)s: %(message)s')

DB_CONF = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '1234',
    'database': 'telco_churn',
    'auth_plugin': 'mysql_native_password'
}

VIEW_SQL = {
    'tenure':   "SELECT tenure AS label, churn_rate FROM churn_rate_by_tenure",
    'gender':   "SELECT label, churn_rate FROM churn_by_gender",
    'contract': "SELECT label, churn_rate FROM churn_by_contract",
    'service':  "SELECT label, churn_rate FROM churn_by_service",
    'charge':   "SELECT label, churn_rate FROM churn_by_charge_group",
}

PROC_MAP = {
    'contract_proc': ('getChurnByContract', ['label','churn_rate','cnt']),
    'payment_proc':  ('getChurnByPayment',  ['label','churn_rate','cnt']),
}

app = Flask(__name__, template_folder='templates')

def get_db():
    return mysql.connector.connect(**DB_CONF)

# 간단 캐시: 같은 요청 60초 동안 재사용
@lru_cache(maxsize=32)
def fetch_view(sql: str):
    conn = get_db(); cur = conn.cursor()
    cur.execute(sql)
    data = cur.fetchall()
    cur.close(); conn.close()
    return data

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/data')
def data():
    by  = request.args.get('by', 'tenure')
    arg = request.args.get('arg', '')
    try:
        if by in VIEW_SQL:
            rows = fetch_view(VIEW_SQL[by])

        elif by in PROC_MAP:
            proc_name, cols = PROC_MAP[by]
            conn = get_db(); cur = conn.cursor()
            cur.callproc(proc_name, [arg])
            results = cur.stored_results()
            raw = next(results).fetchall()
            cur.close(); conn.close()
            rows = [ (r[0], float(r[1])) for r in raw ]

        else:
            rows = fetch_view(VIEW_SQL['tenure'])

        labels = [ r[0] for r in rows ]
        values = [ float(r[1]) for r in rows ]
        return jsonify(labels=labels, values=values)

    except Error as e:
        logging.error("데이터 조회 실패: %s", e)
        return jsonify(error=str(e)), 500

if __name__ == '__main__':
    app.run(debug=True)
