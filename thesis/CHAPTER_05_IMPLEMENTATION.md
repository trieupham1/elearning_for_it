# CHƯƠNG 5: THỰC THI HỆ THỐNG (SYSTEM IMPLEMENTATION)

## 5.1. PHẦN GIAO DIỆN (USER INTERFACE SECTION)

### 5.1.1. Giao diện đăng nhập (Login Interface)

**Hình 5.1: Màn hình đăng nhập**

**Mô tả:**
- Logo hệ thống ở trên cùng
- Text fields cho username và password
- Password có icon toggle để show/hide
- Button "Login" với loading indicator
- Link "Forgot Password?" ở dưới
- Responsive design cho mobile và web

**Features:**
- Input validation (không cho submit khi rỗng)
- Error messages hiển thị rõ ràng
- Remember me option
- Loading state khi đang login
- Auto-focus vào username field

**Code reference:** `lib/screens/login_screen.dart`

### 5.1.2. Giao diện sinh viên (Student Interface)

#### A. Dashboard sinh viên

**Hình 5.2: Dashboard sinh viên**

**Components:**
1. **AppBar:**
   - Title: "Dashboard"
   - Profile avatar (clickable → Profile screen)
   - Notification icon với badge count

2. **Stats Cards:**
   - Total courses enrolled
   - Pending assignments
   - Upcoming quizzes
   - Attendance rate

3. **Course List:**
   - Card view với course color
   - Course code và name
   - Instructor name
   - Progress indicator
   - Click → Course Detail

4. **Deadline Section:**
   - List of upcoming deadlines (sorted by date)
   - Assignment/Quiz title
   - Course name
   - Due date countdown

**Code reference:** `lib/screens/student_dashboard.dart`

#### B. Chi tiết khóa học - Tab Structure

**Hình 5.4-5.7: Course Detail với 4 tabs**

**1. Stream Tab (Hình 5.4):**
- Announcements feed (newest first)
- Post card với author avatar, name, timestamp
- Content với rich text
- Attachments (files to download)
- Comments section
- Add comment input

**Code:** `lib/screens/course_tabs/stream_tab.dart`

**2. Classwork Tab (Hình 5.5):**
- Grouped by type: Assignments, Quizzes, Materials
- Each item shows:
  - Title, due date (for assignments/quizzes)
  - Status badge (Pending/Submitted/Graded)
  - Score (if graded)
- Filter dropdown (All, Pending, Completed)
- Search bar

**Code:** `lib/screens/course_tabs/classwork_tab.dart`

**3. Forum Tab (Hình 5.6):**
- Topic list với:
  - Title, author, timestamp
  - Reply count, view count
  - Pinned topics on top
- FAB button để create new topic
- Topic detail với replies (threaded)

**Code:** `lib/screens/forum/forum_list_screen.dart`

**4. People Tab (Hình 5.7):**
- Teachers section (avatar, name, email)
- Groups section (expandable)
- Ungrouped students section
- Message button để chat

**Code:** `lib/screens/course_tabs/people_tab.dart`

#### C. Quiz Interface

**Hình 5.8: Làm bài quiz trắc nghiệm**

**Layout:**
- Timer ở trên (countdown)
- Question number indicator (1/10)
- Progress bar
- Question text với formatting
- Radio buttons cho choices
- Navigation buttons (Previous, Next, Submit)

**Features:**
- Auto-save answers mỗi 10s
- Confirm dialog khi submit
- Disable back button khi quiz started
- Time expiry tự động submit

**Hình 5.9: Kết quả bài quiz**

**Display:**
- Total score (số điểm/tổng điểm)
- Percentage
- Correct answers count
- Time spent
- Review button (nếu allowed)
- Chart showing performance

**Code:** `lib/screens/student/quiz_taking_screen.dart`, `quiz_result_screen.dart`

#### D. Code Assignment Interface

**Hình 5.10: Code Editor**

