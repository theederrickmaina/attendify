"""
Attendify — Flask API  ·  Embu University
─────────────────────────────────────────
Roles:   superadmin  ·  lecturer  ·  student  ·  kiosk (device-key)
Stack:   Flask + SQLAlchemy + pgvector + InsightFace + JWT
"""

import os
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env'))

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity, get_jwt,
)
from datetime import time, datetime, timedelta, date
import base64, json, hashlib, secrets, math, io, logging
import numpy as np
import cv2
from functools import wraps

# ── App factory ──────────────────────────────────────────────────────────
app = Flask(__name__)
app.logger.setLevel(logging.INFO)

database_uri = os.getenv("SQLALCHEMY_DATABASE_URI", "sqlite:///attendify_dev.db")
app.config["SQLALCHEMY_DATABASE_URI"] = database_uri
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = os.getenv("ATTENDIFY_SECRET_KEY", secrets.token_hex(32))
app.config["JWT_SECRET_KEY"] = os.getenv("ATTENDIFY_JWT_SECRET", secrets.token_hex(32))
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=24)

# CORS — accept any localhost port during development
origins = os.getenv("ATTENDIFY_CORS_ORIGINS", "")
origins_list = [o.strip() for o in origins.split(",") if o.strip()]
origins_list.append(r"http://localhost:\d+")
CORS(app, origins=origins_list, supports_credentials=True, resources={
    r"/api/*": {"origins": origins_list},
    r"/health": {"origins": origins_list},
})

from extensions import db
from models import (
    Department, Course, User, Student, Unit, CourseUnit, LecturerUnit, StudentUnit,
    ClassSession, Attendance, Device, RecognitionMetrics,
    AuditLog, Announcement,
)

db.init_app(app)
jwt = JWTManager(app)

# ── Global error handlers (ensure CORS headers on error responses) ───────
@app.errorhandler(Exception)
def _handle_exception(e):
    """Catch-all: unhandled exceptions → JSON 500 with CORS headers."""
    app.logger.exception(f"Unhandled exception: {e}")
    code = getattr(e, "code", 500)
    return jsonify({"error": str(e), "_ok": False}), code

@app.errorhandler(500)
def _handle_500(e):
    app.logger.exception(f"Internal error: {e}")
    return jsonify({"error": "internal_server_error", "_ok": False}), 500

@app.errorhandler(404)
def _handle_404(e):
    return jsonify({"error": "not_found", "_ok": False}), 404

# ── Request logging ──────────────────────────────────────────────────────
@app.before_request
def _log_request():
    app.logger.info(f"path={request.path} method={request.method}")

# ── Services ─────────────────────────────────────────────────────────────
from facenet_service import get_facenet_service
from liveness_detection import get_liveness_detector
from vector_face_service import get_vector_face_service


# ═══════════════════════════════════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════════════════════════════════

