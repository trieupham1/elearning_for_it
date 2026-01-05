# CHƯƠNG 1: MỞ ĐẦU (INTRODUCTION)

## 1.1. LÝ DO CHỌN ĐỀ TÀI (RATIONALE FOR TOPIC SELECTION)

### 1.1.1. Bối cảnh
Trong bối cảnh cuộc cách mạng công nghiệp 4.0 và đặc biệt là sau đại dịch COVID-19, việc chuyển đổi số trong giáo dục đã trở thành xu hướng tất yếu. Giáo dục trực tuyến (E-Learning) không còn là lựa chọn thay thế mà đã trở thành một phần không thể thiếu của hệ thống giáo dục hiện đại.

Tại Việt Nam, ngành Công nghệ Thông tin đang có sự phát triển mạnh mẽ với nhu cầu nhân lực cao. Tuy nhiên, phương pháp đào tạo truyền thống vẫn còn nhiều hạn chế:
- **Giới hạn không gian và thời gian**: Sinh viên phải có mặt tại lớp học vào thời gian cố định
- **Thiếu tương tác**: Khó khăn trong việc trao đổi, thảo luận ngoài giờ học
- **Quản lý thủ công**: Điểm danh, nộp bài, chấm bài mất nhiều thời gian
- **Thiếu theo dõi tiến độ**: Khó nắm bắt tiến độ học tập của từng sinh viên
- **Hạn chế tài nguyên học tập**: Tài liệu phụ thuộc vào bản in hoặc file tĩnh

### 1.1.2. Nhu cầu thực tế
Đối với **sinh viên Công nghệ Thông tin**, các nhu cầu cụ thể bao gồm:
- Học tập linh hoạt, có thể xem lại bài giảng nhiều lần
- Luyện tập code trực tuyến với hệ thống chấm tự động
- Nộp bài tập điện tử và nhận phản hồi nhanh chóng
- Tương tác với giảng viên và bạn học mọi lúc, mọi nơi
- Theo dõi tiến độ học tập và kết quả cá nhân

Đối với **giảng viên**, các nhu cầu bao gồm:
- Quản lý lớp học, bài tập, điểm số hiệu quả
- Chấm bài tự động để tiết kiệm thời gian
- Theo dõi tiến độ học tập của từng sinh viên
- Tương tác và hỗ trợ sinh viên ngoài giờ học
- Tạo ngân hàng câu hỏi và đề thi

Đối với **nhà trường/quản trị**, các nhu cầu bao gồm:
- Quản lý tập trung các khóa học, giảng viên, sinh viên
- Thống kê, báo cáo tiến độ đào tạo
- Đảm bảo chất lượng giảng dạy
- Tối ưu hóa nguồn lực đào tạo

### 1.1.3. Giải pháp đề xuất
Với những lý do trên, em quyết định chọn đề tài **"Hệ thống Quản lý Học tập Trực tuyến cho Ngành Công nghệ Thông tin"** nhằm:
- Xây dựng một nền tảng E-Learning hoàn chỉnh, hiện đại
- Tích hợp các tính năng đặc thù cho đào tạo CNTT (code editor, auto-grading)
- Hỗ trợ đa nền tảng (Web, Android, iOS) để tiếp cận rộng rãi
- Áp dụng các công nghệ mới nhất (Flutter, Node.js, MongoDB, WebRTC)
- Giải quyết các bài toán thực tế trong quản lý và giảng dạy

---

## 1.2. MỤC TIÊU THỰC HIỆN ĐỀ TÀI (PROJECT OBJECTIVES)

### 1.2.1. Mục tiêu tổng quát
Xây dựng một hệ thống quản lý học tập trực tuyến (E-Learning Management System) hoàn chỉnh, đáp ứng nhu cầu giảng dạy và học tập cho ngành Công nghệ Thông tin, với giao diện thân thiện, hiệu năng cao và khả năng mở rộng tốt.

### 1.2.2. Mục tiêu cụ thể

#### A. Về chức năng
1. **Quản lý người dùng và phân quyền**
   - Hỗ trợ 3 vai trò: Admin, Instructor, Student
   - Đăng ký, đăng nhập, quên mật khẩu
   - Quản lý profile cá nhân

