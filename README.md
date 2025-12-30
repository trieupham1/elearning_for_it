# 🎓 E-Learning Management System for IT Faculty

A comprehensive e-learning platform built with **Flutter** (frontend) and **Node.js/Express** (backend), designed for IT faculty to manage courses, assignments, quizzes, and student interactions.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Express.js](https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white)

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Running the Application](#-running-the-application)
- [Deployment](#-deployment)
- [API Documentation](#-api-documentation)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)

## ✨ Features

### 👨‍🎓 For Students
- **Course Enrollment** - Browse and enroll in available courses
- **Video Learning** - Watch course videos with progress tracking
- **Assignments** - Submit assignments with file uploads and multiple attempts
- **Code Assignments** - Write and submit code with automated testing (Judge0 integration)
- **Quizzes** - Take timed quizzes with automatic grading
- **Forum** - Participate in course discussions
- **Notifications** - Real-time notifications for announcements, grades, and deadlines
- **Chat & Messages** - Direct messaging with instructors and peers
- **Attendance** - View attendance records

### 👨‍🏫 For Instructors
- **Course Management** - Create and manage courses with materials
- **Content Creation** - Upload videos, create assignments, and design quizzes
- **Grading System** - Grade submissions with feedback
- **Student Management** - Track student progress and attendance
- **Announcements** - Post course announcements with email notifications
- **Analytics Dashboard** - View course statistics and student performance
- **Group Management** - Create and manage student groups
- **Export Reports** - Generate PDF/Excel reports

### 👨‍💼 For Administrators
- **User Management** - Manage students, instructors, and admin accounts
- **Department Management** - Organize courses by departments
- **Semester Management** - Configure academic semesters
- **System Settings** - Configure platform settings
- **Activity Logs** - Monitor system activities

### 🔔 Notification System
- Email notifications for:
  - New announcements
  - Assignment deadlines (3-day and 1-day reminders)
  - New quizzes available
  - Submission confirmations
  - Grade releases
- In-app real-time notifications via WebSocket

## 🛠 Tech Stack

### Frontend (Flutter)
| Technology | Purpose |
|------------|---------|
| Flutter 3.5+ | Cross-platform UI framework |
| Dart | Programming language |
| HTTP | API communication |
| SharedPreferences | Local storage for auth tokens |
| Socket.IO Client | Real-time notifications |
| File Picker | File uploads |
| Video Player | Course video playback |
| Chewie | Video player controls |

### Backend (Node.js)
| Technology | Purpose |
|------------|---------|
| Express.js | Web framework |
| MongoDB | Database |
| Mongoose | ODM for MongoDB |
| JWT | Authentication |
| Socket.IO | Real-time communication |
| Nodemailer | Email service |
| Brevo API | Transactional emails |
| Cloudinary | Media storage |
| Multer | File uploads |
| Node-Cron | Scheduled tasks |
| Judge0 | Code execution engine |

## 📁 Project Structure

```
elearning_for_it/
├── elearningit/                 # Main application folder
│   ├── lib/                     # Flutter source code
│   │   ├── config/              # App configuration
│   │   ├── models/              # Data models
│   │   ├── screens/             # UI screens
│   │   │   ├── admin/           # Admin screens
│   │   │   ├── instructor/      # Instructor screens
│   │   │   ├── student/         # Student screens
│   │   │   ├── course_tabs/     # Course detail tabs
│   │   │   ├── chat/            # Chat screens
│   │   │   └── forum/           # Forum screens
│   │   ├── services/            # API services
│   │   └── main.dart            # App entry point
│   │
│   ├── backend/                 # Node.js backend
│   │   ├── models/              # Mongoose schemas
│   │   ├── routes/              # API routes
│   │   ├── middleware/          # Auth middleware
│   │   ├── utils/               # Utilities (email, etc.)
│   │   ├── scripts/             # Database scripts
│   │   └── server.js            # Server entry point
│   │
│   ├── android/                 # Android configuration
│   ├── ios/                     # iOS configuration
│   ├── web/                     # Web configuration
│   └── pubspec.yaml             # Flutter dependencies
│
├── docs/                        # Documentation
└── README.md                    # This file
```

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** 3.5.0 or higher
- **Dart SDK** 3.5.0 or higher
- **Node.js** 18.x or higher
- **npm** 9.x or higher
- **MongoDB** (local or Atlas cloud)
- **Git**

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/trieupham1/elearning_for_it.git
cd elearning_for_it
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd elearningit/backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your configuration (see Configuration section)
```

### 3. Frontend Setup

```bash
# Navigate to Flutter app directory
cd elearningit

# Get Flutter dependencies
flutter pub get

# Generate JSON serialization code
flutter packages pub run build_runner build
```

## ⚙️ Configuration

### Backend Environment Variables (.env)

Create a `.env` file in the `backend` folder:

```env
# MongoDB
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/elearning

# Server
PORT=5000

# JWT Secret (use a strong random string)
JWT_SECRET=your_super_secret_jwt_key_here

# Frontend URL (for email links)
FRONTEND_URL=https://your-domain.com

# Email (Brevo - recommended for production)
BREVO_API_KEY=your_brevo_api_key
EMAIL_FROM=your-email@domain.com

# Cloudinary (for media storage)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Judge0 (for code assignments)
JUDGE0_API_URL=https://judge0-ce.p.rapidapi.com
JUDGE0_API_KEY=your_rapidapi_key
JUDGE0_API_HOST=judge0-ce.p.rapidapi.com

# File Upload Limits
MAX_FILE_SIZE=10485760
MAX_VIDEO_SIZE=524288000
```

### Frontend API Configuration

Edit `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // For production
  static const String baseUrl = 'https://your-backend.onrender.com/api';
  
  // For local development
  // static const String baseUrl = 'http://localhost:5000/api';
  // static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
}
```

## 🏃 Running the Application

### Start Backend Server

```bash
cd elearningit/backend

# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The server will start at `http://localhost:5000`

### Start Flutter App

```bash
cd elearningit

# Run on connected device/emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Run on specific device
flutter devices  # List available devices
flutter run -d <device_id>
```

## 🌐 Deployment

### Backend Deployment (Render.com)

1. Create a new **Web Service** on Render
2. Connect your GitHub repository
3. Configure:
   - **Build Command:** `cd elearningit/backend && npm install`
   - **Start Command:** `cd elearningit/backend && npm start`
4. Add environment variables from your `.env` file
5. Deploy

### Frontend Deployment (GitHub Pages)

```bash
cd elearningit

# Build for web
flutter build web --release --base-href "/elearning_for_it/"

# The build output is in build/web/
# Push to gh-pages branch or configure GitHub Actions
```

Or use the provided GitHub Actions workflow (`.github/workflows/deploy.yml`)

## 📚 API Documentation

### Authentication
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | Register new user |
| `/api/auth/login` | POST | User login |
| `/api/auth/me` | GET | Get current user |
| `/api/auth/forgot-password` | POST | Request password reset |

### Courses
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/courses` | GET | Get all courses |
| `/api/courses/:id` | GET | Get course by ID |
| `/api/courses` | POST | Create course (Instructor) |
| `/api/courses/:id/enroll` | POST | Enroll in course |

### Assignments
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/assignments/:courseId` | GET | Get course assignments |
| `/api/assignments` | POST | Create assignment |
| `/api/assignments/:id/submit` | POST | Submit assignment |

### Quizzes
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/quizzes/:courseId` | GET | Get course quizzes |
| `/api/quizzes` | POST | Create quiz |
| `/api/quiz-attempts/:quizId/start` | POST | Start quiz attempt |

For full API documentation, see [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## 📱 Screenshots

### Student Interface
- Dashboard with enrolled courses
- Course detail with video lessons
- Assignment submission
- Quiz taking interface

### Instructor Interface
- Course management dashboard
- Student progress tracking
- Grading interface
- Analytics and reports

### Admin Interface
- User management
- Department configuration
- System settings

## 🔐 Default Accounts

After seeding the database (`npm run seed`):

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@university.edu | admin123 |
| Instructor | instructor@university.edu | instructor123 |
| Student | student@university.edu | student123 |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is developed for educational purposes as part of a university capstone project.

## 👥 Authors

- **Pham Quoc Trieu** - *Full Stack Developer*

## 🙏 Acknowledgments

- Faculty of Information Technology
- Flutter and Dart teams
- MongoDB Atlas for database hosting
- Render.com for backend hosting
- Brevo for email services
- Cloudinary for media storage

---

<p align="center">
  Made with ❤️ for IT Faculty E-Learning
</p>
