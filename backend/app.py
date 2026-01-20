"""
Attendify Backend Main App
--------------------------
To run: `python -m backend.app`

Sets up the Flask application and SQLite database via SQLAlchemy.

Security & Compliance Notes:
- SECRET_KEY is loaded from the environment when available; otherwise a random, secure fallback is used.
- Database configured to use local SQLite for demo; designed to be replaceable with institutional systems later.
  To use PostgreSQL/MySQL, set `SQLALCHEMY_DATABASE_URI` env var.
- Cryptography is used to encrypt biometric data (facial embeddings) using Fernet to meet Kenya's Data Protection Act requirements
  (e.g., informed consent and DPIA considerations). Only process biometric data when consent_given=True.
"""

import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager,
    create_access_token,
    jwt_required,
    get_jwt_identity,
    get_jwt,
)

from cryptography.fernet import Fernet
from datetime import time, datetime
import base64
import json
import hashlib
import random
import math

# Create the Flask application instance
app = Flask(__name__)

# Configure the app:
# - SECRET_KEY: used for securely signing session data and other security-related features.
#   Prefer loading from environment to avoid hardcoding secrets. Fallback is a securely generated random value.
app.config["SECRET_KEY"] = os.getenv("ATTENDIFY_SECRET_KEY", os.urandom(32))

# - SQLALCHEMY_DATABASE_URI: defaults to local SQLite ("sqlite:///attendify.db").
#   Set this environment variable to connect to PostgreSQL, MySQL, etc.
#   Example: postgresql://user:password@localhost/attendify_db
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("SQLALCHEMY_DATABASE_URI", "sqlite:///attendify.db")

# - Disable track modifications to save overhead unless signals are required.
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

app.config["JWT_SECRET_KEY"] = os.getenv("ATTENDIFY_JWT_SECRET", os.urandom(32))

JWTManager(app)
CORS(app, resources={r"/api/*": {"origins": "*"}})

from backend.extensions import db
db.init_app(app)

# Import models after 'db' is defined to avoid circular imports
from backend.models import User, Student, Course, Class, Attendance  # noqa: E402


def _get_fernet() -> Fernet:
    """
    Returns a Fernet instance using ATTENDIFY_FERNET_KEY if provided,
    otherwise generates a secure ephemeral key for demo purposes.

    Note: Do not log or hardcode keys; in production, load from secrets manager.
    """
    key = os.getenv("ATTENDIFY_FERNET_KEY")
    if key:
        return Fernet(key.encode("utf-8"))
    generated = Fernet.generate_key()
    return Fernet(generated)


def _encrypt_embedding_if_consented(user: User, raw_bytes: bytes, fernet: Fernet) -> bytes:
    """
    Encrypts the facial embedding only if the user has given consent.
    Raises ValueError when consent is not given to prevent processing.
    """
    if not user.consent_given:
        raise ValueError("Consent not given; biometric processing is prohibited.")
    return fernet.encrypt(raw_bytes)


def _bytes_to_vector(enc_bytes: bytes, fernet: Fernet) -> list[float]:
    data = fernet.decrypt(enc_bytes)
    return json.loads(data.decode("utf-8"))


def _vector_to_bytes(vec: list[float], fernet: Fernet) -> bytes:
    payload = json.dumps(vec).encode("utf-8")
    return fernet.encrypt(payload)


def _cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na == 0 or nb == 0:
        return 0.0
    return dot / (na * nb)


def _generate_embedding(image_b64: str) -> list[float]:
    """
    Simulated embedding generator:
    - Derives a deterministic random seed from the image bytes (SHA256)
    - Generates a 128-dim vector and normalizes it
    Note: Replace this with actual ML integration (ML Kit) in the frontend
    and a server-side verification flow if needed.
    """
    try:
        raw = base64.b64decode(image_b64)
    except Exception:
        raw = os.urandom(256)
    digest = hashlib.sha256(raw).hexdigest()
    seed = int(digest[:16], 16)
    rng = random.Random(seed)
    vec = [rng.random() for _ in range(128)]
    norm = math.sqrt(sum(x * x for x in vec)) or 1.0
    return [x / norm for x in vec]


def _current_day_abbrev() -> str:
    return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][datetime.now().weekday()]


def _find_current_class() -> Class | None:
    day = _current_day_abbrev()
    now_t = datetime.now().time()
    return (
        Class.query.filter_by(day_of_week=day)
        .filter(Class.start_time <= now_t, Class.end_time >= now_t)
        .first()
    )


def _require_role(required: str):
    def decorator(fn):
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            role = claims.get("role")
            if role != required:
                return jsonify({"error": "forbidden"}), 403
            return fn(*args, **kwargs)
        wrapper.__name__ = fn.__name__
        return jwt_required()(wrapper)
    return decorator


