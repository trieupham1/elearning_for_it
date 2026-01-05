# CHƯƠNG 3: TÌM HIỂU CÔNG NGHỆ (TECHNOLOGY REVIEW)

## 3.1. CÔNG NGHỆ FRONT-END (FRONTEND TECHNOLOGIES)

### 3.1.1. Flutter Framework

#### A. Giới thiệu
Flutter là một UI toolkit mã nguồn mở được Google phát triển để tạo ứng dụng đa nền tảng (cross-platform) từ một codebase duy nhất. Ra mắt năm 2017, Flutter sử dụng ngôn ngữ lập trình Dart và có thể chạy trên Android, iOS, Web, Windows, macOS và Linux.

**Hình 3.1: Flutter Architecture**
```
┌─────────────────────────────────────┐
│     Flutter Application Code       │
│        (Dart Language)              │
├─────────────────────────────────────┤
│       Flutter Framework             │
│  (Widgets, Rendering, Animation)    │
├─────────────────────────────────────┤
│         Flutter Engine              │
│  (Skia Graphics, Dart Runtime)      │
├─────────────────────────────────────┤
│      Platform Specific Code         │
│   (Android, iOS, Web, Desktop)      │
└─────────────────────────────────────┘
```

#### B. Đặc điểm chính

**1. Single Codebase**
- Viết một lần, chạy mọi nơi (Android, iOS, Web, Desktop)
- Giảm thời gian phát triển 50-60%
- Maintain dễ dàng hơn

**2. Hot Reload**
- Thay đổi code và xem kết quả ngay lập tức
- Không mất state của ứng dụng
- Tăng productivity của developer

**3. Widget-based Architecture**
- Mọi thứ đều là Widget
- Reusable components
- Composition over inheritance

**4. High Performance**
- Compile ra native code (ARM)
- 60fps, 120fps smooth animations
- Gần performance của native app

**5. Rich Widget Library**
- Material Design widgets (Android style)
- Cupertino widgets (iOS style)
- Custom widgets dễ tạo

**6. Dart Language**
- Strong typing với type inference
- Async/await cho asynchronous programming
- Null safety
- AOT & JIT compilation

#### C. Ưu điểm và nhược điểm

**Bảng 3.1: So sánh các Framework Frontend**

| Tiêu chí | Flutter | React Native | Native (Swift/Kotlin) |
|----------|---------|--------------|----------------------|
| **Performance** | 9/10 (gần native) | 7/10 (bridge overhead) | 10/10 |
| **Development Speed** | 9/10 (hot reload, 1 codebase) | 8/10 (hot reload, JS) | 5/10 (2 codebases) |
| **UI Consistency** | 10/10 (pixel-perfect) | 7/10 (native components) | 10/10 (native) |
| **Learning Curve** | 7/10 (learn Dart) | 8/10 (JavaScript) | 6/10 (2 languages) |
| **Community** | 8/10 (growing fast) | 9/10 (mature) | 10/10 (official) |
| **Package Ecosystem** | 8/10 (pub.dev) | 9/10 (npm) | 9/10 (official SDKs) |
| **Code Reuse** | 95% | 90% | 0% |
| **App Size** | Medium (15-20MB) | Medium (15-20MB) | Small (5-10MB) |
| **Platform Support** | Android, iOS, Web, Desktop | Android, iOS, Web | Android OR iOS |
| **Testing** | Excellent (widget tests) | Good (Jest) | Excellent (XCTest/JUnit) |

**✅ Ưu điểm:**
1. **Cross-platform hiệu quả**: 1 codebase cho tất cả platforms
2. **Performance cao**: Gần native app performance
3. **Hot reload**: Developer experience tuyệt vời
4. **UI đẹp và nhất quán**: Pixel-perfect trên mọi thiết bị
5. **Fast development**: Giảm 50% thời gian phát triển
6. **Strong typing**: Dart language với null safety
7. **Rich widgets**: Material và Cupertino widgets có sẵn
8. **Growing ecosystem**: Packages trên pub.dev tăng nhanh
9. **Backed by Google**: Support và update liên tục
10. **Documentation tốt**: flutter.dev có tài liệu đầy đủ

