// config/agora_config.dart

/// Agora RTC Configuration
/// Get your App ID from https://console.agora.io/
class AgoraConfig {
  // Agora App ID from console.agora.io
  static const String appId = 'afa109d795eb450db1793f9f0b5f0ec9';

  // Optional: Token server URL for production
  // For testing, you can use null tokens
  static const String? tokenServerUrl = null;

  /// Generate a channel name for a call between two users
  static String generateChannelName(String userId1, String userId2) {
    // Sort user IDs to ensure same channel name regardless of who calls whom
    final users = [userId1, userId2]..sort();
    return 'call_${users[0]}_${users[1]}';
  }

  /// Get token from server (optional, for production)
  static Future<String?> getToken(String channelName, int uid) async {
    if (tokenServerUrl == null) {
      return null; // Use null token for testing
    }

    // TODO: Implement token fetching from your backend
    // Example:
    // final response = await http.get(
    //   Uri.parse('$tokenServerUrl/token?channel=$channelName&uid=$uid'),
    // );
    // return response.body;

    return null;
  }
}
