# Course Management Implementation - Assign Teacher & Students

## Overview
Implemented comprehensive course management features allowing administrators and instructors to assign teachers and students to courses via invitation system with accept/reject capabilities.

## Features Implemented

### 1. Backend API Endpoints

#### Assign Teacher to Course
- **Endpoint**: `POST /api/courses/:id/assign-teacher`
- **Access**: Admin only
- **Functionality**:
  - Sends invitation notification to instructor
  - Instructor can accept or decline
  - Notification sent via `teacher_invite` type

#### Respond to Teacher Invitation
- **Endpoint**: `POST /api/courses/:id/respond-teacher-invite`
- **Access**: Instructor/Admin only
- **Parameters**:
  - `notificationId`: ID of the invitation notification
  - `accept`: Boolean (true/false)
- **Functionality**:
  - If accepted: Assigns instructor to course
  - If declined: Marks notification as read
  - Notifies admin of response

#### Assign Students to Course
- **Endpoint**: `POST /api/courses/:id/assign-students`
- **Access**: Admin or Course Instructor
- **Parameters**:
  - `studentIds`: Array of student IDs
  - `groupId`: Optional group ID
- **Functionality**:
  - Sends course invitations to selected students
  - Students can accept/reject via existing notification system
  - Supports group assignment

### 2. Frontend Features

#### Create Course Dialog Enhancements
- **Admin Users**:
  - Instructor dropdown showing all users with instructor role
  - Option to assign instructor immediately or leave blank for later assignment
  - Fetches instructors from `/api/admin/instructors`
  
- **Non-Admin Users**:
  - Shows current user as instructor (read-only)

#### Manage Courses Screen - New Actions
1. **Assign Teacher Button** (Admin only)
   - Opens dialog with instructor selection
   - Shows instructor profile pictures and emails
   - Sends invitation to selected instructor
   - Success/error feedback messages

2. **Assign Students Button** (Admin & Instructors)
   - Opens dialog with searchable student list
   - Multi-select checkbox interface
   - Shows student profile pictures
   - Displays count of selected students
   - Sends batch invitations

3. **Updated Course Display**
   - Changed from ListTile to ExpansionTile
   - Shows student count
   - Expandable actions panel with buttons
   - Color-coded action buttons:
     - Blue: Edit
     - Green: Assign Teacher
     - Purple: Assign Students
     - Red: Delete

#### Notification Screen Enhancements
- **Teacher Invitation Notifications**:
  - Type: `teacher_invite`
  - Shows course details (name, code)
  - Accept/Decline buttons for unread invitations
  - Automatically marks as read after response
  - Success confirmation messages

### 3. Service Layer Updates

#### CourseService (`lib/services/course_service.dart`)
Added methods:
```dart
Future<void> assignTeacher({
  required String courseId,
  required String instructorId,
})

Future<void> assignStudents({
  required String courseId,
  required List<String> studentIds,
  String? groupId,
})

Future<void> respondToTeacherInvite({
  required String courseId,
  required String notificationId,
  required bool accept,
})
```

#### AdminService (`lib/services/admin_service.dart`)
- Already had `getAllInstructors()` method
- Returns list of users with instructor or admin roles
- Includes profile pictures and full names

### 4. User Flow

#### Admin Assigning Teacher:
1. Navigate to Manage Courses screen
2. Expand a course
3. Click "Assign Teacher" button
4. Select instructor from dropdown
5. Click "Send Invitation"
6. Instructor receives `teacher_invite` notification

#### Instructor Responding to Assignment:
1. View notification in Notifications screen
2. See course assignment invitation
3. Click "Accept" or "Decline"
4. If accepted: Becomes instructor of the course
5. Admin receives response notification

#### Assigning Students:
1. Navigate to Manage Courses screen
2. Expand a course
3. Click "Assign Students" button
4. Select students from list (multi-select)
5. Click "Send Invitations"
6. Students receive `course_invite` notifications

#### Students Responding (Existing System):
1. View course invitation notification
2. Click "Accept" or "Decline"
3. If accepted: Enrolled in course
4. Instructor receives response notification

## Database Schema
No schema changes required - uses existing:
- Notification collection with `type` field
- Course collection with `instructor` field
- Existing notification data structure

