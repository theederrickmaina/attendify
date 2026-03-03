<div align="center">

# ATTENDIFY

### Facial Recognition Attendance System

**Embu University College**

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://python.org)
[![Flask](https://img.shields.io/badge/Flask-3.0-000000?logo=flask)](https://flask.palletsprojects.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://postgresql.org)
[![pgvector](https://img.shields.io/badge/pgvector-HNSW-blueviolet)](https://github.com/pgvector/pgvector)

*An AI-powered facial recognition attendance system with real-time face detection, vector similarity search, and a premium dark-themed Flutter UI.*

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Database Schema](#database-schema)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Running the Application](#running-the-application)
- [Default Credentials](#default-credentials)
- [API Reference](#api-reference)
- [How It Works](#how-it-works)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Attendify** is a full-stack facial recognition attendance management system built for Embu University College, Kenya. It automates student attendance tracking using AI-powered face detection and recognition, replacing traditional manual roll-call methods.

The system supports three user roles — **Admin (Superadmin)**, **Lecturer**, and **Student** — each with dedicated dashboards and functionality. A **Kiosk Mode** allows deployment on standalone devices (tablets/PCs) where students simply look at the camera to have their attendance recorded automatically.

### Key Highlights

- **Real-time facial recognition** using InsightFace (ArcFace) with 512-dimensional embeddings
- **Vector similarity search** via PostgreSQL pgvector with HNSW indexing for sub-millisecond matching
- **Smart attendance window** — students can check in 15 minutes early to 20 minutes after session start
- **Cross-platform Flutter frontend** — runs on Web, Android, iOS, Windows, macOS, Linux
- **Premium dark futuristic UI** with glassmorphism, neon accents, and smooth animations
- **Full CRUD operations** for all academic entities (departments, courses, units, sessions)
- **Role-based access control** with JWT authentication

---

## Features

### Admin Dashboard
- **Dashboard analytics** — student count, enrollment stats, attendance rates, device status
- **Department management** — full CRUD (create, read, update, delete)
- **Course/Programme management** — full CRUD with department linking
- **Unit management** — full CRUD with many-to-many course linking (year/semester)
- **Lecturer-Unit assignment** — assign lecturers to units, remove assignments
- **Student management** — view students, manage face enrollments
- **User management** — create/edit users, reset passwords, toggle active status
- **Device/Kiosk management** — register kiosk devices, manage device keys

### Lecturer Portal
- **Dashboard** — teaching overview with bar charts, today's sessions, unit stats
- **My Units** — view assigned units and enrolled students with attendance rates
- **Session management** — create, reschedule (edit date/time/venue/status), delete sessions
- **Attendance monitoring** — view per-session attendance counts
- **Session overlap validation** — prevents double-booking of lecturers, units, and venues

### Student Portal
- **Dashboard** — attendance summary, upcoming sessions, overall stats
- **Unit enrollment** — browse available units, enroll/drop with validation
- **Attendance history** — per-unit attendance rates and session-level detail
- **Face enrollment** — capture and register facial embedding via camera

### Kiosk Mode
- **Automated face scanning** — continuous camera feed with real-time detection
- **Smart session matching** — finds eligible sessions within the attendance window
- **Instant feedback** — shows student identity, attendance status (present/late/already marked)
- **Exit protection** — password-protected exit to prevent unauthorized access
- **Animated UI** — scanning lines, pulse effects, neon glow feedback

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Frontend                          │
│  (Web / Android / iOS / Desktop)                                 │
│                                                                  │
│  ┌────────────┐ ┌────────────┐ ┌──────────┐ ┌────────────────┐  │
│  │   Admin    │ │  Lecturer  │ │ Student  │ │  Kiosk Mode    │  │
│  │   Shell    │ │   Shell    │ │  Shell   │ │  (Face Scan)   │  │
│  └─────┬──────┘ └─────┬──────┘ └────┬─────┘ └───────┬────────┘  │
│        └───────────────┴─────────────┴───────────────┘           │
│                         ApiService                               │
│                    (HTTP + JWT Auth)                              │
└──────────────────────────┬───────────────────────────────────────┘
                           │  REST API (JSON)
┌──────────────────────────┴───────────────────────────────────────┐
│                     Flask Backend (app.py)                        │
│                                                                  │
│  ┌──────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────────┐  │
│  │  Auth    │ │  Admin CRUD  │ │  Lecturer    │ │  Student   │  │
│  │  (JWT)   │ │  Endpoints   │ │  Endpoints   │ │  Endpoints │  │
│  └──────────┘ └──────────────┘ └──────────────┘ └────────────┘  │
│  ┌──────────────────┐ ┌──────────────────────────────────────┐   │
│  │  Face Recognition │ │  Vector Similarity Search            │   │
│  │  (InsightFace)    │ │  (pgvector + HNSW)                   │   │
│  └──────────────────┘ └──────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────────────┐
│              PostgreSQL + pgvector                                │
│                                                                  │
│  13 Tables: departments, courses, users, students, units,        │
│  course_units, lecturer_units, student_units, class_sessions,    │
│  attendance, devices, recognition_metrics, audit_log             │
│                                                                  │
│  HNSW Index on 512-d facial embeddings for fast ANN search       │
└──────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### Backend
| Technology | Purpose |
|---|---|
| **Python 3.10+** | Core backend language |
| **Flask 3.0** | Web framework & REST API |
| **Flask-SQLAlchemy** | ORM for database models |
| **Flask-JWT-Extended** | JWT authentication & role-based access |
| **Flask-CORS** | Cross-origin resource sharing |
| **InsightFace 0.7** | Face detection & recognition (ArcFace model) |
| **OpenCV** | Image processing & manipulation |
| **NumPy** | Numerical operations on embeddings |
| **Pillow** | Image decoding (base64 → image) |
| **psycopg2** | PostgreSQL adapter |
| **pgvector** | Vector similarity search in PostgreSQL |
| **python-dotenv** | Environment variable management |
| **cryptography** | Fernet encryption for device keys |

### Frontend
| Technology | Purpose |
|---|---|
| **Flutter 3.10+** | Cross-platform UI framework |
| **Dart** | Frontend language |
| **google_fonts** | Typography (Space Grotesk, Orbitron) |
| **fl_chart** | Bar charts & analytics visualizations |
| **flutter_animate** | Smooth animations & transitions |
| **http** | HTTP client for API calls |
| **jwt_decode** | JWT token parsing |
| **camera / camera_web** | Camera access for face capture |
| **image_picker** | Cross-platform image capture |
| **flutter_secure_storage** | Secure token storage |
| **shared_preferences** | Local settings persistence |

### Database
| Technology | Purpose |
|---|---|
| **PostgreSQL 15+** | Relational database |
| **pgvector** | Vector data type + HNSW index for ANN search |
| **pgcrypto** | Cryptographic device key generation |

---

## Database Schema

The system uses **13 tables** with the following relationships:

```
departments ──< courses ──< course_units >── units
                              │                │
                              │           lecturer_units >── users (lecturers)
                              │                │
                         students ──< student_units
                              │
                         class_sessions ──< attendance
                              │
                           devices    recognition_metrics    audit_log
```

### Core Tables

| Table | Description |
|---|---|
| `departments` | Academic departments (e.g., Computing & IT) |
| `courses` | Degree programmes (e.g., BSc IT) with department FK |
| `users` | All users — superadmin, lecturer, student roles |
| `students` | Student profiles with `vector(512)` facial embeddings |
| `units` | Academic units/modules (e.g., CIT101 Intro to IT) |
| `course_units` | Many-to-many junction: which units belong to which courses (+ year/semester) |
| `lecturer_units` | Lecturer-to-unit assignments |
| `student_units` | Student unit enrollments |
| `class_sessions` | Scheduled class sessions with date, time, venue, status |
| `attendance` | Attendance records (student + session + check-in time + status) |
| `devices` | Kiosk devices with encrypted device keys |
| `recognition_metrics` | Face recognition performance tracking |
| `audit_log` | System audit trail for all CRUD operations |

---

## Project Structure

```
Attendify/
├── backend/
│   ├── app.py                    # Main Flask application (all API endpoints)
│   ├── models.py                 # SQLAlchemy ORM models (13 tables)
│   ├── extensions.py             # Flask extensions (db, jwt)
│   ├── facenet_service.py        # InsightFace wrapper (detect, embed, quality)
│   ├── vector_face_service.py    # pgvector similarity search service
│   ├── face_recognition_service.py # High-level face recognition orchestrator
│   ├── liveness_detection.py     # Anti-spoofing liveness checks
│   ├── init_database.py          # Database initialization helper
│   ├── requirements.txt          # Python dependencies
│   └── test_app.py               # Backend tests
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart             # App entry point & routing
│   │   ├── config/
│   │   │   └── theme.dart        # Premium dark theme + reusable widgets
│   │   ├── screens/
│   │   │   ├── login_screen.dart # Animated login with role detection
│   │   │   ├── admin/
│   │   │   │   ├── admin_shell.dart              # Admin main screen (academics tab)
│   │   │   │   ├── admin_dashboard_screen.dart   # Admin analytics dashboard
│   │   │   │   ├── student_management_screen.dart # Student + face enrollment
│   │   │   │   └── user_management_screen.dart   # User CRUD
│   │   │   ├── lecturer/
│   │   │   │   └── lecturer_shell.dart           # Lecturer dashboard + sessions
│   │   │   ├── student/
│   │   │   │   └── student_shell.dart            # Student dashboard + enrollment
│   │   │   └── kiosk/
│   │   │       └── kiosk_screen.dart             # Kiosk face scanning mode
│   │   ├── services/
│   │   │   ├── api_service.dart    # HTTP client (all API methods + JWT)
│   │   │   ├── capture_service.dart # Platform-agnostic camera abstraction
│   │   │   ├── capture_web.dart    # Web camera implementation
│   │   │   ├── capture_mobile.dart # Mobile camera implementation
│   │   │   └── capture_stub.dart   # Stub for unsupported platforms
│   │   └── widgets/
│   │       └── face_scan_painter.dart # Face detection overlay painter
│   ├── pubspec.yaml              # Flutter dependencies
│   ├── android/                  # Android platform files
│   ├── ios/                      # iOS platform files
│   ├── web/                      # Web platform files
│   └── windows/                  # Windows platform files
│
├── database/
│   ├── setup_postgresql.sql      # Full SQL schema (13 tables + indexes)
│   ├── create_database.py        # Automated DB creation script
│   ├── recreate_db.py            # Drop & recreate database
│   └── install_pgvector.md       # pgvector installation guide
│
├── .env.example                  # Environment variables template
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

---

## Prerequisites

Before setting up Attendify, ensure you have:

1. **Python 3.10+** — [Download](https://www.python.org/downloads/)
2. **Flutter SDK 3.10+** — [Install Guide](https://docs.flutter.dev/get-started/install)
3. **PostgreSQL 15+** — [Download](https://www.postgresql.org/download/)
4. **pgvector extension** — see `database/install_pgvector.md` for installation instructions
5. **Git** — [Download](https://git-scm.com/)
6. **Chrome** (for Flutter web development)

### Hardware Requirements
- Webcam (for face enrollment and kiosk mode)
- Minimum 8GB RAM (InsightFace model loading)
- GPU optional but recommended for faster face detection

---

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/theederrickmaina/attendify.git
cd attendify
```

### 2. Set Up PostgreSQL Database

```bash
# Create the database
psql -U postgres -p 5433 -c "CREATE DATABASE attendify_db;"

# Install pgvector extension (if not already installed)
# See database/install_pgvector.md for platform-specific instructions

# Run the schema
psql -U postgres -p 5433 -d attendify_db -f database/setup_postgresql.sql
```

### 3. Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your database credentials
```

**`.env` configuration:**
```env
# Database — adjust username, password, host, port to match your setup
SQLALCHEMY_DATABASE_URI=postgresql://postgres:yourpassword@localhost:5433/attendify_db

# Security Keys (generate unique values for production)
ATTENDIFY_SECRET_KEY=your-secret-key-here
ATTENDIFY_JWT_SECRET=your-jwt-secret-here
ATTENDIFY_FERNET_KEY=your-fernet-key-here

# CORS — allowed frontend origins
ATTENDIFY_CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 4. Set Up Python Backend

```bash
# Create virtual environment
python -m venv .venv

# Activate it
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt
```

> **Note:** InsightFace will download the ArcFace model (~300MB) on first run.

### 5. Set Up Flutter Frontend

```bash
cd frontend

# Get dependencies
flutter pub get

# Verify setup
flutter doctor
```

---

## Running the Application

### Start the Backend

```bash
# From project root, with virtual environment activated
cd backend
python app.py
```

The Flask server starts on **http://localhost:5000** with:
- Auto-reload enabled (debug mode)
- Database tables auto-created via SQLAlchemy
- Demo seed data inserted on first run

### Start the Frontend

```bash
# In a separate terminal
cd frontend

# Run on Chrome (web)
flutter run -d chrome --web-port=8080

# Or run on connected Android device
flutter run -d <device-id>

# Or build for production
flutter build web
flutter build apk
```

The Flutter app runs on **http://localhost:8080** and connects to the backend at `localhost:5000`.

---

## Default Credentials

The system seeds demo data on first run with these accounts:

| Role | Username | Password |
|---|---|---|
| **Admin** | `admin` | `admin123` |
| **Lecturer** | `dr.mwangi` | `lecturer123` |
| **Lecturer** | `prof.njeri` | `lecturer123` |
| **Lecturer** | `dr.ochieng` | `lecturer123` |
| **Lecturer** | `ms.wambui` | `lecturer123` |
| **Student** | `john.njoroge` | `student123` |

> **Important:** Change these passwords in production. The system supports password change via the Settings screen.

### Demo Data Includes
- **4 Departments** — Computing & IT, Business & Economics, Education, Agriculture
- **6 Courses** — BSc IT, BSc CS, BIT, BCom, BEd Science, BSc Agriculture
- **8 Units** — CIT101 through various department units
- **20 Students** — with registration numbers and course assignments
- **4 Lecturers** — assigned to various units
- **1 Kiosk Device** — pre-registered for testing

---

## API Reference

### Authentication
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/login` | Login → JWT token |
| `POST` | `/api/auth/change-password` | Change password |

### Admin Endpoints (require `superadmin` role)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/dashboard` | Dashboard statistics |
| `GET/POST` | `/api/admin/departments` | List / Create departments |
| `PUT/DELETE` | `/api/admin/departments/<id>` | Update / Delete department |
| `GET/POST` | `/api/admin/courses` | List / Create courses |
| `PUT/DELETE` | `/api/admin/courses/<id>` | Update / Delete course |
| `GET/POST` | `/api/admin/units` | List / Create units |
| `PUT/DELETE` | `/api/admin/units/<id>` | Update / Delete unit |
| `GET/POST` | `/api/admin/course-units` | List / Add course-unit links |
| `DELETE` | `/api/admin/course-units/<id>` | Remove course-unit link |
| `GET/POST` | `/api/admin/lecturer-units` | List / Assign lecturer to unit |
| `DELETE` | `/api/admin/lecturer-units/<id>` | Remove lecturer assignment |
| `GET/POST` | `/api/admin/students` | List / Create students |
| `PUT` | `/api/admin/students/<id>` | Update student |
| `POST` | `/api/admin/students/<id>/enroll-face` | Enroll student face |
| `DELETE` | `/api/admin/students/<id>/remove-face` | Remove face enrollment |
| `GET/POST` | `/api/admin/users` | List / Create users |
| `PUT` | `/api/admin/users/<id>` | Update user |
| `GET/POST` | `/api/admin/devices` | List / Register kiosk devices |

### Lecturer Endpoints (require `lecturer` role)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/lecturer/dashboard` | Lecturer dashboard data |
| `GET` | `/api/lecturer/units` | My assigned units |
| `GET` | `/api/lecturer/sessions` | All my sessions |
| `POST` | `/api/lecturer/sessions` | Create a session |
| `PUT` | `/api/lecturer/sessions/<id>` | Edit / Reschedule session |
| `DELETE` | `/api/lecturer/sessions/<id>` | Delete session |
| `GET` | `/api/lecturer/unit/<id>/students` | Students enrolled in unit |

### Student Endpoints (require `student` role)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/student/dashboard` | Student dashboard data |
| `GET` | `/api/student/available-units` | Units available to enroll |
| `GET` | `/api/student/my-units` | Enrolled units with attendance |
| `POST` | `/api/student/enroll-unit` | Enroll in a unit |
| `DELETE` | `/api/student/drop-unit/<id>` | Drop a unit |

### Kiosk Endpoints (require device key)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/kiosk/recognize` | Recognize face + mark attendance |
| `GET` | `/api/kiosk/sessions` | Today's sessions for display |

### Face Recognition
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/recognize` | Smart recognition + auto-attendance |

---

## How It Works

### Face Enrollment Flow

```
1. Admin navigates to Student Management
2. Selects a student → "Enroll Face"
3. Camera captures student's face
4. InsightFace detects face → extracts 512-d embedding
5. Embedding stored in PostgreSQL (vector column)
6. HNSW index updated for fast future lookups
```

### Attendance Marking Flow (Kiosk)

```
1. Student approaches kiosk device
2. Camera captures face automatically
3. InsightFace detects & extracts embedding
4. pgvector HNSW search finds closest match (cosine similarity > 0.5)
5. System checks:
   a. Is the student enrolled in any active session's unit?
   b. Is current time within the attendance window?
      - Window opens: 15 minutes BEFORE session start
      - Window closes: 20 minutes AFTER session start
6. If eligible:
   - Before start_time → marked as "present"
   - After start_time (within 20 min) → marked as "late"
7. Kiosk displays result: student name, match %, attendance status
```

### Session Status Lifecycle

```
scheduled ──(15 min before start)──→ active ──(after end_time)──→ completed
     │                                                               
     └──────────── cancelled (manual) ───────────────────────────────
```

- Sessions auto-promote to **"active"** 15 minutes before their start time
- Sessions auto-promote to **"completed"** after their end time
- Lecturers can manually cancel or change status

### Overlap Validation

When creating or rescheduling sessions, the system checks for:
1. **Lecturer overlap** — same lecturer can't teach two sessions simultaneously
2. **Unit overlap** — same unit can't have two sessions at the same time
3. **Venue overlap** — same venue can't host two sessions simultaneously

### Security

- **JWT tokens** with role claims for API access control
- **Password hashing** via Werkzeug (PBKDF2-SHA256)
- **Device key encryption** using Fernet symmetric encryption
- **CORS** restricted to configured origins
- **Input validation** on all endpoints with proper error responses

---


### Login Screen
Premium dark-themed login with animated gradient background, glassmorphism card, and role-based routing.

### Admin Dashboard
Analytics overview with student counts, attendance rates, department/course management, and device monitoring.

### Lecturer Portal
Session management with create/reschedule/delete, unit overview with bar charts, and student attendance tracking.

### Kiosk Mode
Full-screen face scanning with animated scan lines, pulse effects, instant identity + attendance feedback.

### Student Dashboard
Personal attendance stats, unit enrollment, and session history.

---

## Troubleshooting

### Common Issues

**"Session not detected" on kiosk:**
- Ensure the session was created for the **current date** and the current time is within the attendance window (15 min before → 20 min after start)
- Check that the student is **enrolled in the unit** (Student → My Units → Enroll)
- Verify the session status is "scheduled" or "active" (not "cancelled" or "completed")

**Face not recognized:**
- Ensure the student's face has been enrolled (Admin → Student Management → Enroll Face)
- Check lighting conditions — the system needs clear, well-lit face images
- Similarity threshold is 0.5 (50%) — if below this, the match is rejected

**Database connection error:**
- Verify PostgreSQL is running on the configured port
- Check `.env` credentials match your PostgreSQL setup
- Ensure `pgvector` extension is installed: `CREATE EXTENSION IF NOT EXISTS vector;`

**CORS errors in browser:**
- Ensure `ATTENDIFY_CORS_ORIGINS` in `.env` includes your frontend URL
- The backend must be running when the frontend makes requests

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## License

This project is developed for **Embu University College** as part of an academic project.

---

<div align="center">

**Built with** ❤️ **by Derrick Maina**

*Embu University College — Faculty of Computing & Information Technology*

</div>
