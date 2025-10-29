import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ReportService {
  final String baseUrl = '${ApiConfig.baseUrl}/admin/reports';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Generate department report
  Future<void> generateDepartmentReport({
    required String departmentId,
    required String format, // 'excel' or 'pdf'
    required Function(List<int> bytes, String filename) onSuccess,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'departmentId': departmentId,
        'format': format,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/generate-department-report'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Extract filename from Content-Disposition header
        final contentDisposition = response.headers['content-disposition'];
        String filename =
            'department_report.${format == 'pdf' ? 'pdf' : 'xlsx'}';

        if (contentDisposition != null) {
          final filenameMatch = RegExp(
            r'filename="?([^"]+)"?',
          ).firstMatch(contentDisposition);
          if (filenameMatch != null) {
            filename = filenameMatch.group(1)!;
          }
        }

        onSuccess(response.bodyBytes, filename);
      } else {
        throw Exception('Failed to generate report: ${response.body}');
      }
    } catch (e) {
      print('Error generating department report: $e');
      rethrow;
    }
  }

  // Generate individual student report
  Future<void> generateIndividualReport({
    required String userId,
    required String format, // 'excel' or 'pdf'
    required Function(List<int> bytes, String filename) onSuccess,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'userId': userId, 'format': format});

      final response = await http.post(
        Uri.parse('$baseUrl/generate-individual-report'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Extract filename from Content-Disposition header
        final contentDisposition = response.headers['content-disposition'];
        String filename =
            'individual_report.${format == 'pdf' ? 'pdf' : 'xlsx'}';

        if (contentDisposition != null) {
          final filenameMatch = RegExp(
            r'filename="?([^"]+)"?',
          ).firstMatch(contentDisposition);
          if (filenameMatch != null) {
            filename = filenameMatch.group(1)!;
          }
        }

        onSuccess(response.bodyBytes, filename);
      } else {
        throw Exception('Failed to generate report: ${response.body}');
      }
    } catch (e) {
      print('Error generating individual report: $e');
      rethrow;
    }
  }

  // Export all users
  Future<void> exportAllUsers({
    required Function(List<int> bytes, String filename) onSuccess,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/export-all-users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Extract filename from Content-Disposition header
        final contentDisposition = response.headers['content-disposition'];
        String filename = 'all_users.xlsx';

        if (contentDisposition != null) {
          final filenameMatch = RegExp(
            r'filename="?([^"]+)"?',
          ).firstMatch(contentDisposition);
          if (filenameMatch != null) {
            filename = filenameMatch.group(1)!;
          }
        }

        onSuccess(response.bodyBytes, filename);
      } else {
        throw Exception('Failed to export users: ${response.body}');
      }
    } catch (e) {
      print('Error exporting users: $e');
      rethrow;
    }
  }
}
