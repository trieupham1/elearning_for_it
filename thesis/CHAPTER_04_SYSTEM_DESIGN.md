# CHƯƠNG 4: THIẾT KẾ HỆ THỐNG (SYSTEM DESIGN)

## 4.1. CẤU TRÚC CỦA HỆ THỐNG (SYSTEM STRUCTURE)

### 4.1.1. Tổng quan kiến trúc

Hệ thống E-Learning được thiết kế theo mô hình **3-tier architecture**:

1. **Presentation Tier (Client)**: Flutter apps (Android, iOS, Web)
2. **Application Tier (Server)**: Node.js/Express.js backend
3. **Data Tier**: MongoDB database + Third-party services

### 4.1.2. Các thành phần chính

**Frontend Components:**
- Authentication screens
- Dashboard screens (Student, Instructor, Admin)
- Course management screens
- Assignment & quiz interfaces
- Video player & code editor
- Chat & video call screens
- Profile & settings screens

**Backend Components:**
- RESTful API endpoints (35+ routes)
- Authentication middleware (JWT)
- Authorization middleware (RBAC)
- Real-time server (Socket.IO)
- File upload handler (Multer + GridFS)
- Email service
- Notification system

**Database Collections:**
- Users, Courses, Semesters
- Assignments, Submissions, CodeSubmissions
- Quizzes, Questions, QuizAttempts
- Materials, Videos, Announcements
- Messages, Notifications, ForumTopics
- Attendance, Groups, Departments

---

## 4.2. SƠ ĐỒ CẤU TRÚC (SYSTEM ARCHITECTURE DIAGRAM)

**Hình 4.1: Kiến trúc tổng thể hệ thống**

### AI Prompt để vẽ diagram:
```
Create a system architecture diagram for an E-Learning Management System with:

LAYER 1 - CLIENT TIER:
- 3 Flutter apps (Android, iOS, Web) in rounded rectangles
- Connected via HTTPS/WebSocket arrows

LAYER 2 - APPLICATION TIER (in a large box):
- Node.js + Express.js server
- Authentication Service, Course Service, Assignment Service, Quiz Service
- Middleware layer: JWT Auth, RBAC, Validation, Error Handling
- Socket.IO Server for real-time

LAYER 3 - DATA & SERVICES TIER:
- MongoDB database with GridFS
- Judge0 API (code execution)
- Agora RTC (video calling)
- Email Service (Brevo)

Show bidirectional arrows between layers with protocol labels (REST API, WebSocket).
Use blue for client tier, green for application tier, orange for data tier.
```

---

## 4.3. MÔ TẢ NGHIỆP VỤ (BUSINESS DESCRIPTION)

### 4.3.1. Vai trò Student (Sinh viên)

**Quyền hạn:**
- Xem khóa học đã đăng ký
- Nộp bài tập, làm quiz
- Xem video bài giảng
- Tham gia forum thảo luận
- Chat với giảng viên
- Điểm danh QR code
- Xem điểm và tiến độ học tập

**Quy trình điển hình:**
1. Đăng nhập vào hệ thống
2. Xem dashboard với thông báo, deadline
3. Chọn khóa học → xem nội dung
4. Làm bài tập/quiz → nộp bài
5. Xem kết quả và feedback
6. Tương tác với giảng viên qua chat/forum

### 4.3.2. Vai trò Instructor (Giảng viên)

**Quyền hạn:**
- Tạo và quản lý khóa học
- Tạo bài tập, quiz, tài liệu
- Chấm bài và cho điểm
- Tạo session điểm danh
- Upload video bài giảng
- Quản lý sinh viên trong khóa học
- Xem báo cáo và thống kê

**Quy trình điển hình:**
1. Đăng nhập vào hệ thống
2. Chọn khóa học cần quản lý
3. Tạo bài tập/quiz/tài liệu mới
4. Theo dõi submissions của sinh viên
5. Chấm bài và cho feedback
6. Xem thống kê lớp học

### 4.3.3. Vai trò Admin (Quản trị viên)

**Quyền hạn:**
- Quản lý tất cả users (create, update, delete)
- Quản lý departments và semesters
- Phân công giảng viên cho khóa học
- Xem activity logs
- Xem dashboard tổng quan hệ thống
- Export báo cáo
- Bulk import users từ CSV

**Quy trình điển hình:**
1. Đăng nhập vào hệ thống
2. Xem dashboard với metrics tổng quan
3. Quản lý users, courses, departments
4. Xem activity logs và reports
5. Export dữ liệu khi cần

