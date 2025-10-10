# Content Management System Implementation

## Overview
This document outlines the implementation of four content types in the e-learning platform:
1. **Announcements** - Social media-style posts with comments
2. **Assignments** - Graded work with file submissions
3. **Quizzes** - Auto-graded assessments from question banks
4. **Materials** - Reference documents and links

## Content Type Specifications

### 1. Announcement
**Purpose**: Instructor communicates with students in a social media style

**Features**:
- Title + rich-text content
- Multiple file attachments
- Group scoping (select one/multiple/all groups)
- Commenting system (both instructor and students)
- View tracking
- Download tracking (per file)

**Tracking**:
- Who viewed the announcement
- Who downloaded which files
- Comment history

**Scope**: One, multiple, or all groups in a course

---

### 2. Assignment
**Purpose**: Graded work submissions with detailed tracking

**Features**:
- Title + description
- Multiple file/image attachments
- Start date + deadline
- Late submission settings (allowed/not allowed, late deadline)
- Maximum submission attempts
- File format restrictions (e.g., .pdf, .docx)
- File size limits
- Group scoping

**Tracking Dashboard** (Real-time):
- ✅ Who has submitted
- ❌ Who hasn't submitted
- 🕐 Late submissions
- 🔄 Multiple attempts (1st, 2nd, 3rd)
- 📊 Current grades
- **Filtering**: By name, group, time, status
- **Searching**: Student name, ID
- **Sorting**: Name, submission time, grade, status
- **Export**: CSV for individual assignment or all assignments in course/semester

**Scope**: One, multiple, or all groups

---

### 3. Quiz
**Purpose**: Auto-graded assessments from reusable question banks

**Question Bank**:
- Course-specific
- Reusable across semesters
- Multiple choice questions
- One correct answer per question
- Difficulty levels: Easy, Medium, Hard
- Optional explanation for each question

**Quiz Configuration**:
- Time window (open date/time - close date/time)
- Number of attempts allowed
- Duration (time limit in minutes)
- Question structure (e.g., 5 easy, 3 medium, 2 hard)
- Random selection from question bank based on structure
- Group scoping

**Tracking Dashboard**:
- ✅ Who completed the quiz
- ❌ Who hasn't completed
- 📊 Scores
- 🕐 Submission times
- 🔄 Attempt numbers
- **Filtering**: By name, group, score range, completion status
- **Searching**: Student name, ID
- **Sorting**: Name, score, submission time
- **Export**: CSV for individual quiz or all quizzes in course/semester

**Scope**: One, multiple, or all groups

---

### 4. Material
**Purpose**: Reference documents and resources

**Features**:
- Title + description
- Multiple files
- Multiple links (URLs)
- View tracking
- Download tracking

**Tracking**:
- Who viewed the material
- Who downloaded which files

**Scope**: **ALL students in course** (no group scoping)

---

## Database Schema

### Models Updated

#### Announcement
```javascript
{
  courseId: ObjectId ref Course,
  title: String,
  content: String (rich-text),
  authorId: ObjectId ref User,
  authorName: String,
  authorAvatar: String,
  groupIds: [ObjectId ref Group], // empty = all groups
  attachments: [{
    fileName, fileUrl, fileSize, mimeType
  }],
  comments: [{
    userId, userName, userAvatar, text, createdAt
  }],
  viewedBy: [{
    userId, viewedAt
  }],
  downloadedBy: [{
    userId, fileName, downloadedAt
  }],
  timestamps: true
}
```

#### Assignment
```javascript
{
  courseId: ObjectId ref Course,
  createdBy: ObjectId ref User,
  title: String,
  description: String,
  groupIds: [ObjectId ref Group], // empty = all groups
  startDate: Date,
  deadline: Date,
  allowLateSubmission: Boolean,
  lateDeadline: Date,
  maxAttempts: Number,
  allowedFileTypes: [String], // e.g., ['.pdf', '.docx']
  maxFileSize: Number, // in bytes
  attachments: [{
    fileName, fileUrl, fileSize, mimeType
  }],
  points: Number,
  timestamps: true
}
```

