"""
Attendify — SQLAlchemy Models  ·  Embu University
──────────────────────────────────────────────────
Roles:   superadmin  ·  lecturer  ·  student
Tables:  departments, courses, users, students, units, course_units,
         lecturer_units, student_units, class_sessions, attendance,
         devices, recognition_metrics, audit_log, announcements
"""

from datetime import datetime, date
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import CheckConstraint, UniqueConstraint
from extensions import db

# pgvector type
try:
    from pgvector.sqlalchemy import Vector
    VECTOR_AVAILABLE = True
except ImportError:
    VECTOR_AVAILABLE = False
    class Vector:
        def __init__(self, dim): self.dim = dim


# ── Department ───────────────────────────────────────────────────────────
class Department(db.Model):
    __tablename__ = "departments"
    id          = db.Column(db.Integer, primary_key=True)
    name        = db.Column(db.String(150), nullable=False)
    code        = db.Column(db.String(20), nullable=False, unique=True)
    description = db.Column(db.Text)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    courses = db.relationship("Course", back_populates="department", cascade="all, delete-orphan")

    def to_dict(self):
        return {"id": self.id, "name": self.name, "code": self.code,
                "description": self.description,
                "course_count": len(self.courses) if self.courses else 0}


# ── Course / Programme ───────────────────────────────────────────────────
class Course(db.Model):
    __tablename__ = "courses"
    id             = db.Column(db.Integer, primary_key=True)
    name           = db.Column(db.String(150), nullable=False)
    code           = db.Column(db.String(20), nullable=False, unique=True)
    department_id  = db.Column(db.Integer, db.ForeignKey("departments.id"), nullable=False)
    duration_years = db.Column(db.Integer, nullable=False, default=4)
    created_at     = db.Column(db.DateTime, default=datetime.utcnow)

    department   = db.relationship("Department", back_populates="courses")
    course_units = db.relationship("CourseUnit", back_populates="course", cascade="all, delete-orphan")
    students     = db.relationship("Student", back_populates="course_rel")

    def to_dict(self):
        return {"id": self.id, "name": self.name, "code": self.code,
                "department_id": self.department_id, "duration_years": self.duration_years,
                "department_name": self.department.name if self.department else None,
                "student_count": len(self.students) if self.students else 0}


# ── User (all roles) ────────────────────────────────────────────────────
class User(db.Model):
    __tablename__ = "users"
    id                   = db.Column(db.Integer, primary_key=True)
    email                = db.Column(db.String(150), unique=True)
    username             = db.Column(db.String(80), nullable=False, unique=True)
    password_hash        = db.Column(db.String(256), nullable=False)
    role                 = db.Column(db.String(20), nullable=False)
    first_name           = db.Column(db.String(80), nullable=False)
    last_name            = db.Column(db.String(80), nullable=False)
    phone                = db.Column(db.String(20))
    is_active            = db.Column(db.Boolean, default=True)
    must_change_password = db.Column(db.Boolean, default=False)
    last_login           = db.Column(db.DateTime)
    created_at           = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at           = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    student         = db.relationship("Student", back_populates="user", uselist=False)
    lecturer_units  = db.relationship("LecturerUnit", back_populates="lecturer",
                                      foreign_keys="LecturerUnit.lecturer_id")
    class_sessions  = db.relationship("ClassSession", back_populates="lecturer",
                                      foreign_keys="ClassSession.lecturer_id")
    announcements   = db.relationship("Announcement", back_populates="author")

    __table_args__ = (
        CheckConstraint("role IN ('superadmin','lecturer','student')", name="ck_users_role"),
    )

    def set_password(self, plaintext: str):
        self.password_hash = generate_password_hash(plaintext)

    def check_password(self, plaintext: str) -> bool:
        return check_password_hash(self.password_hash, plaintext)

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    def to_dict(self, include_email=False):
        d = {"id": self.id, "username": self.username, "role": self.role,
             "first_name": self.first_name, "last_name": self.last_name,
             "full_name": self.full_name, "phone": self.phone,
             "is_active": self.is_active, "must_change_password": self.must_change_password,
             "last_login": self.last_login.isoformat() if self.last_login else None,
             "created_at": self.created_at.isoformat() if self.created_at else None}
        if include_email:
            d["email"] = self.email
        return d