2. **Quản lý khóa học**
   - Tạo, sửa, xóa khóa học
   - Gán giảng viên, phân công sinh viên
   - Quản lý nhóm học (groups)
   - Quản lý học kỳ (semesters)

3. **Hệ thống bài tập và kiểm tra**
   - Bài tập file upload truyền thống
   - Bài tập code với chấm điểm tự động (Python, Java, C++, JavaScript, C)
   - Quiz trắc nghiệm tự động
   - Ngân hàng câu hỏi theo độ khó
   - Chấm điểm và phản hồi tự động

4. **Quản lý nội dung học tập**
   - Upload và quản lý video bài giảng
   - Theo dõi tiến độ xem video
   - Quản lý tài liệu học tập (PDF, slides)
   - Thông báo và announcement

5. **Tương tác và giao tiếp**
   - Forum thảo luận
   - Chat 1-1 realtime
   - Video call trong khóa học
   - Thông báo đa kênh (in-app, email)

6. **Điểm danh và theo dõi**
   - Điểm danh QR Code với GPS verification
   - Theo dõi lịch sử điểm danh
   - Báo cáo thống kê

7. **Dashboard và báo cáo**
   - Dashboard cho từng vai trò
   - Thống kê tiến độ học tập
   - Báo cáo theo khóa học, sinh viên
   - Export dữ liệu (CSV, PDF)

#### B. Về kỹ thuật
1. **Frontend (Flutter)**
   - Xây dựng ứng dụng đa nền tảng (Android, iOS, Web)
   - Giao diện responsive, thân thiện
   - Hỗ trợ dark mode
   - Animations và transitions mượt mà

2. **Backend (Node.js/Express)**
   - RESTful API architecture
   - JWT authentication & authorization
   - Real-time communication (Socket.IO, WebRTC)
   - File storage với GridFS
   - Email notifications
   - Integration với Judge0 API (code execution)
   - Integration với Agora RTC (video call)

3. **Database (MongoDB)**
   - Thiết kế schema tối ưu
   - Indexing cho performance
   - Data validation
   - Backup và recovery

4. **Deployment**
   - Deploy backend lên cloud (Render)
   - Deploy database lên MongoDB Atlas
   - CI/CD pipeline
   - Monitoring và logging

#### C. Về nghiên cứu
1. Nghiên cứu và áp dụng các công nghệ mới nhất
2. So sánh và lựa chọn giải pháp tối ưu
3. Đánh giá hiệu năng và khả năng mở rộng
4. Phân tích và giải quyết các thách thức kỹ thuật

---

## 1.3. ĐỐI TƯỢNG VÀ PHẠM VI NGHIÊN CỨU (RESEARCH SCOPE AND OBJECTS)

### 1.3.1. Đối tượng nghiên cứu (Research Objects)

#### A. Đối tượng người dùng
1. **Sinh viên (Students)**
   - Sinh viên ngành Công nghệ Thông tin
   - Có thiết bị thông minh (smartphone, tablet, laptop)
   - Có kết nối Internet

2. **Giảng viên (Instructors)**
   - Giảng viên giảng dạy các môn CNTT
   - Có kinh nghiệm sử dụng công nghệ

3. **Quản trị viên (Administrators)**
   - Cán bộ quản lý khoa/trường
   - Quản lý hệ thống và người dùng

#### B. Đối tượng công nghệ
1. **Frontend Framework**: Flutter 3.5.0
2. **Backend Framework**: Node.js 18+ với Express.js 4.x
3. **Database**: MongoDB 7.x
4. **Real-time**: Socket.IO 4.x
5. **Video Call**: Agora RTC Engine 6.x
6. **Code Execution**: Judge0 CE API
7. **Email Service**: Nodemailer/Brevo
8. **Cloud Platform**: Render.com, MongoDB Atlas

#### C. Đối tượng chức năng
1. Quản lý khóa học và người dùng
2. Hệ thống bài tập và kiểm tra
3. Giao tiếp và tương tác
4. Quản lý nội dung học tập
5. Theo dõi và thống kê

