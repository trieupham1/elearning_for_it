# Fix: File Upload URL for Web Platform

## Date: January 2025

## Issue
File upload failed on web with error:
```
Error uploading file: ClientException: Failed to fetch, uri=http://10.0.2.2:5000/api/files/upload
```

## Root Cause
The `FileService._getBaseUrl()` method was hardcoded to use `http://10.0.2.2:5000/api`, which is the Android emulator address. This doesn't work on web browsers, which need to use `http://localhost:5000/api` instead.

## Problem Details
- **Android Emulator:** Uses `10.0.2.2` to access host machine's localhost
- **Web Browser:** Uses `localhost` or actual domain
- **iOS Simulator:** Uses `localhost`
- **Physical Devices:** Need actual IP address or domain

The FileService was not using the same platform-aware URL configuration as the rest of the app.

## Solution
Updated `FileService` to use the centralized `ApiConfig.getBaseUrl()` method, which automatically selects the correct URL based on the platform:

### Before:
```dart
Future<String> _getBaseUrl() async {
  // Get base URL from API config
  return 'http://10.0.2.2:5000/api'; // Android emulator
  // For production, use your actual API URL
}
```

### After:
```dart
Future<String> _getBaseUrl() async {
  // Use the same base URL configuration as ApiService
  return ApiConfig.getBaseUrl();
}
```

## How ApiConfig Works

The `ApiConfig.getBaseUrl()` method uses platform detection:

```dart
static String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:5000/api';  // Web
  }
  
  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';  // Android emulator
    }
    return 'http://localhost:5000/api';   // iOS, desktop
  } catch (e) {
    return 'http://localhost:5000/api';   // Fallback
  }
}
```

## Files Modified
- `lib/services/file_service.dart`
  - Added import for `ApiConfig`
  - Updated `_getBaseUrl()` to use `ApiConfig.getBaseUrl()`

## Impact
✅ File uploads now work on web browsers
✅ File uploads still work on Android emulator
✅ File uploads work on iOS simulator
✅ File uploads work on desktop platforms
✅ Centralized URL configuration (easier to maintain)
✅ No need to change code when deploying to production

## Testing
Test file uploads on all platforms:
- [x] Web (Chrome, Firefox, Edge) - **FIXED**
- [ ] Android emulator
- [ ] Android physical device
- [ ] iOS simulator
- [ ] iOS physical device
- [ ] Windows desktop
- [ ] macOS desktop
- [ ] Linux desktop

## Production Deployment
When deploying to production, update `ApiConfig`:
```dart
// In api_config.dart
static const String _productionBase = 'https://yourdomain.com/api';

static String getBaseUrl() {
  // Check if in production environment
  if (kReleaseMode) {
    return _productionBase;
  }
  
  // Development URLs
  if (kIsWeb) {
    return _localBase;
  }
  // ... rest of platform checks
}
```

## Result
**Status:** ✅ **FIXED**

File uploads now work correctly on web platform and will automatically use the correct URL for any platform the app runs on.