def _require_role(*roles):
    """Decorator: JWT required + role check."""
    def decorator(fn):
        @wraps(fn)
        @jwt_required()
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            if claims.get("role") not in roles:
                return jsonify({"error": "forbidden"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def _current_user() -> User | None:
    uid = int(get_jwt_identity())
    return db.session.get(User, uid)


def _audit(action: str, entity_type: str = None, entity_id: int = None,
           details: dict = None, user_id: int = None):
    entry = AuditLog(
        user_id=user_id or (int(get_jwt_identity()) if get_jwt_identity() else None),
        action=action, entity_type=entity_type, entity_id=entity_id,
        details=details, ip_address=request.remote_addr,
    )
    db.session.add(entry)


def _decode_image(image_b64: str) -> np.ndarray | None:
    try:
        if ',' in image_b64:
            image_b64 = image_b64.split(',')[1]
        img_data = base64.b64decode(image_b64)
        nparr = np.frombuffer(img_data, dtype=np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return image
    except Exception as e:
        app.logger.error(f"Image decode failed: {e}")
        return None


def _get_metrics() -> RecognitionMetrics:
    m = RecognitionMetrics.query.first()
    if not m:
        m = RecognitionMetrics()
        db.session.add(m)
        db.session.commit()
    return m


# ═══════════════════════════════════════════════════════════════════════════
#  HEALTH
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "Attendify API",
                    "university": "Embu University"})


# ═══════════════════════════════════════════════════════════════════════════
#  AUTH
# ═══════════════════════════════════════════════════════════════════════════

@app.post("/api/auth/login")
def api_login():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")
    if not username or not password:
        return jsonify({"error": "missing_credentials"}), 400

    user = User.query.filter_by(username=username).first()
    if not user or not user.check_password(password):
        return jsonify({"error": "invalid_credentials"}), 401
    if not user.is_active:
        return jsonify({"error": "account_disabled"}), 403

    user.last_login = datetime.utcnow()
    db.session.commit()

    token = create_access_token(
        identity=str(user.id),
        additional_claims={"role": user.role, "username": user.username,
                           "name": user.full_name},
    )
    resp = {
        "access_token": token,
        "user": user.to_dict(include_email=True),
        "must_change_password": user.must_change_password,
    }
    if user.role == "student" and user.student:
        resp["student"] = user.student.to_dict()
    return jsonify(resp)


@app.post("/api/auth/change-password")
@jwt_required()
def api_change_password():
    data = request.get_json(silent=True) or {}
    current_pw = data.get("current_password", "")
    new_pw = data.get("new_password", "")
    if not current_pw or not new_pw or len(new_pw) < 6:
        return jsonify({"error": "invalid_input", "message": "New password must be at least 6 characters"}), 400

    user = _current_user()
    if not user or not user.check_password(current_pw):
        return jsonify({"error": "wrong_password"}), 401

    user.set_password(new_pw)
    user.must_change_password = False
    _audit("password_changed", "user", user.id)
    db.session.commit()
    return jsonify({"status": "ok", "message": "Password changed"})


@app.get("/api/auth/me")
@jwt_required()
def api_me():
    user = _current_user()
    if not user:
        return jsonify({"error": "not_found"}), 404
    resp = user.to_dict(include_email=True)
    if user.role == "student" and user.student:
        resp["student"] = user.student.to_dict()
    if user.role == "lecturer":
        resp["unit_count"] = len(user.lecturer_units)
    return jsonify(resp)


# ═══════════════════════════════════════════════════════════════════════════
#  KIOSK — Public face scanning for attendance (device-key auth)
# ═══════════════════════════════════════════════════════════════════════════

def _validate_device():
    key = request.headers.get("X-Device-Key", "")
    if not key:
        return None
    return Device.query.filter_by(device_key=key, is_active=True).first()


@app.post("/api/kiosk/scan")
def api_kiosk_scan():
    """Face scan from a kiosk device — identifies student and marks attendance."""
    device = _validate_device()
    if not device:
        return jsonify({"error": "invalid_device"}), 401

    data = request.get_json(silent=True) or {}
    image_b64 = data.get("image")
    session_id = data.get("class_session_id")

    if not image_b64:
        return jsonify({"error": "missing_image"}), 400

    img = _decode_image(image_b64)
    if img is None:
        return jsonify({"error": "invalid_image"}), 400

    # Quality check — soft gate
    facenet = get_facenet_service()
    quality = facenet.assess_image_quality(img)
    if not quality.get("quality_usable", False) and not quality.get("quality_ok", False):
        m = _get_metrics()
        m.low_quality_rejects += 1
        db.session.commit()
        return jsonify({"status": "error", "message": "Image quality too low",
                        "quality": quality}), 400

    # Extract embedding
    faces = facenet.detect_faces(img, confidence_threshold=0.3)
    if not faces:
        return jsonify({"status": "error", "message": "No face detected"}), 400

    best = max(faces, key=lambda f: f['confidence'])
    embedding = facenet.extract_embedding(img, best['bbox'])
    if embedding is None or len(embedding) != 512:
        return jsonify({"status": "error", "message": "Embedding extraction failed"}), 400

    # Vector similarity search
    vs = get_vector_face_service()
    match, similarity = vs.find_best_match(embedding, similarity_threshold=0.5)

    metrics = _get_metrics()
    metrics.total_attempts += 1

    if not match:
        metrics.failed_matches += 1
        db.session.commit()
        return jsonify({"status": "no_match", "message": "Face not recognized",
                        "similarity": 0.0}), 200

    metrics.successful_matches += 1

    student = db.session.get(Student, match["student_id"])
    result = {
        "status": "matched",
        "student": student.to_dict() if student else match,
        "similarity": similarity,
    }

    # Mark attendance if session_id provided
    if session_id and student:
        cs = db.session.get(ClassSession, int(session_id))
        if cs and cs.status in ("scheduled", "active"):
            existing = Attendance.query.filter_by(
                student_id=student.id, class_session_id=cs.id).first()
            if not existing:
                # Determine late status — local time since sessions use local time
                now = datetime.now()
                sched_start = datetime.combine(cs.session_date, cs.start_time)
                status = "late" if now > sched_start else "present"
                att = Attendance(
                    student_id=student.id, class_session_id=cs.id,
                    check_in_time=now, status=status,
                    confidence_score=similarity,
                    verification_method="facial_recognition",
                    device_id=device.id,
                )
                db.session.add(att)
                result["attendance"] = {"status": status, "class_session_id": cs.id}
            else:
                result["attendance"] = {"status": "already_marked"}

    device.last_heartbeat = datetime.utcnow()
    db.session.commit()
    return jsonify(result)


@app.get("/api/kiosk/sessions")
def api_kiosk_sessions():
    """Get today's active/scheduled sessions for kiosk display."""
    device = _validate_device()
    if not device:
        return jsonify({"error": "invalid_device"}), 401
    today = date.today()
    sessions = ClassSession.query.filter(
        ClassSession.session_date == today,
        ClassSession.status.in_(["scheduled", "active"])
    ).all()
    return jsonify({"sessions": [s.to_dict() for s in sessions]})


# ═══════════════════════════════════════════════════════════════════════════
#  ADMIN — Superadmin endpoints
# ═══════════════════════════════════════════════════════════════════════════

# ── Dashboard stats ──────────────────────────────────────────────────────
@app.get("/api/admin/dashboard")
@_require_role("superadmin")
def api_admin_dashboard():
    total_students = Student.query.count()
    enrolled_faces = Student.query.filter(Student.facial_embedding.isnot(None)).count()
    total_lecturers = User.query.filter_by(role="lecturer").count()
    total_departments = Department.query.count()
    total_courses = Course.query.count()
    total_units = Unit.query.count()
    total_devices = Device.query.filter_by(is_active=True).count()
    today_attendance = Attendance.query.filter(
        Attendance.check_in_time >= datetime.combine(date.today(), time.min)
    ).count()
    metrics = _get_metrics()
    return jsonify({
        "students": total_students, "enrolled_faces": enrolled_faces,
        "lecturers": total_lecturers, "departments": total_departments,
        "courses": total_courses, "units": total_units,
        "active_devices": total_devices, "today_attendance": today_attendance,
        "metrics": metrics.to_dict(),
    })


# ── User management ─────────────────────────────────────────────────────
@app.get("/api/admin/users")
@_require_role("superadmin")
def api_admin_users():
    role = request.args.get("role")
    q = request.args.get("q", "").strip()
    query = User.query
    if role:
        query = query.filter_by(role=role)
    if q:
        query = query.filter(
            (User.first_name.ilike(f"%{q}%")) |
            (User.last_name.ilike(f"%{q}%")) |
            (User.username.ilike(f"%{q}%"))
        )
    users = query.order_by(User.created_at.desc()).all()
    return jsonify({"count": len(users), "users": [u.to_dict(include_email=True) for u in users]})


@app.post("/api/admin/users")
@_require_role("superadmin")
def api_admin_create_user():
    data = request.get_json(silent=True) or {}
    required = ["username", "password", "role", "first_name", "last_name"]
    if not all(data.get(f) for f in required):
        return jsonify({"error": "missing_fields", "required": required}), 400
    if data["role"] not in ("superadmin", "lecturer", "student"):
        return jsonify({"error": "invalid_role"}), 400
    if User.query.filter_by(username=data["username"]).first():
        return jsonify({"error": "username_exists"}), 409

    user = User(
        username=data["username"], role=data["role"],
        first_name=data["first_name"], last_name=data["last_name"],
        email=data.get("email"), phone=data.get("phone"),
        must_change_password=data.get("must_change_password", True),
    )
    user.set_password(data["password"])
    db.session.add(user)
    db.session.flush()

    # If creating a student user, also create student record
    if data["role"] == "student":
        reg_no = data.get("registration_number")
        course_id = data.get("course_id")
        if not reg_no or not course_id:
            return jsonify({"error": "student_requires_reg_no_and_course_id"}), 400
        student = Student(
            user_id=user.id, registration_number=reg_no,
            course_id=int(course_id),
            year=int(data.get("year", 1)), semester=int(data.get("semester", 1)),
            consent_given=data.get("consent", False),
        )
        db.session.add(student)

    _audit("user_created", "user", user.id, {"role": user.role})
    db.session.commit()
    return jsonify({"status": "created", "user": user.to_dict(include_email=True)}), 201


@app.put("/api/admin/users/<int:uid>")
@_require_role("superadmin")
def api_admin_update_user(uid):
    user = db.session.get(User, uid)
    if not user:
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}
    for field in ["first_name", "last_name", "email", "phone", "is_active"]:
        if field in data:
            setattr(user, field, data[field])
    if "password" in data and data["password"]:
        user.set_password(data["password"])
        user.must_change_password = data.get("must_change_password", True)
    _audit("user_updated", "user", uid)
    db.session.commit()
    return jsonify({"status": "updated", "user": user.to_dict(include_email=True)})


@app.delete("/api/admin/users/<int:uid>")
@_require_role("superadmin")
def api_admin_delete_user(uid):
    user = db.session.get(User, uid)
    if not user:
        return jsonify({"error": "not_found"}), 404
    _audit("user_deleted", "user", uid, {"username": user.username})
    db.session.delete(user)
    db.session.commit()
    return jsonify({"status": "deleted"})


# ── Department CRUD ──────────────────────────────────────────────────────
@app.get("/api/admin/departments")
@_require_role("superadmin")
def api_admin_departments():
    depts = Department.query.order_by(Department.name).all()
    return jsonify({"departments": [d.to_dict() for d in depts]})

