import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/instructor_home_screen.dart';
import 'screens/api_test_screen.dart';
import 'screens/manage_semesters_screen.dart';
import 'screens/manage_courses_screen.dart';
import 'screens/manage_students_screen.dart';
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/student-home': (context) => const StudentHomeScreen(),
        '/instructor-home': (context) => const InstructorHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/api-test': (context) => const ApiTestScreen(),
        '/manage-semesters': (context) => const ManageSemestersScreen(),
        '/manage-courses': (context) => const ManageCoursesScreen(),
        '/manage-students': (context) => const ManageStudentsScreen(),
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