# ── Student (extends User) ──────────────────────────────────────────────
class Student(db.Model):
    __tablename__ = "students"
    id                  = db.Column(db.Integer, primary_key=True)
    user_id             = db.Column(db.Integer, db.ForeignKey("users.id"), unique=True, nullable=False)
    registration_number = db.Column(db.String(50), nullable=False, unique=True)
    course_id           = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)
    year                = db.Column(db.Integer, nullable=False)
    semester            = db.Column(db.Integer, nullable=False)
    enrollment_date     = db.Column(db.Date, default=date.today)
    consent_given       = db.Column(db.Boolean, default=False)
    created_at          = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at          = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    if VECTOR_AVAILABLE:
        facial_embedding = db.Column(Vector(512), nullable=True)
    else:
        facial_embedding = db.Column(db.LargeBinary, nullable=True)

    user          = db.relationship("User", back_populates="student")
    course_rel    = db.relationship("Course", back_populates="students")
    attendances   = db.relationship("Attendance", back_populates="student", cascade="all, delete-orphan")
    student_units = db.relationship("StudentUnit", back_populates="student", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint("year BETWEEN 1 AND 6", name="ck_students_year"),
        CheckConstraint("semester IN (1,2,3)", name="ck_students_semester"),
    )

    @property
    def has_face(self):
        return self.facial_embedding is not None

    def to_dict(self):
        return {
            "id": self.id, "user_id": self.user_id,
            "registration_number": self.registration_number,
            "name": self.user.full_name if self.user else "",
            "first_name": self.user.first_name if self.user else "",
            "last_name": self.user.last_name if self.user else "",
            "course_id": self.course_id,
            "course_code": self.course_rel.code if self.course_rel else None,
            "course_name": self.course_rel.name if self.course_rel else None,
            "year": self.year, "semester": self.semester,
            "has_face": self.has_face, "consent_given": self.consent_given,
            "enrollment_date": self.enrollment_date.isoformat() if self.enrollment_date else None,
        }


# ── Unit / Module ────────────────────────────────────────────────────────
class Unit(db.Model):
    __tablename__ = "units"
    id           = db.Column(db.Integer, primary_key=True)
    name         = db.Column(db.String(150), nullable=False)
    code         = db.Column(db.String(20), nullable=False, unique=True)
    credit_hours = db.Column(db.Integer, nullable=False, default=3)
    created_at   = db.Column(db.DateTime, default=datetime.utcnow)

    course_units    = db.relationship("CourseUnit", back_populates="unit", cascade="all, delete-orphan")
    lecturer_units  = db.relationship("LecturerUnit", back_populates="unit", cascade="all, delete-orphan")
    student_units   = db.relationship("StudentUnit", back_populates="unit", cascade="all, delete-orphan")
    class_sessions  = db.relationship("ClassSession", back_populates="unit", cascade="all, delete-orphan")

    def to_dict(self):
        courses = []
        for cu in (self.course_units or []):
            courses.append({
                "course_id": cu.course_id,
                "course_code": cu.course.code if cu.course else None,
                "course_name": cu.course.name if cu.course else None,
                "year": cu.year, "semester": cu.semester,
            })
        d = {"id": self.id, "name": self.name, "code": self.code,
             "credit_hours": self.credit_hours, "courses": courses}
        # Backward-compat: expose first course info as top-level fields
        if courses:
            d["course_id"] = courses[0]["course_id"]
            d["course_code"] = courses[0]["course_code"]
            d["year"] = courses[0]["year"]
            d["semester"] = courses[0]["semester"]
        else:
            d["course_id"] = None
            d["course_code"] = None
            d["year"] = None
            d["semester"] = None
        return d


# ── Course ↔ Unit (many-to-many junction) ────────────────────────────────
class CourseUnit(db.Model):
    __tablename__ = "course_units"
    id        = db.Column(db.Integer, primary_key=True)
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)
    unit_id   = db.Column(db.Integer, db.ForeignKey("units.id"), nullable=False)
    year      = db.Column(db.Integer, nullable=False)
    semester  = db.Column(db.Integer, nullable=False)

    course = db.relationship("Course", back_populates="course_units")
    unit   = db.relationship("Unit", back_populates="course_units")

    __table_args__ = (
        UniqueConstraint("course_id", "unit_id", name="uq_course_unit"),
        CheckConstraint("year BETWEEN 1 AND 6", name="ck_course_units_year"),
        CheckConstraint("semester IN (1,2,3)", name="ck_course_units_semester"),
    )

    def to_dict(self):
        return {"id": self.id, "course_id": self.course_id, "unit_id": self.unit_id,
                "year": self.year, "semester": self.semester,
                "course_code": self.course.code if self.course else None,
                "course_name": self.course.name if self.course else None,
                "unit_code": self.unit.code if self.unit else None,
                "unit_name": self.unit.name if self.unit else None}


