import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/attendance.dart';
import '../utils/token_manager.dart';

class AttendanceService {
  // Create attendance session
  static Future<AttendanceSession> createSession({
    required String courseId,
    required String title,
    required DateTime sessionDate,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    List<String>? allowedMethods,
    LocationData? location,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/attendance/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'courseId': courseId,
          'title': title,
          'description': description,
          'sessionDate': sessionDate.toUtc().toIso8601String(),
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'allowedMethods': allowedMethods ?? ['qr_code'],
          if (location != null) 'location': location.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AttendanceSession.fromJson(data['session']);
      } else {
        throw Exception('Failed to create session: ${response.body}');
      }
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  // Get all sessions for a course
  static Future<List<AttendanceSession>> getCourseSessions(
    String courseId,
  ) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/attendance/sessions/course/$courseId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AttendanceSession.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sessions: ${response.body}');
      }
    } catch (e) {
      print('Error loading sessions: $e');
      rethrow;
    }
  }

  // Get session details
  static Future<AttendanceSession> getSession(String sessionId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/attendance/sessions/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return AttendanceSession.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load session: ${response.body}');
      }
    } catch (e) {
      print('Error loading session: $e');
      rethrow;
    }
  }

  // Student check-in with QR code
  static Future<void> checkIn({
    required String qrCode,
    CheckInLocation? location,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/attendance/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'qrCode': qrCode,
          if (location != null) 'location': location.toJson(),
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to check in');
      }
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  // Check if student has already checked in for this session
  static Future<Map<String, dynamic>> getMyAttendanceStatus(
    String sessionId,
  ) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/attendance/sessions/$sessionId/my-status',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get attendance status');
      }
    } catch (e) {
      print('Error getting attendance status: $e');
      rethrow;
    }
  }

  // Manual attendance marking by instructor
  static Future<void> markAttendance({
    required String sessionId,
    required String studentId,
    required String status,
    String? notes,
    String? excuseReason,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/attendance/sessions/$sessionId/mark',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'studentId': studentId,
          'status': status,
          'notes': notes,
          'excuseReason': excuseReason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark attendance: ${response.body}');
      }
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  // Get attendance records for a session
  static Future<List<AttendanceRecord>> getSessionRecords(
    String sessionId,
  ) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/attendance/sessions/$sessionId/records',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load records: ${response.body}');
      }
    } catch (e) {
      print('Error loading records: $e');
      rethrow;
    }
  }

  // Get student's attendance history
  static Future<List<AttendanceRecord>> getStudentHistory({
    String? courseId,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final uri = courseId != null
          ? Uri.parse(
              '${ApiConfig.baseUrl}/api/attendance/student/history?courseId=$courseId',
            )
          : Uri.parse('${ApiConfig.baseUrl}/api/attendance/student/history');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      print('Error loading history: $e');
      rethrow;
    }
  }

  // Get attendance report for a course
  static Future<AttendanceReport> getCourseReport(String courseId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/attendance/reports/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return AttendanceReport.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load report: ${response.body}');
      }
    } catch (e) {
      print('Error loading report: $e');
      rethrow;
    }
  }

  // Update session (close, regenerate QR, etc.)
  static Future<AttendanceSession> updateSession({
    required String sessionId,
    bool? isActive,
    bool? regenerateQR,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/attendance/sessions/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (isActive != null) 'isActive': isActive,
          if (regenerateQR != null) 'regenerateQR': regenerateQR,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceSession.fromJson(data['session']);
      } else {
        throw Exception('Failed to update session: ${response.body}');
      }
    } catch (e) {
      print('Error updating session: $e');
      rethrow;
    }
  }
}