### 1.3.2. Phạm vi nghiên cứu (Research Scope)

#### A. Phạm vi bao gồm (In Scope)
1. **Chức năng core:**
   ✅ Đăng ký, đăng nhập, quản lý profile
   ✅ Quản lý khóa học, học kỳ
   ✅ Bài tập file upload và code assignment
   ✅ Quiz trắc nghiệm tự động
   ✅ Video upload và streaming
   ✅ Điểm danh QR Code
   ✅ Forum và chat realtime
   ✅ Video call 1-1 và nhóm
   ✅ Thông báo in-app và email
   ✅ Dashboard và báo cáo

2. **Nền tảng:**
   ✅ Web app (Chrome, Firefox, Safari, Edge)
   ✅ Android app (Android 7.0+)
   ✅ iOS app (iOS 12.0+)

3. **Ngôn ngữ lập trình được hỗ trợ (Code Assignment):**
   ✅ Python 3
   ✅ Java
   ✅ C++
   ✅ JavaScript (Node.js)
   ✅ C

4. **Triển khai:**
   ✅ Backend trên Render cloud platform
   ✅ Database trên MongoDB Atlas
   ✅ Email service qua Brevo/Nodemailer
   ✅ Code execution qua Judge0 API

#### B. Phạm vi không bao gồm (Out of Scope)
❌ Tích hợp với hệ thống quản lý học sinh của trường (SIS)
❌ Payment gateway cho các khóa học trả phí
❌ AI-based plagiarism detection
❌ Advanced analytics với Machine Learning
❌ Mobile offline mode đầy đủ
❌ Multi-language interface (chỉ hỗ trợ tiếng Việt/Anh cơ bản)
❌ SCORM/LTI compliance
❌ Native desktop applications (Windows/Mac executable)

#### C. Giới hạn kỹ thuật
- **File upload**: Tối đa 500MB per file
- **Video streaming**: Sử dụng GridFS (không có adaptive bitrate streaming)
- **Concurrent users**: Tối ưu cho ~100 users đồng thời
- **Code execution**: Giới hạn bởi Judge0 free tier (50 requests/day) hoặc paid plan
- **Video call**: Sử dụng Agora free tier (10,000 minutes/month)

---

## 1.4. PHƯƠNG PHÁP NGHIÊN CỨU (RESEARCH METHODS)

### 1.4.1. Nghiên cứu lý thuyết (Theoretical Research)

#### A. Nghiên cứu tài liệu
1. **Sách và giáo trình**
   - Giáo trình về Công nghệ Phần mềm
   - Sách về Design Patterns
   - Tài liệu về Web Application Development

2. **Tài liệu kỹ thuật**
   - Flutter documentation (flutter.dev)
   - Node.js và Express.js documentation
   - MongoDB documentation
   - Socket.IO documentation
   - Agora RTC documentation
   - Judge0 API documentation

3. **Bài báo và nghiên cứu**
   - Các bài báo về E-Learning systems
   - Nghiên cứu về code auto-grading
   - Best practices trong web development

#### B. Phân tích hệ thống tương tự
Nghiên cứu các nền tảng E-Learning hiện có:
1. **Google Classroom**
   - Ưu điểm: Đơn giản, tích hợp Google Suite, miễn phí
   - Nhược điểm: Thiếu tính năng đặc thù cho CNTT (code editor, auto-grading)

2. **Moodle**
   - Ưu điểm: Open-source, nhiều tính năng, cộng đồng lớn
   - Nhược điểm: Giao diện cũ, khó sử dụng, khó tùy chỉnh

3. **Udemy/Coursera**
   - Ưu điểm: Giao diện đẹp, trải nghiệm tốt
   - Nhược điểm: Tập trung vào MOOCs, không phù hợp cho quản lý lớp học

4. **CodeSignal/HackerRank**
   - Ưu điểm: Code editor xuất sắc, auto-grading tốt
   - Nhược điểm: Chỉ tập trung vào coding, thiếu tính năng quản lý khóa học

