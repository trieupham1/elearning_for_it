# Backend API Integration Guide

This document provides complete details for integrating the Flutter frontend with the backend APIs.

## Base URL
- Local Development: `http://localhost:5000/api`

## Authentication
All API requests (except `/auth/login` and `/auth/register`) require an authentication token in the header:
```
Authorization: Bearer <token>
```

---

## 📢 Announcements API

### 1. Get Announcements by Course
**GET** `/announcements?courseId=<courseId>`

**Response:**
```json
[
  {
    "_id": "...",
    "courseId": "...",
    "title": "Week 1 Assignment",
    "content": "Please submit your assignment by Friday",
    "authorId": "...",
    "authorName": "Dr. Smith",
    "authorAvatar": "https://...",
    "comments": [
      {
        "userId": "...",
        "userName": "John Doe",
        "userAvatar": "https://...",
        "text": "Thank you!",
        "createdAt": "2024-01-15T10:30:00Z"
      }
    ],
    "attachments": [],
    "createdAt": "2024-01-15T08:00:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  }
]
```

### 2. Create Announcement (Instructor Only)
**POST** `/announcements`

**Request Body:**
```json
{
  "courseId": "...",
  "title": "Week 1 Assignment",
  "content": "Please submit your assignment by Friday",
  "groupIds": [],
  "attachments": []
}
```

### 3. Add Comment to Announcement
**POST** `/announcements/:id/comments`

**Request Body:**
```json
{
  "text": "Thank you for the announcement!"
}
```

**Response:** Returns the updated announcement with all comments

---

## 📚 Classwork API

### 1. Get All Classwork for a Course
**GET** `/classwork/course/:courseId?search=<query>&filter=<type>`

**Query Parameters:**
- `search` (optional): Search term for filtering by title/description
- `filter` (optional): `assignments`, `quizzes`, or `materials`

**Response:**
```json
[
  {
    "_id": "...",
    "type": "assignment",
    "courseId": "...",
    "title": "HTML & CSS Basics",
    "description": "Complete the exercises...",
    "deadline": "2024-01-20T23:59:00Z",
    "maxAttempts": 1,
    "allowLateSubmission": false,
    "createdAt": "2024-01-15T08:00:00Z"
  },
  {
    "_id": "...",
    "type": "quiz",
    "courseId": "...",
    "title": "JavaScript Quiz",
    "description": "Test your knowledge...",
    "openDate": "2024-01-15T00:00:00Z",
    "closeDate": "2024-01-20T23:59:00Z",
    "duration": 3600,
    "maxAttempts": 2,
    "createdAt": "2024-01-15T08:00:00Z"
  },
  {
    "_id": "...",
    "type": "material",
    "courseId": "...",
    "title": "Week 1 Slides",
    "description": "Introduction to Web Development",
    "files": [
      {
        "fileName": "slides.pdf",
        "fileUrl": "https://...",
        "fileSize": 1024000,
        "mimeType": "application/pdf"
      }
    ],
    "createdAt": "2024-01-15T08:00:00Z"
  }
]
```

### 2. Create Assignment (Instructor Only)
**POST** `/classwork/assignments`

**Request Body:**
```json
{
  "courseId": "...",
  "title": "HTML & CSS Basics",
  "description": "Complete the exercises on HTML and CSS",
  "groupIds": [],
  "startDate": "2024-01-15T00:00:00Z",
  "deadline": "2024-01-20T23:59:00Z",
  "allowLateSubmission": false,
  "maxAttempts": 1,
  "allowedFileTypes": [".pdf", ".docx"],
  "maxFileSize": 10485760
}
```

### 3. Create Quiz (Instructor Only)
**POST** `/classwork/quizzes`

**Request Body:**
```json
{
  "courseId": "...",
  "title": "JavaScript Quiz",
  "description": "Test your knowledge of JavaScript basics",
  "groupIds": [],
  "openDate": "2024-01-15T00:00:00Z",
  "closeDate": "2024-01-20T23:59:00Z",
  "duration": 3600,
  "maxAttempts": 2,
  "questionStructure": {
    "easy": 5,
    "medium": 3,
    "hard": 2
  }
}
```

### 4. Create Material (Instructor Only)
**POST** `/classwork/materials`

**Request Body:**
```json
{
  "courseId": "...",
  "title": "Week 1 Slides",
  "description": "Introduction to Web Development",
  "files": [
    {
      "fileName": "slides.pdf",
      "fileUrl": "https://...",
      "fileSize": 1024000,
      "mimeType": "application/pdf"
    }
  ],
  "links": ["https://developer.mozilla.org"]
}
```

---

## 👥 People API

### Get People in a Course
**GET** `/courses/:courseId/people`

**Response:**
```json
{
  "instructors": [
    {
      "_id": "...",
      "fullName": "Dr. Jane Smith",
      "email": "jane.smith@university.edu",
      "avatar": "https://...",
      "role": "instructor"
    }
  ],
  "students": [
    {
      "_id": "...",
      "fullName": "John Doe",
      "email": "john.doe@student.edu",
      "avatar": "https://...",
      "role": "student",
      "studentId": "2021001"
    }
  ]
}
```

---

## 💬 Messaging API

### 1. Get Conversation with a User
**GET** `/messages/conversation/:userId`

**Response:**
```json
[
  {
    "_id": "...",
    "senderId": {
      "_id": "...",
      "fullName": "John Doe",
      "avatar": "https://...",
      "role": "student"
    },
    "receiverId": {
      "_id": "...",
      "fullName": "Dr. Smith",
      "avatar": "https://...",
      "role": "instructor"
    },
    "content": "Hello, I have a question about the assignment",
    "isRead": true,
    "readAt": "2024-01-15T10:30:00Z",
    "createdAt": "2024-01-15T10:00:00Z"
  }
]
```