@app.post("/api/admin/departments")
@_require_role("superadmin")
def api_admin_create_department():
    data = request.get_json(silent=True) or {}
    if not data.get("name") or not data.get("code"):
        return jsonify({"error": "missing_fields"}), 400
    dept = Department(name=data["name"], code=data["code"].upper(),
                      description=data.get("description"))
    db.session.add(dept)
    _audit("department_created", "department", None, {"code": dept.code})
    db.session.commit()
    return jsonify({"status": "created", "department": dept.to_dict()}), 201

@app.put("/api/admin/departments/<int:did>")
@_require_role("superadmin")
def api_admin_update_department(did):
    dept = db.session.get(Department, did)
    if not dept:
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}
    for f in ["name", "code", "description"]:
        if f in data:
            setattr(dept, f, data[f])
    db.session.commit()
    return jsonify({"status": "updated", "department": dept.to_dict()})

@app.delete("/api/admin/departments/<int:did>")
@_require_role("superadmin")
def api_admin_delete_department(did):
    dept = db.session.get(Department, did)
    if not dept:
        return jsonify({"error": "not_found"}), 404
    db.session.delete(dept)
    db.session.commit()
    return jsonify({"status": "deleted"})


# ── Course CRUD ──────────────────────────────────────────────────────────
@app.get("/api/admin/courses")
@_require_role("superadmin", "lecturer")
def api_admin_courses():
    courses = Course.query.order_by(Course.code).all()
    return jsonify({"courses": [c.to_dict() for c in courses]})

@app.post("/api/admin/courses")
@_require_role("superadmin")
def api_admin_create_course():
    data = request.get_json(silent=True) or {}
    if not all(data.get(f) for f in ["name", "code", "department_id"]):
        return jsonify({"error": "missing_fields"}), 400
    course = Course(name=data["name"], code=data["code"].upper(),
                    department_id=int(data["department_id"]),
                    duration_years=int(data.get("duration_years", 4)))
    db.session.add(course)
    _audit("course_created", "course", None, {"code": course.code})
    db.session.commit()
    return jsonify({"status": "created", "course": course.to_dict()}), 201

@app.put("/api/admin/courses/<int:cid>")
@_require_role("superadmin")
def api_admin_update_course(cid):
    course = db.session.get(Course, cid)
    if not course:
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}
    for f in ["name", "code", "duration_years", "department_id"]:
        if f in data:
            setattr(course, f, data[f])
    db.session.commit()
    return jsonify({"status": "updated", "course": course.to_dict()})

@app.delete("/api/admin/courses/<int:cid>")
@_require_role("superadmin")
def api_admin_delete_course(cid):
    course = db.session.get(Course, cid)
    if not course:
        return jsonify({"error": "not_found"}), 404
    db.session.delete(course)
    db.session.commit()
    return jsonify({"status": "deleted"})


# ── Unit CRUD ────────────────────────────────────────────────────────────
@app.get("/api/admin/units")
@_require_role("superadmin", "lecturer")
def api_admin_units():
    course_id = request.args.get("course_id")
    if course_id:
        # Filter units linked to this course via course_units junction
        cu_links = CourseUnit.query.filter_by(course_id=int(course_id)).all()
        unit_ids = [cu.unit_id for cu in cu_links]
        units = Unit.query.filter(Unit.id.in_(unit_ids)).order_by(Unit.code).all() if unit_ids else []
    else:
        units = Unit.query.order_by(Unit.code).all()
    return jsonify({"units": [u.to_dict() for u in units]})

@app.post("/api/admin/units")
@_require_role("superadmin")
def api_admin_create_unit():
    """Create a unit and link it to one or more courses.
    Body: { name, code, credit_hours, courses: [{course_id, year, semester}, ...] }
    Also supports legacy single-course: { name, code, course_id, year, semester }
    """
    data = request.get_json(silent=True) or {}
    if not data.get("name") or not data.get("code"):
        return jsonify({"error": "name and code are required"}), 400

    # Build course links list
    courses_list = data.get("courses") or []
    if not courses_list and data.get("course_id"):
        # Legacy single-course format
        courses_list = [{"course_id": data["course_id"],
                         "year": data.get("year", 1), "semester": data.get("semester", 1)}]

    if not courses_list:
        return jsonify({"error": "At least one course link is required (courses array or course_id+year+semester)"}), 400

    unit = Unit(name=data["name"], code=data["code"].upper(),
                credit_hours=int(data.get("credit_hours", 3)))
    db.session.add(unit)
    db.session.flush()  # get unit.id

    for cl in courses_list:
        cu = CourseUnit(course_id=int(cl["course_id"]), unit_id=unit.id,
                        year=int(cl.get("year", 1)), semester=int(cl.get("semester", 1)))
        db.session.add(cu)

    db.session.commit()
    return jsonify({"status": "created", "unit": unit.to_dict()}), 201

@app.put("/api/admin/units/<int:uid>")
@_require_role("superadmin")
def api_admin_update_unit(uid):
    unit = db.session.get(Unit, uid)
    if not unit:
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}
    for f in ["name", "code", "credit_hours"]:
        if f in data:
            setattr(unit, f, data[f])
    # Optionally replace course links if provided
    if "courses" in data:
        # Remove old links
        CourseUnit.query.filter_by(unit_id=uid).delete()
        for cl in (data["courses"] or []):
            cu = CourseUnit(course_id=int(cl["course_id"]), unit_id=uid,
                            year=int(cl.get("year", 1)), semester=int(cl.get("semester", 1)))
            db.session.add(cu)
    db.session.commit()
    return jsonify({"status": "updated", "unit": unit.to_dict()})

@app.delete("/api/admin/units/<int:uid>")
@_require_role("superadmin")
def api_admin_delete_unit(uid):
    unit = db.session.get(Unit, uid)
    if not unit:
        return jsonify({"error": "not_found"}), 404
    db.session.delete(unit)
    db.session.commit()
    return jsonify({"status": "deleted"})

@app.get("/api/admin/course-units")
@_require_role("superadmin", "lecturer")
def api_admin_course_units():
    """List all course-unit links, optionally filtered by course_id or unit_id."""
    course_id = request.args.get("course_id")
    unit_id = request.args.get("unit_id")
    query = CourseUnit.query
    if course_id:
        query = query.filter_by(course_id=int(course_id))
    if unit_id:
        query = query.filter_by(unit_id=int(unit_id))
    return jsonify({"course_units": [cu.to_dict() for cu in query.all()]})

@app.post("/api/admin/course-units")
@_require_role("superadmin")
def api_admin_add_course_unit():
    """Link an existing unit to another course. Body: { unit_id, course_id, year, semester }"""
    data = request.get_json(silent=True) or {}
    if not all(data.get(f) for f in ["unit_id", "course_id", "year", "semester"]):
        return jsonify({"error": "unit_id, course_id, year, semester are required"}), 400
    existing = CourseUnit.query.filter_by(
        course_id=int(data["course_id"]), unit_id=int(data["unit_id"])).first()
    if existing:
        return jsonify({"error": "This unit is already linked to this course"}), 409
    cu = CourseUnit(course_id=int(data["course_id"]), unit_id=int(data["unit_id"]),
                    year=int(data["year"]), semester=int(data["semester"]))
    db.session.add(cu)
    db.session.commit()
    return jsonify({"status": "linked", "course_unit": cu.to_dict()}), 201

@app.delete("/api/admin/course-units/<int:cuid>")
@_require_role("superadmin")
def api_admin_delete_course_unit(cuid):
    cu = db.session.get(CourseUnit, cuid)
    if not cu:
        return jsonify({"error": "not_found"}), 404
    db.session.delete(cu)
    db.session.commit()
    return jsonify({"status": "deleted"})