---

## 4.4. SƠ ĐỒ USE CASE (USE CASE DIAGRAMS)

### 4.4.1. Xác định Use Case (Use Case Identification)

**Bảng 4.1: Danh sách Use Case - Student**

| ID | Use Case | Actor | Mô tả ngắn |
|----|----------|-------|------------|
| UC-S01 | Đăng nhập | Student | Đăng nhập vào hệ thống |
| UC-S02 | Xem khóa học | Student | Xem danh sách khóa học đã đăng ký |
| UC-S03 | Nộp bài tập | Student | Upload file bài tập |
| UC-S04 | Làm quiz | Student | Trả lời câu hỏi trắc nghiệm |
| UC-S05 | Nộp code assignment | Student | Viết và submit code |
| UC-S06 | Xem video | Student | Xem video bài giảng |
| UC-S07 | Điểm danh QR | Student | Scan QR code để check-in |
| UC-S08 | Chat với giảng viên | Student | Gửi tin nhắn |
| UC-S09 | Tham gia forum | Student | Thảo luận trên forum |
| UC-S10 | Xem thông báo | Student | Xem notifications |

**Bảng 4.2: Danh sách Use Case - Instructor**

| ID | Use Case | Actor | Mô tả ngắn |
|----|----------|-------|------------|
| UC-I01 | Tạo khóa học | Instructor | Tạo khóa học mới |
| UC-I02 | Tạo bài tập | Instructor | Tạo assignment hoặc code assignment |
| UC-I03 | Tạo quiz | Instructor | Tạo quiz với câu hỏi |
| UC-I04 | Chấm bài | Instructor | Chấm và cho điểm bài tập |
| UC-I05 | Upload video | Instructor | Upload video bài giảng |
| UC-I06 | Tạo session điểm danh | Instructor | Tạo QR code điểm danh |
| UC-I07 | Quản lý sinh viên | Instructor | Mời/xóa sinh viên khỏi khóa học |
| UC-I08 | Xem báo cáo | Instructor | Xem thống kê lớp học |

**Bảng 4.3: Danh sách Use Case - Admin**

| ID | Use Case | Actor | Mô tả ngắn |
|----|----------|-------|------------|
| UC-A01 | Quản lý users | Admin | CRUD users |
| UC-A02 | Bulk import users | Admin | Import users từ CSV |
| UC-A03 | Quản lý departments | Admin | CRUD departments |
| UC-A04 | Quản lý semesters | Admin | CRUD semesters |
| UC-A05 | Phân công giảng viên | Admin | Assign instructor to course |
| UC-A06 | Xem activity logs | Admin | Monitor system activities |
| UC-A07 | Xem dashboard | Admin | Xem metrics tổng quan |
| UC-A08 | Export báo cáo | Admin | Export data to CSV/PDF |

### 4.4.2. Use Case Diagram - Student

**Hình 4.3: Sơ đồ Use Case - Sinh viên**

### AI Prompt:
```
Create a UML Use Case diagram for Student role in E-Learning system:

ACTOR: Student (stick figure on left)

USE CASES (ovals):
- Đăng nhập (Login)
- Xem khóa học (View Courses)
- Làm bài quiz (Take Quiz)
- Nộp bài tập file (Submit Assignment)
- Nộp code assignment (Submit Code)
- Xem video bài giảng (Watch Video)
- Điểm danh QR code (QR Check-in)
- Chat với giảng viên (Chat with Instructor)
- Tham gia forum (Join Forum)
- Xem thông báo (View Notifications)
- Xem điểm số (View Grades)

RELATIONSHIPS:
- All use cases connected to Student actor
- "Đăng nhập" has <<include>> relationship to most other use cases
- "Xem khóa học" has <<extend>> to "Làm bài quiz", "Nộp bài tập", "Xem video"

SYSTEM BOUNDARY: Rectangle labeled "E-Learning System"
```

### 4.4.3. Use Case Diagram - Instructor

**Hình 4.4: Sơ đồ Use Case - Giảng viên**

### AI Prompt:
```
Create a UML Use Case diagram for Instructor role:

ACTOR: Instructor (stick figure)

USE CASES:
- Đăng nhập
- Tạo khóa học (Create Course)
- Quản lý khóa học (Manage Course)
- Tạo bài tập (Create Assignment)
- Tạo code assignment (Create Code Assignment)
- Tạo quiz (Create Quiz)
- Quản lý câu hỏi (Manage Questions)
- Upload video (Upload Video)
- Chấm bài (Grade Submissions)
- Tạo điểm danh (Create Attendance)
- Xem báo cáo (View Reports)
- Chat với sinh viên (Chat with Students)

RELATIONSHIPS:
- "Quản lý khóa học" <<include>> "Tạo bài tập", "Tạo quiz", "Upload video"
- "Tạo quiz" <<include>> "Quản lý câu hỏi"
- "Chấm bài" has association with "Tạo bài tập"

SYSTEM BOUNDARY: "E-Learning System"
```

