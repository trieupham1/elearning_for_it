# Notification Types Specification

## Student Notifications

Students receive the following notification types:

1. **Material** (`material`)
   - When instructor uploads new course material
   - Icon: Folder (📁)
   - Color: Blue (#2196F3)

2. **Announcement** (`announcement`)
   - When instructor posts a new announcement
   - Icon: Campaign (📢)
   - Color: Orange (#FF9800)

3. **Assignment** (`assignment`)
   - When a new assignment is created
   - Icon: Assignment (📝)
   - Color: Red (#F44336)

4. **Comment** (`comment`)
   - When someone replies to their forum post or comment
   - Icon: Comment (💬)
   - Color: Purple (#9C27B0)

5. **Message** (`message`)
   - When instructor sends a private message to the student
   - Icon: Message (✉️)
   - Color: Green (#4CAF50)

6. **Quiz** (`quiz`)
   - When a new quiz is available
   - Icon: Quiz (❓)
   - Color: Deep Orange (#FF5722)

7. **Course Invite** (`course_invite`)
   - When instructor invites them to join a course
   - Shows Accept/Decline buttons
   - Icon: School (🎓)
   - Color: Indigo (#3F51B5)

## Instructor Notifications

Instructors receive the following notification types:

1. **Comment** (`comment`)
   - When students post comments in forums or discussions
   - Icon: Comment (💬)
   - Color: Purple (#9C27B0)

2. **Submission** (`submission`)
   - When a student submits an assignment
   - Icon: Assignment Turned In (✅)
   - Color: Cyan (#00BCD4)

3. **Message** (`message`)
   - When student sends a private message to the instructor
   - When student requests to join a course (via join code)
   - Icon: Message (✉️)
   - Color: Green (#4CAF50)

4. **Quiz Attempt** (`quiz_attempt`)
   - When a student completes a quiz
   - Icon: Assignment Turned In (✅)
   - Color: Cyan (#00BCD4)

5. **Course Invite Response** (`course_invite`)
   - When student accepts/declines course invitation
   - Icon: School (🎓)
   - Color: Indigo (#3F51B5)

## Notification Filters

The notification screen has three simple filters:

- **All**: Shows all notifications
- **Unread**: Shows only unread notifications
- **Read**: Shows only read notifications

Each filter chip displays the count in parentheses, e.g., "Unread (5)"

## Notification Badge

The notification bell icon in the dashboard shows:
- Red circular badge with unread count when there are unread notifications
- Displays "99+" if unread count exceeds 99
- Badge disappears when all notifications are read

## UI Features

- **Swipe to delete**: Swipe left on any notification to delete it
- **Mark as read**: Tap the notification or use the mark as read button
- **Mark all as read**: Button in app bar when unread notifications exist
- **Timeago format**: Shows relative time like "2 hours ago", "yesterday", etc.
- **Course invitations**: Special action buttons (Accept/Decline) for course invitation notifications
