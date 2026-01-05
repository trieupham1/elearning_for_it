# LUẬN VĂN TỐT NGHIỆP - HỆ THỐNG E-LEARNING MANAGEMENT

## 📚 Thông tin luận văn

**Đề tài:** E-learning system to train IT staff for businesses (Hệ thống E-Learning đào tạo nhân viên IT cho doanh nghiệp)

**Sinh viên thực hiện:**  
- PHAM QUOC TRIEU - 522K0010  
- NGUYEN HUYNH THANH HUNG - 522K0006  

**Lớp:** 22K50201  
**Khoa:** Công nghệ Thông tin  
**Trường:** Ton Duc Thang University  
**Giảng viên hướng dẫn:** PH.D PHU TRAN TIN  
**Năm:** 2025

---

## 📁 Cấu trúc luận văn

Luận văn được chia thành **13 files** tổng cộng **236 KB**:

### Phần mở đầu (Front Matter)
- ✅ **00_FRONT_MATTER.md** (5.1 KB) - Trang bìa, lời cảm ơn, tóm tắt
- ✅ **01_TABLE_OF_CONTENTS.md** (6.0 KB) - Mục lục chi tiết 7 chương
- ✅ **02_LIST_OF_FIGURES_TABLES.md** (9.6 KB) - Danh sách 50+ hình vẽ, 30+ bảng biểu
- ✅ **03_ABBREVIATIONS.md** (4.4 KB) - Danh mục thuật ngữ viết tắt

### Nội dung chính (Main Chapters)
- ✅ **CHAPTER_01_INTRODUCTION.md** (18.1 KB)
  - Lý do chọn đề tài
  - Mục tiêu nghiên cứu
  - Đối tượng và phạm vi
  - Phương pháp nghiên cứu
  - Cấu trúc luận văn

- ✅ **CHAPTER_02_OVERVIEW.md** (28.3 KB)
  - Tình hình nghiên cứu
  - Các giải pháp tương tự
  - Giải pháp đề xuất
  - Kế hoạch thực hiện
  - 141 use cases chi tiết

- ✅ **CHAPTER_03_TECHNOLOGY.md** (37.4 KB)
  - Flutter 3.5.0 (Frontend)
  - Node.js 18 + Express 4.18 (Backend)
  - MongoDB 7.x (Database)
  - Socket.IO, Judge0, Agora RTC
  - So sánh công nghệ

- ✅ **CHAPTER_04_SYSTEM_DESIGN.md** (31.2 KB)
  - Kiến trúc hệ thống
  - Use case diagrams (5 AI prompts)
  - 10 use case specifications chi tiết
  - Sequence diagrams (4 AI prompts)
  - ERD với 24 collections

- ✅ **CHAPTER_05_IMPLEMENTATION.md** (24.2 KB)
  - 24+ giao diện với mô tả chi tiết
  - 35+ API endpoints documentation
  - Code examples (Authentication, Grading, Judge0)
  - Database implementation
  - Frontend services

- ✅ **CHAPTER_06_DEPLOYMENT.md** (23.4 KB)
  - Render.com (Backend hosting)
  - MongoDB Atlas (Database cloud)
  - GitHub Pages (Web hosting)
  - APK distribution (Mobile)
  - External services setup
  - Testing và monitoring

- ✅ **CHAPTER_07_CONCLUSION.md** (17.8 KB)
  - Đánh giá hoàn thành 100% mục tiêu
  - Testing results (75% coverage)
  - Performance benchmarks
  - Khó khăn và bài học
  - Ưu điểm và hạn chế
  - Hướng phát triển (AI, Microservices, VR)

### Phần kết (Back Matter)
- ✅ **REFERENCES.md** (11.3 KB) - 80 tài liệu tham khảo (APA format)
- ✅ **APPENDICES.md** (19.2 KB) - Mã nguồn, schemas, API examples, deployment scripts

---

## 📊 Thống kê

**Tổng số trang ước tính:** ~120-150 trang (khi format A4)

**Tổng số từ:** ~45,000 từ

**Thống kê nội dung:**
- 7 chương chính
- 50+ hình vẽ (diagrams, screenshots)
- 30+ bảng biểu
- 80 tài liệu tham khảo
- 141 use cases
- 35+ API endpoints
- 24 database collections
- 40+ màn hình UI

---

## 🔧 Tech Stack của hệ thống

**Frontend:**
- Flutter 3.5.0 (Dart)
- Material Design 3
- 70+ packages (dio, socket_io_client, agora_rtc_engine, etc.)

**Backend:**
- Node.js 18 LTS
- Express.js 4.18
- Socket.IO 4.8
- JWT authentication

**Database:**
- MongoDB 7.x
- Mongoose ODM
- GridFS (file storage)

**External Services:**
- Judge0 CE (code execution)
- Agora RTC 6.3 (video calling)
- Brevo (email notifications)

**Deployment:**
- Render.com (backend)
- MongoDB Atlas (database)
- GitHub Pages (web frontend)
- APK (mobile)