**Kết luận**: Cần xây dựng hệ thống kết hợp ưu điểm của các nền tảng trên, với các tính năng đặc thù cho đào tạo CNTT.

#### C. Nghiên cứu công nghệ
1. **So sánh các framework frontend**
   - React Native vs Flutter vs Native
   - Kết luận: Chọn Flutter vì cross-platform hiệu quả, performance tốt

2. **So sánh các backend framework**
   - Express.js vs NestJS vs Django
   - Kết luận: Chọn Express.js vì nhẹ, linh hoạt, ecosystem lớn

3. **So sánh databases**
   - MongoDB vs PostgreSQL vs MySQL
   - Kết luận: Chọn MongoDB vì flexible schema, phù hợp với agile development

### 1.4.2. Nghiên cứu thực nghiệm (Experimental Research)

#### A. Phát triển theo mô hình Agile
1. **Sprint Planning**
   - Chia dự án thành các sprint 1-2 tuần
   - Xác định requirements và priorities

2. **Development**
   - Phát triển features theo độ ưu tiên
   - Daily code review và testing

3. **Testing & Feedback**
   - Unit testing, integration testing
   - User acceptance testing (UAT)
   - Thu thập feedback và cải thiện

#### B. Phương pháp phát triển
1. **Backend Development**
   - Thiết kế RESTful API theo chuẩn
   - Test API với Postman
   - Viết unit tests cho các route quan trọng

2. **Frontend Development**
   - Xây dựng UI theo Material Design
   - Responsive design cho nhiều màn hình
   - Test trên nhiều thiết bị (Android, iOS, Web)

3. **Integration**
   - Tích hợp frontend với backend API
   - Tích hợp third-party services (Judge0, Agora)
   - Test end-to-end scenarios

4. **Deployment**
   - Setup CI/CD pipeline
   - Deploy lên production environment
   - Monitor và fix bugs

#### C. Thử nghiệm và đánh giá
1. **Performance Testing**
   - Load testing với nhiều users đồng thời
   - Đo response time của các API
   - Tối ưu queries và indexes

2. **Security Testing**
   - Test authentication và authorization
   - Kiểm tra input validation
   - Test SQL injection, XSS attacks

3. **Usability Testing**
   - Thu thập feedback từ users
   - Đo time-to-complete các tasks
   - Đánh giá satisfaction score

### 1.4.3. Phương pháp đánh giá (Evaluation Methods)

#### A. Đánh giá chức năng
Sử dụng **Checklist** để kiểm tra các yêu cầu chức năng:
- ✅ Đã implement đầy đủ tính năng theo requirements
- ✅ Các tính năng hoạt động đúng theo mô tả
- ✅ Edge cases được xử lý properly

#### B. Đánh giá phi chức năng
1. **Performance**
   - API response time < 500ms (95th percentile)
   - Page load time < 3 seconds
   - Video streaming without buffering

2. **Scalability**
   - Hỗ trợ ít nhất 100 concurrent users
   - Database có thể scale horizontally

3. **Reliability**
   - Uptime > 99%
   - Data backup hàng ngày
   - Error handling và recovery

4. **Usability**
   - Giao diện trực quan, dễ sử dụng
   - Đáp ứng accessibility standards
   - Mobile-friendly

5. **Security**
   - Authentication với JWT
   - Authorization cho từng resource
   - HTTPS cho tất cả connections
   - Input validation và sanitization

#### C. Đánh giá từ người dùng
Thu thập feedback thông qua:
- Surveys (Google Forms)
- User interviews
- Analytics data (Google Analytics)
- Error logs và user reports

---

## 1.5. Ý NGHĨA NGHIÊN CỨU (RESEARCH SIGNIFICANCE)

### 1.5.1. Ý nghĩa lý luận

#### A. Đóng góp về mặt học thuật
1. **Áp dụng công nghệ mới**
   - Nghiên cứu và ứng dụng Flutter cho mobile development
   - Áp dụng microservices architecture pattern
   - Sử dụng NoSQL database cho flexible schema

2. **Giải quyết bài toán thực tế**
   - Automated code grading với Judge0
   - Real-time communication với WebRTC
   - Scalable file storage với GridFS

