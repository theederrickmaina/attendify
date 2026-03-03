"""Non-interactive database recreation for the revamped schema."""
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from pathlib import Path
from urllib.parse import urlparse, unquote
from dotenv import load_dotenv
import os

env_path = Path(__file__).resolve().parent.parent / '.env'
load_dotenv(str(env_path))

uri = os.getenv("SQLALCHEMY_DATABASE_URI", "")
parsed = urlparse(uri)
host = parsed.hostname or "localhost"
port = parsed.port or 5433
user = unquote(parsed.username) if parsed.username else "postgres"
password = unquote(parsed.password) if parsed.password else ""
dbname = parsed.path.lstrip("/") or "attendify_db"

print(f"Connecting to {host}:{port} as {user}...")

# 1. Drop and recreate database
conn = psycopg2.connect(host=host, port=port, database="postgres", user=user, password=password)
conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
cur = conn.cursor()

# Terminate existing connections
cur.execute(f"""
    SELECT pg_terminate_backend(pid) FROM pg_stat_activity
    WHERE datname = '{dbname}' AND pid <> pg_backend_pid()
""")
cur.execute(f"DROP DATABASE IF EXISTS {dbname}")
cur.execute(f"CREATE DATABASE {dbname}")
print(f"✓ Recreated database '{dbname}'")
conn.close()

# 2. Apply new schema
conn = psycopg2.connect(host=host, port=port, database=dbname, user=user, password=password)
cur = conn.cursor()

sql_path = Path(__file__).resolve().parent / "setup_postgresql.sql"
with open(sql_path, encoding="utf-8") as f:
    schema = f.read()

cur.execute(schema)
conn.commit()
print("✓ Applied new schema (12 tables, HNSW index, triggers)")
conn.close()

print("\n🎉 Database recreated. Start backend with: python start_backend.py")
