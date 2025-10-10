# Instructor Create/Edit Announcement Screen - COMPLETE ✅

## Overview
Created a comprehensive Flutter screen for instructors to create and edit announcements with file uploads and group targeting.

## Files Created

### 1. `lib/screens/instructor/create_announcement_screen.dart` (550+ lines)

A full-featured form screen for creating and editing announcements.

#### Key Features

**Dual Mode Operation:**
- ✅ Create mode (when `announcement` parameter is null)
- ✅ Edit mode (when `announcement` parameter is provided)
- Pre-populates all fields in edit mode

**Form Fields:**
- ✅ Title (required, max 200 characters)
- ✅ Content (required, max 5000 characters, multiline)
- ✅ Group selection (multi-select or all students)
- ✅ File attachments (multiple files supported)

**Group Targeting:**
- ✅ "All Students" option (empty groupIds array)
- ✅ Individual group selection with checkboxes
- ✅ Shows member count for each group
- ✅ Dynamic status display (e.g., "2 group(s) selected")

**File Upload System:**
- ✅ Pick multiple files using `file_picker` package
- ✅ Two-stage upload (pick → pending → upload)
- ✅ Manual upload control ("Upload All" button)
- ✅ File type icons (PDF, image, doc, etc.)
- ✅ File size formatting (B, KB, MB, GB)
- ✅ Remove files before upload
- ✅ Upload progress indication

**User Experience:**
- ✅ Form validation with error messages
- ✅ Loading states (saving, uploading)
- ✅ Success/error snackbars
- ✅ Check icon in AppBar to save
- ✅ Returns `true` on success for parent refresh

---

### 2. `lib/services/file_service.dart` (110+ lines)

Service for handling file uploads to the backend.

#### Methods

**uploadFile():**
```dart
Future<Map<String, dynamic>> uploadFile({
  required String filePath,
  required String fileName,
  String folder = 'uploads',
})
```
- Uploads single file via multipart/form-data
- Returns map with `url`, `name`, `size`
- Supports custom folder organization
- Handles authentication headers

**uploadFiles():**
```dart
Future<List<Map<String, dynamic>>> uploadFiles({
  required List<String> filePaths,
  required List<String> fileNames,
  String folder = 'uploads',
})
```
- Batch upload multiple files
- Continues on individual file errors
- Returns list of successful uploads

**deleteFile():**
```dart
Future<void> deleteFile(String fileUrl)
```
- Placeholder for file deletion
- Currently not implemented on backend
- Logs deletion attempt

---

## UI Components

### Title & Content Section
```dart
TextFormField(
  controller: _titleController,
  decoration: InputDecoration(
    labelText: 'Title *',
    hintText: 'Enter announcement title',
    border: OutlineInputBorder(),
  ),
  maxLength: 200,
  validator: (value) => value?.trim().isEmpty ?? true 
      ? 'Title is required' 
      : null,
)
```

### Group Selection Card
Shows:
- Current selection status
- "All Students" checkbox
- Individual group checkboxes with member counts
- Mutually exclusive logic (all vs specific)

### Attachments Section
Shows:
- **Uploaded files** (green icon, with remove button)
- **Pending files** (orange icon, awaiting upload)
- **Upload All button** (when pending files exist)
- **Add Files button** (file picker trigger)
- Empty state message

---

## Workflow

### Create Flow:
1. User opens screen (no announcement parameter)
2. Fills title and content
3. Selects target groups (or all students)
4. Picks files → adds to pending list
5. Clicks "Upload All" → files upload to server
6. Clicks check icon → creates announcement
7. Screen closes, returns `true`

### Edit Flow:
1. User opens screen with announcement parameter
2. Fields pre-populated with existing data
3. User modifies title/content/groups
4. Can add new files or remove existing
5. Clicks check icon → updates announcement
6. Screen closes, returns `true`

---

## Dependencies

### Required Packages:
```yaml
dependencies:
  file_picker: ^latest  # For picking files from device
  http: ^latest         # For multipart file upload
```

### Required Services:
- ✅ `AnnouncementService` - Create/update announcements
- ✅ `GroupService` - Load course groups
- ✅ `FileService` - Upload files (created)

### Required Models:
- ✅ `Course` - Course information
- ✅ `Group` - Group data with members
- ✅ `Announcement` - Announcement model
- ✅ `AnnouncementAttachment` - File attachment model

---

## Code Highlights