3. **Mô hình hóa hệ thống**
   - Use case diagrams
   - Sequence diagrams
   - ER diagrams
   - System architecture design

#### B. Kiến thức và kỹ năng đạt được
1. **Kiến thức chuyên môn**
   - Full-stack development (Frontend + Backend)
   - Database design và optimization
   - RESTful API design
   - Real-time communication protocols
   - Cloud deployment và DevOps

2. **Kỹ năng mềm**
   - Phân tích và thiết kế hệ thống
   - Quản lý dự án (Agile/Scrum)
   - Làm việc nhóm và communication
   - Problem-solving và debugging

### 1.5.2. Ý nghĩa thực tiễn

#### A. Đối với sinh viên
1. **Cải thiện trải nghiệm học tập**
   - Học tập mọi lúc, mọi nơi
   - Xem lại bài giảng nhiều lần
   - Luyện tập code với feedback tức thì
   - Tương tác với giảng viên dễ dàng hơn

2. **Nâng cao hiệu quả học tập**
   - Theo dõi tiến độ học tập cá nhân
   - Nhận thông báo về bài tập, deadline
   - Tham gia forum để học hỏi lẫn nhau

#### B. Đối với giảng viên
1. **Tiết kiệm thời gian**
   - Chấm bài tự động (quiz, code assignment)
   - Quản lý lớp học điện tử
   - Gửi thông báo hàng loạt

2. **Nâng cao chất lượng giảng dạy**
   - Theo dõi tiến độ từng sinh viên
   - Phân tích điểm yếu, điểm mạnh
   - Hỗ trợ sinh viên kịp thời

3. **Quản lý hiệu quả**
   - Tạo ngân hàng câu hỏi
   - Tái sử dụng tài liệu giảng dạy
   - Thống kê và báo cáo tự động

#### C. Đối với nhà trường
1. **Quản lý tập trung**
   - Quản lý người dùng, khóa học, học kỳ
   - Thống kê toàn diện về đào tạo
   - Đảm bảo chất lượng giảng dạy

2. **Tối ưu hóa nguồn lực**
   - Giảm chi phí giảng dạy
   - Tăng số lượng sinh viên có thể tiếp cận
   - Linh hoạt về mặt bằng

3. **Đáp ứng chuyển đổi số**
   - Theo xu hướng Education 4.0
   - Chuẩn bị cho tương lai giáo dục
   - Nâng cao uy tín và thương hiệu

#### D. Đối với cộng đồng
1. **Mã nguồn mở (nếu có)**
   - Chia sẻ kiến thức cho cộng đồng
   - Góp phần phát triển giáo dục Việt Nam

2. **Mô hình có thể nhân rộng**
   - Áp dụng cho các trường khác
   - Mở rộng cho các ngành học khác
   - Customize theo nhu cầu cụ thể

### 1.5.3. Triển vọng phát triển

#### A. Ngắn hạn (6-12 tháng)
- Deploy chính thức tại khoa CNTT
- Thu thập feedback và cải thiện
- Training cho giảng viên và sinh viên

#### B. Trung hạn (1-2 năm)
- Mở rộng cho toàn trường
- Thêm nhiều tính năng nâng cao
- Tích hợp với hệ thống quản lý sinh viên hiện có

#### C. Dài hạn (>2 năm)
- Thương mại hóa sản phẩm
- Mở rộng ra các trường khác
- Phát triển thành startup EdTech

---

**Kết luận Chương 1:**

Đề tài "Hệ thống Quản lý Học tập Trực tuyến cho Ngành Công nghệ Thông tin" được chọn dựa trên nhu cầu thực tế của giáo dục hiện đại và xu hướng chuyển đổi số. Với mục tiêu xây dựng một nền tảng E-Learning hoàn chỉnh, đề tài có ý nghĩa cả về mặt lý luận và thực tiễn, góp phần cải thiện chất lượng giảng dạy và học tập ngành Công nghệ Thông tin.

Các chương tiếp theo sẽ trình bày chi tiết về tổng quan, công nghệ sử dụng, thiết kế hệ thống, implementation và deployment.

---
