import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/token_manager.dart';

class VideoCallService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Get Agora token from backend
  Future<Map<String, dynamic>> getAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/video-call/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'channelName': channelName,
          'uid': uid,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get Agora token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting Agora token: $e');
    }
  }

  /// Notify backend that user joined the call
  Future<void> joinCall({
    required String courseId,
    required String channelName,
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      await http.post(
        Uri.parse('$baseUrl/api/video-call/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'courseId': courseId,
          'channelName': channelName,
        }),
      );
    } catch (e) {
      print('Error notifying join: $e');
    }
  }

  /// Notify backend that user left the call
  Future<void> leaveCall({
    required String courseId,
    required String channelName,
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      await http.post(
        Uri.parse('$baseUrl/api/video-call/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'courseId': courseId,
          'channelName': channelName,
        }),
      );
    } catch (e) {
      print('Error notifying leave: $e');
    }
  }

  /// Get user name by UID
  Future<String> getUserNameByUid(int uid) async {
    try {
      final userInfo = await getUserInfoByUid(uid);
      return userInfo['userName'] ?? 'Unknown User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Unknown User';
    }
  }

  /// Get full user info by UID (name + profile picture)
  Future<Map<String, dynamic>> getUserInfoByUid(int uid) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/video-call/user/$uid'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'userName': data['userName'] ?? 'Unknown User',
          'profilePicture': data['profilePicture'],
          'userId': data['userId'],
        };
      }
      return {'userName': 'Unknown User', 'profilePicture': null};
    } catch (e) {
      print('Error getting user info: $e');
      return {'userName': 'Unknown User', 'profilePicture': null};
    }
  }

  /// Get active participants in a call
  Future<List<Map<String, dynamic>>> getActiveParticipants({
    required String courseId,
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/video-call/participants/$courseId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['participants'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting participants: $e');
      return [];
    }
  }
}
