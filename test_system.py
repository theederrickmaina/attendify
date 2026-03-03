"""
Attendify System Integration Test
----------------------------------
Validates all components: .env loading, DB connection, services, and API endpoints.
Run from project root: python test_system.py
"""

import os
import sys
from pathlib import Path

# Ensure backend is on the path so its modules resolve
backend_dir = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_dir))

# ── helpers ──────────────────────────────────────────────────────────────
PASS = "✅ PASS"
FAIL = "❌ FAIL"
WARN = "⚠  WARN"

results = []

def record(name: str, ok: bool, detail: str = ""):
    results.append((name, ok, detail))
    tag = PASS if ok else FAIL
    msg = f"  {tag}  {name}"
    if detail:
        msg += f"  — {detail}"
    print(msg)
    return ok


# ── 1. Environment ──────────────────────────────────────────────────────
def test_env():
    print("\n═══ 1. Environment & Configuration ═══")
    from dotenv import load_dotenv
    env_path = Path(__file__).parent / ".env"
    load_dotenv(dotenv_path=str(env_path))

    db_uri = os.getenv("SQLALCHEMY_DATABASE_URI", "")
    record(".env file exists", env_path.exists())
    record("SQLALCHEMY_DATABASE_URI is set", bool(db_uri),
           db_uri[:60] + "…" if len(db_uri) > 60 else db_uri if db_uri else "(empty)")

    secret = os.getenv("ATTENDIFY_SECRET_KEY", "")
    record("ATTENDIFY_SECRET_KEY is set", bool(secret))

    jwt = os.getenv("ATTENDIFY_JWT_SECRET", "")
    record("ATTENDIFY_JWT_SECRET is set", bool(jwt))
    return bool(db_uri)


# ── 2. Database connection ──────────────────────────────────────────────
def test_db_connection():
    print("\n═══ 2. Database Connection ═══")
    try:
        import psycopg2
        db_uri = os.getenv("SQLALCHEMY_DATABASE_URI", "")
        if not db_uri or "postgresql" not in db_uri:
            record("PostgreSQL URI valid", False, "URI missing or not postgresql")
            return False

        # Parse URI:  postgresql://user:pass@host:port/dbname
        from urllib.parse import urlparse, unquote
        parsed = urlparse(db_uri)
        conn = psycopg2.connect(
            host=parsed.hostname or "localhost",
            port=parsed.port or 5432,
            database=parsed.path.lstrip("/"),
            user=unquote(parsed.username) if parsed.username else "postgres",
            password=unquote(parsed.password) if parsed.password else "",
        )
        cur = conn.cursor()

        # pgvector extension
        cur.execute("SELECT extname FROM pg_extension WHERE extname = 'vector'")
        has_pgvector = cur.fetchone() is not None
        record("PostgreSQL connection", True)
        record("pgvector extension loaded", has_pgvector,
               "Required for vector similarity search" if not has_pgvector else "")

        # Check tables
        cur.execute("""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
        """)
        tables = [r[0] for r in cur.fetchall()]
        expected = {"users", "students", "courses", "classes", "attendance", "recognition_metrics"}
        missing = expected - set(tables)
        record("Required tables exist", len(missing) == 0,
               f"Missing: {missing}" if missing else f"Found: {', '.join(sorted(expected & set(tables)))}")

        conn.close()
        return True
    except ImportError:
        record("psycopg2 installed", False, "pip install psycopg2-binary")
        return False
    except Exception as e:
        record("PostgreSQL connection", False, str(e)[:120])
        return False


