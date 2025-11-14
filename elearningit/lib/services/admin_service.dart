import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/admin_dashboard.dart';
import '../services/auth_service.dart';

class AdminService {
  final String baseUrl = '${ApiConfig.baseUrl}${ApiConfig.admin}';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ========== USER MANAGEMENT ==========

  // Get users with filters and pagination
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? department,
    bool? isActive,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null) queryParams['role'] = role;
      if (department != null) queryParams['department'] = department;
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final uri = Uri.parse(
        '$baseUrl/users',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'users': (data['users'] as List)
              .map((json) => User.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  // Create a new user manually
  Future<User> createUser({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? role,
    String? department,
    String? studentId,
    String? phoneNumber,
  }) async {
    try {
      final headers = await _getHeaders();
      final bodyData = {
        'username': username,
        'email': email,
        'password': password,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (role != null) 'role': role,
        if (department != null) 'department': department,
        if (studentId != null) 'studentId': studentId,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: headers,
        body: json.encode(bodyData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Bulk import users from file
  Future<Map<String, dynamic>> bulkImportUsers(File file) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/bulk-import'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to import users: ${response.body}');
      }
    } catch (e) {
      print('Error importing users: $e');
      rethrow;
    }
  }

  // Bulk import users from bytes (for web)
  Future<Map<String, dynamic>> bulkImportUsersFromBytes(
    List<int> bytes,
    String filename,
  ) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/bulk-import'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to import users: ${response.body}');
      }
    } catch (e) {
      print('Error importing users: $e');
      rethrow;
    }
  }

  // Suspend user account
  Future<User> suspendUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/suspend'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to suspend user: ${response.body}');
      }
    } catch (e) {
      print('Error suspending user: $e');
      rethrow;
    }
  }

  // Activate user account
  Future<User> activateUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/activate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to activate user: ${response.body}');
      }
    } catch (e) {
      print('Error activating user: $e');
      rethrow;
    }
  }

  // Reset user password (admin action)
  Future<void> resetUserPassword(String userId, String newPassword) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'newPassword': newPassword});

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/reset-password'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.body}');
      }
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Update user role/permissions
  Future<User> updateUserRole(String userId, String role) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'role': role});

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/permissions'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to update role: ${response.body}');
      }
    } catch (e) {
      print('Error updating role: $e');
      rethrow;
    }
  }

  // Update user information (full name, email, username)
  Future<User> updateUser({
    required String userId,
    String? fullName,
    String? email,
    String? username,
    String? role,
    bool? isActive,
  }) async {
    try {
      final headers = await _getHeaders();
      final bodyData = <String, dynamic>{};

      if (fullName != null) {
        final parts = fullName.split(' ');
        if (parts.length >= 2) {
          bodyData['firstName'] = parts.first;
          bodyData['lastName'] = parts.sublist(1).join(' ');
        } else {
          bodyData['firstName'] = fullName;
        }
      }
      if (email != null) bodyData['email'] = email;
      if (username != null) bodyData['username'] = username;
      if (role != null) bodyData['role'] = role;
      if (isActive != null) bodyData['isActive'] = isActive;

      final body = json.encode(bodyData);

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Get user activity logs
  Future<ActivityLogResponse> getUserActivityLogs(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/users/$userId/activity-logs',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return ActivityLogResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load activity logs: ${response.body}');
      }
    } catch (e) {
      print('Error getting activity logs: $e');
      rethrow;
    }
  }

  // Get all activity logs (system-wide)
  Future<ActivityLogResponse> getAllActivityLogs({
    int page = 1,
    int limit = 50,
    String? action,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (action != null) queryParams['action'] = action;
      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse(
        '$baseUrl/activity-logs',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return ActivityLogResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load activity logs: ${response.body}');
      }
    } catch (e) {
      print('Error getting activity logs: $e');
      rethrow;
    }
  }

  // Get user statistics
  Future<UserStatistics> getUserStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/statistics/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return UserStatistics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.body}');
      }
    } catch (e) {
      print('Error getting statistics: $e');
      rethrow;
    }
  }

  // ========== INSTRUCTOR ASSIGNMENT ==========

  // Assign instructor to course
  Future<void> assignInstructor(String courseId, String instructorId) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'instructorId': instructorId});

      final response = await http.put(
        Uri.parse('$baseUrl/courses/$courseId/assign-instructor'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to assign instructor: ${response.body}');
      }
    } catch (e) {
      print('Error assigning instructor: $e');
      rethrow;
    }
  }

  // Get instructor workload
  Future<List<InstructorWorkload>> getInstructorWorkload() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/instructors/workload'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => InstructorWorkload.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load workload: ${response.body}');
      }
    } catch (e) {
      print('Error getting workload: $e');
      rethrow;
    }
  }

  // Get all instructors
  Future<List<User>> getAllInstructors() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/instructors'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load instructors: ${response.body}');
      }
    } catch (e) {
      print('Error getting instructors: $e');
      rethrow;
    }
  }
}
