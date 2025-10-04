import 'dart:io' show Platform;

class ApiConfig {
  // Development server URL - change this to your actual backend URL
  // Note: Android emulator cannot access host's localhost; use 10.0.2.2 instead.
  static const String _localBase = 'http://localhost:5000/api';
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000/api';

  // API endpoints (based on your actual backend routes)
  static const String auth = '/auth';
  static const String users = '/users';
  static const String semesters = '/semesters';
  static const String courses = '/courses';
  static const String groups = '/groups';
  static const String students = '/students';
  static const String announcements = '/announcements';
  static const String files = '/files';
  static const String notifications = '/notifications';

  // File upload endpoints
  static const String uploadFile = '/files/upload';
  static const String downloadFile = '/files';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> headersWithAuth(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };

  // Helper method to get the correct base URL for different environments
  static String getBaseUrl() {
    try {
      if (Platform.isAndroid) return _androidEmulatorBase;
    } catch (_) {
      // If Platform is not available (e.g., during tests), fall back to local
    }
    return _localBase;
  }
}
