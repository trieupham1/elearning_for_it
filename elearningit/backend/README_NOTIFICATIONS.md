# Notification System Backend Documentation

## Overview

The backend notification system is fully implemented with comprehensive support for all notification types for both students and instructors.

## Database Model

**File**: `backend/models/Notification.js`

### Schema Fields

```javascript
{
  userId: ObjectId,           // Reference to User who receives the notification
  type: String,               // Type of notification (see below)
  title: String,              // Notification title
  message: String,            // Notification message/description
  data: Object,              // Additional metadata (courseId, assignmentId, etc.)
  isRead: Boolean,           // Read status (default: false)
  readAt: Date,              // Timestamp when marked as read
  createdAt: Date,           // Auto-generated
  updatedAt: Date            // Auto-generated
}
```

### Notification Types

- `material` - New material uploaded
- `announcement` - New announcement posted
- `assignment` - New assignment created
- `comment` - New comment on forum/discussion
- `message` - Private message or join request
- `quiz` - New quiz available
- `submission` - Student submitted assignment (instructor only)
- `quiz_attempt` - Student completed quiz (instructor only)
- `course_invite` - Course invitation

### Helper Methods

- `createNotification(data)` - Create a single notification
- `createBulkNotifications(array)` - Create multiple notifications at once
- `markAsRead()` - Instance method to mark notification as read

## API Endpoints

**Base URL**: `/api/notifications`

All endpoints require authentication (JWT token in Authorization header).

### 1. Get Notifications

```
GET /api/notifications?unreadOnly=true
```

**Query Parameters:**
- `unreadOnly` (optional) - Set to "true" to get only unread notifications

**Response:**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "userId": "507f191e810c19729de860ea",
    "type": "material",
    "title": "New Material Available",
    "message": "New material 'Chapter 1 Slides' uploaded in Web Development",
    "data": {
      "courseId": "507f...",
      "courseName": "Web Development",
      "materialTitle": "Chapter 1 Slides"
    },
    "isRead": false,
    "createdAt": "2025-10-10T10:30:00.000Z",
    "updatedAt": "2025-10-10T10:30:00.000Z"
  }
]
```

### 2. Get Unread Count

```
GET /api/notifications/unread/count
```

**Response:**
```json
{
  "count": 5
}
```

### 3. Mark as Read

```
PUT /api/notifications/:id/read
```

**Response:**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "isRead": true,
  "readAt": "2025-10-10T11:00:00.000Z",
  ...
}
```

### 4. Mark All as Read

```
PUT /api/notifications/read/all
```

**Response:**
```json
{
  "message": "All notifications marked as read"
}
```

### 5. Delete Notification

```
DELETE /api/notifications/:id
```

**Response:**
```json
{
  "message": "Notification deleted"
}
```

### 6. Send Course Invitation (Instructor Only)

```
POST /api/notifications/course-invitation
```

**Request Body:**
```json
{
  "courseId": "507f191e810c19729de860ea",
  "studentIds": [
    "507f1f77bcf86cd799439011",
    "507f1f77bcf86cd799439012"
  ]
}
```

**Response:**
```json
{
  "message": "Invitations sent successfully",
  "count": 2
}
```

### 7. Respond to Course Invitation (Student Only)

```
POST /api/notifications/:id/respond
```

**Request Body:**
```json
{
  "accept": true  // true to accept, false to decline
}
```

**Response (if accepted):**
```json
{
  "message": "Course invitation accepted",
  "course": {
    "id": "507f...",
    "name": "Web Development",
    ...
  }
}
```

**Response (if declined):**
```json
{
  "message": "Course invitation declined"
}
```

### 8. Create Notification (Manual/Testing)

```
POST /api/notifications
```

**Request Body:**
```json
{
  "userId": "507f191e810c19729de860ea",
  "type": "material",
  "title": "Test Notification",
  "message": "This is a test notification",
  "data": {
    "courseId": "507f...",
    "customField": "customValue"
  }
}
```

## Notification Helper Utilities

**File**: `backend/utils/notificationHelper.js`

These helper functions should be called when specific events occur in your application:

### For Students

#### 1. New Material Uploaded
```javascript
const { notifyNewMaterial } = require('./utils/notificationHelper');

await notifyNewMaterial(
  courseId,
  courseName,
  materialTitle,
  studentIds  // Array of student IDs enrolled in the course
);
```

#### 2. New Announcement Posted
```javascript
const { notifyNewAnnouncement } = require('./utils/notificationHelper');

await notifyNewAnnouncement(
  courseId,
  courseName,
  announcementTitle,
  studentIds
);
```

#### 3. New Assignment Created
```javascript
const { notifyNewAssignment } = require('./utils/notificationHelper');

await notifyNewAssignment(
  courseId,
  courseName,
  assignmentTitle,
  dueDate,  // String or Date
  studentIds
);
```