# ── 3. Backend services ─────────────────────────────────────────────────
def test_services():
    print("\n═══ 3. Backend Services ═══")
    import numpy as np

    # FaceNet
    try:
        from facenet_service import FaceNetService
        svc = FaceNetService()
        img = np.random.randint(0, 255, (200, 200, 3), dtype=np.uint8)
        emb = svc.extract_embedding(img)
        using_real = not svc.use_mock
        record("FaceNetService initialises", True,
               "InsightFace (real)" if using_real else "mock mode")
        if using_real:
            # Real InsightFace won't find a face in random noise — that's correct
            record("extract_embedding correct on noise", emb is None,
                   "Correctly returns None for non-face image")
        else:
            record("extract_embedding returns 512-d (mock)", emb is not None and len(emb) == 512)
        quality = svc.assess_image_quality(img)
        record("assess_image_quality runs", "quality_ok" in quality)
    except Exception as e:
        record("FaceNetService", False, str(e)[:120])

    # Liveness
    try:
        from liveness_detection import LivenessDetector
        det = LivenessDetector()
        img = np.random.randint(0, 255, (200, 200, 3), dtype=np.uint8)
        res = det.quick_liveness_check(img)
        record("LivenessDetector initialises", True)
        record("quick_liveness_check runs", "is_live" in res)
    except Exception as e:
        record("LivenessDetector", False, str(e)[:120])


# ── 4. Flask app boots ──────────────────────────────────────────────────
def test_flask_app():
    print("\n═══ 4. Flask Application ═══")
    try:
        from app import app
        record("Flask app imports without error", True)

        with app.test_client() as c:
            r = c.get("/health")
            record("/health returns 200", r.status_code == 200)

            # Login with demo admin
            r = c.post("/api/login", json={
                "username": "admin_lecturer1",
                "password": "adminpasshash1"
            })
            login_ok = r.status_code == 200 and "access_token" in (r.get_json() or {})
            record("Demo admin login", login_ok,
                   "Token received" if login_ok else f"status={r.status_code}")

            if login_ok:
                token = r.get_json()["access_token"]
                headers = {"Authorization": f"Bearer {token}"}

                # Admin list students
                r = c.get("/api/admin/students", headers=headers)
                resp = r.get_json() or {}
                record("GET /api/admin/students", r.status_code == 200,
                       f"{resp.get('count', '?')} students" if r.status_code == 200
                       else f"status={r.status_code} body={resp}")

                # Admin reports
                r = c.get("/api/admin/reports", headers=headers)
                resp2 = r.get_json() or {}
                record("GET /api/admin/reports", r.status_code == 200,
                       "OK" if r.status_code == 200
                       else f"status={r.status_code} body={resp2}")

            # Enroll validation (no image → 400)
            r = c.post("/api/enroll", json={"name": "Test"})
            record("POST /api/enroll rejects missing fields", r.status_code == 400)

            # Recognize validation (no image → 400)
            r = c.post("/api/recognize", json={})
            record("POST /api/recognize rejects missing image", r.status_code == 400)

        return True
    except Exception as e:
        record("Flask app", False, str(e)[:200])
        return False


# ── 5. DB seeding ────────────────────────────────────────────────────────
def test_seeding():
    print("\n═══ 5. Demo Data Seeding ═══")
    try:
        from app import app, initialize_database_with_demo_data
        from extensions import db
        from models import User, Student, Course, Class

        with app.app_context():
            initialize_database_with_demo_data()

            users = User.query.count()
            students = Student.query.count()
            courses = Course.query.count()
            classes = Class.query.count()

            record("Users seeded", users >= 2, f"{users} users")
            record("Students seeded", students >= 50, f"{students} students")
            record("Courses seeded", courses >= 5, f"{courses} courses")
            record("Classes seeded", classes > 0, f"{classes} classes")
        return True
    except Exception as e:
        record("Demo data seeding", False, str(e)[:200])
        return False


# ── main ─────────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  ATTENDIFY — Full System Integration Test")
    print("=" * 60)

    env_ok = test_env()

    if env_ok:
        db_ok = test_db_connection()
    else:
        print("\n  ⏭  Skipping DB test (no URI configured)")
        db_ok = False

    test_services()

    if env_ok:
        test_seeding()
        test_flask_app()
    else:
        print("\n  ⏭  Skipping Flask & seeding tests (no URI configured)")

    # ── summary ──────────────────────────────────────────────────────────
    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print("\n" + "=" * 60)
    print(f"  RESULT: {passed}/{total} checks passed")
    print("=" * 60)

    failed = [(n, d) for n, ok, d in results if not ok]
    if failed:
        print("\n  Items that need attention:")
        for n, d in failed:
            print(f"    • {n}" + (f"  — {d}" if d else ""))

    if not env_ok:
        print("\n  ⚠  YOUR .env FILE IS EMPTY — see instructions below.")

    print()
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
