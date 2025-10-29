# Phân Tích Khoảng Trống - E-Learning Platform

## 📋 Tổng Quan

Dựa trên yêu cầu ban đầu so với hệ thống hiện tại, dưới đây là danh sách chi tiết các phần **THIẾU** và **CẦN BỔ SUNG**.

---

## ✅ NHỮNG GÌ ĐÃ CÓ (Implemented)

### Backend
- ✅ User management (thêm, sửa, xóa người dùng)
- ✅ Phân quyền: student, instructor, admin
- ✅ Quản lý khóa học (CRUD)
- ✅ Quản lý học kỳ (semesters)
- ✅ Quiz và câu hỏi trắc nghiệm
- ✅ Chấm quiz tự động
- ✅ Assignment (bài tập) với file upload
- ✅ Materials (tài liệu học tập)
- ✅ Announcements (thông báo)
- ✅ Groups (nhóm học)
- ✅ Chat 1-1 realtime (text + files)
- ✅ Notifications in-app
- ✅ Email notifications
- ✅ Dashboard thống kê cơ bản
- ✅ Export báo cáo (CSV)
- ✅ Forum discussions
- ✅ File upload/download với GridFS

### Frontend (Flutter)
- ✅ Login/Logout
- ✅ Student dashboard
- ✅ Instructor dashboard
- ✅ Course detail với tabs (Stream, Classwork, People)
- ✅ Quiz taking interface
- ✅ Assignment submission
- ✅ Chat screen (1-1 messaging)
- ✅ Profile management
- ✅ Notifications screen
- ✅ Theme switching (light/dark)
- ✅ Password reset
- ✅ Settings screen

---

## ❌ NHỮNG GÌ THIẾU (Missing Features)

### 1. **Admin/HR Features - THIẾU HOÀN TOÀN** 🔴

#### 1.1. Quản lý người dùng nâng cao
**Hiện trạng:** Chỉ có basic CRUD users
**Thiếu:**
- ❌ Dashboard quản lý người dùng với filters, search, pagination
- ❌ Bulk user import (CSV/Excel)
- ❌ Phân quyền chi tiết hơn (roles & permissions)
- ❌ User activity logs
- ❌ Suspend/activate accounts
- ❌ Reset password cho users (admin action)

**Cần làm:**
```javascript
// Backend routes cần thêm:
- POST /api/admin/users/bulk-import
- PUT /api/admin/users/:id/suspend
- PUT /api/admin/users/:id/activate
- GET /api/admin/users/activity-logs
- PUT /api/admin/users/:id/permissions

// Frontend screens cần thêm:
- lib/screens/admin/user_management_screen.dart
- lib/screens/admin/bulk_import_screen.dart
- lib/screens/admin/user_activity_logs.dart
```

#### 1.2. Phân công giảng viên cho khóa học
**Hiện trạng:** Courses có instructor field nhưng không có UI quản lý
**Thiếu:**
- ❌ Assign/reassign instructor to course
- ❌ Multiple instructors per course
- ❌ Instructor workload dashboard

**Cần làm:**
```javascript
// Backend:
- PUT /api/admin/courses/:id/assign-instructor
- GET /api/admin/instructors/workload

// Frontend:
- lib/screens/admin/assign_instructor_screen.dart
```

#### 1.3. Gán khóa học cho phòng ban
**Hiện trạng:** User có field `department` nhưng không liên kết với courses
**Thiếu:**
- ❌ Department management (thêm/sửa/xóa phòng ban)
- ❌ Assign courses to departments
- ❌ Auto-enroll students theo department
- ❌ Department-based course catalog

**Cần làm:**
```javascript
// Backend models:
- models/Department.js (NEW)
  - name, code, description
  - courses[] (ref to Course)
  - employees[] (ref to User)

// Backend routes:
- POST /api/admin/departments
- PUT /api/admin/departments/:id/assign-courses
- POST /api/admin/departments/:id/auto-enroll

// Frontend:
- lib/screens/admin/department_management_screen.dart
- lib/models/department.dart
```

#### 1.4. Dashboard tổng hợp (Admin)
**Hiện trạng:** Có instructor & student dashboards riêng
**Thiếu:**
- ❌ Admin dashboard với metrics toàn hệ thống
- ❌ Charts: user growth, course completion rates
- ❌ Training progress by department
- ❌ Top performers, low performers