# ── Lecturer-Unit assignment ─────────────────────────────────────────────
@app.get("/api/admin/lecturer-units")
@_require_role("superadmin")
def api_admin_lecturer_units():
    lus = LecturerUnit.query.all()
    return jsonify({"assignments": [lu.to_dict() for lu in lus]})

@app.post("/api/admin/lecturer-units")
@_require_role("superadmin")
def api_admin_assign_lecturer_unit():
    data = request.get_json(silent=True) or {}
    lu = LecturerUnit(
        lecturer_id=int(data["lecturer_id"]), unit_id=int(data["unit_id"]),
        academic_year=data.get("academic_year", "2025/2026"))
    db.session.add(lu)
    db.session.commit()
    return jsonify({"status": "assigned", "assignment": lu.to_dict()}), 201

@app.delete("/api/admin/lecturer-units/<int:lid>")
@_require_role("superadmin")
def api_admin_delete_lecturer_unit(lid):
    lu = db.session.get(LecturerUnit, lid)
    if not lu:
        return jsonify({"error": "not_found"}), 404
    db.session.delete(lu)
    db.session.commit()
    return jsonify({"status": "deleted"})


# ── Student management ───────────────────────────────────────────────────
@app.get("/api/admin/students")
@_require_role("superadmin", "lecturer")
def api_admin_students():
    q = request.args.get("q", "").strip()
    course_id = request.args.get("course_id")
    unregistered = request.args.get("unregistered")
    query = Student.query.join(User)
    if q:
        query = query.filter(
            (User.first_name.ilike(f"%{q}%")) |
            (User.last_name.ilike(f"%{q}%")) |
            (Student.registration_number.ilike(f"%{q}%"))
        )
    if course_id:
        query = query.filter(Student.course_id == int(course_id))
    if unregistered:
        query = query.filter(Student.facial_embedding.is_(None))
    students = query.order_by(Student.registration_number).all()
    return jsonify({"count": len(students), "students": [s.to_dict() for s in students]})


# ── Enroll face (admin sets student face) ────────────────────────────────
@app.post("/api/admin/students/<int:sid>/face")
@_require_role("superadmin")
def api_admin_set_face(sid):
    student = db.session.get(Student, sid)
    if not student:
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}
    image_b64 = data.get("image") or data.get("facial_image_base64")
    if not image_b64:
        return jsonify({"error": "missing_image"}), 400

    img = _decode_image(image_b64)
    if img is None:
        return jsonify({"error": "invalid_image"}), 400

    facenet = get_facenet_service()
    quality = facenet.assess_image_quality(img)
    if not quality.get("quality_usable") and not quality.get("quality_ok"):
        return jsonify({"status": "error", "message": "Image unusable", "quality": quality}), 400

    faces = facenet.detect_faces(img, confidence_threshold=0.3)
    if not faces:
        return jsonify({"status": "error", "message": "No face detected"}), 400

    best = max(faces, key=lambda f: f['confidence'])
    embedding = facenet.extract_embedding(img, best['bbox'])
    if embedding is None or len(embedding) != 512:
        return jsonify({"status": "error", "message": "Embedding extraction failed"}), 400

    vs = get_vector_face_service()
    if not vs.store_embedding(student.id, embedding):
        return jsonify({"status": "error", "message": "Failed to store embedding"}), 500

    _audit("face_enrolled", "student", student.id)
    db.session.commit()
    return jsonify({"status": "success", "student_id": student.id,
                    "quality_warning": None if quality.get("quality_ok") else "Image usable but not ideal"})


# ── Device CRUD ──────────────────────────────────────────────────────────
@app.get("/api/admin/devices")
@_require_role("superadmin")
def api_admin_devices():
    devices = Device.query.order_by(Device.name).all()
    return jsonify({"devices": [d.to_dict() for d in devices]})

@app.post("/api/admin/devices")
@_require_role("superadmin")
def api_admin_create_device():
    data = request.get_json(silent=True) or {}
    device = Device(name=data.get("name", "Kiosk"),
                    location=data.get("location"),
                    device_key=secrets.token_hex(32))
    db.session.add(device)
    db.session.commit()
    return jsonify({"status": "created", "device": device.to_dict(),
                    "device_key": device.device_key}), 201


# ── Announcements ────────────────────────────────────────────────────────
@app.get("/api/announcements")
@jwt_required()
def api_announcements():
    role = get_jwt().get("role", "student")
    anns = Announcement.query.filter(
        (Announcement.target_role == "all") | (Announcement.target_role == role)
    ).order_by(Announcement.is_pinned.desc(), Announcement.created_at.desc()).limit(20).all()
    return jsonify({"announcements": [a.to_dict() for a in anns]})

@app.post("/api/admin/announcements")
@_require_role("superadmin", "lecturer")
def api_create_announcement():
    data = request.get_json(silent=True) or {}
    ann = Announcement(
        title=data.get("title", ""), content=data.get("content", ""),
        author_id=int(get_jwt_identity()),
        target_role=data.get("target_role", "all"),
        is_pinned=data.get("is_pinned", False),
    )
    db.session.add(ann)
    db.session.commit()
    return jsonify({"status": "created", "announcement": ann.to_dict()}), 201


# ── Admin reports ────────────────────────────────────────────────────────
@app.get("/api/admin/reports")
@_require_role("superadmin")
def api_admin_reports():
    metrics = _get_metrics()
    total_students = Student.query.count()
    face_enrolled = Student.query.filter(Student.facial_embedding.isnot(None)).count()
    today_att = Attendance.query.filter(
        Attendance.check_in_time >= datetime.combine(date.today(), time.min)).count()
    return jsonify({
        "total_students": total_students,
        "face_enrollment_rate": face_enrolled / total_students if total_students else 0,
        "today_attendance": today_att,
        "metrics": metrics.to_dict(),
    })

# ── Audit log ────────────────────────────────────────────────────────────
@app.get("/api/admin/audit-log")
@_require_role("superadmin")
def api_admin_audit_log():
    limit = min(int(request.args.get("limit", 50)), 200)
    logs = AuditLog.query.order_by(AuditLog.created_at.desc()).limit(limit).all()
    return jsonify({"logs": [l.to_dict() for l in logs]})


# ═══════════════════════════════════════════════════════════════════════════
#  LECTURER
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/api/lecturer/dashboard")
@_require_role("lecturer")
def api_lecturer_dashboard():
    user = _current_user()
    my_units = LecturerUnit.query.filter_by(lecturer_id=user.id).all()
    unit_ids = [lu.unit_id for lu in my_units]
    today_sessions = ClassSession.query.filter(
        ClassSession.lecturer_id == user.id,
        ClassSession.session_date == date.today()
    ).all()
    total_sessions = ClassSession.query.filter_by(lecturer_id=user.id).count()
    return jsonify({
        "units": [lu.to_dict() for lu in my_units],
        "today_sessions": [s.to_dict() for s in today_sessions],
        "total_sessions": total_sessions,
    })


@app.get("/api/lecturer/units")
@_require_role("lecturer")
def api_lecturer_units():
    user = _current_user()
    lus = LecturerUnit.query.filter_by(lecturer_id=user.id).all()
    return jsonify({"units": [lu.to_dict() for lu in lus]})