**❌ Nhược điểm:**
1. **Learning curve**: Phải học Dart (ngôn ngữ mới)
2. **App size lớn hơn native**: ~15-20MB minimum
3. **Native features**: Một số tính năng native cần plugin
4. **Ecosystem chưa mature như React Native**: Một số packages còn thiếu
5. **Web performance**: Chưa tốt bằng React/Vue cho web
6. **Platform-specific code**: Vẫn cần viết platform channels cho một số tính năng

#### D. Tại sao chọn Flutter cho dự án này?

**Lý do lựa chọn:**
1. ✅ **Cross-platform requirement**: Cần hỗ trợ Android, iOS, Web
2. ✅ **Time constraint**: 5 tháng để hoàn thành
3. ✅ **Performance**: Cần smooth animations và fast loading
4. ✅ **UI consistency**: Cần giao diện nhất quán trên mọi platform
5. ✅ **Material Design**: Phù hợp với design system của dự án
6. ✅ **Learning opportunity**: Sinh viên muốn học công nghệ mới

#### E. Các package Flutter sử dụng trong dự án

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # HTTP & API
  http: ^1.2.0                      # HTTP client
  
  # State Management
  provider: ^6.1.2                  # State management
  
  # Storage
  shared_preferences: ^2.2.2        # Local storage
  path_provider: ^2.1.2             # File paths
  
  # Serialization
  json_annotation: ^4.8.1           # JSON serialization
  
  # File Handling
  file_picker: ^8.0.0+1             # File picker
  csv: ^6.0.0                       # CSV parsing
  
  # UI Components
  cupertino_icons: ^1.0.8           # iOS icons
  timeago: ^3.7.0                   # Time formatting
  intl: ^0.19.0                     # Internationalization
  
  # Real-time Communication
  socket_io_client: ^3.1.2          # WebSocket client
  agora_rtc_engine: ^6.3.2          # Video calling
  
  # Media
  image_picker: ^1.2.0              # Image picker
  video_player: ^2.10.0             # Video player
  chewie: ^1.12.0                   # Video player controls
  
  # QR Code & Scanning
  qr_flutter: ^4.1.0                # QR code generator
  mobile_scanner: ^5.0.0            # QR scanner
  
  # Location
  geolocator: ^12.0.0               # GPS location
  permission_handler: ^11.0.0       # Permissions
  
  # Code Editor
  flutter_code_editor: ^0.3.0       # Code editor
  flutter_highlight: ^0.7.0         # Syntax highlighting
  
  # Charts & Analytics
  fl_chart: ^0.68.0                 # Charts
  
  # UI Enhancements
  cached_network_image: ^3.3.0      # Image caching
  photo_view: ^0.14.0               # Image viewer
  flutter_staggered_animations: ^1.1.1  # Animations
  shimmer: ^3.0.0                   # Shimmer effect
  lottie: ^3.1.0                    # Lottie animations
  
  # Utilities
  url_launcher: ^6.2.5              # Open URLs
  share_plus: ^7.2.2                # Share content
  connectivity_plus: ^6.0.5         # Network status
```

---

## 3.2. CÔNG NGHỆ BACK-END (BACKEND TECHNOLOGIES)

### 3.2.1. Node.js và Express.js

#### A. Node.js

**Giới thiệu:**
Node.js là một runtime environment cho phép chạy JavaScript code phía server. Ra mắt năm 2009 bởi Ryan Dahl, Node.js sử dụng V8 JavaScript engine của Google Chrome.

**Hình 3.2: Node.js Event Loop**
```
   ┌───────────────────────────┐