#### Submission (Student work for assignments)
```javascript
{
  assignmentId: ObjectId ref Assignment,
  studentId: ObjectId ref User,
  attemptNumber: Number,
  files: [{
    fileName, fileUrl, fileSize, mimeType
  }],
  submittedAt: Date,
  isLate: Boolean,
  grade: Number,
  feedback: String,
  gradedAt: Date,
  gradedBy: ObjectId ref User
}
```

#### Quiz
```javascript
{
  courseId: ObjectId ref Course,
  createdBy: ObjectId ref User,
  title: String,
  description: String,
  groupIds: [ObjectId ref Group], // empty = all groups
  openDate: Date,
  closeDate: Date,
  duration: Number, // minutes
  maxAttempts: Number,
  questionStructure: {
    easy: Number,
    medium: Number,
    hard: Number
  },
  randomizeQuestions: Boolean,
  selectedQuestions: [ObjectId ref Question],
  totalPoints: Number,
  timestamps: true
}
```

#### Question (Question Bank)
```javascript
{
  courseId: ObjectId ref Course,
  questionText: String,
  choices: [{
    text: String,
    isCorrect: Boolean
  }],
  difficulty: String enum ['easy', 'medium', 'hard'],
  explanation: String,
  timestamps: true
}
```

#### QuizAttempt
```javascript
{
  quizId: ObjectId ref Quiz,
  studentId: ObjectId ref User,
  attemptNumber: Number,
  answers: [{
    questionId, selectedChoice, isCorrect
  }],
  startedAt: Date,
  submittedAt: Date,
  score: Number,
  totalQuestions: Number
}
```

#### Material
```javascript
{
  courseId: ObjectId ref Course,
  createdBy: ObjectId ref User,
  title: String,
  description: String,
  files: [{
    fileName, fileUrl, fileSize, mimeType
  }],
  links: [String],
  viewedBy: [{
    userId, viewedAt
  }],
  downloadedBy: [{
    userId, fileName, downloadedAt
  }],
  timestamps: true
}
```

---

## API Endpoints

### Announcements
```
POST   /api/announcements              Create announcement
GET    /api/announcements?courseId=    List announcements
GET    /api/announcements/:id          Get single announcement
PUT    /api/announcements/:id          Update announcement
DELETE /api/announcements/:id          Delete announcement
POST   /api/announcements/:id/comment  Add comment
POST   /api/announcements/:id/view     Mark as viewed
POST   /api/announcements/:id/download Track download
GET    /api/announcements/:id/tracking Get view/download stats
```

### Assignments
```
POST   /api/assignments                           Create assignment
GET    /api/assignments?courseId=                 List assignments
GET    /api/assignments/:id                       Get single assignment
PUT    /api/assignments/:id                       Update assignment
DELETE /api/assignments/:id                       Delete assignment
POST   /api/submissions                           Submit assignment
GET    /api/assignments/:id/submissions           Get all submissions
GET    /api/assignments/:id/tracking              Get detailed tracking
POST   /api/submissions/:id/grade                 Grade submission
GET    /api/assignments/:id/export                Export to CSV
GET    /api/courses/:id/assignments/export        Export all course assignments
```

### Quizzes & Questions
```
POST   /api/questions                    Create question
GET    /api/questions?courseId=          List questions by course
PUT    /api/questions/:id                Update question
DELETE /api/questions/:id                Delete question

POST   /api/quizzes                      Create quiz
GET    /api/quizzes?courseId=            List quizzes
GET    /api/quizzes/:id                  Get quiz
PUT    /api/quizzes/:id                  Update quiz
DELETE /api/quizzes/:id                  Delete quiz
POST   /api/quizzes/:id/start            Start quiz attempt
POST   /api/quizzes/:id/submit           Submit quiz
GET    /api/quizzes/:id/attempts         Get all attempts
GET    /api/quizzes/:id/tracking         Get detailed tracking
GET    /api/quizzes/:id/export           Export to CSV
GET    /api/courses/:id/quizzes/export   Export all course quizzes
```

