import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/admin_dashboard.dart';
import '../services/auth_service.dart';

class AdminDashboardService {
  final String baseUrl = '${ApiConfig.baseUrl}${ApiConfig.adminDashboard}';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get dashboard overview
  Future<AdminDashboardOverview> getOverview() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/overview'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return AdminDashboardOverview.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load overview: ${response.body}');
      }
    } catch (e) {
      print('Error getting overview: $e');
      rethrow;
    }
  }

  // Get user growth data
  Future<UserGrowthData> getUserGrowth({String period = 'month'}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '$baseUrl/user-growth',
      ).replace(queryParameters: {'period': period});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return UserGrowthData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user growth: ${response.body}');
      }
    } catch (e) {
      print('Error getting user growth: $e');
      rethrow;
    }
  }

  // Get course completion rates
  Future<List<CompletionRate>> getCompletionRates() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/completion-rates'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CompletionRate.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load completion rates: ${response.body}');
      }
    } catch (e) {
      print('Error getting completion rates: $e');
      rethrow;
    }
  }

  // Get training progress by department
  Future<List<DepartmentProgress>> getTrainingProgressByDepartment() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/training-progress-by-department'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DepartmentProgress.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load department progress: ${response.body}');
      }
    } catch (e) {
      print('Error getting department progress: $e');
      rethrow;
    }
  }

  // Get top performers
  Future<List<TopPerformer>> getTopPerformers({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '$baseUrl/top-performers',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TopPerformer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load top performers: ${response.body}');
      }
    } catch (e) {
      print('Error getting top performers: $e');
      rethrow;
    }
  }

  // Get low performers
  Future<List<TopPerformer>> getLowPerformers({
    int threshold = 50,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/low-performers').replace(
        queryParameters: {
          'threshold': threshold.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TopPerformer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load low performers: ${response.body}');
      }
    } catch (e) {
      print('Error getting low performers: $e');
      rethrow;
    }
  }
}
