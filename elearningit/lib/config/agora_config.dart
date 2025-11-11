// config/agora_config.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

/// Agora RTC Configuration
/// Get your App ID from https://console.agora.io/
class AgoraConfig {
  // Agora App ID from console.agora.io
  static const String appId = 'afa109d795eb450db1793f9f0b5f0ec9';

  // Token server URL (your backend)
  static String get tokenServerUrl => '${ApiConfig.baseUrl}/api/agora';

  /// Generate a channel name for a call between two users
  static String generateChannelName(String userId1, String userId2) {
    // Sort user IDs to ensure same channel name regardless of who calls whom
    final users = [userId1, userId2]..sort();
    return 'call_${users[0]}_${users[1]}';
  }

  /// Get token from server
  static Future<String?> getToken(String channelName, int uid) async {
    try {
      print('🎫 Requesting Agora token from: $tokenServerUrl/generate-token');
      
      final headers = await ApiConfig.headers();
      final response = await http.post(
        Uri.parse('$tokenServerUrl/generate-token'),
        headers: headers,
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
          'role': 'publisher',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Agora token received');
        return data['token'] as String;
      } else {
        print('❌ Failed to get token: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting Agora token: $e');
      return null;
    }
  }
}