### 4.4.4. Use Case Diagram - Admin

**Hình 4.5: Sơ đồ Use Case - Quản trị viên**

### AI Prompt:
```
Create a UML Use Case diagram for Admin role:

ACTOR: Admin (stick figure)

USE CASES:
- Đăng nhập
- Quản lý users (Manage Users)
- Thêm user (Add User)
- Sửa user (Edit User)
- Xóa user (Delete User)
- Bulk import (Import CSV)
- Quản lý departments (Manage Departments)
- Quản lý semesters (Manage Semesters)
- Quản lý khóa học (Manage Courses)
- Phân công giảng viên (Assign Instructor)
- Xem activity logs (View Activity Logs)
- Xem dashboard (View Dashboard)
- Export báo cáo (Export Reports)

RELATIONSHIPS:
- "Quản lý users" <<include>> "Thêm", "Sửa", "Xóa", "Bulk import"
- "Quản lý khóa học" <<include>> "Phân công giảng viên"

SYSTEM BOUNDARY: "E-Learning System"
```

---

## 4.5. ĐẶC TẢ CÁC USE CASE (USE CASE SPECIFICATIONS)

### 4.5.1. UC-S01: Đăng nhập (Login)

**Bảng 4.4: Đặc tả Use Case - Đăng nhập**

| **Thuộc tính** | **Mô tả** |
|----------------|-----------|
| **Use Case ID** | UC-S01 |
| **Use Case Name** | Đăng nhập hệ thống |
| **Actor** | Student, Instructor, Admin |
| **Description** | Người dùng đăng nhập vào hệ thống bằng username và password |
| **Precondition** | - User đã có tài khoản<br>- App đã được cài đặt/mở |
| **Postcondition** | - User được xác thực<br>- JWT token được tạo và lưu<br>- Redirect đến dashboard tương ứng |
| **Normal Flow** | 1. User mở app<br>2. System hiển thị màn hình login<br>3. User nhập username và password<br>4. User click "Login"<br>5. System validate credentials<br>6. System tạo JWT token<br>7. System lưu token vào SharedPreferences<br>8. System load user settings (theme)<br>9. System redirect đến dashboard theo role |
| **Alternative Flow** | **3a. Username/password rỗng:**<br>&nbsp;&nbsp;3a1. System hiển thị error "Please fill all fields"<br>&nbsp;&nbsp;3a2. Return to step 3<br><br>**5a. Credentials không đúng:**<br>&nbsp;&nbsp;5a1. System return 401 Unauthorized<br>&nbsp;&nbsp;5a2. System hiển thị "Invalid credentials"<br>&nbsp;&nbsp;5a3. Return to step 3<br><br>**5b. Network error:**<br>&nbsp;&nbsp;5b1. System catch exception<br>&nbsp;&nbsp;5b2. System hiển thị "Network error. Please try again"<br>&nbsp;&nbsp;5b3. Return to step 3 |
| **Exception Flow** | **E1. Server down:**<br>&nbsp;&nbsp;E1.1. System không thể connect<br>&nbsp;&nbsp;E1.2. Hiển thị "Server unavailable"<br>&nbsp;&nbsp;E1.3. Retry sau 5 giây |
| **Special Requirements** | - Password phải được hash (bcrypt)<br>- JWT token expire sau 24 giờ<br>- Rate limiting: 5 attempts/minute |
| **Frequency** | Cao (mỗi user login ít nhất 1 lần/ngày) |

### 4.5.2. UC-S03: Nộp bài tập file (Submit Assignment)

**Bảng 4.5: Đặc tả Use Case - Nộp bài tập**

