import '../models/user.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService extends ApiService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await post(
        '${ApiConfig.auth}/login',
        body: request.toJson(),
        withAuth: false,
      );

      final data = parseResponse(response);
      final loginResponse = LoginResponse.fromJson(data);

      // Save token and user data
      await saveToken(loginResponse.token);
      _currentUser = loginResponse.user;

      return loginResponse;
    } catch (e) {
      throw ApiException('Login failed: $e');
    }
  }

  Future<User> register(RegisterRequest request) async {
    try {
      final response = await post(
        '${ApiConfig.auth}/register',
        body: request.toJson(),
        withAuth: false,
      );

      final data = parseResponse(response);
      return User.fromJson(data['user']);
    } catch (e) {
      throw ApiException('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Call backend logout endpoint if needed
      await post('${ApiConfig.auth}/logout');
    } catch (e) {
      // Continue with local logout even if server call fails
    } finally {
      // Clear local data
      await clearToken();
      _currentUser = null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      final token = await getToken();
      if (token == null) {
        return null;
      }

      final response = await get('${ApiConfig.auth}/me');
      final data = parseResponse(response);
      _currentUser = User.fromJson(data);

      return _currentUser;
    } catch (e) {
      // If token is invalid, clear it
      await clearToken();
      _currentUser = null;
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await put(
        '${ApiConfig.auth}/change-password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (e) {
      throw ApiException('Failed to change password: $e');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await post(
        '${ApiConfig.auth}/forgot-password',
        body: {'email': email},
        withAuth: false,
      );
    } catch (e) {
      throw ApiException('Failed to request password reset: $e');
    }
  }

  Future<User> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await put('${ApiConfig.users}/profile', body: userData);
      final data = parseResponse(response);
      _currentUser = User.fromJson(data);
      return _currentUser!;
    } catch (e) {
      throw ApiException('Failed to update profile: $e');
    }
  }

  Future<bool> checkAuthStatus() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
