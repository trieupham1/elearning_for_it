import 'package:flutter/material.dart';
import '../../models/admin_dashboard.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin_drawer.dart';

class InstructorWorkloadDetailScreen extends StatefulWidget {
  const InstructorWorkloadDetailScreen({super.key});

  @override
  State<InstructorWorkloadDetailScreen> createState() =>
      _InstructorWorkloadDetailScreenState();
}

class _InstructorWorkloadDetailScreenState
    extends State<InstructorWorkloadDetailScreen> {
  final _notificationService = NotificationService();
  User? _currentUser;
  bool _isLoading = true;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      
      // Load notification count
      try {
        final count = await _notificationService.getUnreadCount();
        setState(() => _unreadNotificationCount = count);
      } catch (e) {
        print('Error loading notification count: $e');
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workload = ModalRoute.of(context)!.settings.arguments as InstructorWorkload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Workload Details'),
        actions: _buildAppBarActions(context),
      ),
      drawer: _currentUser != null ? AdminDrawer(currentUser: _currentUser!) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructorInfoCard(workload),
                  const SizedBox(height: 24),
                  _buildStatisticsCards(workload),
                  const SizedBox(height: 24),
                  _buildCoursesSection(workload),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructorInfoCard(InstructorWorkload workload) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: workload.instructor.profilePicture != null
                  ? NetworkImage(workload.instructor.profilePicture!)
                  : null,
              child: workload.instructor.profilePicture == null
                  ? Text(
                      workload.instructor.fullName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              workload.instructor.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  workload.instructor.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (workload.instructor.department != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    workload.instructor.department!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(InstructorWorkload workload) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Courses',
            workload.totalCourses.toString(),
            Icons.school,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Students',
            workload.totalStudents.toString(),
            Icons.people,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection(InstructorWorkload workload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (workload.courses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No courses assigned'),
            ),
          )
        else
          ...workload.courses.map((course) => _buildCourseCard(course)),
      ],
    );
  }

  Widget _buildCourseCard(WorkloadCourse course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            course.courseCode.isNotEmpty
                ? course.courseCode.substring(0, 2).toUpperCase()
                : 'C',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          course.courseName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseCode,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${course.studentCount} students',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.check_circle, color: Colors.green.shade400),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.pushNamed(context, '/notifications');
              try {
                final count = await _notificationService.getUnreadCount();
                setState(() => _unreadNotificationCount = count);
              } catch (e) {
                print('Error reloading notification count: $e');
              }
            },
          ),
          if (_unreadNotificationCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.message),
        tooltip: 'Messages',
        onPressed: () {
          Navigator.pushNamed(context, '/messages');
        },
      ),
      const SizedBox(width: 16),
    ];
  }

}
