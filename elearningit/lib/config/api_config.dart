import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/token_manager.dart';

class ApiConfig {
  // Development server URL - change this to your actual backend URL
  // Note: Android emulator cannot access host's localhost; use 10.0.2.2 instead.
  static const String _localBase = 'http://localhost:5000';
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000';
  
  // ⚠️ CHANGE THIS to your PC's local IP address (find it with 'ipconfig')
  // This is used for REAL Android devices on the same WiFi network
  static const String _pcLocalIp = 'http://172.31.98.89:5000'; // ⬅️ Updated to actual WiFi IP!
  
  // 🔧 CONFIGURATION: Set to true if using Android EMULATOR, false if using REAL DEVICE
  static const bool _useEmulator = false; // ⬅️ Changed to FALSE for real device!

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
        // Choose emulator or real device based on configuration
        return _useEmulator ? _androidEmulatorBase : _pcLocalIp;
      }
      return _pcLocalIp; // For iOS, macOS, etc.
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