# ── Lecturer ↔ Unit ─────────────────────────────────────────────────────
class LecturerUnit(db.Model):
    __tablename__ = "lecturer_units"
    id            = db.Column(db.Integer, primary_key=True)
    lecturer_id   = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    unit_id       = db.Column(db.Integer, db.ForeignKey("units.id"), nullable=False)
    academic_year = db.Column(db.String(20), nullable=False, default="2025/2026")

    lecturer = db.relationship("User", back_populates="lecturer_units")
    unit     = db.relationship("Unit", back_populates="lecturer_units")

    __table_args__ = (
        UniqueConstraint("lecturer_id", "unit_id", "academic_year", name="uq_lec_unit_year"),
    )

    def to_dict(self):
        return {"id": self.id, "lecturer_id": self.lecturer_id, "unit_id": self.unit_id,
                "academic_year": self.academic_year,
                "lecturer_name": self.lecturer.full_name if self.lecturer else None,
                "unit_code": self.unit.code if self.unit else None,
                "unit_name": self.unit.name if self.unit else None}


# ── Student ↔ Unit enrollment ──────────────────────────────────────────
class StudentUnit(db.Model):
    __tablename__ = "student_units"
    id            = db.Column(db.Integer, primary_key=True)
    student_id    = db.Column(db.Integer, db.ForeignKey("students.id"), nullable=False)
    unit_id       = db.Column(db.Integer, db.ForeignKey("units.id"), nullable=False)
    academic_year = db.Column(db.String(20), nullable=False, default="2025/2026")
    enrolled_at   = db.Column(db.DateTime, default=datetime.utcnow)

    student = db.relationship("Student", back_populates="student_units")
    unit    = db.relationship("Unit", back_populates="student_units")

    __table_args__ = (
        UniqueConstraint("student_id", "unit_id", "academic_year", name="uq_student_unit_year"),
    )

    def to_dict(self):
        # Derive course context from the student's own course via course_units
        cu = None
        if self.student and self.unit:
            cu = CourseUnit.query.filter_by(
                course_id=self.student.course_id, unit_id=self.unit_id
            ).first()
        return {
            "id": self.id, "student_id": self.student_id, "unit_id": self.unit_id,
            "academic_year": self.academic_year,
            "student_name": self.student.user.full_name if self.student and self.student.user else None,
            "registration_number": self.student.registration_number if self.student else None,
            "unit_code": self.unit.code if self.unit else None,
            "unit_name": self.unit.name if self.unit else None,
            "course_code": cu.course.code if cu and cu.course else None,
            "year": cu.year if cu else None,
            "semester": cu.semester if cu else None,
            "credit_hours": self.unit.credit_hours if self.unit else None,
            "enrolled_at": self.enrolled_at.isoformat() if self.enrolled_at else None,
        }


# ── Class Session ────────────────────────────────────────────────────────
class ClassSession(db.Model):
    __tablename__ = "class_sessions"
    id           = db.Column(db.Integer, primary_key=True)
    unit_id      = db.Column(db.Integer, db.ForeignKey("units.id"), nullable=False)
    lecturer_id  = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    session_date = db.Column(db.Date, nullable=False)
    start_time   = db.Column(db.Time, nullable=False)
    end_time     = db.Column(db.Time, nullable=False)
    venue        = db.Column(db.String(100))
    status       = db.Column(db.String(20), nullable=False, default="scheduled")
    created_at   = db.Column(db.DateTime, default=datetime.utcnow)

    unit        = db.relationship("Unit", back_populates="class_sessions")
    lecturer    = db.relationship("User", back_populates="class_sessions")
    attendances = db.relationship("Attendance", back_populates="class_session", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint("status IN ('scheduled','active','completed','cancelled')", name="ck_cs_status"),
    )

    def to_dict(self):
        return {
            "id": self.id, "unit_id": self.unit_id, "lecturer_id": self.lecturer_id,
            "unit_code": self.unit.code if self.unit else None,
            "unit_name": self.unit.name if self.unit else None,
            "lecturer_name": self.lecturer.full_name if self.lecturer else None,
            "session_date": self.session_date.isoformat() if self.session_date else None,
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "venue": self.venue, "status": self.status,
            "attendance_count": len(self.attendances) if self.attendances else 0,
        }


