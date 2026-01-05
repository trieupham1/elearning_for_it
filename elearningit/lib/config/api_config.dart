import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import '../utils/token_manager.dart';

class ApiConfig {
  // ==========================================
  // PRODUCTION BACKEND URL (Render deployment)
  // ==========================================
  static const String _productionBase = 'https://elearningit.onrender.com';
  
  // Development URLs
  static const String _localBase = 'http://localhost:5000';
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000';
  static const String _pcLocalIp = 'http://192.168.1.224:5000'; // Your PC's WiFi IP

  // ==========================================
  // SET THIS TO TRUE TO USE RENDER BACKEND
  // ==========================================
  static const bool useProductionBackend = true;

  // Set this to true if using Android emulator, false if using real device
  static const bool _useEmulator = false;

  // API endpoints (based on your actual backend routes)
  static const String auth = '/api/auth';
  static const String users = '/api/users';
  static const String courses = '/api/courses';
  static const String semesters = '/api/semesters';
  static const String students = '/api/students';
  static const String notifications = '/api/notifications';
  static const String announcements = '/api/announcements';
  static const String assignments = '/api/assignments';
  static const String classwork = '/api/classwork';
  static const String messages = '/api/messages';
  static const String groups = '/api/groups';
  static const String quizzes = '/api/quizzes';
  static const String questions = '/api/questions';
  static const String quizAttempts = '/api/quiz-attempts';
  static const String materials = '/api/materials';
  static const String forum = '/api/forum';
  static const String agora = '/api/agora';
  static const String dashboard = '/api/dashboard';
  static const String export = '/api/export';
  static const String settings = '/api/settings';
  static const String departments = '/api/departments';
  static const String admin = '/api/admin';
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminReports = '/api/admin/reports';
  static const String files = '/api/files';
  static const String videos = '/api/videos';
  static const String attendance = '/api/attendance';
  static const String codeAssignments = '/api/code';
  static const String calls = '/api/calls';
  
  // File upload endpoints
  static const String uploadFile = '/api/files/upload';
  static const String downloadFile = '/api/files';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // Helper method to get the correct base URL for different environments
  static String getBaseUrl() {
    // Always use production if flag is set (for testing with Render backend)
    if (useProductionBackend || kReleaseMode) {
      return _productionBase;
    }
    
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
