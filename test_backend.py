"""Quick backend verification for the revamped Attendify system."""
import sys
sys.path.insert(0, "backend")
from dotenv import load_dotenv
load_dotenv(".env")
from app import app

PASS = "✅"
FAIL = "❌"
results = []

def check(name, ok, detail=""):
    results.append(ok)
    print(f"  {PASS if ok else FAIL}  {name}" + (f"  — {detail}" if detail else ""))

with app.test_client() as c:
    print("\n═══ Auth ═══")
    # Admin login
    r = c.post("/api/auth/login", json={"username": "admin", "password": "admin123"})
    d = r.get_json() or {}
    check("Admin login", r.status_code == 200, d.get("user", {}).get("full_name", ""))
    admin_token = d.get("access_token", "")
    ah = {"Authorization": f"Bearer {admin_token}"}

    # Lecturer login
    r = c.post("/api/auth/login", json={"username": "dr.mwangi", "password": "lecturer123"})
    d = r.get_json() or {}
    check("Lecturer login", r.status_code == 200, d.get("user", {}).get("full_name", ""))
    lec_token = d.get("access_token", "")
    lh = {"Authorization": f"Bearer {lec_token}"}

    # Student login
    r = c.post("/api/auth/login", json={"username": "john.njoroge", "password": "student123"})
    d = r.get_json() or {}
    check("Student login", r.status_code == 200, d.get("user", {}).get("full_name", ""))
    stu_token = d.get("access_token", "")
    sh = {"Authorization": f"Bearer {stu_token}"}

    # Wrong password
    r = c.post("/api/auth/login", json={"username": "admin", "password": "wrong"})
    check("Bad password rejected", r.status_code == 401)

    print("\n═══ Admin endpoints ═══")
    r = c.get("/api/admin/dashboard", headers=ah)
    d = r.get_json() or {}
    check("Dashboard", r.status_code == 200, f"students={d.get('students')}")

    r = c.get("/api/admin/users", headers=ah)
    d = r.get_json() or {}
    check("Users list", r.status_code == 200, f"count={d.get('count')}")

    r = c.get("/api/admin/departments", headers=ah)
    d = r.get_json() or {}
    check("Departments", r.status_code == 200, f"count={len(d.get('departments', []))}")

    r = c.get("/api/admin/courses", headers=ah)
    d = r.get_json() or {}
    check("Courses", r.status_code == 200, f"count={len(d.get('courses', []))}")

    r = c.get("/api/admin/units", headers=ah)
    d = r.get_json() or {}
    check("Units", r.status_code == 200, f"count={len(d.get('units', []))}")

    r = c.get("/api/admin/students", headers=ah)
    d = r.get_json() or {}
    check("Students", r.status_code == 200, f"count={d.get('count')}")

    r = c.get("/api/admin/devices", headers=ah)
    d = r.get_json() or {}
    check("Devices", r.status_code == 200, f"count={len(d.get('devices', []))}")

    r = c.get("/api/admin/reports", headers=ah)
    check("Reports", r.status_code == 200)

    r = c.get("/api/admin/audit-log", headers=ah)
    check("Audit log", r.status_code == 200)

    # Role enforcement
    r = c.get("/api/admin/dashboard", headers=lh)
    check("Lecturer blocked from admin", r.status_code == 403)

    print("\n═══ Lecturer endpoints ═══")
    r = c.get("/api/lecturer/dashboard", headers=lh)
    d = r.get_json() or {}
    check("Lecturer dashboard", r.status_code == 200, f"units={len(d.get('units', []))}")

    r = c.get("/api/lecturer/units", headers=lh)
    check("Lecturer units", r.status_code == 200)

    r = c.get("/api/lecturer/sessions", headers=lh)
    d = r.get_json() or {}
    check("Lecturer sessions", r.status_code == 200, f"count={len(d.get('sessions', []))}")

    print("\n═══ Student endpoints ═══")
    r = c.get("/api/student/dashboard", headers=sh)
    d = r.get_json() or {}
    check("Student dashboard", r.status_code == 200, d.get("student", {}).get("name", ""))

    r = c.get("/api/student/attendance", headers=sh)
    check("Student attendance", r.status_code == 200)

    print("\n═══ Health ═══")
    r = c.get("/health")
    check("Health check", r.status_code == 200)

passed = sum(results)
total = len(results)
print(f"\n{'='*50}")
print(f"  RESULT: {passed}/{total} checks passed")
print(f"{'='*50}")
