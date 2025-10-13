import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/instructor_home_screen.dart';
import 'screens/api_test_screen.dart';
import 'screens/manage_semesters_screen.dart';
import 'screens/manage_courses_screen.dart';
import 'screens/manage_students_screen.dart';
import 'screens/student/quiz_taking_screen.dart';
import 'screens/student/quiz_result_screen.dart';
import 'screens/instructor/quiz_settings_screen.dart';
import 'screens/instructor/create_quiz_screen.dart';
import 'screens/instructor/create_question_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'models/quiz.dart';
import 'config/theme.dart';

void main() {
  runApp(const ELearningApp());
}

class ELearningApp extends StatelessWidget {
  const ELearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning System',
      theme: AppTheme.lightTheme,
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
        '/manage-semesters': (context) => const ManageSemestersScreen(),
        '/manage-courses': (context) => const ManageCoursesScreen(),
        '/manage-students': (context) => const ManageStudentsScreen(),
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
            builder: (context) => QuizResultScreen(
              attempt: attempt,
            ),
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
            builder: (context) => CreateQuizScreen(
              courseId: args?['courseId'] ?? '',
            ),
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
            builder: (context) => ResetPasswordScreen(
              token: args?['token'],
            ),
          );
        }
        return null;
      },
      themeMode: ThemeMode.system,
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