---

## 📖 Hướng dẫn sử dụng

### 1. Đọc luận văn theo thứ tự

```
00_FRONT_MATTER.md
├─ 01_TABLE_OF_CONTENTS.md
├─ 02_LIST_OF_FIGURES_TABLES.md
├─ 03_ABBREVIATIONS.md
│
├─ CHAPTER_01_INTRODUCTION.md
├─ CHAPTER_02_OVERVIEW.md
├─ CHAPTER_03_TECHNOLOGY.md
├─ CHAPTER_04_SYSTEM_DESIGN.md
├─ CHAPTER_05_IMPLEMENTATION.md
├─ CHAPTER_06_DEPLOYMENT.md
├─ CHAPTER_07_CONCLUSION.md
│
├─ REFERENCES.md
└─ APPENDICES.md
```

### 2. Convert sang PDF (khuyến nghị)

**Sử dụng Pandoc:**
```bash
# Install Pandoc
# Windows: choco install pandoc
# Mac: brew install pandoc

# Convert tất cả chapters sang một PDF
pandoc 00_FRONT_MATTER.md 01_TABLE_OF_CONTENTS.md 02_LIST_OF_FIGURES_TABLES.md 03_ABBREVIATIONS.md CHAPTER_01_INTRODUCTION.md CHAPTER_02_OVERVIEW.md CHAPTER_03_TECHNOLOGY.md CHAPTER_04_SYSTEM_DESIGN.md CHAPTER_05_IMPLEMENTATION.md CHAPTER_06_DEPLOYMENT.md CHAPTER_07_CONCLUSION.md REFERENCES.md APPENDICES.md -o thesis.pdf --toc --number-sections --pdf-engine=xelatex
```

**Sử dụng VS Code:**
- Install extension: Markdown PDF
- Open file markdown
- Right-click → Markdown PDF: Export (pdf)

**Sử dụng Typora:**
- Open file markdown trong Typora
- File → Export → PDF

### 3. Format cho in ấn

**Khuyến nghị:**
- Font: Times New Roman, size 13 (nội dung), size 16 (tiêu đề)
- Lề: Trái 3cm, Phải 2cm, Trên 2cm, Dưới 2cm
- Giãn dòng: 1.5
- Căn lề: Justify (hai bên)

### 4. Chỉnh sửa nội dung

Mỗi file Markdown có thể edit trực tiếp:
- Thay thế `[Tên sinh viên]`, `[MSSV]`, `[Tên trường]`
- Thêm screenshots vào phần Implementation (Chapter 5)
- Update thông tin thực tế thay cho placeholder data
- Bổ sung thêm tài liệu tham khảo nếu cần

---

## 🎨 Tạo diagrams (AI Prompts included)

Luận văn có sẵn **AI prompts** để tạo diagrams:

**Chapter 2 - Use Case Diagram:**
- 5 prompts cho PlantUML/Draw.io
- Bao gồm: Student, Instructor, Admin, Code, Video

**Chapter 4 - Detailed Diagrams:**
- 5 Use Case diagrams chi tiết
- 4 Sequence diagrams (Login, Submit, Quiz, Auto-grade)
- 1 ERD với 24 collections

**Tools để vẽ:**
- PlantUML (code → diagram)
- Draw.io / Diagrams.net (drag-drop)
- Lucidchart (online)
- dbdiagram.io (ERD)

---

## ✅ Checklist trước khi nộp

- [x] Thay thế tất cả placeholders (✅ Đã hoàn thành)
- [ ] Thêm screenshots thực tế vào Chapter 5
- [ ] Vẽ tất cả diagrams từ AI prompts
- [ ] Kiểm tra lỗi chính tả và ngữ pháp
- [ ] Format đúng chuẩn trường quy định
- [ ] Đánh số trang
- [ ] Tạo Table of Contents tự động (nếu dùng Word)
- [ ] In thử một bản để kiểm tra layout
- [ ] Xin chữ ký giảng viên hướng dẫn
- [ ] Đóng quyển và nộp

---

## 📞 Liên hệ và hỗ trợ

**Repository:** https://github.com/yourusername/elearning_for_it

**Documentation:** `elearningit/docs/`

**Demo:** https://yourusername.github.io/elearning_for_it/

**Contact:** Ton Duc Thang University - Faculty of Information Technology

---

## 📝 License

Đồ án này được cung cấp dưới **MIT License** cho phần mã nguồn hệ thống.

Nội dung đồ án (văn bản, diagrams) thuộc bản quyền của sinh viên và Ton Duc Thang University.

---

## 🙏 Lời cảm ơn

Đồ án này được hoàn thành nhờ sự hướng dẫn tận tình của:
- Giảng viên hướng dẫn: PH.D PHU TRAN TIN
- Khoa Công nghệ Thông tin - Ton Duc Thang University
- Gia đình và bạn bè

---

**Ngày hoàn thành:** 01/2025  
**Phiên bản:** 1.0  
**Status:** ✅ HOÀN THÀNH

---
