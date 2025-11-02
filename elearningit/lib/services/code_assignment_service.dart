import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/code_assignment.dart';
import '../config/api_config.dart';
import '../utils/token_manager.dart';
import 'api_service.dart';

class CodeAssignmentService {
  final String baseUrl = ApiConfig.baseUrl;

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Create code assignment (instructor only)
  Future<CodeAssignment> createAssignment({
    required String courseId,
    required String title,
    required String description,
    required String language,
    required DateTime deadline,
    String? starterCode,
    String? solutionCode,
    List<String>? allowedLanguages,
    List<Map<String, dynamic>>? testCases,
    int points = 100,
    int timeLimit = 5000,
    int memoryLimit = 128000,
    bool showTestCases = true,
  }) async {
    try {
      final headers = await _getHeaders();
      final programmingLang = ProgrammingLanguage.fromKey(language);

      if (programmingLang == null) {
        throw ApiException('Unsupported language: $language');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/code/assignments'),
        headers: headers,
        body: jsonEncode({
          'courseId': courseId,
          'title': title,
          'description': description,
          'language': language,
          'languageId': programmingLang.judge0Id,
          'starterCode': starterCode,
          'solutionCode': solutionCode,
          'allowedLanguages': allowedLanguages ?? [language],
          'testCases': testCases,
          'deadline': deadline.toIso8601String(),
          'startDate': DateTime.now().toIso8601String(),
          'points': points,
          'timeLimit': timeLimit,
          'memoryLimit': memoryLimit,
          'showTestCases': showTestCases,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return CodeAssignment.fromJson(data['assignment']);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to create assignment');
      }
    } catch (e) {
      throw ApiException('Error creating assignment: $e');
    }
  }

  // Get code assignment with test cases
  Future<Map<String, dynamic>> getAssignment(String assignmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/code/assignments/$assignmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug: Print the assignment data
        print(
          'Assignment data from backend: ${jsonEncode(data['assignment'])}',
        );

        print('Test cases count: ${data['testCases'].length}');
        if (data['testCases'].length > 0) {
          print('First test case: ${jsonEncode(data['testCases'][0])}');
        }

        try {
          final assignment = CodeAssignment.fromJson(data['assignment']);
          print('✅ Assignment parsed successfully');

          final testCases = (data['testCases'] as List).map((tc) {
            print('Parsing test case: ${jsonEncode(tc)}');
            return TestCase.fromJson(tc);
          }).toList();
          print('✅ All test cases parsed successfully');

          return {'assignment': assignment, 'testCases': testCases};
        } catch (parseError) {
          print('❌ Parsing error: $parseError');
          rethrow;
        }
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get assignment');
      }
    } catch (e) {
      print('Error in getAssignment: $e');
      throw ApiException('Error getting assignment: $e');
    }
  }

  // Submit code for grading
  Future<Map<String, dynamic>> submitCode({
    required String assignmentId,
    required String code,
    required String language,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/code/assignments/$assignmentId/submit'),
        headers: headers,
        body: jsonEncode({'code': code, 'language': language}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        print('📤 Submit response: ${jsonEncode(data)}');

        // Handle submissionId which might be an object or string
        final submissionId = data['submissionId'] is String
            ? data['submissionId']
            : data['submissionId'].toString();

        return {
          'submissionId': submissionId,
          'status': data['status']?.toString() ?? 'unknown',
          'message': data['message']?.toString() ?? 'Submitted',
        };
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to submit code');
      }
    } catch (e) {
      print('❌ Error submitting code: $e');
      throw ApiException('Error submitting code: $e');
    }
  }

  // Test code without submitting (dry run)
  Future<Map<String, dynamic>> testCode({
    required String assignmentId,
    required String code,
    required String language,
    String input = '',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/code/assignments/$assignmentId/test'),
        headers: headers,
        body: jsonEncode({'code': code, 'language': language, 'input': input}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'output': data['output'] ?? '',
          'error': data['error'] ?? '',
          'executionTime': data['executionTime'] ?? 0.0,
          'memoryUsed': data['memoryUsed'] ?? 0,
          'status': data['status'] ?? 'unknown',
          'message': data['message'] ?? '',
        };
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to test code');
      }
    } catch (e) {
      throw ApiException('Error testing code: $e');
    }
  }

  // Get submission result
  Future<CodeSubmission> getSubmission(String submissionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/code/submissions/$submissionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('📥 Submission data received:');
        print('  - assignmentId type: ${data['assignmentId'].runtimeType}');
        print('  - studentId type: ${data['studentId'].runtimeType}');
        print('  - status: ${data['status']}');

        final submission = CodeSubmission.fromJson(data);
        print('✅ Submission parsed successfully');
        return submission;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get submission');
      }
    } catch (e) {
      print('❌ Error in getSubmission: $e');
      throw ApiException('Error getting submission: $e');
    }
  }

  // Get student's submission history
  Future<List<CodeSubmission>> getMySubmissions(String assignmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/code/assignments/$assignmentId/my-submissions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((s) => CodeSubmission.fromJson(s)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get submissions');
      }
    } catch (e) {
      throw ApiException('Error getting submissions: $e');
    }
  }

  // Get all submissions for assignment (instructor only)
  Future<List<Map<String, dynamic>>> getAllSubmissions(
    String assignmentId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/code/assignments/$assignmentId/submissions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get submissions');
      }
    } catch (e) {
      throw ApiException('Error getting submissions: $e');
    }
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(
    String assignmentId, {
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/code/assignments/$assignmentId/leaderboard?limit=$limit',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((entry) => LeaderboardEntry.fromJson(entry)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get leaderboard');
      }
    } catch (e) {
      throw ApiException('Error getting leaderboard: $e');
    }
  }

  // Add test case (instructor only)
  Future<TestCase> addTestCase({
    required String assignmentId,
    required String name,
    required String input,
    required String expectedOutput,
    String? description,
    int weight = 1,
    int? timeLimit,
    int? memoryLimit,
    bool isHidden = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/code/assignments/$assignmentId/test-cases'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'input': input,
          'expectedOutput': expectedOutput,
          'weight': weight,
          'timeLimit': timeLimit,
          'memoryLimit': memoryLimit,
          'isHidden': isHidden,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TestCase.fromJson(data['testCase']);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to add test case');
      }
    } catch (e) {
      throw ApiException('Error adding test case: $e');
    }
  }

  // Delete test case (instructor only)
  Future<void> deleteTestCase(String testCaseId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/code/test-cases/$testCaseId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to delete test case');
      }
    } catch (e) {
      throw ApiException('Error deleting test case: $e');
    }
  }

  // Poll submission status until completed
  Future<CodeSubmission> pollSubmissionStatus(
    String submissionId, {
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final startTime = DateTime.now();

    while (true) {
      final submission = await getSubmission(submissionId);

      if (submission.isCompleted || submission.hasError) {
        return submission;
      }

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        throw ApiException('Submission timeout: taking too long to grade');
      }

      // Wait before next poll
      await Future.delayed(pollInterval);
    }
  }
}
