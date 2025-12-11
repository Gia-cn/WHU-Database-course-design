from sqlalchemy import create_engine, text

DB_URL = "mysql+pymysql://root:root@127.0.0.1:3306/mini_ats?charset=utf8mb4"

engine = create_engine(
    DB_URL,
    pool_size=10,
    max_overflow=20,
    pool_recycle=1800,
    pool_pre_ping=True,
)

def fetch_all(sql: str, params: dict | None = None):
    with engine.connect() as conn:
        return conn.execute(text(sql), params or {}).fetchall()

def exec_one(sql: str, params: dict | None = None):
    with engine.begin() as conn:
        conn.execute(text(sql), params or {})

def call_proc(proc_name: str, args: list):
    raw_conn = engine.raw_connection()
    cur = raw_conn.cursor()
    try:
        cur.callproc(proc_name, args)
        raw_conn.commit()
    except Exception:
        raw_conn.rollback()
        raise
    finally:
        cur.close()
        raw_conn.close()