| **Thuộc tính** | **Mô tả** |
|----------------|-----------|
| **Use Case ID** | UC-S03 |
| **Use Case Name** | Nộp bài tập file |
| **Actor** | Student |
| **Description** | Sinh viên upload file để nộp bài tập |
| **Precondition** | - Student đã đăng nhập<br>- Assignment tồn tại và chưa quá deadline<br>- Student thuộc khóa học này |
| **Postcondition** | - File được upload lên GridFS<br>- Submission record được tạo trong DB<br>- Instructor nhận notification<br>- Student nhận confirmation |
| **Normal Flow** | 1. Student navigate đến assignment detail<br>2. System hiển thị thông tin assignment<br>3. Student click "Submit"<br>4. System mở file picker<br>5. Student chọn file<br>6. Student click "Upload"<br>7. System validate file (type, size)<br>8. System hiển thị upload progress<br>9. System upload file lên server<br>10. Server lưu file vào GridFS<br>11. Server tạo Submission record<br>12. Server gửi notification cho instructor<br>13. System hiển thị "Submitted successfully"<br>14. System refresh assignment detail |
| **Alternative Flow** | **5a. Student cancel:**<br>&nbsp;&nbsp;5a1. Return to assignment detail<br><br>**7a. File type không hợp lệ:**<br>&nbsp;&nbsp;7a1. Hiển thị "Invalid file type. Allowed: PDF, DOCX, ZIP"<br>&nbsp;&nbsp;7a2. Return to step 4<br><br>**7b. File quá lớn:**<br>&nbsp;&nbsp;7b1. Hiển thị "File too large. Max: 10MB"<br>&nbsp;&nbsp;7b2. Return to step 4<br><br>**9a. Upload bị ngắt:**<br>&nbsp;&nbsp;9a1. System retry upload<br>&nbsp;&nbsp;9a2. Nếu fail 3 lần, hiển thị error<br><br>**9b. Quá deadline:**<br>&nbsp;&nbsp;9b1. Server check deadline<br>&nbsp;&nbsp;9b2. Nếu late submission allowed: mark as "late"<br>&nbsp;&nbsp;9b3. Nếu không: return error "Deadline passed" |
| **Exception Flow** | **E1. Network timeout:**<br>&nbsp;&nbsp;E1.1. Hiển thị "Upload timeout. Please try again" |
| **Special Requirements** | - Max file size: 10MB<br>- Allowed types: PDF, DOCX, TXT, ZIP<br>- Upload progress indicator<br>- Multiple attempts allowed (if configured) |
| **Frequency** | Cao (nhiều submissions mỗi ngày) |

### 4.5.3. UC-S04: Làm bài quiz (Take Quiz)

**Bảng 4.6: Đặc tả Use Case - Làm quiz**

| **Thuộc tính** | **Mô tả** |
|----------------|-----------|
| **Use Case ID** | UC-S04 |
| **Use Case Name** | Làm bài quiz trắc nghiệm |
| **Actor** | Student |
| **Description** | Sinh viên làm bài quiz với câu hỏi trắc nghiệm |
| **Precondition** | - Student đã login<br>- Quiz đang active (trong khoảng open-close date)<br>- Student chưa hết lượt làm |
| **Postcondition** | - Quiz attempt được tạo với status "in_progress"<br>- Khi submit: status = "completed"<br>- Điểm được tính tự động<br>- Student xem được kết quả (nếu allowed) |
| **Normal Flow** | 1. Student xem quiz detail<br>2. System hiển thị info (duration, questions count, attempts left)<br>3. Student click "Start Quiz"<br>4. System tạo quiz attempt<br>5. System fetch questions (random nếu configured)<br>6. System start timer<br>7. System hiển thị câu hỏi đầu tiên<br>8. **Loop for each question:**<br>&nbsp;&nbsp;8.1. Student đọc câu hỏi<br>&nbsp;&nbsp;8.2. Student chọn đáp án<br>&nbsp;&nbsp;8.3. System lưu answer tạm (auto-save mỗi 10s)<br>&nbsp;&nbsp;8.4. Student click "Next"<br>&nbsp;&nbsp;8.5. System hiển thị câu tiếp theo<br>9. Sau câu hỏi cuối, Student click "Submit Quiz"<br>10. System confirm "Are you sure?"<br>11. Student confirm<br>12. System stop timer<br>13. System gửi tất cả answers lên server<br>14. Server tính điểm (so sánh với correct answers)<br>15. Server update attempt status = "completed"<br>16. Server tính score, correctAnswers<br>17. System hiển thị kết quả |
| **Alternative Flow** | **8a. Hết thời gian:**<br>&nbsp;&nbsp;8a1. Timer về 0<br>&nbsp;&nbsp;8a2. System tự động submit quiz<br>&nbsp;&nbsp;8a3. Jump to step 13<br><br>**8b. Mất kết nối:**<br>&nbsp;&nbsp;8b1. Auto-save failed<br>&nbsp;&nbsp;8b2. Khi reconnect, restore từ last save<br><br>**11a. Student cancel submit:**<br>&nbsp;&nbsp;11a1. Return to quiz<br>&nbsp;&nbsp;11a2. Continue from current question |
| **Exception Flow** | **E1. Browser/app closed:**<br>&nbsp;&nbsp;E1.1. Khi reopen, attempt vẫn in_progress<br>&nbsp;&nbsp;E1.2. Student có thể resume<br>&nbsp;&nbsp;E1.3. Timer continue từ remaining time<br><br>**E2. Server error khi submit:**<br>&nbsp;&nbsp;E2.1. Retry submit 3 lần<br>&nbsp;&nbsp;E2.2. Nếu vẫn fail, lưu local storage<br>&nbsp;&nbsp;E2.3. Sync khi có network |
| **Special Requirements** | - Timer chính xác (server-side validation)<br>- Auto-save answers mỗi 10 giây<br>- Không cho back về câu đã submit<br>- Shuffle questions nếu configured<br>- Shuffle choices nếu configured |
| **Frequency** | Trung bình (vài lần/tuần) |