### Two-Stage File Upload:
```dart
// Stage 1: Pick files (adds to pending)
Future<void> _pickFiles() async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);
  if (result != null) {
    setState(() => _pendingFiles.addAll(result.files));
  }
}

// Stage 2: Upload to server
Future<void> _uploadPendingFiles() async {
  for (final file in _pendingFiles) {
    final attachment = await _fileService.uploadFile(
      filePath: file.path!,
      fileName: file.name,
      folder: 'announcements',
    );
    _attachments.add(AnnouncementAttachment(...));
  }
  _pendingFiles.clear();
}
```

### Group Selection Logic:
```dart
// All Students checkbox
CheckboxListTile(
  title: const Text('All Students'),
  value: _selectedGroupIds.isEmpty,  // Empty = all
  onChanged: (value) {
    if (value == true) {
      setState(() => _selectedGroupIds.clear());
    }
  },
)

// Individual group checkboxes
CheckboxListTile(
  title: Text(group.name),
  value: _selectedGroupIds.contains(group.id),
  onChanged: (value) {
    setState(() {
      if (value == true) {
        _selectedGroupIds.add(group.id);
      } else {
        _selectedGroupIds.remove(group.id);
      }
    });
  },
)
```

### Smart Save Logic:
```dart
Future<void> _saveAnnouncement() async {
  if (!_formKey.currentState!.validate()) return;

  // Upload pending files first
  if (_pendingFiles.isNotEmpty) {
    await _uploadPendingFiles();
  }

  final attachmentsJson = _attachments.map((a) => a.toJson()).toList();

  if (widget.announcement != null) {
    // Update mode
    await _announcementService.updateAnnouncement(...);
  } else {
    // Create mode
    await _announcementService.createAnnouncement(...);
  }

  Navigator.pop(context, true);  // Return success
}
```

---

## Usage Examples

### From Classwork Tab (Create):
```dart
// Navigate to create screen
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CreateAnnouncementScreen(
      course: widget.course,
    ),
  ),
);

// Refresh if created
if (result == true) {
  _loadAnnouncements();
}
```

### From Announcement Detail (Edit):
```dart
// Navigate to edit screen
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CreateAnnouncementScreen(
      course: widget.course,
      announcement: existingAnnouncement,
    ),
  ),
);

// Refresh if updated
if (result == true) {
  _loadAnnouncementDetail();
}
```

---

## File Upload Backend Integration

### Expected Backend Endpoint:
```
POST /api/files/upload
Content-Type: multipart/form-data

FormData:
- file: <binary data>
- folder: "announcements"

Response:
{
  "url": "https://storage.example.com/announcements/file123.pdf",
  "message": "File uploaded successfully"
}
```

### Backend Route (if not exists):
```javascript
// backend/routes/files.js
router.post('/upload', authMiddleware, upload.single('file'), async (req, res) => {
  const { folder = 'uploads' } = req.body;
  const file = req.file;
  
  // Upload to cloud storage (S3, Cloudinary, etc.)
  const url = await uploadToStorage(file, folder);
  
  res.json({ url, message: 'File uploaded successfully' });
});
```

---

## Testing Checklist

- [ ] Create announcement with all fields
- [ ] Create announcement with no groups (all students)
- [ ] Create announcement with specific groups
- [ ] Create announcement with file attachments
- [ ] Edit existing announcement title/content
- [ ] Edit announcement groups
- [ ] Add files to existing announcement
- [ ] Remove files before saving
- [ ] Upload files with "Upload All"
- [ ] Validate required fields
- [ ] Test file size formatting
- [ ] Test file type icons
- [ ] Test loading states
- [ ] Test error handling
- [ ] Test success navigation

---

## Next Steps

### Immediate (Tracking Dashboard):
1. Create `lib/screens/instructor/announcement_tracking_screen.dart`
2. Display view/download statistics
3. Show student details table
4. Add CSV export button
5. Implement filtering/sorting

### Then (Student View):
1. Create `lib/screens/student/announcement_detail_screen.dart`
2. Display announcement content (HTML rendering)
3. Show file list with download buttons
4. Comment section with add functionality
5. Auto-track view on load
6. Track downloads on file tap

### Integration:
1. Update `classwork_tab.dart` to show announcements
2. Add FAB for create (instructor)
3. Navigate to detail on tap
4. Test complete flow

---

## Progress Update

**Announcement Feature:**
- ✅ Backend Model (100%)
- ✅ Backend Routes (100%)
- ✅ Flutter Models (100%)
- ✅ Flutter Service (100%)
- ✅ Instructor Create/Edit UI (100%)
- ⏳ Instructor Tracking UI (0%) - NEXT
- ⏳ Student View UI (0%)
- ⏳ Integration (0%)

**Total Progress: ~65%**

**Time Remaining: 5-8 hours**
- Tracking Dashboard: 3-4 hours
- Student View: 3-4 hours  
- Integration: 1-2 hours