┌─>│           timers          │
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
│  │     pending callbacks     │
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
│  │       idle, prepare       │
│  └─────────────┬─────────────┘      ┌───────────────┐
│  ┌─────────────▼─────────────┐      │   incoming:   │
│  │           poll            │<─────┤  connections, │
│  └─────────────┬─────────────┘      │   data, etc.  │
│  ┌─────────────▼─────────────┐      └───────────────┘
│  │           check           │
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
└──┤      close callbacks      │
   └───────────────────────────┘
```

**Đặc điểm:**
1. **Non-blocking I/O**: Xử lý nhiều requests đồng thời
2. **Event-driven**: Callback-based architecture
3. **Single-threaded**: Một thread nhưng handle nhiều connections
4. **Fast**: V8 engine compile JS sang machine code
5. **NPM**: Package manager lớn nhất thế giới (2M+ packages)

#### B. Express.js

**Giới thiệu:**
Express.js là web framework minimalist và linh hoạt nhất cho Node.js. Ra mắt năm 2010, Express giúp xây dựng web applications và APIs dễ dàng.

**Đặc điểm:**
1. **Minimalist**: Không áp đặt structure, developer tự do chọn
2. **Middleware**: Chain of functions để xử lý requests
3. **Routing**: Define routes dễ dàng
4. **Fast**: Overhead thấp, performance cao
5. **Flexible**: Tích hợp dễ với các thư viện khác

**Example Express Server:**
```javascript
const express = require('express');
const app = express();

// Middleware
app.use(express.json());

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(5000, () => {
  console.log('Server running on port 5000');
});
```

#### C. Ưu điểm và nhược điểm

**Bảng 3.2: So sánh các Backend Framework**

| Tiêu chí | Express.js | NestJS | Django | Spring Boot |
|----------|------------|--------|--------|-------------|
| **Language** | JavaScript | TypeScript | Python | Java |
| **Learning Curve** | 7/10 (dễ) | 6/10 (phức tạp hơn) | 7/10 (Python dễ) | 5/10 (Java khó) |
| **Performance** | 9/10 | 9/10 | 7/10 | 8/10 |
| **Flexibility** | 10/10 | 7/10 | 6/10 | 6/10 |
| **Structure** | Minimal | Opinionated | Opinionated | Opinionated |
| **Ecosystem** | 10/10 (NPM) | 9/10 (NPM) | 8/10 (PyPI) | 8/10 (Maven) |
| **Real-time** | Excellent (Socket.IO) | Excellent | Good | Good |
| **RESTful API** | Excellent | Excellent | Excellent | Excellent |
| **ORM** | Mongoose, Sequelize | TypeORM | Django ORM | JPA/Hibernate |
| **Async/Await** | Yes | Yes | Yes | Limited |
| **Community** | Huge | Growing | Huge | Huge |

**✅ Ưu điểm Node.js + Express:**
1. **JavaScript everywhere**: Cùng ngôn ngữ frontend & backend
2. **Fast development**: Viết code nhanh, ít boilerplate
3. **NPM ecosystem**: 2M+ packages
4. **Non-blocking I/O**: Handle nhiều requests đồng thời
5. **Real-time**: Socket.IO tích hợp dễ dàng
6. **JSON native**: Perfect cho RESTful APIs
7. **Scalability**: Horizontal scaling dễ dàng
8. **Microservices friendly**: Lightweight, fast startup
9. **Community lớn**: Nhiều tutorials, stackoverflow answers
10. **Modern JavaScript**: ES6+, async/await

**❌ Nhược điểm:**
1. **Callback hell**: Nếu không dùng async/await
2. **Lack of structure**: Cần tự tổ chức code
3. **Single-threaded**: CPU-intensive tasks block event loop
4. **Immature ORM**: Không mạnh bằng Django ORM hoặc Hibernate
5. **Type safety**: JavaScript không có static typing (dùng TypeScript để khắc phục)

#### D. Tại sao chọn Express.js?

1. ✅ **JavaScript expertise**: Team quen với JavaScript
2. ✅ **Fast development**: Deadline ngắn (5 tháng)
3. ✅ **Real-time needs**: Socket.IO cho chat và notifications
4. ✅ **RESTful API**: Express perfect cho REST APIs
5. ✅ **Lightweight**: Không cần framework nặng
6. ✅ **Flexible**: Tự do structure theo ý muốn
7. ✅ **NPM packages**: Tận dụng ecosystem lớn

### 3.2.2. RESTful API Architecture

#### A. Khái niệm REST

REST (Representational State Transfer) là một architectural style cho distributed systems. RESTful API sử dụng HTTP methods để thực hiện CRUD operations.

**Hình 3.3: RESTful API Request Flow**
```
Client                   Server                Database
  │                        │                       │
  │  GET /api/courses      │                       │
  ├───────────────────────>│                       │
  │                        │  Query courses        │
  │                        ├──────────────────────>│
  │                        │  Return data          │
  │                        │<──────────────────────┤
  │  200 OK + JSON data    │                       │
  │<───────────────────────┤                       │
  │                        │                       │
