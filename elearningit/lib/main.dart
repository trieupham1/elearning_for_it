import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/instructor_home_screen.dart';
import 'screens/api_test_screen.dart';
import 'screens/student/quiz_taking_screen.dart';
import 'screens/student/quiz_result_screen.dart';
import 'screens/instructor/quiz_settings_screen.dart';
import 'screens/instructor/create_quiz_screen.dart';
import 'screens/instructor/create_question_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/messages_list_screen.dart';
import 'screens/chat_screen.dart';
// Admin screens
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/bulk_import_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/department_management_screen.dart';
import 'screens/admin/manage_semesters_screen.dart';
import 'screens/admin/manage_courses_screen.dart';
import 'screens/manage_students_screen.dart';
// Models & services
import 'models/quiz.dart';
import 'models/user.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
// Yellow Priority Features - Video, Attendance, Code Assignment
import 'screens/student/video_player_screen.dart';
import 'screens/instructor/upload_video_screen.dart';
import 'screens/instructor/attendance_screen.dart';
import 'screens/instructor/create_attendance_session_screen.dart';
import 'screens/instructor/attendance_records_screen.dart';
import 'screens/student/check_in_screen.dart';
import 'screens/student/code_editor_screen.dart';
import 'screens/student/code_submission_results_screen.dart';
import 'screens/instructor/create_code_assignment_screen.dart';
import 'models/attendance.dart';
import 'models/code_assignment.dart';

// Global navigator key for showing dialogs/screens from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ELearningApp(),
    ),
  );
}

class ELearningApp extends StatefulWidget {
  const ELearningApp({super.key});

  @override
  State<ELearningApp> createState() => _ELearningAppState();
}

class _ELearningAppState extends State<ELearningApp> {
  @override
  void initState() {
    super.initState();
    // Don't load theme on startup - user needs to login first
    // Theme will be loaded after successful login
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Add global navigator key
          title: 'E-Learning System',
          theme: themeProvider.themeData,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/login': (context) => const LoginScreen(),
            '/student-home': (context) => const StudentHomeScreen(),
            '/instructor-home': (context) => const InstructorHomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/api-test': (context) => const ApiTestScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/manage-students': (context) => const ManageStudentsScreen(),
            // Admin routes
            '/admin/home': (context) => const AdminHomeScreen(),
            '/admin/dashboard': (context) => const AdminDashboardScreen(),
            '/admin/users': (context) => const UserManagementScreen(),
            '/admin/users/bulk-import': (context) => const BulkImportScreen(),
            '/admin/departments': (context) =>
                const DepartmentManagementScreen(),
            '/admin/semesters': (context) => const ManageSemestersScreen(),
            '/admin/courses': (context) => const ManageCoursesScreen(),
            '/admin/reports': (context) => const ReportsScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle dynamic routes
            if (settings.name == '/quiz-taking') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => QuizTakingScreen(
                  quizId: args?['quizId'] ?? '',
                  attemptId: args?['attemptId'],
                ),
              );
            }
            if (settings.name == '/quiz-result') {
              final attempt = settings.arguments as QuizAttempt;
              return MaterialPageRoute(
                builder: (context) => QuizResultScreen(attempt: attempt),
              );
            }
            if (settings.name == '/quiz-settings') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => QuizSettingsScreen(
                  quizId: args?['quizId'] ?? '',
                  quiz: args?['quiz'],
                ),
              );
            }
            if (settings.name == '/create-quiz') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) =>
                    CreateQuizScreen(courseId: args?['courseId'] ?? ''),
              );
            }
            if (settings.name == '/create-question') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CreateQuestionScreen(
                  courseId: args?['courseId'] ?? '',
                  courseName: args?['courseName'] ?? 'Course',
                ),
              );
            }
            if (settings.name == '/reset-password') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) =>
                    ResetPasswordScreen(token: args?['token']),
              );
            }
            if (settings.name == '/messages') {
              return MaterialPageRoute(
                builder: (context) => const MessagesListScreen(),
              );
            }
            if (settings.name == '/message') {
              final args = settings.arguments as Map<String, dynamic>?;
              final otherUserId = args?['otherUserId'] ?? '';
              final otherUserName = args?['otherUserName'] ?? 'User';
              final otherUserAvatar = args?['otherUserAvatar'] as String?;

              // Create User object for ChatScreen recipient
              final recipient = User(
                id: otherUserId,
                username: otherUserName,
                email: '',
                role: 'student',
                profilePicture: otherUserAvatar,
              );

              return MaterialPageRoute(
                builder: (context) => FutureBuilder<User?>(
                  future: AuthService().getCurrentUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final currentUser =
                        snapshot.data ??
                        User(
                          id: 'unknown',
                          username: 'Current User',
                          email: '',
                          role: 'student',
                        );

                    return ChatScreen(
                      recipient: recipient,
                      currentUser: currentUser,
                    );
                  },
                ),
              );
            }

            // ========== VIDEO ROUTES ==========
            if (settings.name == '/video-player') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) =>
                    VideoPlayerScreen(videoId: args?['videoId'] ?? ''),
              );
            }
            if (settings.name == '/upload-video') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) =>
                    UploadVideoScreen(courseId: args?['courseId'] ?? ''),
              );
            }

            // ========== ATTENDANCE ROUTES ==========
            if (settings.name == '/attendance') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => AttendanceScreen(
                  courseId: args?['courseId'] ?? '',
                  courseName: args?['courseName'] ?? 'Course',
                ),
              );
            }
            if (settings.name == '/create-attendance-session') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CreateAttendanceSessionScreen(
                  courseId: args?['courseId'] ?? '',
                  courseName: args?['courseName'] ?? 'Course',
                ),
              );
            }
            if (settings.name == '/attendance-records') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => AttendanceRecordsScreen(
                  session: args?['session'] as AttendanceSession,
                ),
              );
            }
            if (settings.name == '/check-in') {
              return MaterialPageRoute(
                builder: (context) => const CheckInScreen(),
              );
            }

            // ========== CODE ASSIGNMENT ROUTES ==========
            if (settings.name == '/code-editor') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CodeEditorScreen(
                  assignment: args?['assignment'] as CodeAssignment,
                  testCases: args?['testCases'] as List<TestCase>,
                ),
              );
            }
            if (settings.name == '/code-submission-results') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CodeSubmissionResultsScreen(
                  submission: args?['submission'] as CodeSubmission,
                  assignment: args?['assignment'] as CodeAssignment,
                ),
              );
            }
            if (settings.name == '/create-code-assignment') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CreateCodeAssignmentScreen(
                  courseId: args?['courseId'] ?? '',
                ),
              );
            }

            return null;
          },
        );
      },
    );
  }
}

// Simple Profile Screen placeholder
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Profile Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Coming soon!'),
          ],
        ),
      ),
    );
  }
}