def initialize_database_with_demo_data():
    """
    Creates tables and seeds demo data:
    - 2 admins (lecturers)
    - 5 courses and 5 classes (Mon 09:00-11:00)
    - 10 students with consent and encrypted facial embeddings
    """
    with app.app_context():
        db.create_all()

        # Seed only if empty to avoid duplicates
        if User.query.count() > 0:
            return

        fernet = _get_fernet()

        # Create admins (lecturers)
        admin1 = User(
            username="admin_lecturer1",
            password_hash="pbkdf2:sha256:adminpasshash1",
            role="admin",
            consent_given=True,
        )
        admin2 = User(
            username="admin_lecturer2",
            password_hash="pbkdf2:sha256:adminpasshash2",
            role="admin",
            consent_given=True,
        )
        db.session.add_all([admin1, admin2])
        db.session.flush()  # ensure IDs for FKs

        # Create courses
        course_data = [
            ("Introduction to IT", "IT101"),
            ("Data Structures", "IT201"),
            ("Databases", "IT301"),
            ("Computer Networks", "IT401"),
            ("Software Engineering", "IT501"),
        ]
        courses = []
        for name, code in course_data:
            c = Course(name=name, code=code)
            courses.append(c)
        db.session.add_all(courses)
        db.session.flush()

        # Create classes (Mon 9-11 AM) each taught by alternating admins
        classes = []
        for idx, course in enumerate(courses):
            lecturer = admin1 if idx % 2 == 0 else admin2
            cls = Class(
                course_id=course.id,
                day_of_week="Mon",
                start_time=time(9, 0),
                end_time=time(11, 0),
                lecturer_id=lecturer.id,
            )
            classes.append(cls)
        db.session.add_all(classes)
        db.session.flush()

        # Create 10 students with consent and encrypted facial embeddings
        names = [
            "John Doe",
            "Jane Doe",
            "Alice Kim",
            "Bob Otieno",
            "Peter Njoroge",
            "Mary Wambui",
            "Samuel Karanja",
            "Lucy Wangari",
            "Brian Mwangi",
            "Diana Achieng",
        ]

        student_users = []
        student_rows = []
        for i, name in enumerate(names, start=1):
            username = f"student{i}"
            # Simple demo password hash placeholder; replace with a secure hash in real flows
            # For demo: store a recognizable hash-like string; in production, hash securely
            user = User(
                username=username,
                password_hash=f"pbkdf2:sha256:studentpasshash{i}",
                role="student",
                consent_given=True,
            )
            student_users.append(user)
        db.session.add_all(student_users)
        db.session.flush()

        for i, (user, name) in enumerate(zip(student_users, names), start=1):
            year = (i % 4) + 1  # 1..4
            semester = (i % 2) + 1  # 1..2
            course_name = ["IT", "CS", "SE", "IS"][i % 4]
            reg_no = f"EMB-{course_name}-{i:04d}"

            # Demo raw embedding (random-like bytes); encrypt only if consent is given
            raw_embedding = os.urandom(128)
            try:
                encrypted_embedding = _encrypt_embedding_if_consented(user, raw_embedding, fernet)
            except ValueError:
                encrypted_embedding = None

            student = Student(
                user_id=user.id,
                name=name,
                registration_number=reg_no,
                course=course_name,
                year=year,
                semester=semester,
                facial_embedding=encrypted_embedding,
            )
            student_rows.append(student)
        db.session.add_all(student_rows)

        # Optionally, seed a few attendance records to demonstrate relationships
        # (Not required, kept minimal)
        if classes:
            # Ensure student IDs are available
            db.session.flush()
            now = datetime.utcnow()
            sample_class = classes[0]
            for s in student_rows[:5]:
                att = Attendance(
                    student_id=s.id,
                    class_id=sample_class.id,
                    timestamp=now,
                    status="present" if s.id % 2 == 0 else "absent",
                )
                db.session.add(att)

        db.session.commit()
        # End seeding


# Optional: Provide a minimal health-check route for quick verification during development.
# Actual API routes will be added in later steps.
@app.get("/health")
def health():
    return {"status": "ok", "service": "attendify-backend"}


@app.post("/api/login")
def api_login():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "")
    password = data.get("password", "")
    user = User.query.filter_by(username=username).first()
    if not user:
        return jsonify({"error": "invalid_credentials"}), 401
    # Demo check: compare against seeded labels; replace with real hash checking in production
    expected = user.password_hash
    if not expected.endswith(password):
        return jsonify({"error": "invalid_credentials"}), 401
    token = create_access_token(
        identity=user.id,
        additional_claims={"role": user.role, "username": user.username},
    )
    return jsonify({"access_token": token})


@app.post("/api/consent")
@jwt_required()
def api_consent():
    uid = get_jwt_identity()
    user = User.query.get(uid)
    if not user:
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}
    consent = bool(data.get("consent", False))
    user.consent_given = consent
    db.session.commit()
    return jsonify({"message": "consent_updated", "consent_given": user.consent_given})


