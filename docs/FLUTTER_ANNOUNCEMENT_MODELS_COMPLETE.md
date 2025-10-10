# Announcement Flutter Models - COMPLETE ✅

## Overview
Created comprehensive Flutter models for the Announcements feature with full tracking support.

## Created Files

### 1. `lib/models/announcement.dart` (350+ lines)

**Main Classes:**

#### `Announcement`
The primary model representing an announcement.

**Key Fields:**
```dart
- id, courseId, title, content
- authorId, authorName, authorAvatar
- groupIds (List<String>) - empty = all students
- attachments (List<AnnouncementAttachment>)
- comments (List<AnnouncementComment>)
- viewedBy (List<AnnouncementView>)
- downloadedBy (List<AnnouncementDownload>)
- createdAt, updatedAt
- groups (List<GroupInfo>?) - populated group data
```

**Helper Methods:**
- `viewCount`, `uniqueViewerCount` - View statistics
- `downloadCount`, `uniqueDownloaderCount` - Download statistics
- `commentCount`, `hasAttachments`, `isForAllGroups` - Convenience getters
- `groupDisplay` - Formatted group names or "All Students"
- `hasUserViewed(userId)` - Check if user viewed
- `hasUserDownloadedFile(userId, fileName)` - Check if user downloaded file
- `getFileDownloadCount(fileName)` - Downloads per file

#### `AnnouncementAttachment`
Represents a file attached to an announcement.

**Features:**
```dart
- name, url, size
- formattedSize - Display-friendly size (KB, MB, GB)
- extension - File extension extraction
- isImage, isDocument - Type detection
```

#### `AnnouncementComment`
Represents a comment on an announcement.

**Fields:**
```dart
- userId, userName, userAvatar
- text, createdAt
```

**Features:**
- Handles both string userId and populated user objects
- Fallback to username if fullName missing

#### `AnnouncementView`
Tracks who viewed the announcement.

**Fields:**
```dart
- userId, viewedAt
```

#### `AnnouncementDownload`
Tracks file downloads.

**Fields:**
```dart
- userId, fileName, downloadedAt
```

#### `GroupInfo`
Represents populated group data.

**Fields:**
```dart
- id, name
```

---

### 2. `lib/models/announcement_tracking.dart` (220+ lines)

**Main Classes:**

#### `AnnouncementTracking`
The main analytics model returned by `/api/announcements/:id/tracking`.

**Fields:**
```dart
- announcementId, title, createdAt
- viewStats (ViewStatistics)
- downloadStats (DownloadStatistics)
- fileStats (Map<String, FileStatistics>)
```

#### `ViewStatistics`
Aggregate view statistics.

**Fields:**
```dart
- totalViews - Total view count
- uniqueViewers - Unique viewer count
- viewers (List<ViewerInfo>) - Detailed viewer list
```

**Methods:**
- `viewRate` - Average views per viewer

#### `DownloadStatistics`
Aggregate download statistics.

**Fields:**
```dart
- totalDownloads - Total download count
- uniqueDownloaders - Unique downloader count
- downloads (List<DownloadInfo>) - Detailed download list
```

**Methods:**
- `downloadRate` - Average downloads per downloader

#### `ViewerInfo`
Individual viewer details.

**Fields:**
```dart
- userId, fullName, email, studentId
- viewedAt
```

**Methods:**
- `displayName` - Formatted name with student ID

#### `DownloadInfo`
Individual download details.

**Fields:**
```dart
- userId, fullName, email, studentId
- fileName, downloadedAt
```

**Methods:**
- `displayName` - Formatted name with student ID

#### `FileStatistics`
Per-file download statistics.

**Fields:**
```dart
- totalDownloads
- uniqueDownloaders
```

**Methods:**
- `downloadRate` - Average downloads per downloader

---

## Model Features

### JSON Serialization
✅ All models have `fromJson` and `toJson` methods
✅ Handle both populated and non-populated references (e.g., authorId as String or Object)
✅ Safe null handling with fallbacks
✅ Proper DateTime parsing

### Type Safety
✅ Explicit types for all fields
✅ Required vs optional fields clearly marked
✅ Type casting with safety checks