**Components:**
- Language selector dropdown (Python, Java, C++, JS, C)
- Code editor với syntax highlighting
- Line numbers
- Tab size và theme options
- Test button (dry run)
- Submit button

**Features:**
- Auto-save code to local storage
- Restore code on reopen
- Sample test cases để test locally
- Copy/paste support
- Indentation assist

**Hình 5.11: Code Submission Results**

**Display:**
- Overall score (70/100)
- Execution time và memory used
- Test cases table:
  - Test # | Status | Input | Expected | Actual | Score
  - Green checkmark for passed
  - Red X for failed
- Hidden test cases (chỉ show status, không show input/output)
- Leaderboard link

**Code:** `lib/screens/student/code_editor_screen.dart`, `code_submission_results_screen.dart`

#### E. Video Player

**Hình 5.12: Video Player với Progress Tracking**

**Features:**
- Chewie video player controls
- Play/pause, seek, volume
- Fullscreen mode
- Playback speed control (0.5x, 1x, 1.5x, 2x)
- Progress bar với resume point
- Auto-save progress mỗi 10s
- Completion percentage

**Code:** `lib/screens/student/video_player_screen.dart`

#### F. QR Code Check-in

**Hình 5.13: QR Code Scan Screen**

**Features:**
- Camera preview
- QR scanner overlay
- Flash toggle
- Switch camera (front/back)
- Instructions text
- GPS location capture
- Success/error messages

**Code:** `lib/screens/student/check_in_screen.dart`

### 5.1.3. Giao diện giảng viên (Instructor Interface)

#### A. Dashboard giảng viên

**Hình 5.14: Instructor Dashboard**

**Sections:**
1. **Stats Overview:**
   - Total courses teaching
   - Total students
   - Pending submissions to grade
   - Recent activities

2. **Course List:**
   - My Courses
   - Quick actions: Edit, View, Add content

3. **Recent Submissions:**
   - Latest submissions needing grading
   - Student name, assignment, timestamp
   - Grade button

**Code:** `lib/screens/instructor_dashboard.dart`

#### B. Tạo bài tập

**Hình 5.15: Create Assignment**

**Form Fields:**
- Title (required)
- Description (rich text editor)
- Assignment type (File upload / Code)
- Start date & Deadline (date pickers)
- Allow late submission (checkbox)
- Max attempts (number)
- Points (number)
- Allowed file types (multi-select)
- Attach files (optional)
- Assign to groups (multi-select)

**For Code Assignment:**
- Starter code (text area)
- Language selection
- Add test cases:
  - Input, Expected output, Weight, Visibility (public/hidden)

**Code:** `lib/screens/instructor/create_assignment_screen.dart`, `create_code_assignment_screen.dart`

#### C. Quản lý câu hỏi Quiz

**Hình 5.16: Question Bank**

**Features:**
- Filter by difficulty (Easy/Medium/Hard)
- Filter by category/tags
- Search questions
- Add new question button
- Edit/Delete actions
- Bulk select để add to quiz

**Question Form:**
- Question text (required)
- Choices (minimum 2, add more button)
- Mark correct answer (radio button)
- Difficulty level (dropdown)
- Explanation (optional)
- Tags (multi-input)

**Code:** `lib/screens/instructor/manage_questions_screen.dart`, `create_question_screen.dart`

#### D. Attendance Management

**Hình 5.17: Attendance Session**

**Create Session:**
- Select date
- Select session number (1-15)
- Generate QR Code button
- Set GPS location (optional)

**Active Session View:**
- Large QR Code display
- Refresh button (regenerate QR)
- Real-time check-in list:
  - Student name, time, status (Present/Late)
  - Color-coded (green/orange)
- Statistics (checked-in / total students)
- Manual check-in button
- Close session button

**Attendance Records:**
- Grid view of all sessions
- Each cell shows status icon
- Export to CSV button