## Notification Types

### New Type Added:
- **`teacher_invite`**: Course assignment invitation for instructors
  - Data includes: courseId, courseName, courseCode, adminId, adminName
  - Supports accept/reject workflow

### Existing Types Used:
- **`course_invite`**: Course invitation for students
- **`teacher_invite_response`**: Notification to admin about instructor's response

## UI Components

### Dialogs Created:
1. **Assign Teacher Dialog**
   - Instructor dropdown with avatars
   - Shows current instructor
   - Loading states

2. **Assign Students Dialog**
   - Searchable student list
   - Checkbox multi-select
   - Selected count display
   - Profile picture avatars

### Enhanced Components:
1. **Course Card (ExpansionTile)**
   - Expandable design
   - Action buttons panel
   - Student count display
   - Conditional visibility (admin-only buttons)

## Security & Permissions

### Backend Security:
- **Assign Teacher**: Admin only
- **Respond to Teacher Invite**: Instructor/Admin only
- **Assign Students**: Admin or course instructor only
- All endpoints protected by `auth` middleware

### Frontend Permissions:
- "Assign Teacher" button visible to admins only
- "Assign Students" available to admins and instructors
- Edit/Delete restricted to courses from active semesters

## Error Handling

### Backend:
- Validates course existence
- Validates user roles
- Checks notification existence
- Proper error messages returned

### Frontend:
- Loading spinners during operations
- Success/error SnackBar messages
- Form validation
- Try-catch blocks with user feedback

## Testing Checklist

- [ ] Admin can view all instructors in dropdown
- [ ] Admin can send teacher invitation
- [ ] Instructor receives notification
- [ ] Instructor can accept invitation
- [ ] Instructor can decline invitation
- [ ] Admin receives response notification
- [ ] Course instructor field updates on acceptance
- [ ] Admin can assign students
- [ ] Instructor can assign students to their course
- [ ] Students receive course invitations
- [ ] Students can accept/decline
- [ ] Multiple students can be invited at once
- [ ] Profile pictures display correctly
- [ ] Loading states work properly
- [ ] Error messages display correctly

## Files Modified

### Backend:
- `backend/routes/courses.js` - Added 3 new endpoints

### Frontend:
- `lib/screens/manage_courses_screen.dart` - Major UI overhaul
- `lib/screens/notifications_screen.dart` - Added teacher invite handling
- `lib/services/course_service.dart` - Added 3 new methods

### No Changes Required:
- `lib/services/admin_service.dart` - Already had getAllInstructors()
- Backend notification system - Works with existing infrastructure

## Next Steps / Future Enhancements

1. **Bulk Operations**: Import CSV to assign multiple students
2. **Assignment History**: Track who assigned whom and when
3. **Reassignment**: Allow changing course instructor
4. **Student Search**: Add search/filter in assign students dialog
5. **Group-Based Assignment**: Auto-assign students by group
6. **Notification Preferences**: Let users configure notification types
7. **Analytics**: Track invitation acceptance rates

## Known Limitations

1. Once instructor accepts, cannot be changed (requires manual database update)
2. No pagination in student selection (may be slow with many students)
3. No search functionality in dialogs
4. Cannot assign multiple instructors to one course

## API Documentation

### POST /api/courses/:id/assign-teacher
Request:
```json
{
  "instructorId": "65abc123..."
}
```

Response (200):
```json
{
  "message": "Teacher invitation sent successfully",
  "notification": { ... }
}
```

### POST /api/courses/:id/respond-teacher-invite
Request:
```json
{
  "notificationId": "65def456...",
  "accept": true
}
```

Response (200) - Accept:
```json
{
  "message": "Course assignment accepted",
  "course": { ... }
}
```

Response (200) - Decline:
```json
{
  "message": "Course assignment declined"
}
```

### POST /api/courses/:id/assign-students
Request:
```json
{
  "studentIds": ["65ghi789...", "65jkl012..."],
  "groupId": "65mno345..." // optional
}
```

Response (200):
```json
{
  "message": "Student invitations sent successfully",
  "count": 2
}
```

---

**Implementation Date**: October 31, 2025  
**Status**: ✅ Complete and Ready for Testing
