// services/call_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/call.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class CallService {
  final ApiService _apiService = ApiService();

  // Initiate a call
  Future<Call> initiateCall({
    required String calleeId,
    required String type, // 'voice' or 'video'
  }) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/calls/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'calleeId': calleeId, 'type': type}),
      );

      print('📞 Initiate call response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Call.fromJson(data['call']);
      } else if (response.statusCode == 409) {
        throw Exception('Already in a call');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to initiate call');
      }
    } catch (e) {
      print('❌ Error initiating call: $e');
      rethrow;
    }
  }

  // Update call status
  Future<Call> updateCallStatus(String callId, String status) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/calls/$callId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Call.fromJson(data['call']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update call status');
      }
    } catch (e) {
      print('❌ Error updating call status: $e');
      rethrow;
    }
  }

  // End a call
  Future<Call> endCall(String callId, {int? duration}) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/calls/$callId/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'duration': duration ?? 0}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Call.fromJson(data['call']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to end call');
      }
    } catch (e) {
      print('❌ Error ending call: $e');
      rethrow;
    }
  }

  // Get call history
  Future<List<Call>> getCallHistory({int limit = 50}) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/calls/history?limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> callsJson = data['calls'];
        return callsJson.map((json) => Call.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch call history');
      }
    } catch (e) {
      print('❌ Error fetching call history: $e');
      rethrow;
    }
  }

  // Get active calls
  Future<List<Call>> getActiveCalls() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/calls/active'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> callsJson = data['calls'];
        return callsJson.map((json) => Call.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch active calls');
      }
    } catch (e) {
      print('❌ Error fetching active calls: $e');
      rethrow;
    }
  }

  // Toggle screen sharing
  Future<Call> toggleScreenShare(String callId, bool isScreenSharing) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/calls/$callId/screen-share'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'isScreenSharing': isScreenSharing}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Call.fromJson(data['call']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to toggle screen share');
      }
    } catch (e) {
      print('❌ Error toggling screen share: $e');
      rethrow;
    }
  }

  /// Generate Agora RTC token for a channel
  ///
  /// [channelName] - The Agora channel name
  /// [uid] - User ID (0 for auto-assign)
  /// [role] - 'publisher' or 'subscriber' (default: 'publisher')
  ///
  /// Returns a Map with: token, appId, channelName, uid, expiresAt
  Future<Map<String, dynamic>> generateAgoraToken({
    required String channelName,
    int uid = 0,
    String role = 'publisher',
  }) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.getBaseUrl()}/api/agora/generate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'channelName': channelName,
          'uid': uid,
          'role': role,
        }),
      );

      print('🎫 Generate Agora token response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Agora token generated successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to generate Agora token');
      }
    } catch (e) {
      print('❌ Error generating Agora token: $e');
      rethrow;
    }
  }
}
