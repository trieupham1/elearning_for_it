# PHỤ LỤC (APPENDICES)

## PHỤ LỤC A: MÃ NGUỒN QUAN TRỌNG

### A.1. Backend - Server Entry Point

**File:** `backend/server.js` (215 lines)

```javascript
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true
}));
app.use(express.json({ limit: '50mb' }));

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✓ MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

// Import routes (35+ routes)
const authRoutes = require('./routes/auth');
const courseRoutes = require('./routes/courses');
const assignmentRoutes = require('./routes/assignments');
// ... other routes

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/assignments', assignmentRoutes);
// ... other routes

// Socket.IO setup
const io = socketIO(server, {
  cors: { origin: '*' }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('join-course', (courseId) => {
    socket.join(`course-${courseId}`);
  });
  
  socket.on('send-message', (data) => {
    io.to(`course-${data.courseId}`).emit('new-message', data);
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: err.message });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`✓ Server running on port ${PORT}`);
});
```

### A.2. Frontend - Main Entry Point

**File:** `lib/main.dart` (417 lines)

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/instructor_dashboard.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning System',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/student-dashboard': (context) => StudentDashboard(),
        '/instructor-dashboard': (context) => InstructorDashboard(),
        '/admin-dashboard': (context) => AdminDashboardScreen(),
        // ... 40+ other routes
      },
    );
  }
}
```

### A.3. Authentication Middleware

**File:** `backend/middleware/auth.js`

```javascript
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    req.userId = user._id;
    req.userRole = user.role;
    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};

const instructorOnly = (req, res, next) => {
  if (req.userRole !== 'instructor' && req.userRole !== 'admin') {
    return res.status(403).json({ message: 'Instructors only' });
  }
  next();
};

const adminOnly = (req, res, next) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ message: 'Admins only' });
  }
  next();
};

module.exports = { auth, instructorOnly, adminOnly };
```

### A.4. API Service (Flutter)

**File:** `lib/services/api_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseURL = ApiConfig.getBaseUrl();
    _dio.options.connectTimeout = Duration(seconds: 10);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          // Navigate to login
        }
        return handler.next(error);
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      return error.response!.data['message'] ?? 'Server error';
    } else {
      return 'Network error';
    }
  }
}
```

---

## PHỤ LỤC B: DATABASE SCHEMAS

### B.1. User Schema

```javascript
// backend/models/User.js
const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { 
    type: String, 
    enum: ['student', 'instructor', 'admin'], 
    default: 'student' 
  },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  studentId: { type: String, sparse: true },
  departmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Department' },
  avatar: String,
  isActive: { type: Boolean, default: true }
}, { timestamps: true });
```

### B.2. Course Schema

```javascript
// backend/models/Course.js
const courseSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  description: String,
  instructor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  semester: { type: mongoose.Schema.Types.ObjectId, ref: 'Semester' },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  sessions: { type: Number, default: 15 },
  color: { type: String, default: '#1976D2' },
  image: String
}, { timestamps: true });
```

### B.3. Assignment Schema

```javascript
// backend/models/Assignment.js
const assignmentSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  title: { type: String, required: true },
  description: String,
  assignmentType: { type: String, enum: ['file', 'code'], required: true },
  startDate: Date,
  deadline: { type: Date, required: true },
  allowLateSubmission: { type: Boolean, default: false },
  maxAttempts: { type: Number, default: 1 },
  points: { type: Number, default: 100 },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  groups: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Group' }],
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number
  }]
}, { timestamps: true });
```

### B.4. Quiz Schema

```javascript
// backend/models/Quiz.js
const quizSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  title: { type: String, required: true },
  description: String,
  startTime: Date,
  endTime: Date,
  duration: { type: Number, required: true }, // in minutes
  totalPoints: { type: Number, default: 100 },
  passingScore: { type: Number, default: 60 },
  maxAttempts: { type: Number, default: 1 },
  shuffleQuestions: { type: Boolean, default: false },
  showAnswers: { type: Boolean, default: false },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
```

---

## PHỤ LỤC C: API REQUEST/RESPONSE EXAMPLES

### C.1. User Login

**Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "student01",
  "password": "password123"
}
```

