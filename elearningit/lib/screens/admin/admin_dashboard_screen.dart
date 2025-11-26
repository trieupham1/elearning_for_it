import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user.dart';
import '../../models/admin_dashboard.dart';
import '../../models/activity_log.dart';
import '../../services/auth_service.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final AdminService _adminService = AdminService();
  User? _currentUser;
  AdminDashboardOverview? _overview;
  List<ActivityLog> _recentActivity = [];
  List<DepartmentProgress> _departmentProgress = [];
  List<InstructorWorkload> _instructorWorkload = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();

      setState(() {
        _currentUser = user;
      });

      // Load overview
      try {
        final overview = await _dashboardService.getOverview();
        setState(() => _overview = overview);
      } catch (e) {
        debugPrint('Error loading overview: $e');
      }

      // Load recent activity
      try {
        final activityResponse = await _adminService.getAllActivityLogs(
          limit: 10,
        );
        setState(() => _recentActivity = activityResponse.logs);
      } catch (e) {
        debugPrint('Error loading activity logs: $e');
      }

      // Load department progress
      try {
        final deptProgress = await _dashboardService.getTrainingProgressByDepartment();
        setState(() => _departmentProgress = deptProgress);
      } catch (e) {
        debugPrint('Error loading department progress: $e');
      }

      // Load instructor workload
      try {
        final workload = await _adminService.getInstructorWorkload();
        setState(() => _instructorWorkload = workload);
      } catch (e) {
        debugPrint('Error loading instructor workload: $e');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadDashboardData,
      ),
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
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
              child: const Text(
                '3',
                style: TextStyle(
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
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Messages',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messages feature coming soon')),
              );
            },
          ),
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
              child: const Text(
                '5',
                style: TextStyle(
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
      PopupMenuButton<String>(
        tooltip: 'Profile',
        offset: const Offset(0, 50),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(
            radius: 18,
            child: Icon(Icons.person, size: 20),
          ),
        ),
        onSelected: (value) async {
          switch (value) {
            case 'profile':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile feature coming soon')),
              );
              break;
            case 'settings':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings feature coming soon')),
              );
              break;
            case 'logout':
              _handleLogout();
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 8),
                Text('My Profile'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(width: 8),
    ];
  }

  Future<void> _handleLogout() async {
    try {
      final authService = AuthService();
      await authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: _buildAppBarActions(context),
      ),
      drawer: _currentUser != null ? AdminDrawer(currentUser: _currentUser!) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(),
                    const SizedBox(height: 24),
                    _buildDepartmentTrainingProgress(),
                    const SizedBox(height: 24),
                    _buildInstructorWorkloadSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    if (_overview == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          'Total Users',
          _overview!.totalUsers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Courses',
          _overview!.activeCourses.toString(),
          Icons.school,
          Colors.green,
        ),
        _buildStatCard(
          'Total Courses',
          _overview!.totalCourses.toString(),
          Icons.library_books,
          Colors.orange,
        ),
        _buildStatCard(
          'Departments',
          _overview!.totalDepartments.toString(),
          Icons.business,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/activity-logs');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentActivity.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent activity'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivity.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = _recentActivity[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getActionColor(activity.action),
                      child: Icon(
                        _getActionIcon(activity.action),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(activity.description),
                    subtitle: Text(
                      activity.user?.fullName ?? 'Unknown User',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      timeago.format(activity.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentTrainingProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Department Training Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/training-progress');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_departmentProgress.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No department data available'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _departmentProgress.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final dept = _departmentProgress[index];
                  return _buildDepartmentCard(dept);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentProgress dept) {
    final avgScore = dept.overallCompletionRate;
    final progressColor = _getCompletionColor(avgScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dept.departmentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${avgScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: avgScore / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Employees: ${dept.totalEmployees}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.school, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Courses: ${dept.totalCourses}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorWorkloadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instructor Workload',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/instructor-workload');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_instructorWorkload.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No instructor data available'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _instructorWorkload.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final workload = _instructorWorkload[index];
                  final workloadColor = _getWorkloadColor(workload.totalCourses);
                  
                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/admin/instructor-workload-detail',
                        arguments: workload,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              workload.instructor.fullName.isNotEmpty
                                  ? workload.instructor.fullName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workload.instructor.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Courses: ${workload.totalCourses} • Students: ${workload.totalStudents}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (workload.instructor.department != null)
                                  Text(
                                    workload.instructor.department!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: workloadColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: workloadColor),
                            ),
                            child: Text(
                              '${workload.courses.length}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: workloadColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.grey;
      case 'course_enrollment':
        return Colors.blue;
      case 'course_completion':
        return Colors.purple;
      case 'assignment_submission':
        return Colors.orange;
      case 'quiz_attempt':
        return Colors.teal;
      case 'profile_update':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'course_enrollment':
        return Icons.school;
      case 'course_completion':
        return Icons.check_circle;
      case 'assignment_submission':
        return Icons.assignment_turned_in;
      case 'quiz_attempt':
        return Icons.quiz;
      case 'profile_update':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  Color _getCompletionColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getWorkloadColor(int pending) {
    if (pending >= 20) return Colors.red;
    if (pending >= 10) return Colors.orange;
    return Colors.green;
  }
}