# ── Class session management ─────────────────────────────────────────────
def _auto_update_session_statuses():
    """Promote scheduled→active and active/scheduled→completed based on local time.
    Sessions become 'active' 15 minutes before their start_time so early arrivals
    can check in.  They become 'completed' once end_time has passed.
    """
    now = datetime.now()          # local time — sessions are stored in local time
    today = now.date()
    current_time = now.time()
    dirty = False
    # Only touch today's sessions that aren't already cancelled or completed
    pending = ClassSession.query.filter(
        ClassSession.session_date == today,
        ClassSession.status.in_(["scheduled", "active"]),
    ).all()
    for cs in pending:
        early_start = (datetime.combine(today, cs.start_time) - timedelta(minutes=15)).time()
        if current_time > cs.end_time:
            cs.status = "completed"
            dirty = True
        elif current_time >= early_start and cs.status == "scheduled":
            cs.status = "active"
            dirty = True
    if dirty:
        db.session.commit()

@app.get("/api/lecturer/sessions")
@_require_role("lecturer")
def api_lecturer_sessions():
    _auto_update_session_statuses()
    user = _current_user()
    sessions = ClassSession.query.filter_by(lecturer_id=user.id)\
        .order_by(ClassSession.session_date.desc(), ClassSession.start_time.desc()).all()
    return jsonify({"sessions": [s.to_dict() for s in sessions]})

@app.post("/api/lecturer/sessions")
@_require_role("lecturer")
def api_lecturer_create_session():
    user = _current_user()
    data = request.get_json(silent=True) or {}
    if not all(data.get(f) for f in ["unit_id", "session_date", "start_time", "end_time"]):
        return jsonify({"error": "missing_fields"}), 400

    unit_id   = int(data["unit_id"])
    s_date    = date.fromisoformat(data["session_date"])
    s_start   = time.fromisoformat(data["start_time"])
    s_end     = time.fromisoformat(data["end_time"])
    venue     = (data.get("venue") or "").strip() or None

    # ── Time sanity ──
    if s_end <= s_start:
        return jsonify({"error": "End time must be after start time"}), 400

    # ── Verify lecturer is assigned to this unit ──
    assignment = LecturerUnit.query.filter_by(
        lecturer_id=user.id, unit_id=unit_id).first()
    if not assignment:
        return jsonify({"error": "You are not assigned to this unit"}), 403

    # ── Helper: two time ranges overlap? ──
    def _overlaps(a_start, a_end, b_start, b_end):
        return a_start < b_end and b_start < a_end

    # Get all non-cancelled sessions on this date for conflict checks
    day_sessions = ClassSession.query.filter(
        ClassSession.session_date == s_date,
        ClassSession.status != "cancelled",
    ).all()

    # ── Lecturer overlap: same lecturer can't teach two things at once ──
    for cs in day_sessions:
        if cs.lecturer_id == user.id and _overlaps(s_start, s_end, cs.start_time, cs.end_time):
            return jsonify({
                "error": f"You already have a session ({cs.unit.code}) from "
                         f"{cs.start_time.strftime('%H:%M')}–{cs.end_time.strftime('%H:%M')}",
            }), 409

    # ── Unit overlap: same unit can't have two sessions at the same time ──
    for cs in day_sessions:
        if cs.unit_id == unit_id and _overlaps(s_start, s_end, cs.start_time, cs.end_time):
            return jsonify({
                "error": f"This unit already has a session from "
                         f"{cs.start_time.strftime('%H:%M')}–{cs.end_time.strftime('%H:%M')}",
            }), 409

    # ── Venue conflict: same venue can't host two sessions at once ──
    if venue:
        for cs in day_sessions:
            if cs.venue and cs.venue.lower() == venue.lower() and \
               _overlaps(s_start, s_end, cs.start_time, cs.end_time):
                return jsonify({
                    "error": f"Venue '{venue}' is occupied by {cs.unit.code} "
                             f"({cs.start_time.strftime('%H:%M')}–{cs.end_time.strftime('%H:%M')})",
                }), 409

    session = ClassSession(
        unit_id=unit_id, lecturer_id=user.id,
        session_date=s_date, start_time=s_start, end_time=s_end,
        venue=venue, status="scheduled",
    )
    db.session.add(session)
    db.session.commit()
    return jsonify({"status": "created", "session": session.to_dict()}), 201

@app.put("/api/lecturer/sessions/<int:sid>")
@_require_role("lecturer")
def api_lecturer_update_session(sid):
    """Full session update / reschedule. Accepts: session_date, start_time, end_time, venue, status."""
    cs = db.session.get(ClassSession, sid)
    if not cs or cs.lecturer_id != int(get_jwt_identity()):
        return jsonify({"error": "not_found"}), 404
    data = request.get_json(silent=True) or {}

    # Apply simple fields first
    if "status" in data:
        cs.status = data["status"]
    new_venue = data.get("venue", cs.venue)
    if new_venue is not None:
        cs.venue = (new_venue or "").strip() or None

    # Reschedule fields
    new_date  = date.fromisoformat(data["session_date"]) if "session_date" in data else cs.session_date
    new_start = time.fromisoformat(data["start_time"])   if "start_time"   in data else cs.start_time
    new_end   = time.fromisoformat(data["end_time"])     if "end_time"     in data else cs.end_time

    if new_end <= new_start:
        return jsonify({"error": "End time must be after start time"}), 400

    # Only run overlap checks if date/time actually changed
    time_changed = (new_date != cs.session_date or new_start != cs.start_time or new_end != cs.end_time
                    or (cs.venue or "") != (new_venue or "").strip())
    if time_changed:
        def _overlaps(a_start, a_end, b_start, b_end):
            return a_start < b_end and b_start < a_end

        day_sessions = ClassSession.query.filter(
            ClassSession.session_date == new_date,
            ClassSession.status != "cancelled",
            ClassSession.id != sid,  # exclude self
        ).all()

        for other in day_sessions:
            if other.lecturer_id == cs.lecturer_id and _overlaps(new_start, new_end, other.start_time, other.end_time):
                return jsonify({"error": f"You already have a session ({other.unit.code}) from "
                                         f"{other.start_time.strftime('%H:%M')}–{other.end_time.strftime('%H:%M')}"}), 409
        for other in day_sessions:
            if other.unit_id == cs.unit_id and _overlaps(new_start, new_end, other.start_time, other.end_time):
                return jsonify({"error": f"This unit already has a session from "
                                         f"{other.start_time.strftime('%H:%M')}–{other.end_time.strftime('%H:%M')}"}), 409
        venue_check = (new_venue or "").strip()
        if venue_check:
            for other in day_sessions:
                if other.venue and other.venue.lower() == venue_check.lower() and \
                   _overlaps(new_start, new_end, other.start_time, other.end_time):
                    return jsonify({"error": f"Venue '{venue_check}' is occupied by {other.unit.code} "
                                             f"({other.start_time.strftime('%H:%M')}–{other.end_time.strftime('%H:%M')})"}), 409

    cs.session_date = new_date
    cs.start_time = new_start
    cs.end_time = new_end
    db.session.commit()
    return jsonify({"status": "updated", "session": cs.to_dict()})