#### 4. New Quiz Available
```javascript
const { notifyNewQuiz } = require('./utils/notificationHelper');

await notifyNewQuiz(
  courseId,
  courseName,
  quizTitle,
  studentIds
);
```

#### 5. New Comment
```javascript
const { notifyNewComment } = require('./utils/notificationHelper');

await notifyNewComment(
  userId,         // User who receives the notification
  commenterName,  // Name of person who commented
  topicTitle,     // Title of the topic/post
  commentText,    // Text of the comment
  courseId
);
```

#### 6. Private Message Received
```javascript
const { notifyPrivateMessage } = require('./utils/notificationHelper');

await notifyPrivateMessage(
  recipientId,
  senderName,
  messagePreview  // First 100 chars of message
);
```

#### 7. Join Request Approved
```javascript
const { notifyJoinApproved } = require('./utils/notificationHelper');

await notifyJoinApproved(
  studentId,
  courseName,
  courseId
);
```

### For Instructors

#### 1. Assignment Submitted
```javascript
const { notifyAssignmentSubmission } = require('./utils/notificationHelper');

await notifyAssignmentSubmission(
  instructorId,
  courseName,
  assignmentTitle,
  studentName,
  submissionId
);
```

#### 2. Quiz Completed
```javascript
const { notifyQuizAttempt } = require('./utils/notificationHelper');

await notifyQuizAttempt(
  instructorId,
  courseName,
  quizTitle,
  studentName,
  score,        // e.g., "85%"
  attemptId
);
```

#### 3. Student Join Request
```javascript
const { notifyJoinRequest } = require('./utils/notificationHelper');

await notifyJoinRequest(
  instructorId,
  studentName,
  studentId,
  courseName,
  courseId
);
```

## Integration Examples

### Example 1: When Creating a New Assignment

```javascript
// routes/assignments.js
router.post('/', auth, instructorOnly, async (req, res) => {
  try {
    // Create the assignment
    const assignment = new Assignment(req.body);
    await assignment.save();
    
    // Get the course and enrolled students
    const course = await Course.findById(assignment.courseId)
      .populate('students');
    
    // Notify all enrolled students
    const { notifyNewAssignment } = require('../utils/notificationHelper');
    await notifyNewAssignment(
      course._id,
      course.name,
      assignment.title,
      assignment.dueDate,
      course.students.map(s => s._id)
    );
    
    res.status(201).json(assignment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
```

### Example 2: When Student Submits Assignment

```javascript
// routes/submissions.js
router.post('/', auth, async (req, res) => {
  try {
    // Create the submission
    const submission = new Submission({
      ...req.body,
      studentId: req.user.id
    });
    await submission.save();
    
    // Get assignment and course info
    const assignment = await Assignment.findById(submission.assignmentId);
    const course = await Course.findById(assignment.courseId)
      .populate('instructor');
    
    // Notify the instructor
    const { notifyAssignmentSubmission } = require('../utils/notificationHelper');
    await notifyAssignmentSubmission(
      course.instructor._id,
      course.name,
      assignment.title,
      req.user.fullName || req.user.username,
      submission._id
    );
    
    res.status(201).json(submission);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
```

### Example 3: When Student Joins Course via Code

```javascript
// routes/courses.js
router.post('/join', auth, async (req, res) => {
  try {
    const { code } = req.body;
    
    // Find course by code
    const course = await Course.findOne({ code })
      .populate('instructor');
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    
    // Add student to course
    if (!course.students.includes(req.user.id)) {
      course.students.push(req.user.id);
      await course.save();
    }
    
    // Notify instructor
    const { notifyJoinRequest } = require('../utils/notificationHelper');
    await notifyJoinRequest(
      course.instructor._id,
      req.user.fullName || req.user.username,
      req.user.id,
      course.name,
      course._id
    );
    
    res.json({ message: 'Joined course successfully', course });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
```

## Testing the Notification System

### Using curl or Postman

1. **Get all notifications:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:5000/api/notifications
```

2. **Get unread count:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:5000/api/notifications/unread/count
```

3. **Create a test notification:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"material","title":"Test","message":"Test notification"}' \
  http://localhost:5000/api/notifications
```

## Next Steps

To fully integrate the notification system:

1. **Add notification calls** to all relevant routes:
   - Materials routes (when uploading files)
   - Announcements routes (when creating announcements)
   - Assignments routes (when creating/submitting)
   - Quiz routes (when creating/submitting)
   - Forum/Comment routes (when posting comments)
   - Messaging routes (when sending messages)

2. **Consider adding real-time notifications** using Socket.io for instant updates

3. **Add email notifications** as a secondary channel for important events

4. **Implement notification preferences** so users can customize what notifications they receive

5. **Add notification cleanup** to automatically delete old read notifications after a certain period