**Response (Success):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "65a1b2c3d4e5f6g7h8i9j0k1",
    "username": "student01",
    "email": "student01@example.com",
    "role": "student",
    "firstName": "Nguyen",
    "lastName": "Van A",
    "avatar": "https://example.com/avatar.jpg"
  }
}
```

### C.2. Get Courses

**Request:**
```http
GET /api/courses
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "courses": [
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k2",
      "code": "IT4409",
      "name": "Cơ sở dữ liệu",
      "description": "Học về database",
      "instructor": {
        "_id": "65a1b2c3d4e5f6g7h8i9j0k3",
        "firstName": "Tran",
        "lastName": "Van B"
      },
      "color": "#1976D2",
      "studentCount": 45
    }
  ]
}
```

### C.3. Submit Assignment

**Request:**
```http
POST /api/assignments/65a1b2c3d4e5f6g7h8i9j0k4/submit
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: multipart/form-data

files: [File1, File2]
```

**Response:**
```json
{
  "_id": "65a1b2c3d4e5f6g7h8i9j0k5",
  "assignmentId": "65a1b2c3d4e5f6g7h8i9j0k4",
  "studentId": "65a1b2c3d4e5f6g7h8i9j0k1",
  "files": [
    {
      "fileName": "baitap.pdf",
      "fileUrl": "/api/files/65a1b2c3d4e5f6g7h8i9j0k6",
      "fileSize": 2048576
    }
  ],
  "submissionTime": "2024-01-10T10:30:00.000Z",
  "status": "submitted",
  "isLate": false
}
```

### C.4. Grade Submission

**Request:**
```http
PUT /api/assignments/65a1b2c3d4e5f6g7h8i9j0k4/submissions/65a1b2c3d4e5f6g7h8i9j0k5/grade
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "grade": 85,
  "feedback": "Bài làm tốt, cần cải thiện phần kết luận"
}
```

**Response:**
```json
{
  "_id": "65a1b2c3d4e5f6g7h8i9j0k5",
  "grade": 85,
  "feedback": "Bài làm tốt, cần cải thiện phần kết luận",
  "status": "graded",
  "gradedBy": "65a1b2c3d4e5f6g7h8i9j0k3",
  "gradedAt": "2024-01-11T14:20:00.000Z"
}
```

---

## PHỤ LỤC D: ENVIRONMENT SETUP

### D.1. Backend .env Template

```bash
# Server Configuration
NODE_ENV=production
PORT=5000

# Database
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/elearning_db

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long
JWT_EXPIRE=7d

# Email Service (Brevo)
BREVO_API_KEY=xkeysib-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
BREVO_SENDER_EMAIL=noreply@yourdomain.com
BREVO_SENDER_NAME=E-Learning System

# Judge0 (Code Execution)
JUDGE0_API_URL=https://judge0-ce.p.rapidapi.com
JUDGE0_API_KEY=your-rapidapi-key-here
JUDGE0_API_HOST=judge0-ce.p.rapidapi.com

# Agora (Video Calling)
AGORA_APP_ID=your-agora-app-id
AGORA_APP_CERTIFICATE=your-agora-certificate

# Frontend URL (for CORS)
FRONTEND_URL=https://yourusername.github.io

# Optional: Error Tracking
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
```

### D.2. Flutter Environment Configuration

**File:** `lib/config/api_config.dart`

```dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URLs
  static const String productionBaseUrl = 'https://your-app.onrender.com';
  static const String developmentBaseUrl = 'http://localhost:5000';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000';
  
  static String getBaseUrl() {
    if (kReleaseMode) {
      return productionBaseUrl;
    } else {
      // Check if running on Android emulator
      if (defaultTargetPlatform == TargetPlatform.android) {
        return androidEmulatorBaseUrl;
      }
      return developmentBaseUrl;
    }
  }
  
  // API Endpoints
  static const String auth = '/api/auth';
  static const String courses = '/api/courses';
  static const String assignments = '/api/assignments';
  static const String quizzes = '/api/quizzes';
  static const String videos = '/api/videos';
  static const String attendance = '/api/attendance';
  static const String notifications = '/api/notifications';
  static const String chat = '/api/messages';
  static const String files = '/api/files';
}
```

---

## PHỤ LỤC E: DEPLOYMENT COMMANDS

### E.1. Backend Deployment

```bash
# Clone repository
git clone https://github.com/yourusername/elearning_for_it.git
cd elearning_for_it/elearningit/backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
nano .env  # Edit with your values

# Create database indexes
node scripts/create-indexes.js

# Seed sample data (optional)
npm run seed

# Start development server
npm run dev

# Start production server
npm start
```

### E.2. Flutter Web Deployment

```bash
# Navigate to Flutter project
cd elearningit

# Get dependencies
flutter pub get

