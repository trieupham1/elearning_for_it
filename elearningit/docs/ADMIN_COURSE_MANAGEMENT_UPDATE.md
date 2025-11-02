# Admin Course Management - Complete Implementation

## 📍 File Updated
**`lib/screens/admin/manage_courses_screen.dart`**

## ✅ Features Implemented

### 1. **Assign Teacher to Course**
- **Access**: Admin only
- **Location**: Expandable course card → "Assign Teacher" button (Blue)
- **Functionality**:
  - Opens dialog with dropdown of all instructors
  - Shows instructor profile pictures and emails
  - Sends invitation notification to selected instructor
  - Instructor receives notification and can accept/reject
  - Shows current instructor in dialog header
  - Loading spinner during operation
  - Success/error feedback messages

**User Flow:**
1. Expand a course card
2. Click "Assign Teacher" button
3. Select instructor from dropdown
4. Click "Send Invitation"
5. Instructor gets notification → accepts/declines
6. Admin gets response notification

### 2. **Assign Students to Course**
- **Access**: Admin
- **Location**: Expandable course card → "Assign Students" button (Green)
- **Functionality**:
  - Opens full-screen dialog with student list
  - Multi-select checkboxes for bulk invitation
  - Shows student profile pictures
  - Displays count of selected students
  - Sends course invitations to all selected students
  - Students can accept/reject via notifications
  - Loading spinner during operation
  - Success/error feedback messages

**User Flow:**
1. Expand a course card
2. Click "Assign Students" button
3. Check students to invite (multi-select)
4. Click "Send Invitations"
5. Students get notifications → accept/decline
6. Accepted students are enrolled

### 3. **Create Course with Instructor Assignment**
- **Enhanced Dialog**: Admin can now select instructor when creating course
- **Dropdown Options**:
  - "-- Assign Later --" (default) - Creates course without instructor
  - List of all instructors with their names
- **Helper Text**: "Leave blank to assign later via invitation"
- **Fallback**: If instructor not selected, course created without instructor (can assign later)

### 4. **Improved Course Display**
- **ExpansionTile Design**: Tap to expand/collapse course actions
- **Course Info Shown**:
  - Course code
  - Semester name
  - Number of sessions
  - Instructor name (or "Unknown")
  - "READ ONLY" badge for inactive semester courses
  
- **Action Buttons** (in expandable section):
  - 🔵 **Assign Teacher** - Send invitation to instructor
  - 🟢 **Assign Students** - Bulk invite students
  - ⚪ **Edit** - Edit course details (outlined button)
  - 🔴 **Delete** - Remove course (outlined red button)

## 🔧 Technical Details

### Services Used:
```dart
final _courseService = CourseService();
final _semesterService = SemesterService();
final _authService = AuthService();
final _adminService = AdminService();      // NEW
final _studentService = StudentService();  // NEW
```

### State Variables Added:
```dart
List<User> _instructors = [];  // Loaded in _loadData()
```

### API Methods Used:
```dart
// From CourseService
await _courseService.assignTeacher(courseId, instructorId);
await _courseService.assignStudents(courseId, studentIds);

// From AdminService
await _adminService.getAllInstructors();

// From StudentService
await _studentService.getStudents();
```

### Backend Endpoints Called:
- `POST /api/courses/:id/assign-teacher` - Send teacher invitation
- `POST /api/courses/:id/assign-students` - Send student invitations
- `GET /api/admin/instructors` - Get all instructors
- `GET /api/admin/students` - Get all students

## 🎨 UI Components

### Assign Teacher Dialog:
```
┌─────────────────────────────────────┐
│ Assign Teacher to [Course Name]    │
├─────────────────────────────────────┤
│ Current instructor: John Doe        │
│                                     │
│ Select a new instructor to send... │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar] Mai Van Manh           │ │
│ │          mai@example.com        │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [Cancel]  [Send Invitation] │
└─────────────────────────────────────┘
```

### Assign Students Dialog:
```
┌──────────────────────────────────────┐
│ Assign Students to [Course Name]    │
├──────────────────────────────────────┤
│ Select students to send invitations: │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ☑ [Avatar] Nguyen Van An        │ │
│ │            nguyen@student.com   │ │
│ │ ☐ [Avatar] Tran Thi Binh        │ │
│ │ ☑ [Avatar] Le Van Cuong         │ │
│ └──────────────────────────────────┘ │
│                                      │
│ 2 student(s) selected                │
│                                      │
│       [Cancel]  [Send Invitations]   │
└──────────────────────────────────────┘
```

### Course Card (Expanded):
```
┌─────────────────────────────────────────┐
│ [Icon] Course Name               [v]   │
│        Code: AI502083                  │
│        Semester: Semester 1, 2025-2026 │
│        Sessions: 15                    │
│        Instructor: Mai Van Manh        │
├─────────────────────────────────────────┤
│ Course Actions                          │
│                                         │
│ [Assign Teacher] [Assign Students]     │
│ [Edit]           [Delete]              │
└─────────────────────────────────────────┘
```

## 🔒 Security & Permissions

### Button Visibility:
- All buttons disabled for courses in inactive semesters
- "Assign Teacher" visible to admins only
- "Assign Students" visible to admins (and could be extended to instructors)

### Backend Validation:
- `/assign-teacher`: Requires admin role
- `/assign-students`: Requires admin or instructor role
- All endpoints validate course existence
- Notification system validates user roles

## 🚀 Testing Steps

1. **Login as Admin**
2. **Navigate to Manage Courses** (from admin drawer)
3. **Test Create Course with Instructor**:
   - Click "Create Course" FAB
   - Fill in course details
   - Select an instructor from dropdown (or leave blank)
   - Create course
   - Verify course created successfully

4. **Test Assign Teacher**:
   - Expand a course
   - Click "Assign Teacher" (blue button)
   - Select an instructor
   - Send invitation
   - Check instructor's notifications
   - Instructor accepts/declines
   - Verify course instructor updates

5. **Test Assign Students**:
   - Expand a course
   - Click "Assign Students" (green button)
   - Select multiple students
   - Send invitations
   - Check students' notifications
   - Students accept/decline
   - Verify student enrollment

## 📱 Screenshots Location
- Course list with expandable cards
- Assign teacher dialog
- Assign students dialog with multi-select
- Notification acceptance UI

## ⚠️ Known Limitations

1. No search functionality in student selection dialog (may be slow with 100+ students)
2. Cannot reassign instructor after acceptance (requires manual DB update or new backend endpoint)
3. No pagination in dialogs
4. Profile pictures loaded via NetworkImage (may be slow)

## 🔄 Related Files

### Also Updated:
- `lib/services/course_service.dart` - Added assignTeacher(), assignStudents(), respondToTeacherInvite()
- `lib/screens/notifications_screen.dart` - Added teacher invite handling
- `backend/routes/courses.js` - Added 3 new endpoints

### Already Existed (No Changes):
- `lib/services/admin_service.dart` - getAllInstructors()
- `lib/services/student_service.dart` - getStudents()
- Backend notification system

## 📝 Next Steps

**Ready to test now:**
1. Hot reload Flutter app
2. Backend should already be running on port 5000
3. Login as admin
4. Navigate to Manage Courses from admin drawer
5. Test all features!

**Future Enhancements:**
- Add search in student selection dialog
- Add pagination for large student lists
- Allow instructor reassignment
- Add bulk operations (CSV import)
- Add filtering by semester/department
- Show enrollment statistics

---

**Implementation Date**: October 31, 2025  
**Status**: ✅ Complete and Ready for Testing  
**File Location**: `lib/screens/admin/manage_courses_screen.dart`
