// screens/video_call/platform_course_video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/course.dart';
import '../../models/user.dart';
import 'course_video_call_screen.dart';
// Conditional import for web
import 'web_course_video_call_screen_stub.dart'
    if (dart.library.html) 'web_course_video_call_screen.dart';

/// Platform-aware course video call screen
/// - Uses Agora on native platforms (Android, iOS, Windows, etc.)
/// - Uses WebRTC on web browsers
class PlatformCourseVideoCallScreen extends StatelessWidget {
  final Course course;
  final User currentUser;

  const PlatformCourseVideoCallScreen({
    required this.course,
    required this.currentUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      debugPrint('🌐 Loading web course video call screen');
      return WebCourseVideoCallScreen(
        course: course,
        currentUser: currentUser,
      );
    } else {
      debugPrint('📱 Loading Agora course video call screen');
      return CourseVideoCallScreen(
        course: course,
        currentUser: currentUser,
      );
    }
  }
}
