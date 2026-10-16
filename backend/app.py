"""Backend microservice: GET / runs SELECT 1 on RDS and returns JSON."""
import datetime
import logging
import os

import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("backend-api")


def check_db() -> None:
    """Open a short-lived connection and run SELECT 1 (raises on failure)."""
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        sslmode=os.getenv("DB_SSLMODE", "require"),
        connect_timeout=3,
    )
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
            cur.fetchone()
    finally:
        conn.close()


@app.after_request
def cors(resp):
    # Frontend (CloudFront) calls this API cross-origin.
    resp.headers["Access-Control-Allow-Origin"] = os.getenv("CORS_ORIGIN", "*")
    resp.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    return resp


@app.get("/")
def index():
    status, code = "connected", 200
    try:
        check_db()
    except Exception as exc:  # noqa: BLE001
        log.error("database check failed: %s", exc)
        status, code = "error", 503
    return (
        jsonify(
            pod_name=os.getenv("POD_NAME", os.getenv("HOSTNAME", "unknown")),
            db_status=status,
            timestamp=datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        ),
        code,
    )


@app.get("/healthz")
def healthz():
    # Liveness/readiness: deliberately does NOT touch the DB so a DB blip
    # does not cause the ALB to drain every pod.
    return jsonify(status="ok"), 200