### 2. Get All Conversations
**GET** `/messages/conversations`

**Response:**
```json
[
  {
    "user": {
      "_id": "...",
      "fullName": "Dr. Smith",
      "avatar": "https://...",
      "role": "instructor"
    },
    "lastMessage": "Thanks for your question!",
    "lastMessageTime": "2024-01-15T10:30:00Z",
    "isRead": true
  }
]
```

### 3. Send Message
**POST** `/messages`

**Request Body:**
```json
{
  "receiverId": "...",
  "content": "Hello, I have a question about the assignment",
  "attachments": []
}
```

**Permission:** Students can only message instructors. Instructors can message anyone.

### 4. Mark Message as Read
**PUT** `/messages/:id/read`

**Response:**
```json
{
  "_id": "...",
  "senderId": "...",
  "receiverId": "...",
  "content": "...",
  "isRead": true,
  "readAt": "2024-01-15T10:30:00Z",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### 5. Get Unread Message Count
**GET** `/messages/unread/count`

**Response:**
```json
{
  "count": 5
}
```

---

## 🔔 Notifications API

### 1. Get All Notifications
**GET** `/notifications?unreadOnly=true`

**Query Parameters:**
- `unreadOnly` (optional): If `true`, returns only unread notifications

**Response:**
```json
[
  {
    "_id": "...",
    "userId": "...",
    "type": "announcement",
    "title": "New Announcement",
    "message": "Dr. Smith posted: Week 1 Assignment",
    "metadata": {
      "courseId": "...",
      "announcementId": "...",
      "authorName": "Dr. Smith"
    },
    "isRead": false,
    "createdAt": "2024-01-15T08:00:00Z"
  }
]
```

### 2. Get Unread Count
**GET** `/notifications/unread/count`

**Response:**
```json
{
  "count": 8
}
```

### 3. Mark Notification as Read
**PUT** `/notifications/:id/read`

### 4. Mark All as Read
**PUT** `/notifications/read/all`

### 5. Delete Notification
**DELETE** `/notifications/:id`

---

## 🎯 Notification Types

### For Students:
- `material` - New material uploaded
- `announcement` - New announcement posted
- `assignment` - New assignment created
- `comment` - Someone commented on an announcement
- `message` - New private message received
- `quiz` - New quiz available
- `course_invite` - Invited to join a course

### For Instructors:
- `comment` - Student commented on announcement
- `submission` - Student submitted assignment
- `message` - New private message received
- `quiz_attempt` - Student completed a quiz
- `course_invite` - Course invitation related

---

## 📝 Frontend Integration Checklist

### Stream Tab (Announcements)
- [ ] Fetch announcements: `GET /announcements?courseId=<id>`
- [ ] Create announcement (instructor): `POST /announcements`
- [ ] Add comment: `POST /announcements/:id/comments`
- [ ] Display comments from `announcement.comments` array

### Classwork Tab
- [ ] Fetch classwork: `GET /classwork/course/:courseId`
- [ ] Implement search: `GET /classwork/course/:courseId?search=<query>`
- [ ] Implement filters: `GET /classwork/course/:courseId?filter=assignments`
- [ ] Color code by type:
  - 🟠 Orange: `type === 'assignment'`
  - 🔴 Red: `type === 'quiz'`
  - 🔵 Blue: `type === 'material'`

### People Tab
- [ ] Fetch people: `GET /courses/:courseId/people`
- [ ] Display instructors section
- [ ] Display students section
- [ ] Implement message button with permission check:
  - Students can only message instructors
  - Instructors can message anyone
- [ ] Navigate to chat screen on message click

### Chat Screen
- [ ] Fetch conversation: `GET /messages/conversation/:userId`
- [ ] Send message: `POST /messages`
- [ ] Mark messages as read automatically when viewing
- [ ] Display messages with proper styling (sender vs receiver)
- [ ] Show timestamp using timeago format

### Notification Bell
- [ ] Fetch unread count: `GET /notifications/unread/count`
- [ ] Display badge with count
- [ ] Fetch notifications: `GET /notifications`
- [ ] Mark as read: `PUT /notifications/:id/read`
- [ ] Filter by All/Unread/Read in UI

---

## 🔒 Permission Summary

**Students can:**
- View announcements and comment
- View all classwork
- Message instructors only
- View course people
- Receive notifications

**Instructors can:**
- Create announcements, assignments, quizzes, materials
- Comment on announcements
- Message anyone (students and other instructors)
- View course people
- Receive notifications (different types)

---

## 🚀 Next Steps for Frontend

1. **Create API Service Classes:**
   - `lib/services/announcement_service.dart`
   - `lib/services/classwork_service.dart`
   - `lib/services/people_service.dart`
   - `lib/services/message_service.dart`

2. **Update Existing Screens:**
   - `stream_tab.dart` - Connect to announcements API
   - `classwork_tab.dart` - Connect to classwork API
   - `people_tab.dart` - Connect to people API
   - `chat_screen.dart` - Connect to messages API

3. **Test Each Feature:**
   - Announcement creation and commenting
   - Classwork filtering and search
   - Messaging with permission checks
   - Notifications integration

---

## 📋 Example API Call (Dart)

```dart
// In lib/services/announcement_service.dart
class AnnouncementService {
  final String baseUrl = 'http://localhost:5000/api';
  
  Future<List<Announcement>> getAnnouncements(String courseId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/announcements?courseId=$courseId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Announcement.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load announcements');
    }
  }
  
  Future<Announcement> addComment(String announcementId, String text) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$baseUrl/announcements/$announcementId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'text': text}),
    );
    
    if (response.statusCode == 201) {
      return Announcement.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add comment');
    }
  }
}
```