**Code:** `lib/screens/instructor/attendance_screen.dart`, `create_attendance_session_screen.dart`, `attendance_records_screen.dart`

#### E. Video Call Interface

**Hình 5.18: Video Call Room**

**Layout:**
- Remote participants in grid (2x2 or 3x3)
- Local preview in top-right corner (small)
- Control bar at bottom:
  - Mute/Unmute mic (red when muted)
  - Stop/Start video (red when off)
  - Switch camera (mobile only)
  - End call (always red)
- Participant count indicator
- Connection quality indicator

**Code:** `lib/screens/video_call/course_video_call_screen.dart`

### 5.1.4. Giao diện quản trị (Admin Interface)

#### A. Admin Dashboard

**Hình 5.19: Admin Dashboard**

**Metrics Cards:**
- Total users (students, instructors, admins)
- Active courses this semester
- Total departments
- System activity today

**Charts:**
- User growth line chart (last 6 months)
- Course completion rate pie chart
- Department enrollment bar chart

**Recent Activity Logs:**
- User, Action, Description, Timestamp
- Filter by date range
- Export button

**Code:** `lib/screens/admin/admin_dashboard_screen.dart`

#### B. User Management

**Hình 5.20: Manage Users**

**Features:**
- Search bar (by name, email, username)
- Filter by role (Student/Instructor/Admin)
- Filter by department
- User list/table:
  - Avatar, Name, Email, Role, Status
  - Actions: Edit, Delete, Reset Password, Activate/Deactivate
- Add User button
- Bulk Import from CSV button

**User Form:**
- Username (unique)
- Email (unique)
- Password (auto-generate option)
- Role (dropdown)
- First name, Last name
- Student ID (if student)
- Department (dropdown)
- Profile picture upload

**Code:** `lib/screens/admin/user_management_screen.dart`, `bulk_import_screen.dart`

#### C. Course Management (Admin)

**Hình 5.21: Manage Courses**

**Features:**
- All courses list (không giới hạn by instructor)
- Assign instructor button
- Assign students (bulk) button
- Edit course button
- Delete course button (confirm dialog)
- Filter by semester, department

**Assign Instructor Dialog:**
- Search instructors
- Select from dropdown
- Send invitation
- Instructor receives notification to accept/reject

**Code:** `lib/screens/admin/manage_courses_screen.dart`

#### D. Reports

**Hình 5.22: Reports Screen**

**Report Types:**
1. **Training Progress by Department:**
   - Table: Department, Students, Courses, Completion %
   - Export to CSV

2. **Instructor Workload:**
   - Instructor name, Courses teaching, Students, Assignments
   - Sort by workload
   - Export to CSV

3. **Student Performance:**
   - Student name, Courses, Avg score, Completion rate
   - Export to PDF

4. **Activity Logs:**
   - Date range filter
   - User filter
   - Action type filter
   - Export to CSV

**Code:** `lib/screens/admin/reports_screen.dart`

### 5.1.5. Chat và Notifications

#### A. Chat Interface

**Hình 5.23: Chat Screen**

**Layout:**
- Conversation list (left sidebar on tablet/desktop)
- Chat messages (right side)
- Message input at bottom
- File attachment button
- Send button

**Features:**
- Real-time updates (Socket.IO)
- Message timestamps
- Read/unread status
- File attachments (download link)
- Scroll to bottom button

**Code:** `lib/screens/chat_screen.dart`

#### B. Notifications

**Hình 5.24: Notifications Screen**

**Features:**
- Notification list (newest first)
- Group by: Today, Yesterday, Older
- Notification types với icons:
  - Assignment (📝)
  - Quiz (📊)
  - Announcement (📢)
  - Message (💬)
  - Grade (⭐)
- Mark as read/unread
- Delete button
- Action buttons (View Assignment, Take Quiz, etc.)

**Code:** `lib/screens/notifications_screen.dart`

---

