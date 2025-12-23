import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';
  static const String _userDataKey = 'user_data';
  static const String _pendingRedirectKey = 'pending_redirect';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Remember Me functionality
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  // Store user role for auto-redirect after login
  static Future<void> saveUserData(String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, '$userId|$role');
  }

  static Future<Map<String, String>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userDataKey);
    if (data == null) return null;
    final parts = data.split('|');
    if (parts.length != 2) return null;
    return {'userId': parts[0], 'role': parts[1]};
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  // Pending redirect for deep linking (e.g., from email links)
  static Future<void> setPendingRedirect(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRedirectKey, route);
  }

  static Future<String?> getPendingRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingRedirectKey);
  }

  static Future<void> clearPendingRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRedirectKey);
  }

  // Clear all auth data on logout
  static Future<void> clearAll({bool keepRememberMe = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_pendingRedirectKey);
    if (!keepRememberMe) {
      await prefs.remove(_rememberMeKey);
    }
  }
}