@app.delete("/api/lecturer/sessions/<int:sid>")
@_require_role("lecturer")
def api_lecturer_delete_session(sid):
    cs = db.session.get(ClassSession, sid)
    if not cs or cs.lecturer_id != int(get_jwt_identity()):
        return jsonify({"error": "not_found"}), 404
    if cs.status == "completed" and len(cs.attendances) > 0:
        return jsonify({"error": "Cannot delete a completed session with attendance records"}), 400
    db.session.delete(cs)
    db.session.commit()
    return jsonify({"status": "deleted"})


# ── Attendance for a session ─────────────────────────────────────────────
@app.get("/api/lecturer/sessions/<int:sid>/attendance")
@_require_role("lecturer")
def api_lecturer_session_attendance(sid):
    cs = db.session.get(ClassSession, sid)
    if not cs:
        return jsonify({"error": "not_found"}), 404
    records = Attendance.query.filter_by(class_session_id=sid).all()
    return jsonify({
        "session": cs.to_dict(),
        "attendance": [a.to_dict() for a in records],
    })


@app.get("/api/lecturer/unit/<int:uid>/students")
@_require_role("lecturer")
def api_lecturer_unit_students(uid):
    """Get all students enrolled in this unit (via student_units), with attendance stats."""
    unit = db.session.get(Unit, uid)
    if not unit:
        return jsonify({"error": "not_found"}), 404

    # Students who explicitly enrolled in this unit
    enrollments = StudentUnit.query.filter_by(unit_id=uid).all()
    student_ids = [su.student_id for su in enrollments]
    students = Student.query.filter(Student.id.in_(student_ids)).all() if student_ids else []

    sessions = ClassSession.query.filter_by(unit_id=uid).all()
    total_sessions = len(sessions)
    session_ids = [s.id for s in sessions]

    result = []
    for s in students:
        attended = Attendance.query.filter(
            Attendance.student_id == s.id,
            Attendance.class_session_id.in_(session_ids)
        ).count() if session_ids else 0
        d = s.to_dict()
        d["sessions_attended"] = attended
        d["total_sessions"] = total_sessions
        d["attendance_rate"] = attended / total_sessions if total_sessions else 0
        result.append(d)

    return jsonify({"students": result, "total_sessions": total_sessions,
                    "enrolled_count": len(students)})


# ═══════════════════════════════════════════════════════════════════════════
#  STUDENT
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/api/student/dashboard")
@_require_role("student")
def api_student_dashboard():
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404

    attendances = Attendance.query.filter_by(student_id=student.id)\
        .order_by(Attendance.check_in_time.desc()).all()
    total = len(attendances)
    present = sum(1 for a in attendances if a.status in ("present", "late"))

    # Group by unit
    unit_stats = {}
    for a in attendances:
        cs = a.class_session
        if cs:
            ucode = cs.unit.code if cs.unit else "?"
            if ucode not in unit_stats:
                unit_stats[ucode] = {"unit_name": cs.unit.name if cs.unit else "?",
                                     "attended": 0, "total": 0}
            unit_stats[ucode]["attended"] += 1 if a.status in ("present", "late") else 0
            unit_stats[ucode]["total"] += 1

    return jsonify({
        "student": student.to_dict(),
        "total_classes": total,
        "classes_attended": present,
        "attendance_rate": present / total if total else 0,
        "unit_stats": unit_stats,
        "recent_attendance": [a.to_dict() for a in attendances[:10]],
    })


@app.get("/api/student/attendance")
@_require_role("student")
def api_student_attendance():
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404
    records = Attendance.query.filter_by(student_id=student.id)\
        .order_by(Attendance.check_in_time.desc()).all()
    return jsonify({"attendance": [a.to_dict() for a in records]})


@app.post("/api/student/consent")
@_require_role("student")
def api_student_consent():
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404
    data = request.get_json(silent=True) or {}
    student.consent_given = bool(data.get("consent", False))
    db.session.commit()
    return jsonify({"status": "ok", "consent_given": student.consent_given})


# ── Student unit enrollment ──────────────────────────────────────────────

@app.get("/api/student/available-units")
@_require_role("student")
def api_student_available_units():
    """Units for the student's course + current year/semester, minus already enrolled."""
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404

    # Units linked to the student's course AND matching their year/semester via course_units
    cu_links = CourseUnit.query.filter_by(
        course_id=student.course_id,
        year=student.year,
        semester=student.semester,
    ).all()
    unit_ids = [cu.unit_id for cu in cu_links]
    units = Unit.query.filter(Unit.id.in_(unit_ids)).all() if unit_ids else []

    # Already enrolled unit IDs
    enrolled_ids = {su.unit_id for su in
                    StudentUnit.query.filter_by(student_id=student.id).all()}

    available = []
    for u in units:
        d = u.to_dict()
        d["enrolled"] = u.id in enrolled_ids
        # Include lecturer info
        lec_names = [lu.lecturer.full_name for lu in u.lecturer_units if lu.lecturer]
        d["lecturers"] = lec_names
        d["enrolled_count"] = StudentUnit.query.filter_by(unit_id=u.id).count()
        available.append(d)

    return jsonify({"units": available, "student_year": student.year,
                    "student_semester": student.semester,
                    "course_code": student.course_rel.code if student.course_rel else None})


@app.get("/api/student/my-units")
@_require_role("student")
def api_student_my_units():
    """Units the student is currently enrolled in, with session & attendance info."""
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404

    enrollments = StudentUnit.query.filter_by(student_id=student.id).all()
    result = []
    for su in enrollments:
        d = su.to_dict()
        # Attendance stats for this unit
        sessions = ClassSession.query.filter_by(unit_id=su.unit_id).all()
        session_ids = [s.id for s in sessions]
        attended = Attendance.query.filter(
            Attendance.student_id == student.id,
            Attendance.class_session_id.in_(session_ids)
        ).count() if session_ids else 0
        d["total_sessions"] = len(sessions)
        d["sessions_attended"] = attended
        d["attendance_rate"] = attended / len(sessions) if sessions else 0
        # Lecturer info
        lec_names = [lu.lecturer.full_name for lu in su.unit.lecturer_units if lu.lecturer]
        d["lecturers"] = lec_names
        result.append(d)

    return jsonify({"units": result})


@app.post("/api/student/enroll-unit")
@_require_role("student")
def api_student_enroll_unit():
    """Enroll in a unit — must belong to student's course and year/semester."""
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404

    data = request.get_json(silent=True) or {}
    unit_id = data.get("unit_id")
    if not unit_id:
        return jsonify({"error": "missing_unit_id"}), 400

    unit = db.session.get(Unit, int(unit_id))
    if not unit:
        return jsonify({"error": "unit_not_found"}), 404

    # Validate: unit must be linked to student's course AND match year/semester
    cu_link = CourseUnit.query.filter_by(
        course_id=student.course_id, unit_id=unit.id
    ).first()
    if not cu_link:
        return jsonify({"error": "unit_not_in_course",
                        "message": "This unit is not offered for your course"}), 403
    if cu_link.year != student.year or cu_link.semester != student.semester:
        return jsonify({"error": "year_semester_mismatch",
                        "message": "This unit is for a different year/semester"}), 403

    # Check duplicate
    existing = StudentUnit.query.filter_by(
        student_id=student.id, unit_id=unit.id).first()
    if existing:
        return jsonify({"error": "already_enrolled",
                        "message": "Already enrolled in this unit"}), 409

    su = StudentUnit(student_id=student.id, unit_id=unit.id)
    db.session.add(su)
    _audit("unit_enrolled", "student_unit", su.id,
           {"unit_code": unit.code, "student_reg": student.registration_number})
    db.session.commit()
    return jsonify({"status": "enrolled", "enrollment": su.to_dict()}), 201


