import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/token_manager.dart';

/// API Configuration for Testing Video Calls between PC and Android Device
/// 
/// INSTRUCTIONS:
/// 1. Find your PC's local IP address:
///    - Windows: Run 'ipconfig' in CMD
///    - Look for IPv4 Address (e.g., 192.168.1.100)
/// 
/// 2. Update _pcLocalIp below with your actual IP
/// 
/// 3. Rename this file to 'api_config.dart' to use it
///    (or copy the getBaseUrl() method to your existing api_config.dart)

class ApiConfig {
  // ===== IMPORTANT: UPDATE THIS WITH YOUR PC'S LOCAL IP ADDRESS =====
  // Find it using 'ipconfig' command on Windows CMD
  static const String _pcLocalIp = 'http://192.168.1.100:5000'; // CHANGE ME!
  // ==================================================================
  
  static const String _localBase = 'http://localhost:5000';
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000';

  // API endpoints
  static const String auth = '/api/auth';
  static const String users = '/api/users';
  static const String semesters = '/api/semesters';
  static const String courses = '/api/courses';
  static const String groups = '/api/groups';
  static const String students = '/api/students';
  static const String announcements = '/api/announcements';
  static const String files = '/api/files';
  static const String notifications = '/api/notifications';
  static const String uploadFile = '/api/files/upload';
  static const String downloadFile = '/api/files';
  static const Duration timeout = Duration(seconds: 30);

  /// Get the correct base URL based on the platform
  /// 
  /// Testing Modes:
  /// - Web (PC): Uses localhost:5000
  /// - Android Emulator: Uses 10.0.2.2:5000
  /// - Real Android Device: Uses PC's local IP (must be on same WiFi)
  static String getBaseUrl() {
    if (kIsWeb) {
      // Running on web browser (PC)
      return _localBase;
    }

    try {
      if (Platform.isAndroid) {
        // FOR TESTING WITH REAL ANDROID DEVICE:
        // 1. Uncomment the line below
        // 2. Update _pcLocalIp above with your PC's IP
        // 3. Ensure both devices are on same WiFi
        return _pcLocalIp; // <-- Use this for real device testing
        
        // FOR TESTING WITH ANDROID EMULATOR:
        // Uncomment the line below instead
        // return _androidEmulatorBase;
      }
      return _localBase;
    } catch (e) {
      return _localBase;
    }
  }

  static String get baseUrl => getBaseUrl();

  static Future<Map<String, String>> headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> multipartHeaders() async {
    final token = await _getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getToken() async {
    return await TokenManager.getToken();
  }
  
  /// Get WebSocket URL for Socket.IO (video calls)
  static String getSocketUrl() {
    return getBaseUrl();
  }
  
  /// Debug method to check current configuration
  static void printDebugInfo() {
    print('=== API Config Debug Info ===');
    print('Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    print('Base URL: ${getBaseUrl()}');
    print('Socket URL: ${getSocketUrl()}');
    print('============================');
  }
}
