import 'package:flutter/material.dart';
import '../../models/admin_dashboard.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_drawer.dart';

class InstructorWorkloadScreen extends StatefulWidget {
  const InstructorWorkloadScreen({super.key});

  @override
  State<InstructorWorkloadScreen> createState() =>
      _InstructorWorkloadScreenState();
}

class _InstructorWorkloadScreenState extends State<InstructorWorkloadScreen> {
  final AdminService _adminService = AdminService();
  User? _currentUser;
  List<InstructorWorkload> _workloads = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // name, courses, students

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() => _currentUser = user);

      final workloads = await _adminService.getInstructorWorkload();
      setState(() {
        _workloads = workloads;
        _sortWorkloads();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortWorkloads() {
    switch (_sortBy) {
      case 'name':
        _workloads.sort((a, b) =>
            a.instructor.fullName.compareTo(b.instructor.fullName));
        break;
      case 'courses':
        _workloads.sort((a, b) => b.totalCourses.compareTo(a.totalCourses));
        break;
      case 'students':
        _workloads.sort((a, b) => b.totalStudents.compareTo(a.totalStudents));
        break;
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.sort),
        onSelected: (value) {
          setState(() {
            _sortBy = value;
            _sortWorkloads();
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'name',
            child: Text('Sort by Name'),
          ),
          const PopupMenuItem(
            value: 'courses',
            child: Text('Sort by Course Count'),
          ),
          const PopupMenuItem(
            value: 'students',
            child: Text('Sort by Student Count'),
          ),
        ],
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadData,
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
        title: const Text('Instructor Workload'),
        actions: _buildAppBarActions(context),
      ),
      drawer: _currentUser != null ? AdminDrawer(currentUser: _currentUser!) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _workloads.isEmpty
                  ? const Center(child: Text('No instructor data available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _workloads.length,
                      itemBuilder: (context, index) {
                        final workload = _workloads[index];
                        return _buildWorkloadCard(workload);
                      },
                    ),
            ),
    );
  }

  Widget _buildWorkloadCard(InstructorWorkload workload) {
    final workloadColor = _getWorkloadColor(workload.totalCourses);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/instructor-workload-detail',
            arguments: workload,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: workload.instructor.profilePicture != null
                    ? NetworkImage(workload.instructor.profilePicture!)
                    : null,
                child: workload.instructor.profilePicture == null
                    ? Text(
                        workload.instructor.fullName.isNotEmpty
                            ? workload.instructor.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
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
                      workload.instructor.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (workload.instructor.department != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.business,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            workload.instructor.department!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatBadge(
                          Icons.school,
                          workload.totalCourses.toString(),
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBadge(
                          Icons.people,
                          workload.totalStudents.toString(),
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: workloadColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: workloadColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          workload.courses.length.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: workloadColor,
                          ),
                        ),
                        Text(
                          'Courses',
                          style: TextStyle(
                            fontSize: 10,
                            color: workloadColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWorkloadColor(int courses) {
    if (courses >= 5) return Colors.red;
    if (courses >= 3) return Colors.orange;
    return Colors.green;
  }
}
