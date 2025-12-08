import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user.dart';
import '../../models/admin_dashboard.dart';
import '../../models/activity_log.dart';
import '../../services/auth_service.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final AdminService _adminService = AdminService();
  final NotificationService _notificationService = NotificationService();
  User? _currentUser;
  AdminDashboardOverview? _overview;
  List<ActivityLog> _recentActivity = [];
  List<DepartmentProgress> _departmentProgress = [];
  List<InstructorWorkload> _instructorWorkload = [];
  bool _isLoading = true;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

      // Load notification count
      try {
        final count = await _notificationService.getUnreadCount();
        setState(() => _unreadNotificationCount = count);
      } catch (e) {
        debugPrint('Error loading notification count: $e');
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
      // Refresh button with animation
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadDashboardData,
                tooltip: 'Refresh',
              ),
            ),
          );
        },
      ),
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.pushNamed(context, '/notifications');
              try {
                final count = await _notificationService.getUnreadCount();
                setState(() => _unreadNotificationCount = count);
              } catch (e) {
                debugPrint('Error reloading notification count: $e');
              }
            },
          ),
          if (_unreadNotificationCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
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
      const SizedBox(width: 8),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: PopupMenuButton<String>(
              tooltip: 'Profile',
              offset: const Offset(0, 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _currentUser?.fullName.isNotEmpty == true
                          ? _currentUser!.fullName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    Navigator.pushNamed(context, '/profile');
                    break;
                  case 'settings':
                    Navigator.pushNamed(context, '/settings');
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
          );
        },
      ),
      const SizedBox(width: 8),
    ];
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, scaleValue, child) {
        return Transform.scale(
          scale: scaleValue,
          child: SizedBox(
            width: (MediaQuery.of(context).size.width - 48) / 2,
            child: Card(
              elevation: 4,
              shadowColor: color.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 28),
                          ),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, animatedValue, child) {
                              return Text(
                                animatedValue.toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitySection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
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
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: ListTile(
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getActionColor(activity.action).withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: _getActionColor(activity.action),
                                          child: Icon(
                                            _getActionIcon(activity.action),
                                            color: Colors.white,
                                            size: 20,
                                          ),
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
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepartmentTrainingProgress() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.green, Colors.lightGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Department Training Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 500 + (index * 100)),
                              curve: Curves.easeOut,
                              builder: (context, animValue, child) {
                                return Transform.scale(
                                  scale: 0.8 + (animValue * 0.2),
                                  child: Opacity(
                                    opacity: animValue,
                                    child: _buildDepartmentCard(dept),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepartmentCard(DepartmentProgress dept) {
    final avgScore = dept.overallCompletionRate;
    final progressColor = _getCompletionColor(avgScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: progressColor.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: progressColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dept.departmentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: avgScore),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Text(
                    '${value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: avgScore / 100),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                ),
              );
            },
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.orange, Colors.deepOrange],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Instructor Workload',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                            
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 500 + (index * 100)),
                              curve: Curves.easeOut,
                              builder: (context, animValue, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - animValue), 0),
                                  child: Opacity(
                                    opacity: animValue,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/instructor-workload-detail',
                                          arguments: workload,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                          horizontal: 12.0,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              workloadColor.withOpacity(0.05),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: workloadColor.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor: workloadColor.withOpacity(0.2),
                                                child: Text(
                                                  workload.instructor.fullName.isNotEmpty
                                                      ? workload.instructor.fullName[0].toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    color: workloadColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
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
                                                  Row(
                                                    children: [
                                                      Icon(Icons.school, size: 12, color: Colors.grey.shade600),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${workload.totalCourses} courses',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Icon(Icons.people, size: 12, color: Colors.grey.shade600),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${workload.totalStudents} students',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (workload.instructor.department != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Text(
                                                        workload.instructor.department!,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade500,
                                                        ),
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
                                                gradient: LinearGradient(
                                                  colors: [
                                                    workloadColor.withOpacity(0.2),
                                                    workloadColor.withOpacity(0.1),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: workloadColor, width: 2),
                                              ),
                                              child: TweenAnimationBuilder<int>(
                                                tween: IntTween(begin: 0, end: workload.courses.length),
                                                duration: const Duration(milliseconds: 1000),
                                                builder: (context, animValue, child) {
                                                  return Text(
                                                    '$animValue',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: workloadColor,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.chevron_right, color: workloadColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
