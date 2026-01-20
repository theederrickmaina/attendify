"""
SQLAlchemy Models for Attendify
-------------------------------
Defines the database schema and relationships.

Compliance & Security:
- 'facial_embedding' is stored encrypted (LargeBinary) using Fernet in the app logic.
- Consent is required: do not process or store biometric data unless consent_given=True.
"""

from sqlalchemy import CheckConstraint, UniqueConstraint
from backend.extensions import db


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False)  # 'student' or 'admin'
    consent_given = db.Column(db.Boolean, default=False, nullable=False)

    # One-to-one with Student (if role == 'student')
    student = db.relationship("Student", back_populates="user", uselist=False)

    # Lecturer teaches many classes (if role == 'admin' used for lecturer/admin)
    lectures = db.relationship(
        "Class", back_populates="lecturer", foreign_keys="Class.lecturer_id"
    )

    __table_args__ = (
        CheckConstraint(
            "role IN ('student','admin')",
            name="ck_users_role_valid",
        ),
    )


class Student(db.Model):
    __tablename__ = "students"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), unique=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    registration_number = db.Column(db.String(50), nullable=False)
    course = db.Column(db.String(80), nullable=False)
    year = db.Column(db.Integer, nullable=False)
    semester = db.Column(db.Integer, nullable=False)

    # Encrypted facial embedding stored as bytes; application logic handles encryption
    facial_embedding = db.Column(db.LargeBinary, nullable=True)

    user = db.relationship("User", back_populates="student")

    attendances = db.relationship(
        "Attendance",
        back_populates="student",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        UniqueConstraint("registration_number", name="uq_students_regno"),
        CheckConstraint("year BETWEEN 1 AND 6", name="ck_students_year_range"),
        CheckConstraint("semester IN (1,2)", name="ck_students_semester_valid"),
    )


class Course(db.Model):
    __tablename__ = "courses"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    code = db.Column(db.String(20), nullable=False, unique=True)

    classes = db.relationship(
        "Class",
        back_populates="course",
        cascade="all, delete-orphan",
    )


class Class(db.Model):
    __tablename__ = "classes"

    id = db.Column(db.Integer, primary_key=True)
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)
    day_of_week = db.Column(db.String(10), nullable=False)  # e.g. 'Mon'
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    lecturer_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)

    course = db.relationship("Course", back_populates="classes")
    lecturer = db.relationship("User", back_populates="lectures")

    attendances = db.relationship(
        "Attendance",
        back_populates="class_",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        CheckConstraint("day_of_week IN ('Mon','Tue','Wed','Thu','Fri','Sat','Sun')", name="ck_classes_day_valid"),
        CheckConstraint("start_time < end_time", name="ck_classes_time_order"),
    )


class Attendance(db.Model):
    __tablename__ = "attendance"

    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey("students.id"), nullable=False)
    class_id = db.Column(db.Integer, db.ForeignKey("classes.id"), nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False)
    status = db.Column(db.String(10), nullable=False)  # 'present' or 'absent'

    student = db.relationship("Student", back_populates="attendances")
    class_ = db.relationship("Class", back_populates="attendances")

    __table_args__ = (
        CheckConstraint("status IN ('present','absent')", name="ck_attendance_status_valid"),
    )