### 4.5.4. UC-S05: Nộp code assignment (Submit Code)

**Bảng 4.7: Đặc tả Use Case - Nộp code**

| **Thuộc tính** | **Mô tả** |
|----------------|-----------|
| **Use Case ID** | UC-S05 |
| **Use Case Name** | Nộp code assignment |
| **Actor** | Student |
| **Description** | Sinh viên viết code và submit để được chấm tự động |
| **Precondition** | - Student đã login<br>- Code assignment tồn tại<br>- Chưa quá deadline (hoặc late allowed) |
| **Postcondition** | - Code được submit lên server<br>- Judge0 execute code<br>- Test cases được chạy<br>- Kết quả được lưu vào DB<br>- Student xem được results |
| **Normal Flow** | 1. Student xem code assignment detail<br>2. System hiển thị description, test cases (sample)<br>3. Student click "Open Editor"<br>4. System mở code editor với starter code<br>5. Student viết code<br>6. **Optional: Dry Run**<br>&nbsp;&nbsp;6.1. Student click "Test"<br>&nbsp;&nbsp;6.2. Student nhập sample input<br>&nbsp;&nbsp;6.3. System gửi code + input tới Judge0<br>&nbsp;&nbsp;6.4. Judge0 execute và return output<br>&nbsp;&nbsp;6.5. System hiển thị output<br>7. Student click "Submit"<br>8. System confirm "Submit for grading?"<br>9. Student confirm<br>10. System gửi code lên server<br>11. Server validate (language, length)<br>12. Server tạo CodeSubmission record<br>13. **Server call Judge0 cho từng test case:**<br>&nbsp;&nbsp;13.1. Gửi code + test input<br>&nbsp;&nbsp;13.2. Nhận output từ Judge0<br>&nbsp;&nbsp;13.3. So sánh với expected output<br>&nbsp;&nbsp;13.4. Lưu result (passed/failed)<br>14. Server tính total score (weighted sum)<br>15. Server update submission với results<br>16. System hiển thị results page<br>17. Student xem score, passed tests, failed tests |
| **Alternative Flow** | **5a. Auto-save code:**<br>&nbsp;&nbsp;5a1. Mỗi 30s, lưu code vào local storage<br>&nbsp;&nbsp;5a2. Nếu close editor, restore code khi reopen<br><br>**11a. Code quá dài:**<br>&nbsp;&nbsp;11a1. Server return error "Code too long"<br>&nbsp;&nbsp;11a2. Limit: 50KB<br><br>**13a. Judge0 timeout:**<br>&nbsp;&nbsp;13a1. Test case marked as "Time Limit Exceeded"<br>&nbsp;&nbsp;13a2. Score = 0 for that test<br><br>**13b. Runtime error:**<br>&nbsp;&nbsp;13b1. Capture error message<br>&nbsp;&nbsp;13b2. Show to student<br>&nbsp;&nbsp;13b3. Score = 0<br><br>**13c. Wrong output:**<br>&nbsp;&nbsp;13c1. Show expected vs actual<br>&nbsp;&nbsp;13c2. Score = 0 for that test |
| **Exception Flow** | **E1. Judge0 service down:**<br>&nbsp;&nbsp;E1.1. Queue submission<br>&nbsp;&nbsp;E1.2. Retry sau 5 phút<br>&nbsp;&nbsp;E1.3. Notify student "Grading delayed" |
| **Special Requirements** | - Code editor với syntax highlighting<br>- Support languages: Python, Java, C++, JS, C<br>- Time limit: 2s per test case<br>- Memory limit: 128MB<br>- Hidden test cases không show input/output<br>- Leaderboard dựa trên best submission |
| **Frequency** | Trung bình (vài lần/tuần) |