## 5.2. PHẦN HỆ THỐNG (SYSTEM SECTION)

### 5.2.1. API Documentation

**Bảng 5.1: API Endpoints - Authentication**

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/api/auth/register` | Register new user | `{username, email, password, role, firstName, lastName}` | `{token, user}` |
| POST | `/api/auth/login` | Login | `{username, password}` | `{token, user}` |
| GET | `/api/auth/me` | Get current user | - | `{user}` |
| POST | `/api/auth/forgot-password` | Send reset email | `{email}` | `{message}` |
| POST | `/api/auth/reset-password/:token` | Reset password | `{password}` | `{message}` |
| PUT | `/api/auth/change-password` | Change password | `{currentPassword, newPassword}` | `{message}` |

**Bảng 5.2: API Endpoints - Course Management**

| Method | Endpoint | Description | Auth | Request Body |
|--------|----------|-------------|------|--------------|
| GET | `/api/courses` | List user's courses | Required | - |
| GET | `/api/courses/:id` | Get course detail | Required | - |
| POST | `/api/courses` | Create course | Instructor | `{code, name, description, semesterId}` |
| PUT | `/api/courses/:id` | Update course | Instructor | `{name, description, ...}` |
| DELETE | `/api/courses/:id` | Delete course | Instructor | - |
| POST | `/api/courses/:id/invite` | Invite students | Instructor | `{studentIds[], groupId}` |
| POST | `/api/courses/:id/join` | Join course | Student | `{code}` |
| GET | `/api/courses/:id/people` | Get people in course | Required | - |

**Bảng 5.3: API Endpoints - Assignment System**

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| GET | `/api/assignments?courseId=x` | List assignments | - |
| GET | `/api/assignments/:id` | Get assignment detail | - |
| POST | `/api/assignments` | Create assignment | `{courseId, title, description, deadline, type, ...}` |
| POST | `/api/assignments/:id/submit` | Submit assignment | `FormData(file)` |
| GET | `/api/assignments/:id/submissions` | Get all submissions (Instructor) | - |
| PUT | `/api/assignments/:id/submissions/:sid/grade` | Grade submission | `{grade, feedback}` |

**Bảng 5.4: API Endpoints - Quiz System**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/quizzes` | Create quiz |
| POST | `/api/questions` | Add question to bank |
| GET | `/api/questions?courseId=x&difficulty=easy` | Get questions |
| POST | `/api/quizzes/:id/start` | Start quiz attempt |
| POST | `/api/quiz-attempts/:id/submit` | Submit quiz |
| GET | `/api/quiz-attempts/:id/result` | Get quiz result |

**Bảng 5.5: API Endpoints - Code Assignments**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/code` | Create code assignment |
| POST | `/api/code/:id/test-cases` | Add test case |
| POST | `/api/code/:id/submit` | Submit code |
| GET | `/api/code/:id/submissions` | Get submissions |
| GET | `/api/code/:id/leaderboard` | Get leaderboard |

**Bảng 5.6: API Endpoints - Video Management**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/videos/upload` | Upload video (multipart) |
| GET | `/api/videos/:id/stream` | Stream video |
| POST | `/api/videos/:id/progress` | Track progress |
| GET | `/api/videos/:id/progress` | Get progress |

**Bảng 5.7: API Endpoints - Attendance System**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/attendance/sessions` | Create session |
| POST | `/api/attendance/check-in` | QR check-in |
| GET | `/api/attendance/sessions/:id` | Get session detail |
| PUT | `/api/attendance/sessions/:id/close` | Close session |
| GET | `/api/attendance/records?courseId=x` | Get records |

### 5.2.2. Backend Implementation Examples

#### A. Authentication Middleware

```javascript
// backend/middleware/auth.js
const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        message: 'No authentication token, access denied' 
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.userRole = decoded.role;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

const instructorOnly = (req, res, next) => {
  if (req.userRole !== 'instructor') {
    return res.status(403).json({ 
      message: 'Access denied. Instructors only.' 
    });
  }
  next();
};

