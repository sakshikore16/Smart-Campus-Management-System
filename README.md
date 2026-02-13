# Smart Campus Management System

A role-based campus management application for **students**, **faculty**, and **administrators**. Built with a Flutter (Web/macOS) frontend and a Node.js/Express REST API, using MongoDB and JWT authentication.

---

## Features

- **Students:** View attendance, pay fees, request fee receipts, view marks, apply for leave, upload certificates, view timetable and notices, submit complaints, edit own profile.
- **Faculty:** Mark attendance, review attendance grievances and student leaves, upload marks, view timetable and salary slips, apply for leave, request ID cards, manage budget requests, edit own profile.
- **Administrators:** Separate admin login (no public registration). Manage students, faculty, and other admins (add/edit/delete). Oversee attendance, leaves, notices, fee payments, fee receipt requests, expenses, budgets, ID card requests, and complaints. Send targeted notifications. Dashboard statistics. Default admin is created automatically on first run.

---

## Prerequisites

- **Node.js** (v18+)
- **MongoDB** (local or Atlas)
- **Flutter SDK** (for frontend)
- **Cloudinary** account (optional; for file uploads)

---

## Quick Start

### 1. Clone and install

```bash
git clone <repository-url>
cd smart-campus-management-main
```

### 2. Backend

```bash
cd backend
cp .env.example .env    # Edit .env with your values
npm install
npm start               # or: npm run dev
```

Backend runs at **http://localhost:5001** (or the `PORT` in `.env`). On first run, a default admin is created if none exist (see **Default credentials** below).

Optional: run `npm run seed` to reset the database and create sample student, faculty, and admin accounts (see README in `backend` for seed credentials).

### 3. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome    # or: flutter run -d macos
```

Use the URL shown in the terminal (e.g. `http://localhost:xxxxx`). The app is configured to use **http://localhost:5001/api** as the API base URL. To use a different backend, edit `frontend/lib/core/config/api_config.dart` and set `baseUrl` accordingly.

---

## Default credentials

After the backend has run at least once (or after `npm run seed`):

| Role    | Email               | Password   |
|---------|---------------------|------------|
| Admin   | admin@campus.com    | admin123  |
| Faculty | faculty@campus.com  | faculty123 |
| Student | student@campus.com   | student123 |

- **Student/Faculty:** Log in at the main login page; use **Register** for new accounts (admin cannot register here).
- **Admin:** Use the **Admin? Log in here** link to open the admin login page (`/admin-login`).

---

## Environment (backend)

Create `backend/.env` with at least:

| Variable      | Description |
|---------------|-------------|
| `MONGO_URI`   | MongoDB connection string (e.g. `mongodb://127.0.0.1:27017/smartcampusapp`) |
| `JWT_SECRET`  | Secret key for signing JWTs |
| `PORT`        | Server port (default: 5001) |

Optional for file uploads: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.  
Optional for default admin: `DEFAULT_ADMIN_EMAIL`, `DEFAULT_ADMIN_PASSWORD`, `DEFAULT_ADMIN_NAME`.

---

## Project structure

```
smart-campus-management-main/
├── README.md                 # This file – setup and overview
├── APP_DOCUMENTATION.md      # Technical doc – architecture, API, file roles
├── backend/                  # Node.js API
│   ├── config/               # DB, Cloudinary
│   ├── controllers/          # Request handlers
│   ├── middleware/           # Auth, file upload
│   ├── models/               # Mongoose schemas
│   ├── routes/               # API route definitions
│   ├── scripts/              # ensureDefaultAdmin, seed
│   └── server.js             # Entry point
└── frontend/                 # Flutter app
    └── lib/
        ├── core/             # Config, theme, auth state, API client, router
        └── features/         # Auth, student, faculty, admin screens
```

---

## Documentation

- **README.md** (this file): Getting started, setup, credentials, and project layout.
- **APP_DOCUMENTATION.md**: Full technical documentation for submission — architecture, authentication flow, complete API endpoint list, backend and frontend file roles, libraries, and data flow. Use it for deep reference and evaluation.

---

## Tech stack (summary)

| Layer    | Technologies |
|----------|----------------|
| Frontend | Flutter (Web, macOS), Provider, go_router, http |
| Backend  | Node.js, Express, Mongoose, JWT, bcrypt, express-validator, Multer, Cloudinary |
| Database | MongoDB |
| Auth     | JWT, role-based access (student, faculty, admin) |

---

## License

This project is for educational/submission use. Adjust license as needed for your context.
