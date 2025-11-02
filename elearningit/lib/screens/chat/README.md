# Chat Media Components

This directory contains the media gallery components for the chat system.

## Files

### `media_gallery_screen.dart`
Full-screen media gallery with tabbed interface.
- **Images Tab**: 3-column grid of all shared images
- **Videos Tab**: List view of all shared videos
- **Features**: Tap to open full-screen viewer/player, timestamps, counts

### `image_viewer_screen.dart`
Full-screen image viewer with zoom and pan capabilities.
- **Features**: Pinch-to-zoom, pan gestures, Hero animation, download button
- **Usage**: Opened when tapping image preview in chat or gallery

### `video_player_screen.dart`
Full-screen video player with playback controls.
- **Features**: Play/pause, volume, scrubbing, duration display, download
- **Usage**: Opened when tapping video preview in chat or gallery

## Integration

These components are used by `chat_screen.dart`:

```dart
import 'chat/media_gallery_screen.dart';
import 'chat/image_viewer_screen.dart';
import 'chat/video_player_screen.dart';
```

## Navigation Flow

```
ChatScreen
    ├─── User Info Panel
    │       └─── Media Button → MediaGalleryScreen
    │                               ├─── Tap Image → ImageViewerScreen
    │                               └─── Tap Video → VideoPlayerScreen
    │
    └─── Message Bubble
            ├─── Tap Image → ImageViewerScreen
            └─── Tap Video → VideoPlayerScreen
```

## Dependencies

- `cached_network_image` - Image caching
- `photo_view` - Zoom/pan gestures
- `video_player` - Video playback
- `timeago` - Relative timestamps
- `url_launcher` - Downloads

## API Integration

All components use the same file endpoint:
- **Base URL**: `ApiConfig.getBaseUrl()`
- **Endpoint**: `/api/files/:fileId`
- **Method**: GET (streaming)

## See Also

- `../chat_screen.dart` - Main chat interface
- `../../models/message.dart` - Message model with fileId
- `../../services/file_service.dart` - File upload/download
- `../../../docs/MEDIA_GALLERY_*.md` - Full documentation