@app.delete("/api/student/drop-unit/<int:su_id>")
@_require_role("student")
def api_student_drop_unit(su_id):
    """Drop a unit enrollment."""
    user = _current_user()
    student = user.student if user else None
    if not student:
        return jsonify({"error": "no_student_profile"}), 404

    su = db.session.get(StudentUnit, su_id)
    if not su or su.student_id != student.id:
        return jsonify({"error": "not_found"}), 404

    _audit("unit_dropped", "student_unit", su.id,
           {"unit_code": su.unit.code if su.unit else None})
    db.session.delete(su)
    db.session.commit()
    return jsonify({"status": "dropped"})


# ═══════════════════════════════════════════════════════════════════════════
#  FACE RECOGNITION — Shared endpoints
# ═══════════════════════════════════════════════════════════════════════════

@app.post("/api/recognize")
@jwt_required()
def api_recognize():
    """Smart face recognition — identifies student, finds active sessions,
    checks enrollment, and optionally auto-marks attendance.

    Body: { "image": "<base64>", "auto_mark": true/false }
    """
    data = request.get_json(silent=True) or {}
    image_b64 = data.get("image") or data.get("facial_image_base64")
    auto_mark = data.get("auto_mark", False)
    if not image_b64:
        return jsonify({"error": "missing_image"}), 400

    img = _decode_image(image_b64)
    if img is None:
        return jsonify({"error": "invalid_image"}), 400

    facenet = get_facenet_service()
    quality = facenet.assess_image_quality(img)
    if not quality.get("quality_usable") and not quality.get("quality_ok"):
        return jsonify({"status": "error", "message": "Image unusable"}), 400

    faces = facenet.detect_faces(img, confidence_threshold=0.3)
    if not faces:
        return jsonify({"status": "error", "message": "No face detected"}), 400

    best = max(faces, key=lambda f: f['confidence'])
    embedding = facenet.extract_embedding(img, best['bbox'])
    if embedding is None or len(embedding) != 512:
        return jsonify({"status": "error", "message": "Embedding failed"}), 400

    vs = get_vector_face_service()
    match, similarity = vs.find_best_match(embedding, similarity_threshold=0.5)

    if not match:
        return jsonify({"status": "no_match", "similarity": 0.0}), 200

    student = db.session.get(Student, match["student_id"])
    result = {
        "status": "matched",
        "student": student.to_dict() if student else match,
        "similarity": similarity,
    }

    # ── Smart attendance marking ──
    # Attendance window: student can check in from 15 min before session start
    # until 20 min after session start.  Arrivals before start_time → "present",
    # arrivals after start_time but within 20 min → "late".
    EARLY_WINDOW_MIN = 15   # how many minutes before start a student may check in
    LATE_WINDOW_MIN  = 20   # how many minutes after start a student may still check in

    if auto_mark and student:
        now = datetime.now()           # local time — sessions stored in local time
        today = now.date()
        current_time = now.time()

        # Auto-promote session statuses first so sessions are 'active'
        _auto_update_session_statuses()

        # Find today's sessions that are scheduled or active
        todays_sessions = ClassSession.query.filter(
            ClassSession.session_date == today,
            ClassSession.status.in_(["scheduled", "active"]),
        ).all()

        # Filter to sessions within the attendance window
        eligible = []
        for cs in todays_sessions:
            window_open  = (datetime.combine(today, cs.start_time) - timedelta(minutes=EARLY_WINDOW_MIN)).time()
            window_close = (datetime.combine(today, cs.start_time) + timedelta(minutes=LATE_WINDOW_MIN)).time()
            if window_open <= current_time <= window_close:
                eligible.append(cs)

        # Check which eligible sessions the student is enrolled in
        enrolled_unit_ids = {su.unit_id for su in
                            StudentUnit.query.filter_by(student_id=student.id).all()}

        marked = []
        skipped = []
        for cs in eligible:
            if cs.unit_id not in enrolled_unit_ids:
                skipped.append({
                    "session_id": cs.id,
                    "unit_code": cs.unit.code if cs.unit else None,
                    "reason": "not_enrolled"
                })
                continue

            # Check if already marked
            existing = Attendance.query.filter_by(
                student_id=student.id, class_session_id=cs.id).first()
            if existing:
                skipped.append({
                    "session_id": cs.id,
                    "unit_code": cs.unit.code if cs.unit else None,
                    "reason": "already_marked",
                    "status": existing.status
                })
                continue

            # Determine attendance status: before start → present, after start → late
            sched_start = datetime.combine(today, cs.start_time)
            status = "late" if now > sched_start else "present"
            att = Attendance(
                student_id=student.id, class_session_id=cs.id,
                check_in_time=now, status=status,
                confidence_score=similarity,
                verification_method="facial_recognition",
            )
            db.session.add(att)
            marked.append({
                "session_id": cs.id,
                "unit_code": cs.unit.code if cs.unit else None,
                "unit_name": cs.unit.name if cs.unit else None,
                "status": status,
                "venue": cs.venue,
                "time": f"{cs.start_time.strftime('%H:%M')}-{cs.end_time.strftime('%H:%M')}",
            })

        if marked:
            db.session.commit()

        result["attendance"] = {
            "marked": marked,
            "skipped": skipped,
            "total_marked": len(marked),
        }

    return jsonify(result)


# ═══════════════════════════════════════════════════════════════════════════
#  BACKWARD COMPAT (keep old /api/login working)
# ═══════════════════════════════════════════════════════════════════════════

@app.post("/api/login")
def api_login_compat():
    return api_login()


# ═══════════════════════════════════════════════════════════════════════════
#  SEED DATA — Embu University demo
# ═══════════════════════════════════════════════════════════════════════════

