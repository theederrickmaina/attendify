-- ══════════════════════════════════════════════════════════════════════════
-- Attendify — Embu University Facial Attendance System
-- Full PostgreSQL Schema  ·  pgvector + HNSW  ·  Role-based access
-- ══════════════════════════════════════════════════════════════════════════
--
-- Roles:  superadmin  ·  lecturer  ·  student
-- Extensions:  pgvector (512-d face embeddings + HNSW index)
--              pgcrypto (device key generation)
--

-- ── Extensions ──────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Drop old tables (clean slate for revamp) ────────────────────────────
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS class_sessions CASCADE;
DROP TABLE IF EXISTS student_units CASCADE;
DROP TABLE IF EXISTS course_units CASCADE;
DROP TABLE IF EXISTS lecturer_units CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS recognition_metrics CASCADE;
DROP TABLE IF EXISTS users CASCADE;
-- also drop old tables from the previous schema
DROP TABLE IF EXISTS classes CASCADE;

-- ── 1. Departments ──────────────────────────────────────────────────────
CREATE TABLE departments (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    code        VARCHAR(20)  NOT NULL UNIQUE,
    description TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 2. Courses / Programmes ─────────────────────────────────────────────
CREATE TABLE courses (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(150) NOT NULL,
    code           VARCHAR(20)  NOT NULL UNIQUE,
    department_id  INTEGER NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    duration_years INTEGER NOT NULL DEFAULT 4 CHECK (duration_years BETWEEN 1 AND 8),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 3. Users (all roles) ────────────────────────────────────────────────
CREATE TABLE users (
    id                   SERIAL PRIMARY KEY,
    email                VARCHAR(150) UNIQUE,
    username             VARCHAR(80)  NOT NULL UNIQUE,
    password_hash        VARCHAR(256) NOT NULL,
    role                 VARCHAR(20)  NOT NULL CHECK (role IN ('superadmin','lecturer','student')),
    first_name           VARCHAR(80)  NOT NULL,
    last_name            VARCHAR(80)  NOT NULL,
    phone                VARCHAR(20),
    is_active            BOOLEAN  DEFAULT TRUE,
    must_change_password BOOLEAN  DEFAULT FALSE,
    last_login           TIMESTAMP,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 4. Students (extends users) ─────────────────────────────────────────
CREATE TABLE students (
    id                   SERIAL PRIMARY KEY,
    user_id              INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    registration_number  VARCHAR(50) NOT NULL UNIQUE,
    course_id            INTEGER NOT NULL REFERENCES courses(id),
    year                 INTEGER NOT NULL CHECK (year BETWEEN 1 AND 6),
    semester             INTEGER NOT NULL CHECK (semester IN (1,2,3)),
    facial_embedding     vector(512),
    enrollment_date      DATE DEFAULT CURRENT_DATE,
    consent_given        BOOLEAN DEFAULT FALSE,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 5. Units / Modules ──────────────────────────────────────────────────
CREATE TABLE units (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    code         VARCHAR(20)  NOT NULL UNIQUE,
    credit_hours INTEGER NOT NULL DEFAULT 3,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 5b. Course ↔ Unit (many-to-many: one unit can serve multiple courses)
CREATE TABLE course_units (
    id          SERIAL PRIMARY KEY,
    course_id   INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    unit_id     INTEGER NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    year        INTEGER NOT NULL CHECK (year BETWEEN 1 AND 6),
    semester    INTEGER NOT NULL CHECK (semester IN (1,2,3)),
    UNIQUE(course_id, unit_id)
);

-- ── 6. Lecturer ↔ Unit assignments ──────────────────────────────────────
CREATE TABLE lecturer_units (
    id            SERIAL PRIMARY KEY,
    lecturer_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    unit_id       INTEGER NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    academic_year VARCHAR(20) NOT NULL DEFAULT '2025/2026',
    UNIQUE(lecturer_id, unit_id, academic_year)
);

-- ── 6b. Student ↔ Unit enrollment ──────────────────────────────────────
CREATE TABLE student_units (
    id            SERIAL PRIMARY KEY,
    student_id    INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    unit_id       INTEGER NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    academic_year VARCHAR(20) NOT NULL DEFAULT '2025/2026',
    enrolled_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, unit_id, academic_year)
);

-- ── 7. Class Sessions ───────────────────────────────────────────────────
CREATE TABLE class_sessions (
    id           SERIAL PRIMARY KEY,
    unit_id      INTEGER NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    lecturer_id  INTEGER NOT NULL REFERENCES users(id),
    session_date DATE    NOT NULL,
    start_time   TIME    NOT NULL,
    end_time     TIME    NOT NULL,
    venue        VARCHAR(100),
    status       VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                     CHECK (status IN ('scheduled','active','completed','cancelled')),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 8. Attendance ───────────────────────────────────────────────────────
CREATE TABLE attendance (
    id                  SERIAL PRIMARY KEY,
    student_id          INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_session_id    INTEGER NOT NULL REFERENCES class_sessions(id) ON DELETE CASCADE,
    check_in_time       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status              VARCHAR(20) NOT NULL DEFAULT 'present'
                            CHECK (status IN ('present','late','absent')),
    confidence_score    FLOAT,
    verification_method VARCHAR(30) DEFAULT 'facial_recognition',
    device_id           INTEGER,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, class_session_id)
);

-- ── 9. Kiosk Devices ───────────────────────────────────────────────────
CREATE TABLE devices (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    location       VARCHAR(150),
    device_key     VARCHAR(64) NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
    is_active      BOOLEAN DEFAULT TRUE,
    last_heartbeat TIMESTAMP,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 10. Recognition Metrics ─────────────────────────────────────────────
CREATE TABLE recognition_metrics (
    id                   SERIAL PRIMARY KEY,
    total_attempts       INTEGER DEFAULT 0,
    successful_matches   INTEGER DEFAULT 0,
    failed_matches       INTEGER DEFAULT 0,
    low_quality_rejects  INTEGER DEFAULT 0,
    liveness_failures    INTEGER DEFAULT 0,
    avg_confidence       FLOAT   DEFAULT 0.0,
    last_updated         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 11. Audit Log ───────────────────────────────────────────────────────
CREATE TABLE audit_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id   INTEGER,
    details     JSONB,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── 12. Announcements ───────────────────────────────────────────────────
CREATE TABLE announcements (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    content     TEXT NOT NULL,
    author_id   INTEGER NOT NULL REFERENCES users(id),
    target_role VARCHAR(20) DEFAULT 'all' CHECK (target_role IN ('all','lecturer','student')),
    is_pinned   BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP
);

-- ── Indexes ─────────────────────────────────────────────────────────────
CREATE INDEX idx_users_role            ON users(role);
CREATE INDEX idx_users_username        ON users(username);
CREATE INDEX idx_students_user_id      ON students(user_id);
CREATE INDEX idx_students_reg_no       ON students(registration_number);
CREATE INDEX idx_students_course_id    ON students(course_id);
CREATE INDEX idx_course_units_course   ON course_units(course_id);
CREATE INDEX idx_course_units_unit     ON course_units(unit_id);
CREATE INDEX idx_lecturer_units_lec    ON lecturer_units(lecturer_id);
CREATE INDEX idx_lecturer_units_unit   ON lecturer_units(unit_id);
CREATE INDEX idx_student_units_student ON student_units(student_id);
CREATE INDEX idx_student_units_unit    ON student_units(unit_id);
CREATE INDEX idx_class_sessions_unit   ON class_sessions(unit_id);
CREATE INDEX idx_class_sessions_lec    ON class_sessions(lecturer_id);
CREATE INDEX idx_class_sessions_date   ON class_sessions(session_date);
CREATE INDEX idx_attendance_student    ON attendance(student_id);
CREATE INDEX idx_attendance_session    ON attendance(class_session_id);
CREATE INDEX idx_attendance_checkin    ON attendance(check_in_time);
CREATE INDEX idx_audit_log_user        ON audit_log(user_id);
CREATE INDEX idx_audit_log_created     ON audit_log(created_at);
CREATE INDEX idx_announcements_target  ON announcements(target_role);

-- HNSW index for ultra-fast face matching (pgvector)
CREATE INDEX idx_students_face_hnsw
    ON students USING hnsw (facial_embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- ── Triggers ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = CURRENT_TIMESTAMP; RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated    BEFORE UPDATE ON users    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_students_updated BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── Seed initial metrics row ────────────────────────────────────────────
INSERT INTO recognition_metrics (total_attempts) VALUES (0);

-- ── Fast face similarity search function ────────────────────────────────
CREATE OR REPLACE FUNCTION find_similar_faces(
    query_embedding vector(512),
    similarity_threshold FLOAT DEFAULT 0.6,
    max_results INTEGER DEFAULT 10
)
RETURNS TABLE(
    student_id          INTEGER,
    similarity          FLOAT,
    student_name        TEXT,
    registration_number VARCHAR,
    course_code         VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        (1 - (s.facial_embedding <=> query_embedding))::FLOAT,
        (u.first_name || ' ' || u.last_name)::TEXT,
        s.registration_number,
        c.code
    FROM students s
    JOIN users u   ON u.id = s.user_id
    JOIN courses c ON c.id = s.course_id
    WHERE s.facial_embedding IS NOT NULL
      AND 1 - (s.facial_embedding <=> query_embedding) >= similarity_threshold
    ORDER BY s.facial_embedding <=> query_embedding
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;