# ── Attendance ───────────────────────────────────────────────────────────
class Attendance(db.Model):
    __tablename__ = "attendance"
    id                  = db.Column(db.Integer, primary_key=True)
    student_id          = db.Column(db.Integer, db.ForeignKey("students.id"), nullable=False)
    class_session_id    = db.Column(db.Integer, db.ForeignKey("class_sessions.id"), nullable=False)
    check_in_time       = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    status              = db.Column(db.String(20), nullable=False, default="present")
    confidence_score    = db.Column(db.Float)
    verification_method = db.Column(db.String(30), default="facial_recognition")
    device_id           = db.Column(db.Integer)
    created_at          = db.Column(db.DateTime, default=datetime.utcnow)

    student       = db.relationship("Student", back_populates="attendances")
    class_session = db.relationship("ClassSession", back_populates="attendances")

    __table_args__ = (
        UniqueConstraint("student_id", "class_session_id", name="uq_attendance_student_session"),
        CheckConstraint("status IN ('present','late','absent')", name="ck_attendance_status"),
    )

    def to_dict(self):
        return {
            "id": self.id, "student_id": self.student_id,
            "class_session_id": self.class_session_id,
            "student_name": self.student.user.full_name if self.student and self.student.user else "",
            "registration_number": self.student.registration_number if self.student else "",
            "check_in_time": self.check_in_time.isoformat() if self.check_in_time else None,
            "status": self.status, "confidence_score": self.confidence_score,
            "verification_method": self.verification_method,
        }


# ── Device (kiosk) ──────────────────────────────────────────────────────
class Device(db.Model):
    __tablename__ = "devices"
    id             = db.Column(db.Integer, primary_key=True)
    name           = db.Column(db.String(100), nullable=False)
    location       = db.Column(db.String(150))
    device_key     = db.Column(db.String(64), nullable=False, unique=True)
    is_active      = db.Column(db.Boolean, default=True)
    last_heartbeat = db.Column(db.DateTime)
    created_at     = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {"id": self.id, "name": self.name, "location": self.location,
                "is_active": self.is_active,
                "last_heartbeat": self.last_heartbeat.isoformat() if self.last_heartbeat else None}


# ── Recognition Metrics ─────────────────────────────────────────────────
class RecognitionMetrics(db.Model):
    __tablename__ = "recognition_metrics"
    id                  = db.Column(db.Integer, primary_key=True)
    total_attempts      = db.Column(db.Integer, default=0)
    successful_matches  = db.Column(db.Integer, default=0)
    failed_matches      = db.Column(db.Integer, default=0)
    low_quality_rejects = db.Column(db.Integer, default=0)
    liveness_failures   = db.Column(db.Integer, default=0)
    avg_confidence      = db.Column(db.Float, default=0.0)
    last_updated        = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {k: getattr(self, k) for k in
                ["total_attempts", "successful_matches", "failed_matches",
                 "low_quality_rejects", "liveness_failures", "avg_confidence"]}


# ── Audit Log ────────────────────────────────────────────────────────────
class AuditLog(db.Model):
    __tablename__ = "audit_log"
    id          = db.Column(db.Integer, primary_key=True)
    user_id     = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"))
    action      = db.Column(db.String(100), nullable=False)
    entity_type = db.Column(db.String(50))
    entity_id   = db.Column(db.Integer)
    details     = db.Column(db.JSON)
    ip_address  = db.Column(db.String(45))
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship("User")

    def to_dict(self):
        return {"id": self.id, "user_id": self.user_id, "action": self.action,
                "entity_type": self.entity_type, "entity_id": self.entity_id,
                "details": self.details, "ip_address": self.ip_address,
                "user_name": self.user.full_name if self.user else None,
                "created_at": self.created_at.isoformat() if self.created_at else None}


# ── Announcement ─────────────────────────────────────────────────────────
class Announcement(db.Model):
    __tablename__ = "announcements"
    id          = db.Column(db.Integer, primary_key=True)
    title       = db.Column(db.String(200), nullable=False)
    content     = db.Column(db.Text, nullable=False)
    author_id   = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    target_role = db.Column(db.String(20), default="all")
    is_pinned   = db.Column(db.Boolean, default=False)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at  = db.Column(db.DateTime)

    author = db.relationship("User", back_populates="announcements")

    def to_dict(self):
        return {"id": self.id, "title": self.title, "content": self.content,
                "author_name": self.author.full_name if self.author else None,
                "target_role": self.target_role, "is_pinned": self.is_pinned,
                "created_at": self.created_at.isoformat() if self.created_at else None,
                "expires_at": self.expires_at.isoformat() if self.expires_at else None}