### Materials
```
POST   /api/materials              Create material
GET    /api/materials?courseId=    List materials
GET    /api/materials/:id          Get single material
PUT    /api/materials/:id          Update material
DELETE /api/materials/:id          Delete material
POST   /api/materials/:id/view     Mark as viewed
POST   /api/materials/:id/download Track download
GET    /api/materials/:id/tracking Get view/download stats
```

---

## Frontend Structure

### Instructor Screens

#### 1. Content Creation Screens
- `create_announcement_screen.dart` - Create/edit announcements with group selection
- `create_assignment_screen.dart` - Create/edit assignments with all settings
- `create_quiz_screen.dart` - Create/edit quizzes with question bank integration
- `create_material_screen.dart` - Create/edit materials
- `manage_question_bank_screen.dart` - Manage course question bank

#### 2. Tracking Dashboards
- `assignment_tracking_screen.dart` - Real-time submission tracking with filters
- `quiz_tracking_screen.dart` - Real-time quiz completion tracking
- `announcement_tracking_screen.dart` - View/download tracking
- `material_tracking_screen.dart` - View/download tracking

### Student Screens

#### 1. Content View Screens
- `view_announcement_screen.dart` - View announcement with comments
- `view_assignment_screen.dart` - View assignment details and submit
- `take_quiz_screen.dart` - Take quiz with timer
- `view_material_screen.dart` - View materials

#### 2. Integration
- Update `classwork_tab.dart` - Show all four content types with tabs/filters

### Models
```
announcement.dart
assignment.dart
submission.dart
quiz.dart
quiz_attempt.dart
question.dart
material.dart
```

### Services
```
announcement_service.dart
assignment_service.dart
quiz_service.dart
question_service.dart
material_service.dart
tracking_service.dart
```

---

## Implementation Phases

### Phase 1: Backend Foundation ✅
- [x] Update all four content models
- [ ] Create API routes for CRUD operations
- [ ] Create tracking endpoints
- [ ] Create export functionality (CSV)

### Phase 2: Frontend Models & Services
- [ ] Create Dart models for all content types
- [ ] Create service classes
- [ ] Create tracking service

### Phase 3: Instructor UI
- [ ] Content creation screens
- [ ] Tracking dashboards
- [ ] Question bank management
- [ ] CSV export integration

### Phase 4: Student UI
- [ ] Content viewing screens
- [ ] Submission interfaces
- [ ] Quiz taking interface
- [ ] Comment system

### Phase 5: Integration
- [ ] Update classwork tab
- [ ] Add navigation
- [ ] Testing all workflows

---

## Key Features Summary

### Group Scoping
- **Announcement**: Select one/multiple/all groups
- **Assignment**: Select one/multiple/all groups
- **Quiz**: Select one/multiple/all groups
- **Material**: **Always ALL students** (no group selection)

### Tracking & Analytics
- **Real-time dashboards** for instructors
- **Filtering** by name, group, status, date
- **Searching** by student name/ID
- **Sorting** by various columns
- **CSV Export** for individual items or entire course/semester

### File Management
- **Upload limits** configurable per assignment
- **File type restrictions** (e.g., .pdf, .docx only)
- **Download tracking** for all file types
- **Multiple attachments** support

### Question Bank
- **Course-specific** question pools
- **Reusable across semesters**
- **Difficulty categorization** (easy, medium, hard)
- **Random selection** based on structure
- **Explanations** for learning

---

## Next Steps

1. ✅ Update backend models
2. Create comprehensive API routes
3. Build tracking and export functionality
4. Create Flutter models and services
5. Build instructor creation interfaces
6. Build student viewing interfaces
7. Integrate with classwork tab
8. Test all workflows end-to-end