# Build for web
flutter build web --release --base-href "/elearning_for_it/"

# Copy to docs/ for GitHub Pages
cp -r build/web/* ../docs/

# Commit and push
git add docs/
git commit -m "Deploy Flutter web"
git push origin main
```

### E.3. Flutter Mobile Deployment

```bash
# Build Android APK
flutter build apk --release

# Output at: build/app/outputs/flutter-apk/app-release.apk

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Output at: build/app/outputs/bundle/release/app-release.aab

# Build iOS (requires macOS)
flutter build ios --release
```

---

## PHỤ LỤC F: TESTING SCRIPTS

### F.1. API Test with curl

```bash
# Test health endpoint
curl https://your-app.onrender.com/api/health

# Register user
curl -X POST https://your-app.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "role": "student",
    "firstName": "Test",
    "lastName": "User"
  }'

# Login
curl -X POST https://your-app.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# Get courses (with token)
curl https://your-app.onrender.com/api/courses \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### F.2. Load Testing with Artillery

**File:** `load-test.yml`

```yaml
config:
  target: 'https://your-app.onrender.com'
  phases:
    - duration: 60
      arrivalRate: 10
    - duration: 120
      arrivalRate: 20
  processor: "./processor.js"

scenarios:
  - name: "Login and browse courses"
    flow:
      - post:
          url: "/api/auth/login"
          json:
            username: "testuser"
            password: "password123"
          capture:
            - json: "$.token"
              as: "token"
      - get:
          url: "/api/courses"
          headers:
            Authorization: "Bearer {{ token }}"
      - think: 3
      - get:
          url: "/api/assignments?courseId={{ courseId }}"
          headers:
            Authorization: "Bearer {{ token }}"
```

**Run:**
```bash
npm install -g artillery
artillery run load-test.yml --output report.json
artillery report report.json
```

---

## PHỤ LỤC G: SCREENSHOTS

### G.1. Authentication Screens
- **Hình G.1:** Login Screen (Mobile)
- **Hình G.2:** Registration Form
- **Hình G.3:** Forgot Password

### G.2. Student Screens
- **Hình G.4:** Student Dashboard
- **Hình G.5:** Course List
- **Hình G.6:** Course Detail - Stream Tab
- **Hình G.7:** Course Detail - Classwork Tab
- **Hình G.8:** Assignment Submission
- **Hình G.9:** Quiz Taking Screen
- **Hình G.10:** Quiz Results
- **Hình G.11:** Code Editor
- **Hình G.12:** Code Submission Results
- **Hình G.13:** Video Player
- **Hình G.14:** QR Code Scanner
- **Hình G.15:** Notifications

### G.3. Instructor Screens
- **Hình G.16:** Instructor Dashboard
- **Hình G.17:** Create Course
- **Hình G.18:** Create Assignment
- **Hình G.19:** Create Quiz
- **Hình G.20:** Question Bank
- **Hình G.21:** Grade Submissions
- **Hình G.22:** Attendance Session
- **Hình G.23:** Video Call Room

### G.4. Admin Screens
- **Hình G.24:** Admin Dashboard
- **Hình G.25:** User Management
- **Hình G.26:** Course Management
- **Hình G.27:** Reports Screen

---

## PHỤ LỤC H: DOCKER CONFIGURATION

### H.1. Backend Dockerfile

```dockerfile
# backend/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```

### H.2. Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build: ./elearningit/backend
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - MONGODB_URI=${MONGODB_URI}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - mongo

  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

**Run:**
```bash
docker-compose up -d
```

---

## PHỤ LỤC I: ERROR CODES

### I.1. Backend Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Duplicate resource (e.g., username) |
| 413 | Payload Too Large | File exceeds size limit |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |

### I.2. Custom Error Codes

| Code | Message | Action |
|------|---------|--------|
| AUTH_001 | Invalid credentials | Check username/password |
| AUTH_002 | Token expired | Refresh token or re-login |
| COURSE_001 | Not enrolled | Enroll in course first |
| ASSIGNMENT_001 | Deadline passed | Cannot submit |
| QUIZ_001 | Quiz not started | Wait for start time |
| QUIZ_002 | Quiz ended | Cannot take anymore |
| CODE_001 | Compilation error | Fix code syntax |
| VIDEO_001 | File too large | Max 500MB |

---

**PHỤ LỤC KẾT THÚC**

*Note: Các screenshots (Hình G.1 - G.27) được lưu trong thư mục `thesis/screenshots/` với format PNG/JPG độ phân giải cao.*

---
