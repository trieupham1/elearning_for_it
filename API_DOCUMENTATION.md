# API Services Documentation

> **Complete reference for all Flutter service classes in the E-Learning Platform**
> 
> Generated: December 3, 2025  
> Tech Stack: Flutter + Node.js/Express + MongoDB

---

## Table of Contents

1. [Core Services](#core-services)
   - [ApiService](#apiservice)
   - [AuthService](#authservice)
2. [Course Management](#course-management)
   - [CourseService](#courseservice)
   - [AssignmentService](#assignmentservice)
   - [QuizService](#quizservice)
   - [MaterialService](#materialservice)
3. [Communication Services](#communication-services)
   - [MessageService](#messageservice)
   - [NotificationService](#notificationservice)
   - [AnnouncementService](#announcementservice)
4. [Media Services](#media-services)
   - [FileService](#fileservice)
   - [VideoService](#videoservice)
   - [CallService](#callservice)
5. [Administrative Services](#administrative-services)
   - [AdminService](#adminservice)
   - [DepartmentService](#departmentservice)
   - [ReportService](#reportservice)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)

---

## Core Services

### ApiService

**Purpose**: Base service providing HTTP request methods and authentication handling.

**Location**: `lib/services/api_service.dart`

#### Methods

##### `getToken()`
```dart
Future<String?> getToken()
```
**Description**: Retrieves the stored JWT authentication token from SharedPreferences.

**Returns**: `String?` - JWT token or null if not authenticated

**Example**:
```dart
final apiService = ApiService();
final token = await apiService.getToken();
if (token != null) {
  print('User is authenticated');
}
```

---

##### `saveToken(String token)`
```dart
Future<void> saveToken(String token)
```
**Description**: Saves JWT token to SharedPreferences for persistent authentication.

**Parameters**:
- `token` (String): JWT token from login response

**Example**:
```dart
await apiService.saveToken('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
```

---

##### `clearToken()`
```dart
Future<void> clearToken()
```
**Description**: Removes stored authentication token (used on logout).

**Example**:
```dart
await apiService.clearToken(); // User logged out
```

---

##### `get(String endpoint, {bool withAuth = true})`
```dart
Future<http.Response> get(String endpoint, {bool withAuth = true})
```
**Description**: Performs GET request to the API endpoint.

**Parameters**:
- `endpoint` (String): API endpoint path (e.g., '/api/courses')
- `withAuth` (bool): Include Authorization header (default: true)

**Returns**: `Future<http.Response>` - HTTP response object

**Throws**: 
- `ApiException` - On network errors or server errors
- `SocketException` - When backend server is unreachable

**Example**:
```dart
try {
  final response = await apiService.get('/api/courses');
  // Handle response
} on ApiException catch (e) {
  print('API Error: ${e.message}');
} on SocketException {
  print('Server unreachable');
}
```

---

##### `post(String endpoint, {Map<String, dynamic>? body, bool withAuth = true})`
```dart
Future<http.Response> post(
  String endpoint, {
  Map<String, dynamic>? body,
  bool withAuth = true,
})
```
**Description**: Performs POST request with JSON body.

**Parameters**:
- `endpoint` (String): API endpoint path
- `body` (Map<String, dynamic>?): Request body (will be JSON encoded)
- `withAuth` (bool): Include Authorization header (default: true)

**Returns**: `Future<http.Response>` - HTTP response object

**Throws**: `ApiException`, `SocketException`, `HttpException`

**Example**:
```dart
final response = await apiService.post(
  '/api/courses',
  body: {
    'name': 'Introduction to Flutter',
    'code': 'CS101',
    'semester': '2025-1',
  },
);
```

---

##### `put(String endpoint, {Map<String, dynamic>? body, bool withAuth = true})`
```dart
Future<http.Response> put(
  String endpoint, {
  Map<String, dynamic>? body,
  bool withAuth = true,
})
```
**Description**: Performs PUT request for updating resources.

**Parameters**:
- `endpoint` (String): API endpoint path
- `body` (Map<String, dynamic>?): Update data
- `withAuth` (bool): Include Authorization header (default: true)

**Returns**: `Future<http.Response>` - HTTP response object

**Example**:
```dart
await apiService.put(
  '/api/courses/12345',
  body: {'name': 'Advanced Flutter Development'},
);
```

---

##### `delete(String endpoint, {bool withAuth = true})`
```dart
Future<http.Response> delete(String endpoint, {bool withAuth = true})
```
**Description**: Performs DELETE request to remove resources.

**Parameters**:
- `endpoint` (String): API endpoint path
- `withAuth` (bool): Include Authorization header (default: true)

**Returns**: `Future<http.Response>` - HTTP response object

**Example**:
```dart
await apiService.delete('/api/courses/12345');
```

---

##### `parseResponse(http.Response response)`
```dart
Map<String, dynamic> parseResponse(http.Response response)
```
**Description**: Parses JSON response body into Map.

**Parameters**:
- `response` (http.Response): HTTP response to parse

**Returns**: `Map<String, dynamic>` - Parsed JSON data

**Throws**: `ApiException` - On JSON parse failure

**Example**:
```dart
final response = await apiService.get('/api/user/profile');
final data = apiService.parseResponse(response);
final user = User.fromJson(data);
```

---

##### `testConnection()`
```dart
Future<bool> testConnection()
```
**Description**: Tests connectivity to backend server via health check endpoint.

**Returns**: `bool` - True if server is reachable

**Example**:
```dart
final isConnected = await apiService.testConnection();
if (!isConnected) {
  showDialog(context, 'Server unreachable. Please check backend.');
}
```

---

### AuthService

**Purpose**: Handles user authentication, registration, and profile management.

**Location**: `lib/services/auth_service.dart`

**Extends**: `ApiService`

#### Properties

```dart
User? currentUser  // Currently logged in user
bool isLoggedIn    // Authentication status
```

#### Methods

##### `login(LoginRequest request)`
```dart
Future<LoginResponse> login(LoginRequest request)
```
**Description**: Authenticates user with username/email and password.

**Parameters**:
- `request` (LoginRequest): Contains username and password

**Returns**: `Future<LoginResponse>` - Contains user data and JWT token

**Throws**: 
- `ApiException` - On invalid credentials or server error
- `SocketException` - When server is unreachable

**Example**:
```dart
try {
  final authService = AuthService();
  final response = await authService.login(
    LoginRequest(username: 'john@example.com', password: 'password123'),
  );
  
  print('Logged in as: ${response.user.fullName}');
  print('Role: ${response.user.role}');
} on ApiException catch (e) {
  print('Login failed: ${e.message}');
}
```

**Flow**:
1. Tests server connectivity
2. Sends POST to `/api/auth/login`
3. Saves JWT token to SharedPreferences
4. Stores user data in `_currentUser`
5. Returns LoginResponse

---

##### `register(RegisterRequest request)`
```dart
Future<RegisterResponse> register(RegisterRequest request)
```
**Description**: Registers new user account.

**Parameters**:
- `request` (RegisterRequest): User registration data

**Returns**: `Future<RegisterResponse>` - Registration result with user data

**Throws**: `ApiException` - On validation errors or duplicate email

**Example**:
```dart
final response = await authService.register(
  RegisterRequest(
    fullName: 'John Doe',
    email: 'john@example.com',
    username: 'johndoe',
    password: 'SecurePass123!',
    role: 'student',
  ),
);
```

---

##### `logout()`
```dart
Future<void> logout()
```
**Description**: Logs out current user and clears stored data.

**Actions**:
- Sends logout request to server
- Clears JWT token from storage
- Clears `_currentUser`

**Example**:
```dart
await authService.logout();
Navigator.pushReplacementNamed(context, '/login');
```

---

##### `getCurrentUser()`
```dart
Future<User?> getCurrentUser()
```
**Description**: Retrieves current authenticated user profile.

**Returns**: `Future<User?>` - User object or null if not authenticated

**Caching**: Returns cached `_currentUser` if available

**Example**:
```dart
final user = await authService.getCurrentUser();
if (user != null) {
  print('Welcome back, ${user.fullName}!');
}
```

---

##### `changePassword({required String currentPassword, required String newPassword})`
```dart
Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
})
```
**Description**: Changes user's password.

**Parameters**:
- `currentPassword` (String): Current password for verification
- `newPassword` (String): New password to set

**Throws**: `ApiException` - On incorrect current password

**Example**:
```dart
try {
  await authService.changePassword(
    currentPassword: 'oldPass123',
    newPassword: 'newSecurePass456!',
  );
  showSnackBar('Password changed successfully');
} on ApiException catch (e) {
  showSnackBar('Error: ${e.message}');
}
```

---

##### `updateProfile({String? fullName, String? bio, String? phone})`
```dart
Future<User> updateProfile({
  String? fullName,
  String? bio,
  String? phone,
})
```
**Description**: Updates user profile information.

**Parameters**:
- `fullName` (String?): New full name
- `bio` (String?): User biography
- `phone` (String?): Phone number

**Returns**: `Future<User>` - Updated user object

**Example**:
```dart
final updatedUser = await authService.updateProfile(
  fullName: 'John Smith',
  bio: 'Computer Science Student',
  phone: '+1-234-567-8900',
);
```

---

##### `uploadAvatar(PlatformFile file)`
```dart
Future<String> uploadAvatar(PlatformFile file)
```
**Description**: Uploads user profile avatar image.

**Parameters**:
- `file` (PlatformFile): Image file from file_picker

**Returns**: `Future<String>` - URL of uploaded avatar

**Constraints**:
- Max file size: 5MB
- Supported formats: JPG, PNG, GIF

**Example**:
```dart
final result = await FilePicker.platform.pickFiles(
  type: FileType.image,
);
if (result != null) {
  final avatarUrl = await authService.uploadAvatar(result.files.first);
  print('Avatar uploaded: $avatarUrl');
}
```

---

##### `forgotPassword(String email)`
```dart
Future<void> forgotPassword(String email)
```
**Description**: Initiates password reset flow by sending email.

**Parameters**:
- `email` (String): User's registered email address

**Example**:
```dart
await authService.forgotPassword('john@example.com');
showSnackBar('Password reset link sent to your email');
```

---

##### `resetPassword({required String token, required String newPassword})`
```dart
Future<void> resetPassword({
  required String token,
  required String newPassword,
})
```
**Description**: Resets password using token from email.

**Parameters**:
- `token` (String): Reset token from email link
- `newPassword` (String): New password to set

**Example**:
```dart
await authService.resetPassword(
  token: 'reset-token-from-email',
  newPassword: 'NewSecurePassword123!',
);
```

---

## Course Management

### CourseService

**Purpose**: Manages course operations (CRUD, enrollment, materials).

**Location**: `lib/services/course_service.dart`

**Extends**: `ApiService`

#### Methods

##### `getCourses({String? semester})`
```dart
Future<List<Course>> getCourses({String? semester})
```
**Description**: Fetches all courses, optionally filtered by semester.

**Parameters**:
- `semester` (String?): Semester ID to filter by (optional)

**Returns**: `Future<List<Course>>` - List of course objects

**Example**:
```dart
// Get all courses
final allCourses = await courseService.getCourses();

// Get courses for specific semester
final springCourses = await courseService.getCourses(semester: '2025-spring');
```

**Response Data**:
```dart
Course {
  id: String,
  code: String,
  name: String,
  description: String,
  instructor: User,
  semester: Semester,
  students: List<User>,
  color: String,
  sessions: int,
  isPublished: bool,
}
```

---

##### `getCourseById(String id)`
```dart
Future<Course> getCourseById(String id)
```
**Description**: Retrieves detailed course information by ID.

**Parameters**:
- `id` (String): Course ID

**Returns**: `Future<Course>` - Course object with populated fields

**Throws**: `ApiException` - On invalid ID or unauthorized access

**Example**:
```dart
final course = await courseService.getCourseById('course123');
print('Course: ${course.name}');
print('Instructor: ${course.instructor.fullName}');
print('Students enrolled: ${course.students.length}');
```

---

##### `createCourse(...)`
```dart
Future<Course> createCourse({
  required String code,
  required String name,
  required String description,
  required String semesterId,
  required int sessions,
  required String color,
})
```
**Description**: Creates new course (instructors only).

**Parameters**:
- `code` (String): Course code (e.g., "CS101")
- `name` (String): Course name
- `description` (String): Course description
- `semesterId` (String): Semester to create course in
- `sessions` (int): Number of planned sessions
- `color` (String): Theme color (hex format)

**Returns**: `Future<Course>` - Newly created course

**Authorization**: Requires instructor or admin role

**Example**:
```dart
final course = await courseService.createCourse(
  code: 'CS301',
  name: 'Advanced Algorithms',
  description: 'Deep dive into algorithm design and analysis',
  semesterId: '2025-fall',
  sessions: 30,
  color: '#4A90E2',
);
```

---

##### `updateCourse(...)`
```dart
Future<Course> updateCourse({
  required String id,
  required String code,
  required String name,
  required String description,
  required int sessions,
  required String color,
})
```
**Description**: Updates existing course details.

**Parameters**:
- `id` (String): Course ID to update
- Other parameters same as `createCourse`

**Returns**: `Future<Course>` - Updated course object

**Example**:
```dart
final updated = await courseService.updateCourse(
  id: 'course123',
  code: 'CS301',
  name: 'Advanced Algorithms & Data Structures',
  description: 'Updated description',
  sessions: 32,
  color: '#5A9FE2',
);
```

---

##### `deleteCourse(String id)`
```dart
Future<void> deleteCourse(String id)
```
**Description**: Permanently deletes a course.

**Parameters**:
- `id` (String): Course ID to delete

**Warning**: This action cannot be undone. All related data (assignments, quizzes) will be deleted.

**Example**:
```dart
await courseService.deleteCourse('course123');
```

---

##### `enrollStudent(String courseId, String studentId)`
```dart
Future<void> enrollStudent(String courseId, String studentId)
```
**Description**: Enrolls student in course.

**Parameters**:
- `courseId` (String): Course to enroll in
- `studentId` (String): Student user ID

**Example**:
```dart
await courseService.enrollStudent('course123', 'student456');
```

---

##### `unenrollStudent(String courseId, String studentId)`
```dart
Future<void> unenrollStudent(String courseId, String studentId)
```
**Description**: Removes student from course enrollment.

**Parameters**:
- `courseId` (String): Course ID
- `studentId` (String): Student to remove

**Example**:
```dart
await courseService.unenrollStudent('course123', 'student456');
```

---

##### `getEnrolledStudents(String courseId)`
```dart
Future<List<User>> getEnrolledStudents(String courseId)
```
**Description**: Gets list of all students enrolled in course.

**Parameters**:
- `courseId` (String): Course ID

**Returns**: `Future<List<User>>` - List of enrolled students

**Example**:
```dart
final students = await courseService.getEnrolledStudents('course123');
print('${students.length} students enrolled');
```

---

##### `getMyCourses()`
```dart
Future<List<Course>> getMyCourses()
```
**Description**: Gets courses for current authenticated user.
- Students: Returns enrolled courses
- Instructors: Returns teaching courses
- Admins: Returns all courses

**Returns**: `Future<List<Course>>` - User's courses

**Example**:
```dart
final myCourses = await courseService.getMyCourses();
for (var course in myCourses) {
  print('${course.code}: ${course.name}');
}
```

---

### AssignmentService

**Purpose**: Manages assignments, submissions, and grading.

**Location**: `lib/services/assignment_service.dart`

#### Methods

##### `createAssignment(...)`
```dart
Future<Assignment> createAssignment({
  required String courseId,
  required String title,
  String? description,
  List<String>? groupIds,
  required DateTime startDate,
  required DateTime deadline,
  bool allowLateSubmission = false,
  DateTime? lateDeadline,
  int maxAttempts = 1,
  List<String>? allowedFileTypes,
  int maxFileSize = 10485760, // 10MB
  List<AssignmentAttachment>? attachments,
  int points = 100,
})
```
**Description**: Creates new assignment for a course.

**Parameters**:
- `courseId` (String): Course to add assignment to
- `title` (String): Assignment title
- `description` (String?): Detailed instructions
- `groupIds` (List<String>?): Specific student groups (optional, null = all students)
- `startDate` (DateTime): When assignment becomes available
- `deadline` (DateTime): Submission deadline
- `allowLateSubmission` (bool): Allow submissions after deadline
- `lateDeadline` (DateTime?): Final deadline for late submissions
- `maxAttempts` (int): Maximum submission attempts per student
- `allowedFileTypes` (List<String>?): Allowed file extensions (e.g., ['pdf', 'docx'])
- `maxFileSize` (int): Max file size in bytes (default 10MB)
- `attachments` (List<AssignmentAttachment>?): Instructor's attachments
- `points` (int): Total points for assignment

**Returns**: `Future<Assignment>` - Created assignment object

**Example**:
```dart
final assignment = await assignmentService.createAssignment(
  courseId: 'course123',
  title: 'Programming Assignment #1',
  description: 'Implement a binary search tree',
  startDate: DateTime.now(),
  deadline: DateTime.now().add(Duration(days: 7)),
  allowLateSubmission: true,
  lateDeadline: DateTime.now().add(Duration(days: 9)),
  maxAttempts: 3,
  allowedFileTypes: ['zip', 'py', 'java'],
  maxFileSize: 5242880, // 5MB
  points: 100,
);
```

---

##### `getAssignmentsByCourse(String courseId)`
```dart
Future<List<Assignment>> getAssignmentsByCourse(String courseId)
```
**Description**: Gets all assignments for a course.

**Parameters**:
- `courseId` (String): Course ID

**Returns**: `Future<List<Assignment>>` - List of assignments

**Example**:
```dart
final assignments = await assignmentService.getAssignmentsByCourse('course123');
print('Found ${assignments.length} assignments');
```

---

##### `getAssignment(String assignmentId)`
```dart
Future<Assignment> getAssignment(String assignmentId)
```
**Description**: Gets detailed assignment information.

**Parameters**:
- `assignmentId` (String): Assignment ID

**Returns**: `Future<Assignment>` - Assignment with all details

**Example**:
```dart
final assignment = await assignmentService.getAssignment('assign123');
print('Title: ${assignment.title}');
print('Deadline: ${assignment.deadline}');
print('Points: ${assignment.points}');
```

---

##### `submitAssignment(...)`
```dart
Future<AssignmentSubmission> submitAssignment({
  required String assignmentId,
  required List<String> fileUrls,
  String? comment,
})
```
**Description**: Submits student's assignment solution.

**Parameters**:
- `assignmentId` (String): Assignment to submit to
- `fileUrls` (List<String>): URLs of uploaded files
- `comment` (String?): Optional student comment

**Returns**: `Future<AssignmentSubmission>` - Submission record

**Workflow**:
1. Upload files using FileService first
2. Pass file URLs to this method
3. Submission recorded with timestamp

**Example**:
```dart
// Step 1: Upload files
final fileService = FileService();
final file = await fileService.pickFile();
final uploadResult = await fileService.uploadFile(file!);

// Step 2: Submit assignment
final submission = await assignmentService.submitAssignment(
  assignmentId: 'assign123',
  fileUrls: [uploadResult['fileUrl']],
  comment: 'Please review my solution',
);

print('Submitted at: ${submission.submittedAt}');
```

---

##### `getMySubmissions(String assignmentId)`
```dart
Future<List<AssignmentSubmission>> getMySubmissions(String assignmentId)
```
**Description**: Gets current user's submissions for an assignment.

**Parameters**:
- `assignmentId` (String): Assignment ID

**Returns**: `Future<List<AssignmentSubmission>>` - List of submissions (sorted by date)

**Example**:
```dart
final submissions = await assignmentService.getMySubmissions('assign123');
if (submissions.isNotEmpty) {
  final latest = submissions.last;
  print('Latest submission: ${latest.submittedAt}');
  print('Grade: ${latest.grade ?? "Not graded yet"}');
}
```

---

##### `gradeSubmission(...)`
```dart
Future<AssignmentSubmission> gradeSubmission({
  required String submissionId,
  required double grade,
  String? feedback,
})
```
**Description**: Grades student submission (instructors only).

**Parameters**:
- `submissionId` (String): Submission to grade
- `grade` (double): Grade value (0 to assignment.points)
- `feedback` (String?): Instructor comments

**Returns**: `Future<AssignmentSubmission>` - Updated submission with grade

**Authorization**: Requires instructor role

**Example**:
```dart
final graded = await assignmentService.gradeSubmission(
  submissionId: 'sub123',
  grade: 85.5,
  feedback: 'Good work! Consider optimizing the search algorithm.',
);

print('Graded: ${graded.grade}/${graded.assignment.points}');
```

---

##### `getAllSubmissions(String assignmentId)`
```dart
Future<List<AssignmentSubmission>> getAllSubmissions(String assignmentId)
```
**Description**: Gets all student submissions for assignment (instructors only).

**Parameters**:
- `assignmentId` (String): Assignment ID

**Returns**: `Future<List<AssignmentSubmission>>` - All submissions

**Use Case**: Grading dashboard for instructors

**Example**:
```dart
final submissions = await assignmentService.getAllSubmissions('assign123');
final graded = submissions.where((s) => s.grade != null).length;
print('$graded/${submissions.length} submissions graded');
```

---

### QuizService

**Purpose**: Manages quizzes, questions, and quiz attempts.

**Location**: `lib/services/quiz_service.dart`

**Extends**: `ApiService`

#### Methods

##### `getQuizzesForCourse(String courseId)`
```dart
Future<List<Quiz>> getQuizzesForCourse(String courseId)
```
**Description**: Retrieves all quizzes for a course.

**Parameters**:
- `courseId` (String): Course ID

**Returns**: `Future<List<Quiz>>` - List of quiz objects

**Example**:
```dart
final quizzes = await quizService.getQuizzesForCourse('course123');
for (var quiz in quizzes) {
  print('${quiz.title}: ${quiz.questions.length} questions');
}
```

---

##### `getQuiz(String quizId)`
```dart
Future<Quiz> getQuiz(String quizId)
```
**Description**: Gets detailed quiz information.

**Parameters**:
- `quizId` (String): Quiz ID

**Returns**: `Future<Quiz>` - Quiz with questions and settings

**Throws**: `ApiException` - On invalid quiz ID

**Example**:
```dart
try {
  final quiz = await quizService.getQuiz('quiz123');
  print('Duration: ${quiz.duration} minutes');
  print('Attempts allowed: ${quiz.maxAttempts}');
} on ApiException catch (e) {
  print('Quiz not found: ${e.message}');
}
```

---

##### `createQuiz(Map<String, dynamic> quizData)`
```dart
Future<Quiz> createQuiz(Map<String, dynamic> quizData)
```
**Description**: Creates new quiz for a course.

**Parameters**:
- `quizData` (Map<String, dynamic>): Quiz configuration

**Quiz Data Structure**:
```dart
{
  'courseId': String,
  'title': String,
  'description': String?,
  'duration': int,  // minutes
  'maxAttempts': int,
  'passingScore': double,
  'shuffleQuestions': bool,
  'showCorrectAnswers': bool,
  'availableFrom': String,  // ISO 8601
  'availableUntil': String,  // ISO 8601
  'questions': List<String>,  // Question IDs
  'totalPoints': int,
}
```

**Example**:
```dart
final quiz = await quizService.createQuiz({
  'courseId': 'course123',
  'title': 'Midterm Exam',
  'description': 'Covers chapters 1-5',
  'duration': 60,
  'maxAttempts': 2,
  'passingScore': 70.0,
  'shuffleQuestions': true,
  'showCorrectAnswers': false,
  'availableFrom': DateTime.now().toIso8601String(),
  'availableUntil': DateTime.now().add(Duration(days: 2)).toIso8601String(),
  'questions': ['q1', 'q2', 'q3'],
  'totalPoints': 100,
});
```

---

##### `updateQuiz(String quizId, Map<String, dynamic> quizData)`
```dart
Future<Quiz> updateQuiz(String quizId, Map<String, dynamic> quizData)
```
**Description**: Updates quiz configuration.

**Parameters**:
- `quizId` (String): Quiz to update
- `quizData` (Map<String, dynamic>): Fields to update

**Returns**: `Future<Quiz>` - Updated quiz

**Example**:
```dart
final updated = await quizService.updateQuiz('quiz123', {
  'duration': 75,  // Extended time
  'maxAttempts': 3,  // One more attempt
});
```

---

##### `deleteQuiz(String quizId)`
```dart
Future<void> deleteQuiz(String quizId)
```
**Description**: Deletes quiz and all associated attempts.

**Parameters**:
- `quizId` (String): Quiz to delete

**Warning**: Cannot be undone. All student attempts will be deleted.

**Example**:
```dart
await quizService.deleteQuiz('quiz123');
```

---

##### `getQuestionsForCourse(String courseId, {String? difficulty, String? category})`
```dart
Future<List<Question>> getQuestionsForCourse(
  String courseId, {
  String? difficulty,
  String? category,
})
```
**Description**: Gets question bank for a course with optional filters.

**Parameters**:
- `courseId` (String): Course ID
- `difficulty` (String?): Filter by difficulty ('easy', 'medium', 'hard')
- `category` (String?): Filter by category/topic

**Returns**: `Future<List<Question>>` - List of questions

**Example**:
```dart
// All questions
final all = await quizService.getQuestionsForCourse('course123');

// Only hard questions
final hard = await quizService.getQuestionsForCourse(
  'course123',
  difficulty: 'hard',
);

// Questions in specific category
final algorithms = await quizService.getQuestionsForCourse(
  'course123',
  category: 'Algorithms',
);
```

---

##### `startQuizAttempt(String quizId)`
```dart
Future<Map<String, dynamic>> startQuizAttempt(String quizId)
```
**Description**: Starts new quiz attempt for student.

**Parameters**:
- `quizId` (String): Quiz to attempt

**Returns**: `Future<Map<String, dynamic>>` - Attempt data with questions

**Response Structure**:
```dart
{
  'attemptId': String,
  'startTime': DateTime,
  'endTime': DateTime,
  'questions': List<Question>,
  'questionsOrder': List<int>,  // For shuffle
}
```

**Example**:
```dart
final attempt = await quizService.startQuizAttempt('quiz123');
final attemptId = attempt['attemptId'];
final questions = attempt['questions'];
final endTime = attempt['endTime'];

print('You have until ${endTime} to complete');
```

---

##### `submitQuizAttempt(String attemptId, Map<String, dynamic> answers)`
```dart
Future<Map<String, dynamic>> submitQuizAttempt(
  String attemptId,
  Map<String, dynamic> answers,
)
```
**Description**: Submits completed quiz attempt.

**Parameters**:
- `attemptId` (String): Attempt ID from startQuizAttempt
- `answers` (Map<String, dynamic>): Student's answers

**Answers Structure**:
```dart
{
  'answers': [
    {
      'questionId': 'q1',
      'selectedOption': 'A',  // For multiple choice
      'answer': 'text',  // For text/essay
    },
  ],
}
```

**Returns**: `Future<Map<String, dynamic>>` - Grading results

**Response Structure**:
```dart
{
  'score': double,
  'totalPoints': int,
  'percentage': double,
  'passed': bool,
  'correctAnswers': int,
  'incorrectAnswers': int,
  'timeTaken': int,  // seconds
  'feedback': List<Object>,  // Per-question feedback
}
```

**Example**:
```dart
final result = await quizService.submitQuizAttempt('attempt123', {
  'answers': [
    {'questionId': 'q1', 'selectedOption': 'B'},
    {'questionId': 'q2', 'selectedOption': 'C'},
    {'questionId': 'q3', 'answer': 'Binary search tree'},
  ],
});

print('Score: ${result['score']}/${result['totalPoints']}');
print('Percentage: ${result['percentage']}%');
print('Result: ${result['passed'] ? "PASSED" : "FAILED"}');
```

---

##### `getQuizResults(String quizId)`
```dart
Future<Map<String, dynamic>> getQuizResults(String quizId)
```
**Description**: Gets aggregated results for a quiz (instructors only).

**Parameters**:
- `quizId` (String): Quiz ID

**Returns**: `Future<Map<String, dynamic>>` - Statistical data

**Response Structure**:
```dart
{
  'totalAttempts': int,
  'averageScore': double,
  'highestScore': double,
  'lowestScore': double,
  'passRate': double,
  'studentResults': List<Object>,
}
```

**Example**:
```dart
final results = await quizService.getQuizResults('quiz123');
print('Average: ${results['averageScore']}');
print('Pass rate: ${results['passRate']}%');
```

---

## Communication Services

### MessageService

**Purpose**: Handles direct messaging between users.

**Location**: `lib/services/message_service.dart`

#### Methods

##### `getConversation(String userId)`
```dart
Future<List<ChatMessage>> getConversation(String userId)
```
**Description**: Gets message history with specific user.

**Parameters**:
- `userId` (String): Other user's ID

**Returns**: `Future<List<ChatMessage>>` - Messages sorted by time

**Example**:
```dart
final messages = await messageService.getConversation('user456');
for (var msg in messages) {
  print('${msg.sender.fullName}: ${msg.content}');
}
```

---

##### `sendMessage(String recipientId, String content)`
```dart
Future<ChatMessage> sendMessage(String recipientId, String content)
```
**Description**: Sends message to another user.

**Parameters**:
- `recipientId` (String): Recipient user ID
- `content` (String): Message text

**Returns**: `Future<ChatMessage>` - Sent message object

**Example**:
```dart
final message = await messageService.sendMessage(
  'user456',
  'Hey, can you help me with assignment #3?',
);
```

---

##### `getUnreadCount()`
```dart
Future<int> getUnreadCount()
```
**Description**: Gets count of unread messages.

**Returns**: `Future<int>` - Number of unread messages

**Example**:
```dart
final unread = await messageService.getUnreadCount();
if (unread > 0) {
  showNotificationBadge(unread);
}
```

---

##### `markAsRead(String messageId)`
```dart
Future<bool> markAsRead(String messageId)
```
**Description**: Marks message as read.

**Parameters**:
- `messageId` (String): Message to mark

**Returns**: `Future<bool>` - Success status

**Example**:
```dart
await messageService.markAsRead('msg123');
```

---

### NotificationService

**Purpose**: Manages in-app notifications for various events.

**Location**: `lib/services/notification_service.dart`

**Extends**: `ApiService`

#### Methods

##### `getNotifications({bool? unreadOnly})`
```dart
Future<List<NotificationModel>> getNotifications({bool? unreadOnly})
```
**Description**: Retrieves user notifications.

**Parameters**:
- `unreadOnly` (bool?): Filter for unread only (default: false)

**Returns**: `Future<List<NotificationModel>>` - Notifications list

**Example**:
```dart
// Get all notifications
final all = await notificationService.getNotifications();

// Get only unread
final unread = await notificationService.getNotifications(unreadOnly: true);
```

---

##### `getUnreadCount()`
```dart
Future<int> getUnreadCount()
```
**Description**: Gets count of unread notifications.

**Returns**: `Future<int>` - Unread count

**Use Case**: Badge on notification bell icon

**Example**:
```dart
final count = await notificationService.getUnreadCount();
setState(() => _notificationBadge = count);
```

---

##### `markAsRead(String notificationId)`
```dart
Future<void> markAsRead(String notificationId)
```
**Description**: Marks notification as read.

**Parameters**:
- `notificationId` (String): Notification ID

**Example**:
```dart
await notificationService.markAsRead('notif123');
```

---

##### `markAllAsRead()`
```dart
Future<void> markAllAsRead()
```
**Description**: Marks all notifications as read.

**Example**:
```dart
await notificationService.markAllAsRead();
```

---

### AnnouncementService

**Purpose**: Manages course announcements.

**Location**: `lib/services/announcement_service.dart`

#### Methods

##### `getAnnouncements(String courseId)`
```dart
Future<List<Announcement>> getAnnouncements(String courseId)
```
**Description**: Gets all announcements for a course.

**Parameters**:
- `courseId` (String): Course ID

**Returns**: `Future<List<Announcement>>` - Announcements (newest first)

**Filtering**:
- Students: See only announcements for their groups
- Instructors: See all announcements

**Example**:
```dart
final announcements = await announcementService.getAnnouncements('course123');
for (var announcement in announcements) {
  print('[${announcement.createdAt}] ${announcement.title}');
}
```

---

##### `createAnnouncement(...)`
```dart
Future<Announcement> createAnnouncement({
  required String courseId,
  required String title,
  required String content,
  List<String>? groupIds,
  List<String>? attachments,
})
```
**Description**: Posts new announcement (instructors only).

**Parameters**:
- `courseId` (String): Course to post in
- `title` (String): Announcement title
- `content` (String): Announcement body (supports Markdown)
- `groupIds` (List<String>?): Target specific groups (null = all students)
- `attachments` (List<String>?): File URLs

**Returns**: `Future<Announcement>` - Created announcement

**Notifications**: Automatically sends notifications to students

**Example**:
```dart
final announcement = await announcementService.createAnnouncement(
  courseId: 'course123',
  title: 'Class Cancelled Tomorrow',
  content: 'Due to university holiday, no class on 12/4. See you next week!',
  attachments: [],
);
```

---

##### `updateAnnouncement(...)`
```dart
Future<Announcement> updateAnnouncement({
  required String id,
  required String title,
  required String content,
})
```
**Description**: Updates existing announcement.

**Parameters**:
- `id` (String): Announcement ID
- `title` (String): Updated title
- `content` (String): Updated content

**Returns**: `Future<Announcement>` - Updated announcement

**Example**:
```dart
final updated = await announcementService.updateAnnouncement(
  id: 'announce123',
  title: 'Class Rescheduled',
  content: 'Class moved to Friday 2PM instead of cancellation.',
);
```

---

##### `deleteAnnouncement(String id)`
```dart
Future<void> deleteAnnouncement(String id)
```
**Description**: Deletes announcement.

**Parameters**:
- `id` (String): Announcement to delete

**Example**:
```dart
await announcementService.deleteAnnouncement('announce123');
```

---

## Media Services

### FileService

**Purpose**: Handles file uploads and downloads.

**Location**: `lib/services/file_service.dart`

#### Methods

##### `pickFile()`
```dart
Future<PlatformFile?> pickFile()
```
**Description**: Opens file picker for user to select file.

**Returns**: `Future<PlatformFile?>` - Selected file or null if cancelled

**Example**:
```dart
final file = await fileService.pickFile();
if (file != null) {
  print('Selected: ${file.name} (${file.size} bytes)');
}
```

---

##### `uploadFile(PlatformFile file)`
```dart
Future<Map<String, dynamic>> uploadFile(PlatformFile file)
```
**Description**: Uploads file to server using multipart/form-data.

**Parameters**:
- `file` (PlatformFile): File to upload

**Returns**: `Future<Map<String, dynamic>>` - Upload result

**Response Structure**:
```dart
{
  'fileName': String,
  'fileUrl': String,
  'fileId': String,
  'fileSize': int,
  'mimeType': String,
}
```

**Example**:
```dart
final file = await fileService.pickFile();
if (file != null) {
  final result = await fileService.uploadFile(file);
  print('Uploaded to: ${result['fileUrl']}');
  print('File ID: ${result['fileId']}');
}
```

---

##### `downloadFile(String fileId, String fileName)`
```dart
Future<void> downloadFile(String fileId, String fileName)
```
**Description**: Downloads file from server.

**Parameters**:
- `fileId` (String): File ID to download
- `fileName` (String): Original filename

**Implementation**: Opens download URL in browser

**Example**:
```dart
await fileService.downloadFile('file123', 'assignment.pdf');
```

---

### VideoService

**Purpose**: Manages video content and streaming.

**Location**: `lib/services/video_service.dart`

#### Methods

##### `getVideosForCourse(String courseId)`
```dart
Future<List<Video>> getVideosForCourse(String courseId)
```
**Description**: Gets all videos for a course.

**Parameters**:
- `courseId` (String): Course ID

**Returns**: `Future<List<Video>>` - Video list

**Example**:
```dart
final videos = await videoService.getVideosForCourse('course123');
for (var video in videos) {
  print('${video.title} (${video.duration}s)');
}
```

---

##### `uploadVideo(...)`
```dart
Future<Video> uploadVideo({
  required String courseId,
  required String title,
  required PlatformFile file,
  String? description,
})
```
**Description**: Uploads video file to server.

**Parameters**:
- `courseId` (String): Course to add video to
- `title` (String): Video title
- `file` (PlatformFile): Video file
- `description` (String?): Video description

**Returns**: `Future<Video>` - Uploaded video metadata

**Supported Formats**: MP4, WebM, OGG

**Max Size**: 500MB

**Example**:
```dart
final videoFile = await FilePicker.platform.pickFiles(
  type: FileType.video,
);

if (videoFile != null) {
  final video = await videoService.uploadVideo(
    courseId: 'course123',
    title: 'Lecture 1: Introduction',
    file: videoFile.files.first,
    description: 'Course overview and syllabus',
  );
  print('Video uploaded: ${video.url}');
}
```

---

##### `trackProgress(...)`
```dart
Future<void> trackProgress({
  required String videoId,
  required int progress,
  required bool completed,
})
```
**Description**: Updates student's video watch progress.

**Parameters**:
- `videoId` (String): Video being watched
- `progress` (int): Current position in seconds
- `completed` (bool): True if video finished

**Use Case**: Called periodically during video playback

**Example**:
```dart
// During playback
videoPlayer.addListener(() {
  final position = videoPlayer.value.position.inSeconds;
  videoService.trackProgress(
    videoId: 'video123',
    progress: position,
    completed: position >= videoDuration,
  );
});
```

---

### CallService

**Purpose**: Manages video/voice calls using Agora.

**Location**: `lib/services/call_service.dart`

#### Methods

##### `initiateCall({required String calleeId, required String type})`
```dart
Future<Call> initiateCall({
  required String calleeId,
  required String type,
})
```
**Description**: Starts new call to another user.

**Parameters**:
- `calleeId` (String): User to call
- `type` (String): 'voice' or 'video'

**Returns**: `Future<Call>` - Call object with channel info

**Response Structure**:
```dart
Call {
  id: String,
  caller: User,
  callee: User,
  type: String,
  status: String,  // 'ringing', 'active', 'ended'
  channelName: String,
  startTime: DateTime,
}
```

**Example**:
```dart
final call = await callService.initiateCall(
  calleeId: 'user456',
  type: 'video',
);

// Join Agora channel
await agoraEngine.joinChannel(
  token: call.agoraToken,
  channelName: call.channelName,
  uid: 0,
);
```

---

##### `generateAgoraToken(...)`
```dart
Future<Map<String, dynamic>> generateAgoraToken({
  required String channelName,
  required int uid,
})
```
**Description**: Generates Agora RTC token for channel.

**Parameters**:
- `channelName` (String): Agora channel name
- `uid` (int): User's Agora UID

**Returns**: `Future<Map<String, dynamic>>` - Token and expiry

**Response Structure**:
```dart
{
  'token': String,
  'expiry': int,  // Unix timestamp
}
```

**Example**:
```dart
final tokenData = await callService.generateAgoraToken(
  channelName: 'course123-call',
  uid: 12345,
);

print('Token: ${tokenData['token']}');
print('Expires: ${DateTime.fromMillisecondsSinceEpoch(tokenData['expiry'])}');
```

---

## Administrative Services

### AdminService

**Purpose**: Admin-only operations for user and system management.

**Location**: `lib/services/admin_service.dart`

#### Methods

##### `getAllUsers({String? role, String? department})`
```dart
Future<List<User>> getAllUsers({String? role, String? department})
```
**Description**: Gets all system users with optional filters.

**Parameters**:
- `role` (String?): Filter by role ('admin', 'instructor', 'student')
- `department` (String?): Filter by department ID

**Returns**: `Future<List<User>>` - User list

**Authorization**: Admin only

**Example**:
```dart
// All users
final all = await adminService.getAllUsers();

// Only instructors
final instructors = await adminService.getAllUsers(role: 'instructor');

// Students in CS department
final csStudents = await adminService.getAllUsers(
  role: 'student',
  department: 'dept-cs',
);
```

---

##### `createUser(Map<String, dynamic> userData)`
```dart
Future<User> createUser(Map<String, dynamic> userData)
```
**Description**: Creates new user account (admin only).

**Parameters**:
- `userData` (Map<String, dynamic>): User information

**User Data Structure**:
```dart
{
  'fullName': String,
  'email': String,
  'username': String,
  'password': String,
  'role': String,  // 'admin', 'instructor', 'student'
  'department': String?,  // Department ID
  'phone': String?,
}
```

**Returns**: `Future<User>` - Created user

**Example**:
```dart
final user = await adminService.createUser({
  'fullName': 'Jane Smith',
  'email': 'jane@university.edu',
  'username': 'janesmith',
  'password': 'TempPass123!',
  'role': 'instructor',
  'department': 'dept-cs',
  'phone': '+1-555-0123',
});
```

---

##### `updateUser(String userId, Map<String, dynamic> updates)`
```dart
Future<User> updateUser(String userId, Map<String, dynamic> updates)
```
**Description**: Updates user information.

**Parameters**:
- `userId` (String): User to update
- `updates` (Map<String, dynamic>): Fields to update

**Returns**: `Future<User>` - Updated user

**Example**:
```dart
final updated = await adminService.updateUser('user123', {
  'role': 'instructor',  // Promote to instructor
  'department': 'dept-math',
});
```

---

##### `deleteUser(String userId)`
```dart
Future<void> deleteUser(String userId)
```
**Description**: Permanently deletes user account.

**Parameters**:
- `userId` (String): User to delete

**Warning**: Cannot be undone. All user data will be deleted.

**Example**:
```dart
await adminService.deleteUser('user123');
```

---

### DepartmentService

**Purpose**: Manages academic departments and their members.

**Location**: `lib/services/department_service.dart`

#### Methods

##### `getAllDepartments()`
```dart
Future<List<Department>> getAllDepartments()
```
**Description**: Gets all departments.

**Returns**: `Future<List<Department>>` - Department list

**Example**:
```dart
final departments = await departmentService.getAllDepartments();
for (var dept in departments) {
  print('${dept.name}: ${dept.employees.length} employees');
}
```

---

##### `createDepartment(Map<String, dynamic> deptData)`
```dart
Future<Department> createDepartment(Map<String, dynamic> deptData)
```
**Description**: Creates new department.

**Parameters**:
- `deptData` (Map<String, dynamic>): Department information

**Structure**:
```dart
{
  'name': String,
  'code': String,
  'description': String?,
  'head': String?,  // User ID of department head
}
```

**Returns**: `Future<Department>` - Created department

**Example**:
```dart
final dept = await departmentService.createDepartment({
  'name': 'Computer Science',
  'code': 'CS',
  'description': 'Department of Computer Science and Engineering',
  'head': 'user123',
});
```

---

##### `addEmployeesToDepartment(String deptId, List<String> userIds)`
```dart
Future<void> addEmployeesToDepartment(String deptId, List<String> userIds)
```
**Description**: Adds multiple employees to department.

**Parameters**:
- `deptId` (String): Department ID
- `userIds` (List<String>): User IDs to add

**Example**:
```dart
await departmentService.addEmployeesToDepartment(
  'dept-cs',
  ['user1', 'user2', 'user3'],
);
```

---

### ReportService

**Purpose**: Generates analytics and reports.

**Location**: `lib/services/report_service.dart`

#### Methods

##### `generateDepartmentReport(...)`
```dart
Future<void> generateDepartmentReport({
  required String departmentId,
  required String format,  // 'excel' or 'pdf'
  required Function(List<int> bytes, String filename) onSuccess,
})
```
**Description**: Generates department performance report.

**Parameters**:
- `departmentId` (String): Department to report on
- `format` (String): 'excel' or 'pdf'
- `onSuccess` (Function): Callback with file bytes

**Example**:
```dart
await reportService.generateDepartmentReport(
  departmentId: 'dept-cs',
  format: 'excel',
  onSuccess: (bytes, filename) async {
    // Save file
    final file = File('downloads/$filename');
    await file.writeAsBytes(bytes);
    print('Report saved: $filename');
  },
);
```

---

## Error Handling

### ApiException

**Purpose**: Custom exception for API errors.

**Structure**:
```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}
```

### Common Error Patterns

#### Network Errors
```dart
try {
  final data = await apiService.get('/api/endpoint');
} on SocketException {
  // No internet or server unreachable
  showSnackBar('Cannot connect to server');
} on HttpException {
  // HTTP protocol error
  showSnackBar('Network error occurred');
} on ApiException catch (e) {
  // API-specific error with message
  showSnackBar(e.message);
} catch (e) {
  // Unknown error
  showSnackBar('Unexpected error: $e');
}
```

#### Authentication Errors
```dart
try {
  await apiService.get('/api/protected');
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Token expired or invalid
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  } else if (e.statusCode == 403) {
    // Insufficient permissions
    showSnackBar('Access denied');
  }
}
```

#### Validation Errors
```dart
try {
  await courseService.createCourse(...);
} on ApiException catch (e) {
  if (e.statusCode == 400) {
    // Bad request - show validation errors
    showSnackBar(e.message);  // e.g., "Course code already exists"
  }
}
```

---

## Best Practices

### 1. Always Test Connectivity
```dart
final isConnected = await apiService.testConnection();
if (!isConnected) {
  showDialog('Backend server is not running');
  return;
}
```

### 2. Use Proper Error Handling
```dart
// ❌ Bad
try {
  final data = await service.getData();
} catch (e) {
  print(e);  // Silent failure
}

// ✅ Good
try {
  final data = await service.getData();
} on ApiException catch (e) {
  showSnackBar('Error: ${e.message}');
  LoggerService.error('getData failed', e);
} on SocketException {
  showSnackBar('No internet connection');
}
```

### 3. Handle Loading States
```dart
setState(() => _isLoading = true);
try {
  final courses = await courseService.getCourses();
  setState(() {
    _courses = courses;
    _isLoading = false;
  });
} catch (e) {
  setState(() {
    _error = e.toString();
    _isLoading = false;
  });
}
```

### 4. Cache Frequently Accessed Data
```dart
// Cache user profile to avoid repeated API calls
User? _cachedUser;

Future<User> getCurrentUser() async {
  if (_cachedUser != null) return _cachedUser!;
  _cachedUser = await authService.getCurrentUser();
  return _cachedUser!;
}
```

### 5. Use Pagination for Large Lists
```dart
Future<void> _loadMoreCourses() async {
  if (_isLoadingMore || !_hasMore) return;
  
  setState(() => _isLoadingMore = true);
  
  final newCourses = await courseService.getCourses(
    page: _currentPage + 1,
    limit: 20,
  );
  
  setState(() {
    _courses.addAll(newCourses);
    _currentPage++;
    _hasMore = newCourses.length == 20;
    _isLoadingMore = false;
  });
}
```

### 6. Validate Before API Calls
```dart
Future<void> _createCourse() async {
  // Validate locally first
  if (_nameController.text.isEmpty) {
    showSnackBar('Course name is required');
    return;
  }
  
  if (_codeController.text.length < 3) {
    showSnackBar('Course code must be at least 3 characters');
    return;
  }
  
  // Then call API
  try {
    await courseService.createCourse(...);
  } catch (e) {
    // Handle error
  }
}
```

### 7. Use Timeout for Long Operations
```dart
try {
  final result = await videoService
      .uploadVideo(file)
      .timeout(Duration(minutes: 5));
} on TimeoutException {
  showSnackBar('Upload timeout. Please try again.');
}
```

### 8. Implement Retry Logic
```dart
Future<T> retryOperation<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw Exception('Max retries reached');
}

// Usage
final courses = await retryOperation(
  () => courseService.getCourses(),
);
```

---

## Quick Reference

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Success |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Fix validation errors |
| 401 | Unauthorized | Login required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Contact backend team |

### Common Endpoints

```
Authentication:
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/logout
GET    /api/auth/me

Courses:
GET    /api/courses
GET    /api/courses/:id
POST   /api/courses
PUT    /api/courses/:id
DELETE /api/courses/:id

Assignments:
GET    /api/assignments/course/:courseId
POST   /api/assignments
POST   /api/assignments/:id/submit

Quizzes:
GET    /api/quizzes/course/:courseId
POST   /api/quizzes
POST   /api/quiz-attempts/:quizId/start
POST   /api/quiz-attempts/:attemptId/submit

Files:
POST   /api/files/upload
GET    /api/files/:fileId

Notifications:
GET    /api/notifications
GET    /api/notifications/unread/count
PUT    /api/notifications/:id/read
```

---

**Last Updated**: December 3, 2025  
**Maintainer**: Development Team  
**Version**: 1.0.0