---

## 4.6. SƠ ĐỒ SEQUENCE (SEQUENCE DIAGRAMS)

### 4.6.1. Sequence Diagram - Đăng nhập

**Hình 4.6: Sequence Diagram - Login Process**

### AI Prompt:
```
Create a UML Sequence diagram for Login process:

ACTORS/OBJECTS:
- User (actor)
- Flutter App (boundary)
- API Server (control)
- JWT Service (control)
- MongoDB (entity)

SEQUENCE:
1. User enters username & password → Flutter App
2. Flutter App: validate inputs (not empty)
3. Flutter App → API Server: POST /api/auth/login {username, password}
4. API Server → MongoDB: findOne(username)
5. MongoDB → API Server: return user document
6. API Server: compare password with bcrypt
7. API Server → JWT Service: generate token(userId, role)
8. JWT Service → API Server: return JWT token
9. API Server → Flutter App: 200 OK {token, user}
10. Flutter App: save token to SharedPreferences
11. Flutter App: navigate to Dashboard
12. Flutter App → User: show Dashboard

ALTERNATIVE FLOWS:
- If user not found: return 401
- If password wrong: return 401
- If network error: show error message

Use standard UML notation with lifelines and activation boxes.
```

### 4.6.2. Sequence Diagram - Nộp bài tập

**Hình 4.7: Sequence Diagram - Submit Assignment**

### AI Prompt:
```
Create sequence diagram for file assignment submission:

PARTICIPANTS:
- Student (actor)
- Flutter App
- File Picker
- API Server
- GridFS
- MongoDB
- Notification Service

FLOW:
1. Student clicks "Submit Assignment"
2. Flutter App opens File Picker
3. File Picker → Student: select file dialog
4. Student selects file
5. File Picker → Flutter App: return file path
6. Flutter App: validate file (type, size)
7. Flutter App → API Server: POST /api/assignments/:id/submit (multipart form-data)
8. API Server: authenticate & authorize
9. API Server → GridFS: upload file (chunked)
10. GridFS → API Server: return fileId
11. API Server → MongoDB: create Submission {studentId, assignmentId, fileId}
12. MongoDB → API Server: return submission
13. API Server → Notification Service: notify instructor
14. Notification Service: send in-app + email
15. API Server → Flutter App: 201 Created {submission}
16. Flutter App → Student: show "Submitted successfully"

ERROR CASES:
- File too large → show error
- Network timeout → retry
- Deadline passed → check late submission policy
```

### 4.6.3. Sequence Diagram - Làm quiz

**Hình 4.8: Sequence Diagram - Take Quiz**

### AI Prompt:
```
Create sequence diagram for quiz taking process:

PARTICIPANTS:
- Student
- Flutter App
- Quiz Service
- Timer Service
- API Server
- MongoDB

PHASES:

PHASE 1 - START QUIZ:
1. Student clicks "Start Quiz"
2. Flutter App → API Server: POST /api/quizzes/:id/start
3. API Server → MongoDB: create QuizAttempt (status: in_progress)
4. API Server → MongoDB: fetch questions (random if configured)
5. API Server → Flutter App: return {attemptId, questions, duration}
6. Flutter App: start Timer Service
7. Flutter App: show first question

PHASE 2 - ANSWER QUESTIONS (loop):
8. Student selects answer
9. Flutter App: save answer locally
10. Every 10s: Flutter App → API Server: auto-save answers
11. API Server → MongoDB: update attempt.questions[i].selectedAnswer
12. Student clicks "Next"
13. Flutter App: show next question

PHASE 3 - SUBMIT:
14. Timer reaches 0 OR Student clicks "Submit"
15. Flutter App → API Server: POST /api/quiz-attempts/:id/submit {answers}
16. API Server: stop timer
17. API Server: calculate score (compare with correct answers)
18. API Server → MongoDB: update attempt {status: completed, score, correctAnswers}
19. API Server → Flutter App: return results
20. Flutter App → Student: show results page

Handle edge cases: network loss, app closed, time expired.
```

### 4.6.4. Sequence Diagram - Chấm code tự động

**Hình 4.9: Sequence Diagram - Auto-grade Code Assignment**