```

**HTTP Methods:**
- **GET**: Lấy dữ liệu (Read)
- **POST**: Tạo mới (Create)
- **PUT**: Cập nhật toàn bộ (Update)
- **PATCH**: Cập nhật một phần (Partial Update)
- **DELETE**: Xóa (Delete)

**Status Codes:**
- **200 OK**: Thành công
- **201 Created**: Tạo mới thành công
- **400 Bad Request**: Request không hợp lệ
- **401 Unauthorized**: Chưa đăng nhập
- **403 Forbidden**: Không có quyền
- **404 Not Found**: Không tìm thấy
- **500 Internal Server Error**: Lỗi server

**REST Principles:**
1. **Stateless**: Mỗi request độc lập, không lưu state
2. **Client-Server**: Tách biệt frontend và backend
3. **Cacheable**: Response có thể cache
4. **Uniform Interface**: Chuẩn hóa cách giao tiếp
5. **Layered System**: Có thể có nhiều layers (proxy, gateway)

#### B. API Design trong dự án

**Naming Convention:**
```
/api/resource              GET - List all
/api/resource/:id          GET - Get one
/api/resource              POST - Create new
/api/resource/:id          PUT - Update
/api/resource/:id          DELETE - Delete
/api/resource/:id/action   POST - Custom action
```

**Example:**
```javascript
// GET /api/courses - List all courses
router.get('/', auth, async (req, res) => {
  const courses = await Course.find({ 
    students: req.userId 
  }).populate('instructor');
  res.json(courses);
});