module.exports = { auth, instructorOnly };
```

#### B. Assignment Submission Route

```javascript
// backend/routes/assignments.js
router.post('/:id/submit', auth, upload.array('files', 5), async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ message: 'Assignment not found' });
    }

    // Check deadline
    const now = new Date();
    const isLate = now > assignment.deadline;
    if (isLate && !assignment.allowLateSubmission) {
      return res.status(400).json({ message: 'Deadline has passed' });
    }

    // Upload files to GridFS
    const files = [];
    for (const file of req.files) {
      const uploadStream = gfsBucket.openUploadStream(file.originalname, {
        metadata: {
          courseId: assignment.courseId,
          assignmentId: assignment._id,
          uploadedBy: req.userId
        }
      });
      
      const fileId = uploadStream.id;
      uploadStream.end(file.buffer);
      
      files.push({
        fileName: file.originalname,
        fileUrl: `/api/files/${fileId}`,
        fileSize: file.size,
        mimeType: file.mimetype
      });
    }

    // Create submission
    const submission = await Submission.create({
      assignmentId: assignment._id,
      studentId: req.userId,
      files,
      isLate,
      status: 'submitted'
    });

    // Notify instructor
    await notifyNewSubmission(assignment.createdBy, assignment, req.userId);

    res.status(201).json(submission);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
```

#### C. Quiz Auto-grading

```javascript
// backend/routes/quiz-attempts.js
router.post('/:id/submit', auth, async (req, res) => {
  try {
    const attempt = await QuizAttempt.findById(req.params.id);
    if (!attempt) {
      return res.status(404).json({ message: 'Attempt not found' });
    }

    if (attempt.status !== 'in_progress') {
      return res.status(400).json({ message: 'Quiz already submitted' });
    }

    const { answers } = req.body; // {questionId: selectedChoices[]}

    let correctAnswers = 0;
    const quiz = await Quiz.findById(attempt.quizId);

    // Grade each question
    for (let i = 0; i < attempt.questions.length; i++) {
      const question = attempt.questions[i];
      const studentAnswer = answers[question.questionId] || [];
      
      // Get correct choices
      const correctChoices = question.choices
        .filter(c => c.isCorrect)
        .map(c => c.text)
        .sort();
      
      const studentChoicesSorted = studentAnswer.sort();
      
      // Compare arrays
      const isCorrect = JSON.stringify(correctChoices) === 
                       JSON.stringify(studentChoicesSorted);
      
      attempt.questions[i].selectedAnswer = studentAnswer;
      attempt.questions[i].isCorrect = isCorrect;
      
      if (isCorrect) correctAnswers++;
    }

    // Calculate score
    const totalQuestions = attempt.questions.length;
    const score = (correctAnswers / totalQuestions) * 100;
    const pointsEarned = (score / 100) * quiz.totalPoints;

    // Update attempt
    attempt.correctAnswers = correctAnswers;
    attempt.score = score;
    attempt.pointsEarned = pointsEarned;
    attempt.status = 'completed';
    attempt.submissionTime = new Date();
    await attempt.save();

    res.json(attempt);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
```

#### D. Code Execution với Judge0

```javascript
// backend/utils/judge0Helper.js
const axios = require('axios');

async function executeCode(code, languageId, testCase) {
  const submission = {
    source_code: Buffer.from(code).toString('base64'),
    language_id: languageId,
    stdin: Buffer.from(testCase.input).toString('base64'),
    expected_output: Buffer.from(testCase.expectedOutput).toString('base64'),
    cpu_time_limit: 2,
    memory_limit: 128000
  };

  const response = await axios.post(
    `${process.env.JUDGE0_API_URL}/submissions?base64_encoded=true&wait=true`,
    submission,
    {
      headers: {
        'X-RapidAPI-Key': process.env.JUDGE0_API_KEY,
        'X-RapidAPI-Host': process.env.JUDGE0_API_HOST
      }
    }
  );

  const result = response.data;
  
  return {
    status: result.status.description,
    stdout: result.stdout ? Buffer.from(result.stdout, 'base64').toString() : '',
    stderr: result.stderr ? Buffer.from(result.stderr, 'base64').toString() : '',
    executionTime: result.time,
    memory: result.memory,
    passed: result.status.id === 3 // Accepted
  };
}

module.exports = { executeCode };
```

### 5.2.3. Database Implementation

#### A. Mongoose Schema Example - Course

```javascript
// backend/models/Course.js
const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    uppercase: true
  },
  name: {
    type: String,
    required: true
  },
  description: String,
  instructor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  semester: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Semester'
  },
  students: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  sessions: {
    type: Number,
    default: 15
  },
  color: {
    type: String,
    default: '#1976D2'
  },
  image: String
}, {
  timestamps: true,
  toJSON: { virtuals: true }
});