@app.post("/api/enroll")
def api_enroll():
    data = request.get_json(silent=True) or {}
    name = data.get("name")
    reg_no = data.get("reg_no")
    course = data.get("course")
    year = int(data.get("year", 1))
    semester = int(data.get("semester", 1))
    image_b64 = data.get("facial_image_base64")
    consent = bool(data.get("consent", False))
    username = data.get("username") or reg_no
    password = data.get("password") or "changeme"

    if not all([name, reg_no, course, image_b64]):
        return jsonify({"error": "missing_fields"}), 400
    if not consent:
        return jsonify({"error": "consent_required"}), 403

    if User.query.filter_by(username=username).first():
        return jsonify({"error": "user_exists"}), 409
    if Student.query.filter_by(registration_number=reg_no).first():
        return jsonify({"error": "student_exists"}), 409

    fernet = _get_fernet()
    vec = _generate_embedding(image_b64)
    enc_bytes = _vector_to_bytes(vec, fernet)

    user = User(
        username=username,
        password_hash=f"pbkdf2:sha256:{password}",
        role="student",
        consent_given=True,
    )
    db.session.add(user)
    db.session.flush()

    student = Student(
        user_id=user.id,
        name=name,
        registration_number=reg_no,
        course=course,
        year=year,
        semester=semester,
        facial_embedding=enc_bytes,
    )
    db.session.add(student)
    db.session.commit()
    return jsonify({"message": "enrolled", "student_id": student.id})


@app.post("/api/recognize")
def api_recognize():
    data = request.get_json(silent=True) or {}
    image_b64 = data.get("facial_image_base64")
    if not image_b64:
        return jsonify({"error": "missing_image"}), 400
    fernet = _get_fernet()
    probe = _generate_embedding(image_b64)

    best = None
    best_score = 0.0
    for s in Student.query.all():
        u = s.user
        if not u or not u.consent_given or not s.facial_embedding:
            continue
        try:
            vec = _bytes_to_vector(s.facial_embedding, fernet)
            score = _cosine_similarity(probe, vec)
            if score > best_score:
                best, best_score = s, score
        except Exception:
            continue

    if not best or best_score < 0.8:
        return jsonify({"matched": False, "score": best_score}), 200

    current = _find_current_class()
    if not current:
        return jsonify({"matched": True, "score": best_score, "attendance_logged": False, "reason": "no_active_class"}), 200

    att = Attendance(
        student_id=best.id,
        class_id=current.id,
        timestamp=datetime.now(),
        status="present",
    )
    db.session.add(att)
    db.session.commit()
    return jsonify({
        "matched": True,
        "score": best_score,
        "attendance_logged": True,
        "student": {
            "id": best.id,
            "name": best.name,
            "reg_no": best.registration_number,
            "course": best.course,
            "year": best.year,
            "semester": best.semester,
        },
        "class": {
            "id": current.id,
            "course_id": current.course_id,
            "day_of_week": current.day_of_week,
            "start_time": current.start_time.isoformat(),
            "end_time": current.end_time.isoformat(),
        }
    }), 200


@app.get("/api/student/attendance")
@_require_role("student")
def api_student_attendance():
    uid = get_jwt_identity()
    user = User.query.get(uid)
    if not user or not user.student:
        return jsonify({"error": "not_found"}), 404
    s = user.student
    logs = []
    for a in s.attendances:
        logs.append({
            "attendance_id": a.id,
            "class_id": a.class_id,
            "timestamp": a.timestamp.isoformat(),
            "status": a.status,
        })
    present = sum(1 for l in logs if l["status"] == "present")
    absent = sum(1 for l in logs if l["status"] == "absent")
    return jsonify({"student_id": s.id, "logs": logs, "summary": {"present": present, "absent": absent}})


@app.get("/api/admin/reports")
@_require_role("admin")
def api_admin_reports():
    logs = Attendance.query.all()
    total = len(logs)
    present = sum(1 for a in logs if a.status == "present")
    absent = sum(1 for a in logs if a.status == "absent")
    absenteeism_rate = (absent / total) if total else 0.0

    by_class = {}
    for a in logs:
        by_class.setdefault(a.class_id, {"present": 0, "absent": 0})
        by_class[a.class_id][a.status] += 1
    return jsonify({
        "total_records": total,
        "present": present,
        "absent": absent,
        "absenteeism_rate": absenteeism_rate,
        "by_class": by_class,
    })


# Error handlers
@app.errorhandler(400)
def err_400(e):
    return jsonify({"error": "bad_request"}), 400


@app.errorhandler(401)
def err_401(e):
    return jsonify({"error": "unauthorized"}), 401


@app.errorhandler(403)
def err_403(e):
    return jsonify({"error": "forbidden"}), 403


@app.errorhandler(404)
def err_404(e):
    return jsonify({"error": "not_found"}), 404


@app.errorhandler(500)
def err_500(e):
    return jsonify({"error": "server_error"}), 500

if __name__ == "__main__":
    # Debug mode is useful during development; do not enable in production.
    initialize_database_with_demo_data()
    app.run(host="0.0.0.0", port=5000, debug=True)
