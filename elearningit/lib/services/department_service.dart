import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/department.dart';
import '../services/auth_service.dart';

class DepartmentService {
  final String baseUrl = '${ApiConfig.baseUrl}/departments';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all departments
  Future<List<Department>> getDepartments({
    bool? isActive,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};

      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Department.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load departments: ${response.body}');
      }
    } catch (e) {
      print('Error getting departments: $e');
      rethrow;
    }
  }

  // Get department by ID with full details
  Future<DepartmentDetailed> getDepartmentById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('🔍 Department Response: ${response.body}');
        final jsonData = json.decode(response.body);
        print('🔍 Decoded JSON: $jsonData');
        return DepartmentDetailed.fromJson(jsonData);
      } else {
        throw Exception('Failed to load department: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting department: $e');
      rethrow;
    }
  }

  // Create new department
  Future<Department> createDepartment({
    required String name,
    required String code,
    String? description,
    String? headOfDepartment,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'name': name,
        'code': code,
        if (description != null) 'description': description,
        if (headOfDepartment != null) 'headOfDepartment': headOfDepartment,
      });

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        return Department.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create department: ${response.body}');
      }
    } catch (e) {
      print('Error creating department: $e');
      rethrow;
    }
  }

  // Update department
  Future<Department> updateDepartment({
    required String id,
    String? name,
    String? code,
    String? description,
    String? headOfDepartment,
    bool? isActive,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (headOfDepartment != null) 'headOfDepartment': headOfDepartment,
        if (isActive != null) 'isActive': isActive,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return Department.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update department: ${response.body}');
      }
    } catch (e) {
      print('Error updating department: $e');
      rethrow;
    }
  }

  // Delete (deactivate) department
  Future<void> deleteDepartment(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete department: ${response.body}');
      }
    } catch (e) {
      print('Error deleting department: $e');
      rethrow;
    }
  }

  // Assign courses to department
  Future<Department> assignCourses(String id, List<String> courseIds) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'courseIds': courseIds});

      final response = await http.put(
        Uri.parse('$baseUrl/$id/assign-courses'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return Department.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to assign courses: ${response.body}');
      }
    } catch (e) {
      print('Error assigning courses: $e');
      rethrow;
    }
  }

  // Add single course to department
  // Add course to department
  Future<void> addCourse(String id, String courseId) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'courseId': courseId});

      final response = await http.post(
        Uri.parse('$baseUrl/$id/add-course'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add course: ${response.body}');
      }
      // Don't parse response - just return success
      // The department will be reloaded anyway
    } catch (e) {
      print('Error adding course: $e');
      rethrow;
    }
  }

  // Remove course from department
  Future<Department> removeCourse(String id, String courseId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id/remove-course/$courseId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Department.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to remove course: ${response.body}');
      }
    } catch (e) {
      print('Error removing course: $e');
      rethrow;
    }
  }

  // Auto-enroll department employees to courses
  Future<Map<String, dynamic>> autoEnroll(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$id/auto-enroll'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to auto-enroll: ${response.body}');
      }
    } catch (e) {
      print('Error auto-enrolling: $e');
      rethrow;
    }
  }

  // Add employee to department
  // Add employee to department
  Future<void> addEmployee(String id, String userId) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'userId': userId});

      final response = await http.put(
        Uri.parse('$baseUrl/$id/add-employee'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add employee: ${response.body}');
      }
      // Don't parse response - just return success
      // The department will be reloaded anyway
    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  // Get department statistics
  Future<DepartmentStatistics> getStatistics(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id/statistics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return DepartmentStatistics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.body}');
      }
    } catch (e) {
      print('Error getting statistics: $e');
      rethrow;
    }
  }
}
