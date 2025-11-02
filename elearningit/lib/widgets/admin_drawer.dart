import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  final User currentUser;

  const AdminDrawer({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            subtitle: 'Overview',
            route: '/admin/dashboard',
          ),
          const Divider(),
          _buildSectionHeader('User Management'),
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'User List',
            subtitle: 'Users',
            route: '/admin/users',
          ),
          _buildMenuItem(
            context,
            icon: Icons.upload_file,
            title: 'Bulk Import',
            subtitle: 'CSV/Excel Import',
            route: '/admin/users/bulk-import',
          ),
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: 'Activity Logs',
            subtitle: 'User Activity',
            route: '/admin/activity-logs',
          ),
          const Divider(),
          _buildSectionHeader('Department Management'),
          _buildMenuItem(
            context,
            icon: Icons.business,
            title: 'Departments',
            subtitle: 'Department List',
            route: '/admin/departments',
          ),
          _buildMenuItem(
            context,
            icon: Icons.trending_up,
            title: 'Training Progress',
            subtitle: 'By Department',
            route: '/admin/training-progress',
          ),
          const Divider(),
          _buildSectionHeader('Academic Management'),
          _buildMenuItem(
            context,
            icon: Icons.calendar_today,
            title: 'Semesters',
            subtitle: 'Academic Terms',
            route: '/admin/semesters',
          ),
          _buildMenuItem(
            context,
            icon: Icons.school,
            title: 'Courses',
            subtitle: 'Course Management',
            route: '/admin/courses',
          ),
          const Divider(),
          _buildSectionHeader('Instructors'),
          _buildMenuItem(
            context,
            icon: Icons.school,
            title: 'Instructor Workload',
            subtitle: 'Course Assignments',
            route: '/admin/instructors/workload',
          ),
          const Divider(),
          _buildSectionHeader('Reports'),
          _buildMenuItem(
            context,
            icon: Icons.assessment,
            title: 'Generate Reports',
            subtitle: 'Create Reports',
            route: '/admin/reports',
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign Out',
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: currentUser.profilePicture != null
            ? NetworkImage(currentUser.profilePicture!)
            : null,
        child: currentUser.profilePicture == null
            ? Text(
                currentUser.fullName.isNotEmpty
                    ? currentUser.fullName[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : null,
      ),
      accountName: Text(
        currentUser.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      accountEmail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentUser.email),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? route,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap:
          onTap ??
          () {
            if (route != null) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          },
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = AuthService();
      await authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