### Convenience Methods
✅ Formatted file sizes (B, KB, MB, GB)
✅ File type detection (image, document)
✅ Display-friendly names with fallbacks
✅ Statistics calculations (rates, counts)
✅ Group display formatting

### Data Integrity
✅ Default values for missing data
✅ Empty list defaults instead of null
✅ Timestamp defaults to now if missing
✅ Unknown user fallbacks

---

## Usage Examples

### Creating from API Response
```dart
// From GET /api/announcements
final announcements = (json['announcements'] as List)
    .map((a) => Announcement.fromJson(a))
    .toList();

// From GET /api/announcements/:id/tracking
final tracking = AnnouncementTracking.fromJson(json);
```

### Sending to API
```dart
// Create announcement
final body = {
  'courseId': courseId,
  'title': title,
  'content': content,
  'groupIds': selectedGroupIds,
  'attachments': attachments.map((a) => a.toJson()).toList(),
};
```

### Display Logic
```dart
// Show view count
Text('${announcement.viewCount} views (${announcement.uniqueViewerCount} unique)')

// Show file info
Text('${attachment.formattedSize} - ${attachment.name}')

// Show group scope
Text(announcement.groupDisplay) // "All Students" or "Group A, Group B"

// Check if viewed
if (announcement.hasUserViewed(currentUserId)) {
  Icon(Icons.check_circle, color: Colors.green)
}

// Show download stats
Text('${fileStats.totalDownloads} downloads (${fileStats.uniqueDownloaders} students)')
```

---

## Data Flow

### Student View Flow:
1. Fetch announcements: `GET /api/announcements?courseId=X`
2. Parse: `Announcement.fromJson(json)`
3. Display in UI with attachments
4. Auto-track view: `POST /api/announcements/:id/view`
5. Track download: `POST /api/announcements/:id/download` with fileName

### Instructor Analytics Flow:
1. Fetch tracking: `GET /api/announcements/:id/tracking`
2. Parse: `AnnouncementTracking.fromJson(json)`
3. Display statistics dashboard
4. Export CSV: `GET /api/announcements/:id/export`

---

## Next Steps - Announcement Service

Now that models are complete, next create `lib/services/announcement_service.dart` with:

### Required Methods:
```dart
Future<List<Announcement>> getAnnouncements(String courseId)
Future<Announcement> getAnnouncement(String announcementId)
Future<Announcement> createAnnouncement(Map<String, dynamic> data)
Future<Announcement> updateAnnouncement(String id, Map<String, dynamic> data)
Future<void> deleteAnnouncement(String id)
Future<void> addComment(String id, String text)
Future<void> trackView(String id)
Future<void> trackDownload(String id, String fileName)
Future<AnnouncementTracking> getTracking(String id)
Future<void> exportTracking(String id) // Download CSV
```

### Service Features:
- HTTP client with authentication
- Error handling and retry logic
- Loading states
- Cache management (optional)
- File upload support for attachments

---

## Files Modified/Created

### Created:
1. ✅ `lib/models/announcement.dart` - Complete announcement models (350+ lines)
2. ✅ `lib/models/announcement_tracking.dart` - Analytics models (220+ lines)

### Enhanced:
- Previous `announcement.dart` replaced with full tracking support

---

## Testing Checklist

- [ ] Parse announcement list from API
- [ ] Parse single announcement with populated groups
- [ ] Parse announcement with attachments
- [ ] Parse comments with user info
- [ ] Parse tracking analytics
- [ ] Serialize announcement for creation
- [ ] Test file size formatting
- [ ] Test file type detection
- [ ] Test view/download checking
- [ ] Test group display formatting

---

## Estimated Progress

**Announcement Feature:**
- ✅ Backend Model (100%)
- ✅ Backend Routes (100%)
- ✅ Flutter Models (100%)
- ⏳ Flutter Service (0%) - NEXT
- ⏳ Instructor Create UI (0%)
- ⏳ Instructor Tracking UI (0%)
- ⏳ Student View UI (0%)
- ⏳ Integration (0%)

**Total Announcement Progress: ~40%**

**Time Remaining: 12-16 hours**
- Service: 2-3 hours
- Instructor Create: 4-6 hours
- Instructor Tracking: 3-4 hours
- Student View: 3-4 hours
- Integration: 1-2 hours