// Indexes
courseSchema.index({ code: 1 });
courseSchema.index({ instructor: 1, semester: 1 });

// Virtual field
courseSchema.virtual('studentCount').get(function() {
  return this.students.length;
});

// Methods
courseSchema.methods.isStudentEnrolled = function(userId) {
  return this.students.some(id => id.toString() === userId.toString());
};

module.exports = mongoose.model('Course', courseSchema);
```

#### B. Aggregation Query Example

```javascript
// Get top students by course
const topStudents = await QuizAttempt.aggregate([
  { $match: { quizId: quiz._id } },
  {
    $group: {
      _id: '$studentId',
      bestScore: { $max: '$score' },
      attempts: { $sum: 1 }
    }
  },
  { $sort: { bestScore: -1 } },
  { $limit: 10 },
  {
    $lookup: {
      from: 'users',
      localField: '_id',
      foreignField: '_id',
      as: 'student'
    }
  },
  { $unwind: '$student' },
  {
    $project: {
      studentName: { $concat: ['$student.firstName', ' ', '$student.lastName'] },
      bestScore: 1,
      attempts: 1
    }
  }
]);
```

### 5.2.4. Frontend Service Example

```dart
// lib/services/assignment_service.dart
class AssignmentService {
  final String baseUrl = ApiConfig.getBaseUrl();
  final ApiService _apiService = ApiService();

  Future<List<Assignment>> getAssignments(String courseId) async {
    final response = await _apiService.get(
      '$baseUrl${ApiConfig.assignments}',
      queryParameters: {'courseId': courseId},
    );

    return (response['assignments'] as List)
        .map((json) => Assignment.fromJson(json))
        .toList();
  }

  Future<Assignment> submitAssignment(
    String assignmentId,
    List<File> files,
  ) async {
    final formData = FormData();
    
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      ));
    }

    final response = await _apiService.post(
      '$baseUrl${ApiConfig.assignments}/$assignmentId/submit',
      data: formData,
    );

    return Assignment.fromJson(response);
  }
}
```

---

**KẾT LUẬN CHƯƠNG 5:**

Chương này đã trình bày chi tiết implementation của hệ thống E-Learning:

**Phần giao diện:**
- 24 màn hình chính với screenshots
- Design patterns: Material Design 3
- Responsive cho mobile, tablet, web
- Dark mode support
- Smooth animations

**Phần hệ thống:**
- 35+ RESTful API endpoints
- JWT authentication + RBAC authorization
- Real-time với Socket.IO
- Code execution với Judge0
- Video streaming với GridFS
- File storage và retrieval

**Code quality:**
- Clean code, modular architecture
- Error handling đầy đủ
- Input validation
- Security best practices
- Performance optimization

Hệ thống đã được implement đầy đủ các tính năng theo thiết kế ở Chương 4. Chương tiếp theo sẽ trình bày quá trình deployment lên production environment.

---