// POST /api/courses - Create course
router.post('/', auth, instructorOnly, async (req, res) => {
  const course = await Course.create(req.body);
  res.status(201).json(course);
});
```

### 3.2.3. Socket.IO for Real-time Communication

#### A. Giới thiệu
Socket.IO là thư viện cho real-time, bidirectional communication giữa client và server. Sử dụng WebSocket protocol với fallback về long-polling nếu WebSocket không available.

**Đặc điểm:**
1. **Real-time**: Gửi/nhận data ngay lập tức
2. **Bidirectional**: Server có thể push data tới client
3. **Event-based**: Emit và listen events
4. **Room support**: Group connections vào rooms
5. **Auto reconnection**: Tự động reconnect khi mất kết nối

**Example:**
```javascript
// Server
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('sendMessage', (message) => {
    io.to(message.recipientId).emit('newMessage', message);
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Client (Flutter)
socket.on('newMessage', (message) {
  print('New message: ${message.content}');
  updateUI(message);
});
```

#### B. Use cases trong dự án
1. **Chat messaging**: Real-time 1-1 chat
2. **Notifications**: Push notifications ngay lập tức
3. **Live updates**: Course updates, new assignments
4. **Presence**: Hiển thị users online/offline

### 3.2.4. JWT Authentication

#### A. Khái niệm
JSON Web Token (JWT) là một chuẩn mở (RFC 7519) để truyền thông tin an toàn giữa các bên dưới dạng JSON object.

**Hình 3.5: JWT Authentication Flow**
```
Client                    Server                 Database
  │                         │                        │
  │  POST /auth/login       │                        │
  ├────────────────────────>│  Verify credentials    │
  │                         ├───────────────────────>│
  │                         │  User found            │
  │                         │<───────────────────────┤
  │  JWT Token              │  Generate JWT          │
  │<────────────────────────┤                        │
  │                         │                        │
  │  GET /api/courses       │                        │
  │  Header: Bearer JWT     │                        │
  ├────────────────────────>│  Verify JWT            │
  │                         │  Extract userId        │
  │                         │  Query courses         │
  │                         ├───────────────────────>│
  │  200 OK + Data          │                        │
  │<────────────────────────┤                        │
```

**JWT Structure:**
```
header.payload.signature

Example:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJ1c2VySWQiOiI2NWY3YjJhMWQzZTRhZjAwMTJhYjM0NTYiLCJyb2xlIjoic3R1ZGVudCIsImlhdCI6MTcwOTM3MDAwMCwiZXhwIjoxNzA5NDU2NDAwfQ.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

- **Header**: Algorithm & token type
- **Payload**: User data (userId, role)
- **Signature**: Verify token integrity

**Ưu điểm:**
- ✅ Stateless: Server không cần lưu sessions
- ✅ Scalable: Dễ scale horizontal
- ✅ Mobile-friendly: Không cần cookies
- ✅ Cross-domain: CORS-friendly
- ✅ Self-contained: Chứa đủ thông tin user

**Nhược điểm:**
- ❌ Không thể revoke: Token valid cho đến khi expire
- ❌ Size lớn hơn session ID: Mỗi request gửi kèm token
- ❌ Bảo mật: Nếu token bị lộ, attacker có thể dùng cho đến khi expire

**Implementation trong dự án:**
```javascript
// Generate token
const token = jwt.sign(
  { userId: user._id, role: user.role },
  process.env.JWT_SECRET,
  { expiresIn: '24h' }
);

// Verify token middleware
const auth = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ message: 'No token' });
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.userRole = decoded.role;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};
```

---

## 3.3. CƠ SỞ DỮ LIỆU (DATABASE)

### 3.3.1. MongoDB

#### A. Giới thiệu
MongoDB là một NoSQL database, document-oriented, schema-flexible. Ra mắt năm 2009, MongoDB lưu data dưới dạng BSON (Binary JSON) documents.

**Hình 3.4: MongoDB Document Structure**
```json
{
  "_id": ObjectId("65f7b2a1d3e4af0012ab3456"),
  "username": "student123",
  "email": "student@example.com",
  "role": "student",
  "firstName": "Nguyễn",
  "lastName": "Văn A",
  "courses": [
    ObjectId("65f7b2a1d3e4af0012ab3457"),
    ObjectId("65f7b2a1d3e4af0012ab3458")
  ],
  "createdAt": ISODate("2024-01-15T10:30:00Z"),
  "updatedAt": ISODate("2024-01-15T10:30:00Z")
}
```

**Đặc điểm:**
1. **Document-oriented**: Data lưu dưới dạng documents (JSON-like)
2. **Flexible schema**: Không cần define schema trước
3. **Horizontal scaling**: Sharding support
4. **Rich queries**: Complex queries, aggregation framework
5. **Indexing**: Support nhiều loại indexes
6. **Replication**: High availability với replica sets

#### B. So sánh SQL vs NoSQL

**Bảng 3.3: So sánh các loại Database**

| Tiêu chí | MongoDB (NoSQL) | PostgreSQL (SQL) | MySQL (SQL) |
|----------|-----------------|------------------|-------------|
| **Data Model** | Document | Relational | Relational |
| **Schema** | Flexible | Fixed | Fixed |
| **Scaling** | Horizontal | Vertical | Vertical |
| **Joins** | $lookup (slow) | Fast | Fast |
| **Transactions** | Yes (4.0+) | Yes | Yes |
| **ACID** | Yes | Yes | Yes |
| **JSON Support** | Native | JSONB | JSON |
| **Learning Curve** | 7/10 | 6/10 | 7/10 |
| **Use Cases** | Flexible data, agile | Complex queries, reports | Web apps |
| **Performance** | Fast reads | Fast complex queries | Fast simple queries |

**Khi nào dùng MongoDB:**
- ✅ Schema thay đổi thường xuyên
- ✅ Agile development
- ✅ Horizontal scaling requirement
- ✅ JSON/document data
- ✅ Fast development

**Khi nào dùng SQL:**
- ✅ Complex joins nhiều
- ✅ Transactions phức tạp
- ✅ Data analytics, reporting
- ✅ Fixed schema
- ✅ ACID compliance critical

#### C. Tại sao chọn MongoDB?

1. ✅ **Flexible schema**: Requirements thay đổi trong quá trình dev
2. ✅ **JSON native**: Perfect với Express.js và Flutter
3. ✅ **Fast development**: Không cần migration scripts
4. ✅ **GridFS**: Built-in support cho file storage
5. ✅ **Aggregation framework**: Powerful queries
6. ✅ **Horizontal scaling**: Future-proof
7. ✅ **MongoDB Atlas**: Free tier để test và deploy

### 3.3.2. Mongoose ODM

#### A. Giới thiệu
Mongoose là Object Document Mapper (ODM) cho MongoDB và Node.js. Provides schema-based solution để model application data.

**Đặc điểm:**
1. **Schema definition**: Define structure cho documents
2. **Validation**: Built-in và custom validation
3. **Middleware**: Pre/post hooks
4. **Relationships**: Populate để simulate joins
5. **Type casting**: Auto-convert types
6. **Query builder**: Chainable queries

**Example Schema:**
```javascript
const courseSchema = new mongoose.Schema({
  code: { 
    type: String, 
    required: true, 
    unique: true 
  },
  name: { 
    type: String, 
    required: true 
  },
  instructor: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: true 
  },
  students: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  semester: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Semester'
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true }
});

// Index
courseSchema.index({ code: 1 });
courseSchema.index({ instructor: 1, semester: 1 });

// Virtual field
courseSchema.virtual('studentCount').get(function() {
  return this.students.length;
});

module.exports = mongoose.model('Course', courseSchema);
```

### 3.3.3. GridFS for File Storage

#### A. Giới thiệu
GridFS là specification để lưu và retrieve files lớn hơn 16MB trong MongoDB. Chia file thành chunks (255KB each) và lưu vào 2 collections: `fs.files` và `fs.chunks`.

**Structure:**
```
fs.files:
{
  "_id": ObjectId("..."),
  "filename": "video_lecture.mp4",
  "length": 52428800,  // 50MB
  "chunkSize": 261120,
  "uploadDate": ISODate("..."),
  "metadata": {
    "courseId": "...",
    "uploadedBy": "..."
  }
}

fs.chunks:
{
  "_id": ObjectId("..."),
  "files_id": ObjectId("..."),  // Reference to fs.files
  "n": 0,  // Chunk number
  "data": BinData(...)
}
```

**Ưu điểm:**
- ✅ Lưu files lớn (>16MB)
- ✅ Chunked upload: Resume nếu bị ngắt
- ✅ Streaming: Không cần load hết vào memory
- ✅ Metadata support: Store thêm thông tin
- ✅ Integrated: Trong cùng MongoDB database

**Use cases trong dự án:**
1. Video lectures (100MB - 500MB)
2. Assignment submissions (PDF, DOCX, ZIP)
3. Profile pictures
4. Course materials

---

## 3.4. CÔNG NGHỆ BỔ SUNG (ADDITIONAL TECHNOLOGIES)

### 3.4.1. Judge0 API (Code Execution)

#### A. Giới thiệu
Judge0 CE (Community Edition) là một code execution system an toàn, hỗ trợ 50+ programming languages. Sử dụng để auto-grade code assignments.

**Hình 3.7: Judge0 Code Execution Flow**
```
Student → Submit Code → Backend API
                           │
                           ▼
                    Judge0 API
                           │
                           ├─> Compile Code
                           ├─> Run Test Cases
                           ├─> Check Output
                           ├─> Calculate Score
                           │
                           ▼
                    Return Results
                           │
                           ▼
            Backend → Save to DB
                           │
                           ▼
            Student sees Results
```

**Features:**
- 50+ languages support
- Sandbox execution (secure)
- Time & memory limits
- Stdin/stdout handling
- Error handling
- Batch submissions

**Languages hỗ trợ trong dự án:**
- Python 3 (ID: 71)
- Java (ID: 62)
- C++ (ID: 54)
- JavaScript/Node.js (ID: 63)
- C (ID: 50)

**Example Request:**
```javascript
const submission = {
  source_code: "print('Hello World')",
  language_id: 71,  // Python 3
  stdin: "",
  expected_output: "Hello World\n",
  cpu_time_limit: 2,  // seconds
  memory_limit: 128000  // KB
};

const response = await axios.post(
  'https://judge0-ce.p.rapidapi.com/submissions',
  submission,
  {
    headers: {
      'X-RapidAPI-Key': process.env.JUDGE0_API_KEY
    }
  }
);
```

**Tại sao chọn Judge0:**
- ✅ Free tier available (50 requests/day)
- ✅ Secure sandbox
- ✅ Many languages
- ✅ Easy integration
- ✅ Well-documented API

### 3.4.2. Agora RTC (Video Calling)

#### A. Giới thiệu
Agora Real-Time Communication (RTC) là platform cung cấp voice và video calling APIs. Sử dụng WebRTC technology với global edge network.

**Hình 3.8: Agora RTC Architecture**
```
Participant A                     Agora SD-RTN™                    Participant B
     │                                  │                                 │
     │  Join Channel                    │                                 │
     ├─────────────────────────────────>│                                 │
     │  Generate Token                  │                                 │
     │<─────────────────────────────────┤                                 │
     │                                  │  Join Channel                   │
     │                                  │<────────────────────────────────┤
     │                                  │  Generate Token                 │
     │                                  ├────────────────────────────────>│
     │                                  │                                 │
     │  Publish Audio/Video             │                                 │
     ├─────────────────────────────────>│                                 │
     │                                  │  Subscribe & Receive            │
     │                                  ├────────────────────────────────>│
     │                                  │                                 │
     │  Subscribe & Receive             │  Publish Audio/Video            │
     │<─────────────────────────────────┤<────────────────────────────────┤
```

**Features:**
- HD video calling (1080p)
- Screen sharing
- Multiple participants
- Cross-platform (Web, iOS, Android)
- Low latency (<400ms)
- Global coverage

**Free Tier:**
- 10,000 minutes/month
- Unlimited channels
- HD quality

**Use cases trong dự án:**
1. 1-1 video call (student-instructor)
2. Group video call (course meetings)
3. Virtual classroom
4. Office hours

### 3.4.3. Email Service (Nodemailer/Brevo)

#### A. Nodemailer
Nodemailer là module để gửi emails từ Node.js applications.

**Example:**
```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

await transporter.sendMail({
  from: 'E-Learning System <noreply@elearning.com>',
  to: student.email,
  subject: 'New Assignment Posted',
  html: `
    <h2>New Assignment: ${assignment.title}</h2>
    <p>Deadline: ${assignment.deadline}</p>
    <a href="${courseUrl}">View Assignment</a>
  `
});
```

#### B. Brevo (Sendinblue)
Brevo là email marketing platform với transactional email API.

**Features:**
- 300 emails/day (free)
- Email templates
- Analytics
- SMTP relay
- High deliverability

**Use cases:**
- Welcome emails
- Password reset emails
- Assignment notifications
- Quiz reminders
- Announcement notifications

---

## 3.5. KIẾN TRÚC TỔNG THỂ (OVERALL ARCHITECTURE)

### 3.5.1. System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    CLIENT TIER (Presentation)                 │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐         │
│  │   Android   │  │     iOS     │  │     Web      │         │
│  │     App     │  │     App     │  │     App      │         │
│  │  (Flutter)  │  │  (Flutter)  │  │  (Flutter)   │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘         │
│         │                 │                 │                 │
└─────────┼─────────────────┼─────────────────┼─────────────────┘
          │                 │                 │
          └────────────┬────┴────────────┬────┘
                       │                 │
          HTTPS/WSS    │                 │   REST API / WebSocket
                       │                 │
┌──────────────────────▼─────────────────▼─────────────────────┐
│                    APPLICATION TIER (Logic)                    │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │              Node.js + Express.js Server              │    │
│  ├───────────────────────────────────────────────────────┤    │
│  │                                                         │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │    │
│  │  │   Auth   │  │  Course  │  │Assignment│            │    │
│  │  │ Service  │  │ Service  │  │ Service  │   ...      │    │
│  │  └──────────┘  └──────────┘  └──────────┘            │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────┐      │    │
│  │  │         Middleware Layer                     │      │    │
│  │  │  - Authentication (JWT)                      │      │    │
│  │  │  - Authorization (RBAC)                      │      │    │
│  │  │  - Validation                                │      │    │
│  │  │  - Error Handling                            │      │    │
│  │  │  - Logging                                   │      │    │
│  │  └─────────────────────────────────────────────┘      │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────┐      │    │
│  │  │         Socket.IO Server (Real-time)        │      │    │
│  │  │  - Chat                                      │      │    │
│  │  │  - Notifications                             │      │    │
│  │  │  - Live Updates                              │      │    │
│  │  └─────────────────────────────────────────────┘      │    │
│  │                                                         │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
└───────┬──────────────┬──────────────┬──────────────┬──────────┘
        │              │              │              │
┌───────▼──────┐ ┌────▼─────┐ ┌──────▼──────┐ ┌────▼─────┐
│   MongoDB    │ │  Judge0  │ │    Agora    │ │  Email   │
│   Database   │ │    API   │ │     RTC     │ │ Service  │
│   + GridFS   │ │          │ │             │ │  (Brevo) │
└──────────────┘ └──────────┘ └─────────────┘ └──────────┘
```

### 3.5.2. Technology Stack Summary

**Frontend:**
- **Framework**: Flutter 3.5.0
- **Language**: Dart
- **State Management**: Provider
- **UI**: Material Design 3

**Backend:**
- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.18
- **Language**: JavaScript (ES6+)
- **Real-time**: Socket.IO 4.8

**Database:**
- **Primary**: MongoDB 7.x
- **ORM**: Mongoose 7.6
- **File Storage**: GridFS

**Third-party:**
- **Code Execution**: Judge0 CE API
- **Video Call**: Agora RTC 6.3
- **Email**: Brevo (Sendinblue)

**DevOps:**
- **Version Control**: Git + GitHub
- **Backend Hosting**: Render.com
- **Database Hosting**: MongoDB Atlas
- **CI/CD**: GitHub Actions

---

**Kết luận Chương 3:**

Chương này đã trình bày chi tiết các công nghệ được sử dụng trong dự án. Flutter được chọn cho frontend vì khả năng cross-platform và performance cao. Node.js/Express.js được chọn cho backend vì fast development và real-time support. MongoDB được chọn vì flexible schema phù hợp với agile development. Các third-party services (Judge0, Agora, Brevo) giúp tiết kiệm thời gian và tập trung vào core features. Kiến trúc tổng thể theo mô hình Client-Server với RESTful API và WebSocket cho real-time communication.

Chương tiếp theo sẽ trình bày thiết kế chi tiết của hệ thống, bao gồm Use Case diagrams, Sequence diagrams, Activity diagrams và ERD.

---
