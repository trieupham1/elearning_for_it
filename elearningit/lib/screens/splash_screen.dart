import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../providers/theme_provider.dart';
import '../utils/token_manager.dart';

class SplashScreen extends StatefulWidget {
  final String? deepLinkRoute;

  const SplashScreen({super.key, this.deepLinkRoute});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Check authentication and redirect
    _checkAuthAndRedirect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndRedirect() async {
    // Give time for animation to show
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Check if there's a deep link route to handle
      if (widget.deepLinkRoute != null && widget.deepLinkRoute!.isNotEmpty) {
        // Save the deep link for after login
        await TokenManager.setPendingRedirect(widget.deepLinkRoute!);
      }

      // Check for existing valid token
      final token = await TokenManager.getToken();
      final rememberMe = await TokenManager.getRememberMe();

      if (token != null && rememberMe) {
        // Try to validate the token by getting current user
        final authService = AuthService();
        final user = await authService.getCurrentUser();

        if (user != null && mounted) {
          // Token is valid, auto-login
          print('✅ Auto-login successful for: ${user.username}');

          // Initialize socket connection
          try {
            final socketService = SocketService();
            await socketService.connect(user.id, context);
          } catch (e) {
            print('⚠️ Could not initialize socket: $e');
          }

          // Load theme
          try {
            await Provider.of<ThemeProvider>(context, listen: false).loadTheme();
          } catch (e) {
            print('⚠️ Could not load theme: $e');
          }

          // Check for pending deep link redirect
          final pendingRedirect = await TokenManager.getPendingRedirect();
          if (pendingRedirect != null && pendingRedirect.isNotEmpty) {
            await TokenManager.clearPendingRedirect();
            Navigator.pushReplacementNamed(context, pendingRedirect);
            return;
          }

          // Navigate to appropriate home screen
          if (user.role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin/home');
          } else if (user.role == 'instructor') {
            Navigator.pushReplacementNamed(context, '/instructor-home');
          } else {
            Navigator.pushReplacementNamed(context, '/student-home');
          }
          return;
        }
      }

      // No valid token or remember me not enabled, go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('❌ Auto-login failed: $e');
      // Clear invalid token
      await TokenManager.clearToken();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                : [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 80,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      const Text(
                        'E-Learning System',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faculty of Information Technology',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