**Cần làm:**
```javascript
// Backend:
- GET /api/admin/dashboard/overview
- GET /api/admin/dashboard/training-progress-by-department
- GET /api/admin/reports/user-growth
- GET /api/admin/reports/completion-rates

// Frontend:
- lib/screens/admin/admin_dashboard.dart
- lib/widgets/admin/charts/
```

#### 1.5. Xuất báo cáo đào tạo
**Hiện trạng:** Có export basic CSV cho quiz results
**Thiếu:**
- ❌ Export báo cáo theo phòng ban
- ❌ Export báo cáo tiến độ cá nhân
- ❌ Export attendance reports
- ❌ PDF reports với charts
- ❌ Scheduled reports (email hàng tuần/tháng)

**Cần làm:**
```javascript
// Backend:
- POST /api/admin/reports/generate-department-report
- POST /api/admin/reports/generate-individual-report
- POST /api/admin/reports/schedule (with cron jobs)
- GET /api/admin/reports/download/:reportId

// Frontend:
- lib/screens/admin/reports_screen.dart
- lib/services/report_service.dart
```

---

### 2. **Giảng viên Features - THIẾU MỘT PHẦN** 🟡

#### 2.1. Quản lý nội dung giảng dạy
**Hiện trạng:** Có materials (PDF, links) nhưng thiếu video
**Thiếu:**
- ❌ Video upload và streaming
- ❌ Video player với controls (play, pause, seek)
- ❌ Video progress tracking
- ❌ Subtitles/captions support
- ❌ Video playlists

**Cần làm:**
```javascript
// Backend:
- POST /api/videos/upload (chunked upload for large files)
- GET /api/videos/:id/stream
- POST /api/videos/:id/track-progress
- models/Video.js

// Frontend:
- lib/screens/instructor/upload_video_screen.dart
- lib/screens/student/video_player_screen.dart
- lib/services/video_service.dart
- Dependencies: video_player, chewie packages
```

#### 2.2. Bài tập code chấm tự động
**Hiện trạng:** Chỉ có assignment với file upload thủ công
**Thiếu:**
- ❌ Code editor trong app
- ❌ Auto-grading với test cases
- ❌ Support multiple languages (Python, Java, C++, JavaScript)
- ❌ Code execution sandbox
- ❌ Plagiarism detection

**Cần làm:**
```javascript
// Backend:
- POST /api/assignments/:id/submit-code
- POST /api/assignments/:id/run-tests
- Integration với Judge0 API hoặc tự build code executor
- models/CodeSubmission.js
- models/TestCase.js

// Frontend:
- lib/screens/instructor/create_code_assignment_screen.dart
- lib/screens/student/code_editor_screen.dart
- lib/widgets/code_editor.dart
- Dependencies: code_text_field, flutter_highlight
```

#### 2.3. Quản lý lớp học online
**Hiện trạng:** Có groups nhưng không có điểm danh
**Thiếu:**
- ❌ Attendance tracking (điểm danh)
- ❌ Attendance reports
- ❌ Auto attendance via GPS/QR code
- ❌ Late/absent notifications

**Cần làm:**
```javascript
// Backend:
- POST /api/courses/:id/attendance/sessions (create session)
- POST /api/attendance/:sessionId/mark (mark student)
- GET /api/attendance/reports/:courseId
- models/AttendanceSession.js
- models/AttendanceRecord.js

// Frontend:
- lib/screens/instructor/attendance_screen.dart
- lib/screens/student/check_in_screen.dart
- QR code generation/scanning
```

#### 2.4. Lưu lịch sử buổi học trực tuyến
**Hiện trạng:** CHƯA CÓ video call
**Thiếu:**
- ❌ Toàn bộ phần này (xem mục 4)

---

### 3. **Nhân viên/Học viên Features - THIẾU MỘT PHẦN** 🟡

#### 3.1. Bài kiểm tra đầu vào (Placement Test)
**Hiện trạng:** Có quiz nhưng không có concept placement test
**Thiếu:**
- ❌ Placement test riêng biệt với quiz thường
- ❌ Adaptive testing (câu hỏi thay đổi theo trình độ)
- ❌ Skill level assessment
- ❌ Recommended learning path based on results

**Cần làm:**
```javascript
// Backend:
- POST /api/placement-tests/create
- POST /api/placement-tests/:id/take
- GET /api/placement-tests/:id/results
- GET /api/placement-tests/:id/recommendations
- models/PlacementTest.js

// Frontend:
- lib/screens/student/placement_test_screen.dart
- lib/screens/student/skill_assessment_screen.dart
```

