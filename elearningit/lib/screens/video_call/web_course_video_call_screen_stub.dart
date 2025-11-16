// screens/video_call/web_course_video_call_screen_stub.dart
// Stub for non-web platforms
import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/user.dart';

class WebCourseVideoCallScreen extends StatelessWidget {
  final Course course;
  final User currentUser;

  const WebCourseVideoCallScreen({
    super.key,
    required this.course,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('This should not be called on non-web platforms'),
      ),
    );
  }
}
