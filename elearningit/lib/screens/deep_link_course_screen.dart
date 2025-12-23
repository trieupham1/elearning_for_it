import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/auth_service.dart';
import 'course_detail_screen.dart';
import 'login_screen.dart';

/// A wrapper screen that handles deep linking to courses.
/// It loads the course by ID and then navigates to the CourseDetailScreen.
/// If the user is not authenticated, it redirects to login with a pending redirect.
class DeepLinkCourseScreen extends StatefulWidget {
  final String courseId;
  final int initialTabIndex;

  const DeepLinkCourseScreen({
    super.key,
    required this.courseId,
    this.initialTabIndex = 0,
  });

  @override
  State<DeepLinkCourseScreen> createState() => _DeepLinkCourseScreenState();
}

class _DeepLinkCourseScreenState extends State<DeepLinkCourseScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  Course? _course;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      // First check if user is authenticated
      final user = await _authService.getCurrentUser();
      if (user == null) {
        // Not authenticated, redirect to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Load the course
      final course = await _courseService.getCourseById(widget.courseId);
      
      if (mounted) {
        setState(() {
          _course = course;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load course: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading course...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage!),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_course != null) {
      return CourseDetailScreen(
        course: _course!,
      );
    }

    return Scaffold(
      body: Center(
        child: Text('Course not found'),
      ),
    );
  }
}