#### 3.2. Chat realtime - THIẾU HÌNH ẢNH
**Hiện trạng:** Có chat text + file
**Thiếu:**
- ❌ Gửi hình ảnh (image upload + preview)
- ❌ Image gallery trong chat
- ❌ Emoji picker
- ❌ Typing indicators
- ❌ Read receipts
- ❌ Group chat

**Cần làm:**
```javascript
// Backend:
- POST /api/messages/upload-image
- WebSocket events: user_typing, message_read

// Frontend:
- Image picker integration
- lib/widgets/chat/image_message_bubble.dart
- lib/widgets/chat/typing_indicator.dart
- Dependencies: image_picker, cached_network_image
```

#### 3.3. Xem lại lịch sử (chat, file, hình ảnh, video)
**Hiện trạng:** Có chat history + shared files
**Thiếu:**
- ❌ Filter messages by type (text/file/image/video)
- ❌ Search in files
- ❌ Download all files from conversation
- ❌ Media gallery view

**Cần làm:**
```javascript
// Backend:
- GET /api/messages/conversation/:userId/media
- GET /api/messages/conversation/:userId/files

// Frontend:
- lib/screens/chat/media_gallery_screen.dart
- lib/screens/chat/files_archive_screen.dart
```

---

### 4. **Giao tiếp Realtime - THIẾU HOÀN TOÀN** 🔴 **QUAN TRỌNG**

#### 4.1. Gọi thoại (Voice Call)
**Hiện trạng:** CHƯA CÓ
**Thiếu:**
- ❌ WebRTC integration
- ❌ Voice call UI (call, answer, reject, mute)
- ❌ Call notifications
- ❌ Call history
- ❌ Call quality indicators

**Cần làm:**
```javascript
// Backend:
- WebSocket signaling server for WebRTC
- Socket events: call_initiated, call_accepted, call_rejected, call_ended
- POST /api/calls/initiate
- POST /api/calls/:id/end
- GET /api/calls/history
- models/Call.js

// Frontend:
- lib/screens/call/voice_call_screen.dart
- lib/services/webrtc_service.dart
- lib/services/call_service.dart
- Dependencies: flutter_webrtc
```

#### 4.2. Video call
**Hiện trạng:** CHƯA CÓ
**Thiếu:**
- ❌ Video call 1-1
- ❌ Video call nhóm (group video)
- ❌ Camera switch (front/back)
- ❌ Video on/off toggle
- ❌ Picture-in-picture mode

**Cần làm:**
```javascript
// Backend: (same signaling as voice call)
- Additional socket events for video

// Frontend:
- lib/screens/call/video_call_screen.dart
- lib/screens/call/group_video_call_screen.dart
- lib/widgets/call/video_renderer.dart
- Dependencies: flutter_webrtc, permission_handler
```

#### 4.3. Chia sẻ màn hình (Screen Sharing)
**Hiện trạng:** CHƯA CÓ
**Thiếu:**
- ❌ Screen sharing trong video call
- ❌ Screen sharing controls (start/stop)
- ❌ Screen sharing notifications
- ❌ Recording screen share sessions

**Cần làm:**
```javascript
// Backend:
- Socket events: screen_share_started, screen_share_stopped

// Frontend:
- lib/screens/call/screen_share_viewer_screen.dart
- lib/services/screen_capture_service.dart
- Dependencies: flutter_webrtc (has screen capture support)
```

#### 4.4. Lưu lịch sử cuộc gọi
**Hiện trạng:** CHƯA CÓ
**Thiếu:**
- ❌ Call logs (duration, participants, timestamp)
- ❌ Call recordings (optional)
- ❌ Transcripts (optional, AI-based)
- ❌ Shared files during call

**Cần làm:**
```javascript
// Backend:
- models/CallLog.js
- POST /api/calls/:id/record (start recording)
- GET /api/calls/:id/recording
- GET /api/calls/history

// Frontend:
- lib/screens/call/call_history_screen.dart
- lib/screens/call/call_recording_player_screen.dart
```

---

### 5. **Lộ trình học tập cá nhân hóa - THIẾU HOÀN TOÀN** 🔴

#### 5.1. Bài kiểm tra đầu vào + gợi ý lộ trình
**Hiện trạng:** CHƯA CÓ
**Thiếu:**
- ❌ Placement test với skill assessment
- ❌ AI-based course recommendations
- ❌ Learning path generation dựa trên:
  - Kết quả placement test
  - Job role/position
  - Current skill level
  - Learning goals
- ❌ Personalized course sequence

