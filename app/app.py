import os
import time
from flask import Flask, jsonify
import redis
import psycopg2

app = Flask(__name__)

REDIS_HOST = os.environ.get("REDIS_HOST", "redis-cache")
DB_HOST = os.environ.get("DB_HOST", "postgres-db")
DB_NAME = os.environ.get("POSTGRES_DB", "masterydb")
DB_USER = os.environ.get("POSTGRES_USER", "masteryuser")
DB_PASS = os.environ.get("POSTGRES_PASSWORD", "supersecretpass")

# Connect to Redis
cache = redis.Redis(host=REDIS_HOST, port=6379)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": time.time()}), 200

@app.route("/")
def index():
    # Increment visit count in Redis
    visits = cache.incr("visit_count")
    
    # Query PostgreSQL
    db_status = "connected"
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT version();")
        db_version = cur.fetchone()[0]
        cur.close()
        conn.close()
    except Exception as e:
        db_status = f"failed: {str(e)}"
        db_version = "N/A"

    return jsonify({
        "message": "DevOps Master Stack is live!",
        "visit_count": visits,
        "database_status": db_status,
        "database_version": db_version
    }), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
