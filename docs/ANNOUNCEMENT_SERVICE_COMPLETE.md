# Announcement Service - COMPLETE ✅

## Overview
Created comprehensive Flutter service for announcements with all 10 API endpoints, proper error handling, and tracking support.

## File: `lib/services/announcement_service.dart` (300+ lines)

### Service Architecture
- **Base**: Uses `ApiService` for HTTP requests with authentication
- **Error Handling**: Throws `ApiException` with status codes for proper error propagation
- **Tracking**: Silent failures for view/download tracking (doesn't block UI)

---

## API Methods

### 1. **getAnnouncements(courseId)** - List Announcements
```dart
Future<List<Announcement>> getAnnouncements(String courseId)
```

**Endpoint**: `GET /api/announcements?courseId={id}`

**Features:**
- Returns filtered announcements (students see only their groups)
- Instructors see all course announcements
- Throws `ApiException` on failure
- Debug logging for troubleshooting

**Usage:**
```dart
try {
  final announcements = await announcementService.getAnnouncements(courseId);
  // Display announcements
} catch (e) {
  // Handle error
}
```

---

### 2. **getAnnouncement(announcementId)** - Get Single Announcement
```dart
Future<Announcement> getAnnouncement(String announcementId)
```

**Endpoint**: `GET /api/announcements/{id}`

**Features:**
- Returns full announcement with populated data
- Includes comments, attachments, groups
- Throws `ApiException` on failure

**Usage:**
```dart
try {
  final announcement = await announcementService.getAnnouncement(id);
  // Display announcement detail
} catch (e) {
  // Handle error (404 if not found)
}
```

---

### 3. **createAnnouncement()** - Create Announcement (Instructor)
```dart
Future<Announcement> createAnnouncement({
  required String courseId,
  required String title,
  required String content,
  List<String>? groupIds,
  List<Map<String, dynamic>>? attachments,
})
```

**Endpoint**: `POST /api/announcements`

**Parameters:**
- `courseId` - Course ID (required)
- `title` - Announcement title (required)
- `content` - Rich text content (required)
- `groupIds` - List of group IDs (optional, empty = all students)
- `attachments` - List of attachment objects (optional)

**Attachment Format:**
```dart
{
  'name': 'file.pdf',
  'url': 'https://...',
  'size': 12345
}
```

**Usage:**
```dart
try {
  final announcement = await announcementService.createAnnouncement(
    courseId: courseId,
    title: 'Important Update',
    content: '<p>Hello students...</p>',
    groupIds: [], // All students
    attachments: uploadedFiles,
  );
  // Navigate to announcement or show success
} catch (e) {
  // Show error message
}
```

---

### 4. **updateAnnouncement()** - Update Announcement (Instructor)
```dart
Future<Announcement> updateAnnouncement({
  required String announcementId,
  String? title,
  String? content,
  List<String>? groupIds,
  List<Map<String, dynamic>>? attachments,
})
```

**Endpoint**: `PUT /api/announcements/{id}`

**Features:**
- Partial updates (only send changed fields)
- Only author or course instructor can update
- Throws `ApiException` if unauthorized

**Usage:**
```dart
try {
  final updated = await announcementService.updateAnnouncement(
    announcementId: id,
    title: newTitle, // Only update title
  );
  // Show success
} catch (e) {
  // Handle error
}
```

---

### 5. **deleteAnnouncement()** - Delete Announcement (Instructor)
```dart
Future<void> deleteAnnouncement(String announcementId)
```

**Endpoint**: `DELETE /api/announcements/{id}`

**Features:**
- Only author or course instructor can delete
- Throws `ApiException` if unauthorized
- No return value on success

**Usage:**
```dart
try {
  await announcementService.deleteAnnouncement(id);
  // Remove from UI, show success
} catch (e) {
  // Show error
}
```

---

### 6. **addComment()** - Add Comment
```dart
Future<Announcement> addComment({
  required String announcementId,
  required String text,
})
```

**Endpoint**: `POST /api/announcements/{id}/comments`

**Features:**
- Available to all authenticated users
- Returns updated announcement with new comment
- Sends notification to announcement author

**Usage:**
```dart
try {
  final updated = await announcementService.addComment(
    announcementId: id,
    text: commentText,
  );
  // Update UI with new comments
} catch (e) {
  // Show error
}
```

---

### 7. **trackView()** - Track View (Silent)
```dart
Future<void> trackView(String announcementId)
```

**Endpoint**: `POST /api/announcements/{id}/view`

**Features:**
- **Silent failure** - doesn't throw, only logs
- Prevents duplicate tracking (backend checks)
- Call when announcement is displayed

**Usage:**
```dart
@override
void initState() {
  super.initState();
  // Track view when screen loads
  announcementService.trackView(widget.announcementId);
}
```

---

### 8. **trackDownload()** - Track Download (Silent)
```dart
Future<void> trackDownload({
  required String announcementId,
  required String fileName,
})
```

**Endpoint**: `POST /api/announcements/{id}/download`

**Features:**
- **Silent failure** - doesn't block download
- Allows multiple downloads (tracks each one)
- Call before/after file download

**Usage:**
```dart
Future<void> downloadFile(AnnouncementAttachment file) async {
  try {
    // Download the file
    await downloadManager.download(file.url, file.name);
    
    // Track the download (doesn't block if fails)
    await announcementService.trackDownload(
      announcementId: announcementId,
      fileName: file.name,
    );
  } catch (e) {
    // Handle download error
  }
}
```

---

### 9. **getTracking()** - Get Analytics (Instructor)
```dart
Future<AnnouncementTracking> getTracking(String announcementId)
```

**Endpoint**: `GET /api/announcements/{id}/tracking`

**Features:**
- Instructor only (throws 403 if student)
- Returns detailed view/download statistics
- Includes student details (name, email, ID)

**Returns:** `AnnouncementTracking` object with:
- `viewStats` - Total views, unique viewers, viewer list
- `downloadStats` - Total downloads, unique downloaders, download list
- `fileStats` - Per-file download statistics

**Usage:**
```dart
try {
  final tracking = await announcementService.getTracking(announcementId);
  
  print('Views: ${tracking.viewStats.totalViews}');
  print('Unique viewers: ${tracking.viewStats.uniqueViewers}');
  print('Downloads: ${tracking.downloadStats.totalDownloads}');
  
  // Display in tracking dashboard
} catch (e) {
  // Handle error (403 if not instructor)
}
```

---

### 10. **exportTrackingCSV()** - Export CSV (Instructor)
```dart
Future<String> exportTrackingCSV(String announcementId)
```

**Endpoint**: `GET /api/announcements/{id}/export`

**Features:**
- Instructor only
- Returns CSV content as string
- Ready for download/save

**CSV Format:**
```
Type,Student ID,Full Name,Email,Action,File Name,Timestamp
View,ST123,John Doe,john@email.com,Viewed,N/A,2025-10-11T10:30:00
Download,ST123,John Doe,john@email.com,Downloaded,lecture.pdf,2025-10-11T10:35:00
```

**Usage:**
```dart
try {
  final csv = await announcementService.exportTrackingCSV(announcementId);
  
  // Save to file
  final file = await announcementService.saveCSVFile(
    csv,
    'announcement_${announcementId}_tracking.csv',
  );
  
  // Show success message with file path
  showSnackBar('Exported to ${file.path}');
} catch (e) {
  // Handle error
}
```

---

### 11. **saveCSVFile()** - Helper Method
```dart
Future<File> saveCSVFile(String csvContent, String fileName)
```

**Features:**
- Saves CSV to Downloads folder
- Creates directory if doesn't exist
- Returns File object with path

**Usage:**
```dart
final csv = await announcementService.exportTrackingCSV(id);
final file = await announcementService.saveCSVFile(csv, 'report.csv');
print('Saved to: ${file.path}');
```

---

## Error Handling

### ApiException Class
```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
}
```

**Common Status Codes:**
- `200/201` - Success
- `400` - Bad request (validation error)
- `401` - Unauthorized (no token)
- `403` - Forbidden (not instructor)
- `404` - Not found
- `500` - Server error

**Error Handling Pattern:**
```dart
try {
  final result = await announcementService.someMethod();
  // Handle success
} on ApiException catch (e) {
  if (e.statusCode == 403) {
    showError('You do not have permission');
  } else if (e.statusCode == 404) {
    showError('Announcement not found');
  } else {
    showError('Error: ${e.message}');
  }
} catch (e) {
  showError('Network error');
}
```

---

## Service Features

### ✅ Complete Coverage
- All 10 backend endpoints implemented
- CRUD operations (Create, Read, Update, Delete)
- Comment system
- View/download tracking
- Analytics and export

### ✅ Proper Error Handling
- Throws `ApiException` for failures
- Silent tracking (doesn't block UI)
- Debug logging for troubleshooting
- Status code propagation

### ✅ Type Safety
- Returns typed models (not dynamic)
- Required vs optional parameters
- Null safety compliant

### ✅ Documentation
- Method-level documentation
- Parameter descriptions
- Usage examples

---

## Integration Examples

### List Screen (Student/Instructor)
```dart
class AnnouncementsListScreen extends StatefulWidget {
  final String courseId;
  
  @override
  _AnnouncementsListScreenState createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  final announcementService = AnnouncementService();
  List<Announcement> announcements = [];
  bool loading = true;
  
  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }
  
  Future<void> loadAnnouncements() async {
    try {
      final data = await announcementService.getAnnouncements(widget.courseId);
      setState(() {
        announcements = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      showError('Failed to load announcements');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (loading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return AnnouncementCard(announcement: announcement);
      },
    );
  }
}
```

### Detail Screen (Student)
```dart
class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  
  @override
  _AnnouncementDetailScreenState createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final announcementService = AnnouncementService();
  Announcement? announcement;
  
  @override
  void initState() {
    super.initState();
    loadAnnouncement();
    trackView();
  }
  
  Future<void> loadAnnouncement() async {
    try {
      final data = await announcementService.getAnnouncement(widget.announcementId);
      setState(() => announcement = data);
    } catch (e) {
      showError('Failed to load announcement');
    }
  }
  
  Future<void> trackView() async {
    await announcementService.trackView(widget.announcementId);
  }
  
  Future<void> downloadFile(AnnouncementAttachment file) async {
    // Download file
    await downloadManager.download(file.url, file.name);
    
    // Track download
    await announcementService.trackDownload(
      announcementId: widget.announcementId,
      fileName: file.name,
    );
  }
}
```

### Create Screen (Instructor)
```dart
class CreateAnnouncementScreen extends StatefulWidget {
  final String courseId;
  
  @override
  _CreateAnnouncementScreenState createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final announcementService = AnnouncementService();
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  List<String> selectedGroupIds = [];
  List<Map<String, dynamic>> attachments = [];
  
  Future<void> createAnnouncement() async {
    try {
      final announcement = await announcementService.createAnnouncement(
        courseId: widget.courseId,
        title: titleController.text,
        content: contentController.text,
        groupIds: selectedGroupIds,
        attachments: attachments,
      );
      
      Navigator.pop(context, announcement);
      showSuccess('Announcement created');
    } catch (e) {
      showError('Failed to create announcement');
    }
  }
}
```

### Tracking Dashboard (Instructor)
```dart
class AnnouncementTrackingScreen extends StatefulWidget {
  final String announcementId;
  
  @override
  _AnnouncementTrackingScreenState createState() => _AnnouncementTrackingScreenState();
}

class _AnnouncementTrackingScreenState extends State<AnnouncementTrackingScreen> {
  final announcementService = AnnouncementService();
  AnnouncementTracking? tracking;
  
  @override
  void initState() {
    super.initState();
    loadTracking();
  }
  
  Future<void> loadTracking() async {
    try {
      final data = await announcementService.getTracking(widget.announcementId);
      setState(() => tracking = data);
    } catch (e) {
      showError('Failed to load tracking data');
    }
  }
  
  Future<void> exportCSV() async {
    try {
      final csv = await announcementService.exportTrackingCSV(widget.announcementId);
      final file = await announcementService.saveCSVFile(
        csv,
        'announcement_${widget.announcementId}_tracking.csv',
      );
      showSuccess('Exported to ${file.path}');
    } catch (e) {
      showError('Failed to export');
    }
  }
}
```

---

## Next Steps - UI Implementation

Now that the service is complete, create the UI screens:

### 1. Instructor Create/Edit Screen (4-6 hours)
- Title and content inputs
- Rich text editor
- File upload widget
- Group selection (multi-select)
- Form validation

### 2. Instructor Tracking Dashboard (3-4 hours)
- View statistics display
- Download statistics display
- Student details table
- CSV export button
- Filtering/searching

### 3. Student View Screen (3-4 hours)
- Content display with HTML rendering
- File list with download buttons
- Comment section
- Add comment input
- Auto-track view on load

### 4. Integration (1-2 hours)
- Update classwork tab
- Add navigation
- Test complete flow

---

## Files Modified

### Enhanced:
✅ `lib/services/announcement_service.dart` - Complete service (300+ lines)
  - 10 API methods
  - Proper error handling
  - Silent tracking
  - CSV export support
  - Helper methods

---

## Progress Update

**Announcement Feature:**
- ✅ Backend Model (100%)
- ✅ Backend Routes (100%)
- ✅ Flutter Models (100%)
- ✅ Flutter Service (100%)
- ⏳ Instructor Create UI (0%) - NEXT
- ⏳ Instructor Tracking UI (0%)
- ⏳ Student View UI (0%)
- ⏳ Integration (0%)

**Total Progress: ~50%**

**Time Remaining: 8-12 hours**