**Cần làm:**
```javascript
// Backend:
- POST /api/learning-paths/generate
- GET /api/learning-paths/recommendations
- POST /api/learning-paths/customize
- models/LearningPath.js
- models/SkillAssessment.js
- AI/ML integration (hoặc rule-based algorithm)

// Frontend:
- lib/screens/student/learning_path_screen.dart
- lib/screens/student/skill_assessment_screen.dart
- lib/screens/student/course_recommendations_screen.dart
```

#### 5.2. Dashboard cá nhân với skills tracking
**Hiện trạng:** Có student dashboard nhưng rất basic
**Thiếu:**
- ❌ Skills radar chart
- ❌ Competency levels (Beginner, Intermediate, Advanced)
- ❌ Skill gaps identification
- ❌ Recommended skills to improve
- ❌ Learning streaks và motivation gamification

**Cần làm:**
```javascript
// Backend:
- GET /api/students/skills-progress
- GET /api/students/skill-gaps
- GET /api/students/learning-streaks
- models/SkillProgress.js

// Frontend:
- lib/screens/student/skills_dashboard_screen.dart
- lib/widgets/skills/radar_chart.dart
- lib/widgets/skills/skill_card.dart
- Dependencies: fl_chart, syncfusion_flutter_charts
```

---

### 6. **Thống kê và Báo cáo - THIẾU MỘT PHẦN** 🟡

#### 6.1. Báo cáo chi tiết theo phòng ban
**Hiện trạng:** Có export CSV cơ bản
**Thiếu:**
- ❌ Department-level analytics
- ❌ Training completion rates by department
- ❌ Department comparison charts
- ❌ Export PDF reports with charts

**Cần làm:**
```javascript
// Backend:
- GET /api/reports/department/:id/overview
- GET /api/reports/department/:id/completion-rates
- GET /api/reports/departments/compare
- PDF generation library (pdfkit hoặc puppeteer)

// Frontend:
- lib/screens/admin/department_reports_screen.dart
- lib/widgets/reports/completion_chart.dart
```

#### 6.2. Báo cáo cá nhân chi tiết
**Hiện trạng:** Student có dashboard cơ bản
**Thiếu:**
- ❌ Detailed learning analytics
- ❌ Time spent per course/module
- ❌ Performance trends (charts)
- ❌ Certificates earned
- ❌ Downloadable PDF transcript

**Cần làm:**
```javascript
// Backend:
- GET /api/students/detailed-report
- GET /api/students/time-tracking
- GET /api/students/certificates
- POST /api/students/generate-transcript (PDF)

// Frontend:
- lib/screens/student/detailed_report_screen.dart
- lib/screens/student/certificates_screen.dart
```

---

### 7. **Công nghệ Backend - THIẾU** 🟡

#### 7.1. WebSocket cho chat realtime
**Hiện trạng:** Có HTTP polling (không realtime thực sự)
**Thiếu:**
- ❌ Socket.IO integration
- ❌ Real-time message delivery
- ❌ Typing indicators
- ❌ Online/offline status
- ❌ Message read receipts

**Cần làm:**
```javascript
// Backend:
npm install socket.io
// server.js:
const io = require('socket.io')(server);
io.on('connection', (socket) => {
  // Handle chat events
  socket.on('send_message', handleMessage);
  socket.on('typing', handleTyping);
  socket.on('mark_read', handleMarkRead);
});

// Frontend:
- lib/services/socket_service.dart
- Dependencies: socket_io_client
```

#### 7.2. WebRTC signaling server
**Hiện trạng:** CHƯA CÓ
**Thiếu:**
- ❌ WebRTC signaling với Socket.IO
- ❌ STUN/TURN server configuration
- ❌ Call session management

**Cần làm:**
```javascript
// Backend:
// WebRTC signaling events
socket.on('offer', (data) => {
  socket.to(data.to).emit('offer', data);
});
socket.on('answer', (data) => {
  socket.to(data.to).emit('answer', data);
});
socket.on('ice-candidate', (data) => {
  socket.to(data.to).emit('ice-candidate', data);
});

// STUN/TURN server (có thể dùng free: stun.l.google.com:19302)
```

#### 7.3. Cloud Storage cho media
**Hiện trạng:** GridFS (MongoDB) cho files
**Thiếu:**
- ❌ Cloud storage cho videos, images (AWS S3, Google Cloud Storage, hoặc Firebase Storage)
- ❌ CDN integration cho fast delivery
- ❌ Image optimization và compression
- ❌ Video transcoding