### AI Prompt:
```
Create sequence diagram for code assignment grading:

PARTICIPANTS:
- Student
- Flutter App (Code Editor)
- API Server
- Judge0 API
- Test Case DB
- MongoDB

SUBMISSION FLOW:
1. Student writes code in editor
2. Student clicks "Submit"
3. Flutter App → API Server: POST /api/code/:assignmentId/submit {code, language}
4. API Server: validate code (not empty, size < 50KB)
5. API Server → MongoDB: create CodeSubmission {studentId, code, status: pending}
6. API Server → Test Case DB: fetch all test cases for assignment
7. Test Case DB → API Server: return [testCase1, testCase2, ...]

GRADING LOOP (for each test case):
8. API Server → Judge0 API: POST /submissions {source_code, language_id, stdin, expected_output}
9. Judge0 API: compile code
10. Judge0 API: execute code with test input
11. Judge0 API: capture output & errors
12. Judge0 API → API Server: return {stdout, stderr, status, time, memory}
13. API Server: compare output with expected_output
14. API Server: mark test as passed/failed
15. API Server: calculate score (testCase.weight)

FINALIZE:
16. API Server: sum up total score
17. API Server → MongoDB: update submission {testResults, totalScore, status: completed}
18. API Server → Flutter App: 200 OK {results}
19. Flutter App → Student: show results (score, passed tests, failed tests)

Show retry logic if Judge0 timeout.
```

---

## 4.7. THIẾT KẾ CƠ SỞ DỮ LIỆU (DATABASE DESIGN)

### 4.7.1. Sơ đồ ERD tổng thể

**Hình 4.11: ERD Diagram - Complete System**

### AI Prompt cho ERD tổng thể:
```
Create an Entity-Relationship Diagram for E-Learning system with these entities:

CORE ENTITIES:
1. User (PK: _id)
   - username, email, password, role (student/instructor/admin)
   - firstName, lastName, studentId, department
   - Relationships: creates Courses, enrolled in Courses, creates Assignments

2. Course (PK: _id)
   - code, name, description, instructor (FK), semester (FK)
   - students (array of User FK)
   - Relationships: belongs to Semester, has many Assignments/Quizzes/Materials

3. Semester (PK: _id)
   - code, name, year, startDate, endDate
   - Relationships: has many Courses

4. Assignment (PK: _id)
   - courseId (FK), title, description, deadline, type (file/code)
   - Relationships: belongs to Course, has many Submissions

5. Submission (PK: _id)
   - assignmentId (FK), studentId (FK), files, grade, status
   - Relationships: belongs to Assignment and User

6. Quiz (PK: _id)
   - courseId (FK), title, openDate, closeDate, duration
   - Relationships: belongs to Course, references Questions, has QuizAttempts

7. Question (PK: _id)
   - courseId (FK), questionText, choices, difficulty
   - Relationships: belongs to Course, used in Quizzes

8. QuizAttempt (PK: _id)
   - quizId (FK), studentId (FK), questions, score, status
   - Relationships: belongs to Quiz and User

Use crow's foot notation:
- One-to-Many: Course (1) ─< (M) Assignment
- Many-to-Many: Course (M) >─< (M) User (via students array)
- One-to-One: Submission (1) ─ (1) Assignment

Color code: Users (blue), Courses (green), Content (orange), Results (yellow)
```

### 4.7.2. Mô tả chi tiết các Collection

**Bảng 4.9: Collection Users**

| Field | Type | Required | Description | Index |
|-------|------|----------|-------------|-------|
| _id | ObjectId | Yes | Primary key | ✓ |
| username | String | Yes | Unique username | ✓ Unique |
| email | String | Yes | Email address | ✓ Unique |
| password | String | Yes | Hashed password (bcrypt) | |
| role | String | Yes | student/instructor/admin | ✓ |
| firstName | String | No | First name | |
| lastName | String | No | Last name | |
| studentId | String | No | Student ID (for students) | ✓ Sparse |
| department | String | No | Department name | |
| profilePicture | String | No | URL to profile image | |
| isActive | Boolean | Yes | Account status (default: true) | |
| createdAt | Date | Yes | Auto timestamp | |
| updatedAt | Date | Yes | Auto timestamp | |

**Bảng 4.10: Collection Courses**

