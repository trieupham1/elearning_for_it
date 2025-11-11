import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/token_manager.dart';

class ApiConfig {
  // Development server URL - change this to your actual backend URL
  // Note: 
  // - Android emulator: use 10.0.2.2 (emulator's special alias for host)
  // - Real Android device: use PC's WiFi IP address (e.g., 192.168.1.224)
  static const String _localBase = 'http://localhost:5000';
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000';
  static const String _pcLocalIp = 'http://192.168.1.224:5000'; // Your PC's WiFi IP
  
  // Set this to true if using Android emulator, false if using real device
  static const bool _useEmulator = false;

  // API endpoints (based on your actual backend routes)
  static const String auth = '/api/auth';
  static const String users = '/api/users';
  static const String semesters = '/api/semesters';
  static const String courses = '/api/courses';
  static const String groups = '/api/groups';
  static const String students = '/api/students';
  static const String announcements = '/api/announcements';
  static const String files = '/api/files';
  static const String notifications = '/api/notifications';

  // File upload endpoints
  static const String uploadFile = '/api/files/upload';
  static const String downloadFile = '/api/files';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // Helper method to get the correct base URL for different environments
  static String getBaseUrl() {
    if (kIsWeb) {
      return _localBase;
    }

    try {
      if (Platform.isAndroid) {
        // Use emulator address or real device WiFi IP based on flag
        return _useEmulator ? _androidEmulatorBase : _pcLocalIp;
      }
      return _localBase;
    } catch (e) {
      return _localBase;
    }
  }

  // Add baseUrl getter for backward compatibility
  static String get baseUrl => getBaseUrl();

  // Helper method to get headers with authorization token
  static Future<Map<String, String>> headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getToken() async {
    try {
      return await TokenManager.getToken();
    } catch (e) {
      return null;
    }
  }
}