**Cần làm:**
```javascript
// Backend:
npm install @aws-sdk/client-s3
// hoặc
npm install @google-cloud/storage
// hoặc
npm install firebase-admin

// routes/uploads.js
- POST /api/uploads/image
- POST /api/uploads/video
- GET /api/uploads/:id/url (pre-signed URL)
```

---

## 📊 TÓM TẮT ƯU TIÊN

### 🔴 **CỰC KỲ QUAN TRỌNG** (Phải làm ngay)

1. **WebRTC Video/Voice Call** - Core feature thiếu hoàn toàn
2. **Screen Sharing** - Cần thiết cho mentoring
3. **WebSocket realtime chat** - Cải thiện UX
4. **Admin Dashboard** - Quản lý toàn hệ thống
5. **Department Management** - Gán khóa học theo phòng ban

### 🟡 **QUAN TRỌNG** (Nên làm sớm)

6. **Learning Path Personalization** - USP của sản phẩm
7. **Placement Test** - Đánh giá trình độ
8. **Code Assignment Auto-grading** - Tiết kiệm thời gian
9. **Video Upload & Streaming** - Nội dung giảng dạy
10. **Attendance Tracking** - Quản lý lớp học

### 🟢 **BỔ SUNG** (Có thể làm sau)

11. **Advanced Reporting (PDF, Charts)**
12. **Image messaging trong chat**
13. **Group video call**
14. **Call recording & transcripts**
15. **Gamification (badges, streaks)**

---

## 🛠️ CÔNG VIỆC CẦN LÀM

### Phase 1: Foundation (1-2 tuần)
1. Setup Socket.IO cho realtime chat
2. Implement WebSocket messaging
3. Add typing indicators, read receipts
4. Image upload trong chat

### Phase 2: Video/Voice Call (2-3 tuần)
5. Setup WebRTC signaling server
6. Implement 1-1 voice call
7. Implement 1-1 video call
8. Add screen sharing
9. Call history & logging

### Phase 3: Admin Features (2 tuần)
10. Admin dashboard với metrics
11. Department management
12. Assign instructors to courses
13. Bulk user import
14. Advanced reporting

### Phase 4: Learning Path (2 tuần)
15. Placement test system
16. Skill assessment
17. Learning path recommendations
18. Skills tracking dashboard

### Phase 5: Content Management (2 tuần)
19. Video upload & streaming
20. Video player với progress tracking
21. Code assignment system
22. Auto-grading với test cases

### Phase 6: Enhancements (1-2 tuần)
23. Attendance tracking
24. PDF reports generation
25. Email scheduled reports
26. Gamification elements

---

## 📦 DEPENDENCIES MỚI CẦN CÀI

### Backend
```bash
npm install socket.io          # WebSocket realtime
npm install simple-peer        # WebRTC helper (optional)
npm install @aws-sdk/client-s3 # Cloud storage
npm install pdfkit             # PDF generation
npm install node-cron          # Scheduled tasks
npm install bull               # Job queue (for video transcoding)
```

### Frontend (Flutter)
```bash
flutter pub add socket_io_client     # WebSocket
flutter pub add flutter_webrtc       # Video/Voice call
flutter pub add image_picker         # Image upload
flutter pub add cached_network_image # Image caching
flutter pub add fl_chart             # Charts/graphs
flutter pub add video_player         # Video playback
flutter pub add chewie               # Video player UI
flutter pub add code_text_field      # Code editor
flutter pub add qr_flutter           # QR code
flutter pub add mobile_scanner       # QR scanner
```

---

## 🎯 KHUYẾN NGHỊ

### Triển khai theo thứ tự ưu tiên:

1. **Ngay lập tức:** WebRTC call system (core differentiator)
2. **Tuần 2:** Admin dashboard và department management
3. **Tuần 4:** Learning path personalization
4. **Tuần 6:** Video content management
5. **Tuần 8:** Code assignments auto-grading
6. **Tuần 10:** Advanced reporting và gamification

### Lưu ý kỹ thuật:

- **WebRTC**: Cần STUN/TURN server cho NAT traversal (có thể dùng free coturn hoặc paid service như Twilio)
- **Video streaming**: Nên dùng cloud storage + CDN thay vì GridFS (performance better)
- **Socket.IO**: Cần Redis adapter nếu scale to multiple servers
- **Testing**: Cần test WebRTC trên real devices (không chạy tốt trên emulator)

---

**Tóm lại:** Hệ thống hiện tại đã có **60-70%** features cơ bản. Phần quan trọng nhất còn thiếu là **realtime communication (WebRTC)** và **admin management features**. Ưu tiên làm 2 phần này trước!
