class ApiConfig {
  // Development server URL - change this to your actual backend URL
  static const String baseUrl = 'http://localhost:5000/api';

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
    // You can add environment-specific logic here
    return baseUrl;
  }
}