def seed_database():
    """Seed the database with Embu University demo data."""
    if User.query.first():
        return  # already seeded

    app.logger.info("Seeding Embu University demo data...")

    # ── Departments ──
    depts_data = [
        ("Computing & Information Technology", "DCIT", "School of Pure & Applied Sciences"),
        ("Business & Economics", "DBE", "School of Business"),
        ("Education & Social Sciences", "DESS", "School of Education"),
        ("Agriculture & Environmental Sciences", "DAES", "School of Agriculture"),
        ("Health Sciences", "DHS", "School of Health Sciences"),
    ]
    depts = {}
    for name, code, desc in depts_data:
        d = Department(name=name, code=code, description=desc)
        db.session.add(d)
        depts[code] = d
    db.session.flush()

    # ── Courses ──
    courses_data = [
        ("BSc Computer Science", "BSCIT", "DCIT", 4),
        ("BSc Information Technology", "BIT", "DCIT", 4),
        ("Bachelor of Commerce", "BCOM", "DBE", 4),
        ("BSc Agriculture", "BSCAG", "DAES", 4),
        ("Bachelor of Education (Arts)", "BEDA", "DESS", 4),
        ("BSc Nursing", "BSCN", "DHS", 4),
    ]
    courses = {}
    for name, code, dept_code, dur in courses_data:
        c = Course(name=name, code=code, department_id=depts[dept_code].id, duration_years=dur)
        db.session.add(c)
        courses[code] = c
    db.session.flush()

    # ── Superadmin ──
    admin = User(username="admin", role="superadmin",
                 first_name="System", last_name="Administrator",
                 email="admin@embuni.ac.ke")
    admin.set_password("admin123")
    db.session.add(admin)

    # ── Lecturers ──
    lecturers_data = [
        ("dr.mwangi", "James", "Mwangi", "mwangi@embuni.ac.ke"),
        ("prof.wanjiku", "Grace", "Wanjiku", "wanjiku@embuni.ac.ke"),
        ("dr.ochieng", "Peter", "Ochieng", "ochieng@embuni.ac.ke"),
        ("dr.njeri", "Faith", "Njeri", "njeri@embuni.ac.ke"),
    ]
    lecturers = {}
    for uname, fn, ln, email in lecturers_data:
        lec = User(username=uname, role="lecturer", first_name=fn, last_name=ln, email=email)
        lec.set_password("lecturer123")
        db.session.add(lec)
        lecturers[uname] = lec
    db.session.flush()

    # ── Units (course-independent) ──
    units_data = [
        ("Introduction to Programming", "CIT101", 3),
        ("Database Systems", "CIT201", 3),
        ("Data Structures & Algorithms", "CIT202", 3),
        ("Computer Networks", "CIT301", 3),
        ("Artificial Intelligence", "CIT401", 3),
        ("Web Development", "BIT101", 3),
        ("Financial Accounting", "COM101", 3),
        ("Crop Science", "AGR101", 3),
    ]
    units = {}
    for name, code, ch in units_data:
        u = Unit(name=name, code=code, credit_hours=ch)
        db.session.add(u)
        units[code] = u
    db.session.flush()

    # ── Course ↔ Unit links (which courses offer which units at which year/semester) ──
    course_unit_links = [
        ("BSCIT", "CIT101", 1, 1),  # BSc IT Year 1 Sem 1
        ("BSCIT", "CIT201", 2, 1),  # BSc IT Year 2 Sem 1
        ("BSCIT", "CIT202", 2, 1),  # BSc IT Year 2 Sem 1
        ("BSCIT", "CIT301", 3, 1),  # BSc IT Year 3 Sem 1
        ("BSCIT", "CIT401", 4, 1),  # BSc IT Year 4 Sem 1
        ("BIT",   "BIT101", 1, 1),  # BIT Year 1 Sem 1
        ("BIT",   "CIT101", 1, 1),  # BIT also takes Intro to Programming!
        ("BCOM",  "COM101", 1, 1),  # BCom Year 1 Sem 1
        ("BSCAG", "AGR101", 1, 1),  # BSc Ag Year 1 Sem 1
    ]
    for ccode, ucode, yr, sem in course_unit_links:
        cu = CourseUnit(course_id=courses[ccode].id, unit_id=units[ucode].id,
                        year=yr, semester=sem)
        db.session.add(cu)
    db.session.flush()

    # ── Lecturer-Unit assignments ──
    assignments = [
        ("dr.mwangi", "CIT101"), ("dr.mwangi", "CIT201"),
        ("prof.wanjiku", "CIT202"), ("prof.wanjiku", "CIT301"),
        ("dr.ochieng", "CIT401"), ("dr.ochieng", "BIT101"),
        ("dr.njeri", "COM101"), ("dr.njeri", "AGR101"),
    ]
    for lec_uname, unit_code in assignments:
        lu = LecturerUnit(lecturer_id=lecturers[lec_uname].id,
                          unit_id=units[unit_code].id)
        db.session.add(lu)
    db.session.flush()

    # ── Students ──
    first_names = ["John", "Mary", "Peter", "Grace", "James", "Faith", "David",
                   "Alice", "Brian", "Lucy", "Kevin", "Diana", "Samuel", "Joy",
                   "Victor", "Sarah", "Daniel", "Rose", "Patrick", "Ann"]
    last_names = ["Njoroge", "Wanjiru", "Mwangi", "Kamau", "Ochieng", "Nyambura",
                  "Gitau", "Muthoni", "Kipchoge", "Wambui", "Otieno", "Akinyi",
                  "Kimani", "Waithera", "Kibet", "Nyokabi", "Mutua", "Wangari",
                  "Rotich", "Chebet"]
    student_courses = ["BSCIT", "BSCIT", "BSCIT", "BSCIT", "BSCIT",
                       "BIT", "BIT", "BCOM", "BCOM", "BSCAG",
                       "BSCIT", "BSCIT", "BIT", "BCOM", "BSCAG",
                       "BSCIT", "BSCIT", "BIT", "BCOM", "BSCN"]
    for i in range(20):
        fn = first_names[i]
        ln = last_names[i]
        ccode = student_courses[i]
        yr = (i % 4) + 1
        sem = (i % 3) + 1
        reg_no = f"{ccode}-{yr:02d}-{i+1:03d}/2025"
        uname = f"{fn.lower()}.{ln.lower()}"

        user = User(username=uname, role="student", first_name=fn, last_name=ln,
                    email=f"{uname}@students.embuni.ac.ke")
        user.set_password("student123")
        db.session.add(user)
        db.session.flush()

        student = Student(user_id=user.id, registration_number=reg_no,
                          course_id=courses[ccode].id, year=yr, semester=sem,
                          consent_given=True)
        db.session.add(student)
    db.session.flush()

    # ── Auto-enroll students in their matching units (via course_units) ──
    all_students = Student.query.all()
    enrollment_count = 0
    for s in all_students:
        matching_cu = CourseUnit.query.filter_by(
            course_id=s.course_id, year=s.year, semester=s.semester).all()
        for cu in matching_cu:
            su = StudentUnit(student_id=s.id, unit_id=cu.unit_id)
            db.session.add(su)
            enrollment_count += 1
    db.session.flush()

    # ── Demo class sessions (realistic non-overlapping schedule) ──
    today = date.today()
    session_slots = [
        ("CIT101", "dr.mwangi",    time(8, 0),  time(10, 0), "Lecture Hall 1"),
        ("CIT201", "dr.mwangi",    time(10, 30), time(12, 30), "Lecture Hall 2"),
        ("CIT202", "prof.wanjiku", time(8, 0),  time(10, 0), "Lab Block A"),
        ("BIT101", "dr.ochieng",   time(8, 0),  time(10, 0), "ICT Lab 1"),
    ]
    for unit_code, lec_uname, st, et, venue in session_slots:
        cs = ClassSession(
            unit_id=units[unit_code].id, lecturer_id=lecturers[lec_uname].id,
            session_date=today, start_time=st, end_time=et,
            venue=venue, status="scheduled",
        )
        db.session.add(cs)

    # ── Demo device ──
    device = Device(name="Main Gate Kiosk", location="Main Entrance",
                    device_key="demo-device-key-for-testing-only")
    db.session.add(device)

    # ── Metrics ──
    db.session.add(RecognitionMetrics(total_attempts=0))

    db.session.commit()
    app.logger.info(f"Demo data seeded: 1 admin, 4 lecturers, 20 students, "
                    f"6 courses, 8 units, {enrollment_count} enrollments, "
                    f"4 sessions, 1 device")


# ── Boot ─────────────────────────────────────────────────────────────────
with app.app_context():
    db.create_all()
    seed_database()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