| Field | Type | Required | Description | Index |
|-------|------|----------|-------------|-------|
| _id | ObjectId | Yes | Primary key | ✓ |
| code | String | Yes | Course code (e.g., CS101) | ✓ Unique |
| name | String | Yes | Course name | |
| description | String | No | Course description | |
| instructor | ObjectId | Yes | Ref: User (instructor) | ✓ |
| semester | ObjectId | No | Ref: Semester | ✓ |
| students | [ObjectId] | No | Array of User refs | |
| sessions | Number | No | Number of sessions (default: 15) | |
| color | String | No | UI color (default: #1976D2) | |
| image | String | No | Course cover image URL | |
| createdAt | Date | Yes | Auto timestamp | |
| updatedAt | Date | Yes | Auto timestamp | |

**Compound Index:** `{instructor: 1, semester: 1}`

**Bảng 4.11: Collection Assignments**

| Field | Type | Required | Description | Index |
|-------|------|----------|-------------|-------|
| _id | ObjectId | Yes | Primary key | ✓ |
| courseId | ObjectId | Yes | Ref: Course | ✓ |
| createdBy | ObjectId | Yes | Ref: User (instructor) | |
| title | String | Yes | Assignment title | |
| description | String | No | Assignment description | |
| type | String | Yes | file / code | |
| startDate | Date | Yes | Available from date | |
| deadline | Date | Yes | Due date | ✓ |
| allowLateSubmission | Boolean | No | Default: false | |
| maxAttempts | Number | No | Default: 1 | |
| points | Number | No | Max score (default: 100) | |
| attachments | [Object] | No | Files attached to assignment | |
| groupIds | [ObjectId] | No | Assigned to specific groups | ✓ |
| createdAt | Date | Yes | Auto timestamp | |

**Compound Index:** `{courseId: 1, deadline: 1}`

**Bảng 4.12: Collection Quizzes**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| _id | ObjectId | Yes | Primary key |
| courseId | ObjectId | Yes | Ref: Course |
| title | String | Yes | Quiz title |
| openDate | Date | Yes | Start date |
| closeDate | Date | Yes | End date |
| duration | Number | Yes | Duration in minutes |
| maxAttempts | Number | No | Default: 1 |
| shuffleQuestions | Boolean | No | Randomize order |
| questionStructure | Object | No | {easy: 5, medium: 3, hard: 2} |
| selectedQuestions | [ObjectId] | No | Ref: Question array |
| totalPoints | Number | No | Default: 100 |
| status | String | No | draft/active/closed |

**Indexes:** `courseId`, `{openDate, closeDate}`

### 4.7.3. Mối quan hệ giữa các Collection

**1. User ↔ Course (Many-to-Many)**
- Instructor creates Courses: `Course.instructor → User._id` (One-to-Many)
- Students enroll in Courses: `Course.students[] → User._id` (Many-to-Many)

**2. Course ↔ Assignment (One-to-Many)**
- One Course has many Assignments
- `Assignment.courseId → Course._id`

**3. Assignment ↔ Submission (One-to-Many)**
- One Assignment has many Submissions
- `Submission.assignmentId → Assignment._id`
- `Submission.studentId → User._id`

**4. Course ↔ Quiz (One-to-Many)**
- One Course has many Quizzes
- `Quiz.courseId → Course._id`

**5. Quiz ↔ Question (Many-to-Many)**
- One Quiz can use many Questions
- One Question can be in many Quizzes
- `Quiz.selectedQuestions[] → Question._id`

**6. Quiz ↔ QuizAttempt (One-to-Many)**
- One Quiz has many Attempts
- `QuizAttempt.quizId → Quiz._id`
- `QuizAttempt.studentId → User._id`

**Referential Integrity:**
- Mongoose `.populate()` để join data
- Indexes on foreign keys để optimize queries
- Cascade delete khi cần (e.g., xóa Course → xóa Assignments)

---

**KẾT LUẬN CHƯƠNG 4:**

Chương này đã trình bày chi tiết thiết kế hệ thống E-Learning, bao gồm:
- Kiến trúc 3-tier với các thành phần rõ ràng
- Use case diagrams cho 3 vai trò với 141 use cases
- Đặc tả chi tiết các use case quan trọng (login, submit, quiz, code grading)
- Sequence diagrams minh họa flow của các tính năng chính
- ERD với 24 collections và mối quan hệ giữa chúng

Thiết kế này đảm bảo:
✓ Phân quyền rõ ràng (RBAC)
✓ Data integrity với indexes và relationships
✓ Scalability với MongoDB flexible schema
✓ Performance với compound indexes

Chương tiếp theo sẽ trình bày implementation chi tiết với code examples, API documentation và screenshots của hệ thống.

---
