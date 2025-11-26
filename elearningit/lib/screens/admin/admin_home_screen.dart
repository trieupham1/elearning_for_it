import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/message_service.dart';
import '../../widgets/admin_drawer.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  User? _currentUser;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  final NotificationService _notificationService = NotificationService();
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadNotificationCount();
    _loadMessageCount();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user information: $e')),
        );
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    } catch (e) {
      // Silently fail - notification count is not critical
    }
  }

  Future<void> _loadMessageCount() async {
    try {
      final count = await _messageService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadMessages = count;
        });
      }
    } catch (e) {
      // Silently fail - message count is not critical
    }
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Unable to load user information'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        elevation: 0,
        actions: [
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadNotifications',
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
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            tooltip: 'Notifications',
          ),
          // Messages
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.message_outlined),
                if (_unreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadMessages',
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
            onPressed: () {
              Navigator.pushNamed(context, '/messages');
            },
            tooltip: 'Messages',
          ),
          // Profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _currentUser!.fullName.isNotEmpty
                      ? _currentUser!.fullName[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              tooltip: 'Profile',
              onSelected: (value) {
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
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: const [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 12),
                      Text('My Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: const [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: AdminDrawer(currentUser: _currentUser!),
      body: RefreshIndicator(
        onRefresh: _loadCurrentUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildManagementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${_currentUser!.fullName}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to the E-Learning Administration Portal',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4, // 4 columns for better layout
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2, // Make boxes more rectangular and compact
            children: [
              _buildActionCard(
                icon: Icons.dashboard,
                title: 'Dashboard',
                subtitle: 'Overview',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/admin/dashboard'),
              ),
              _buildActionCard(
                icon: Icons.people,
                title: 'Users',
                subtitle: 'User Management',
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, '/admin/users'),
              ),
              _buildActionCard(
                icon: Icons.school,
                title: 'Courses',
                subtitle: 'Course Management',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/admin/courses'),
              ),
              _buildActionCard(
                icon: Icons.business,
                title: 'Departments',
                subtitle: 'Department List',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/admin/departments'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12), // Smaller icon container
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28, // Smaller icon size
                  color: color,
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11, // Smaller subtitle
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildManagementCard(
          icon: Icons.upload_file,
          title: 'Bulk User Import',
          subtitle: 'Import users from Excel/CSV',
          onTap: () =>
              Navigator.of(context).pushNamed('/admin/users/bulk-import'),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Icons.school,
          title: 'Instructor Workload',
          subtitle: 'View instructor statistics',
          onTap: () =>
              Navigator.of(context).pushNamed('/admin/instructors/workload'),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Icons.trending_up,
          title: 'Training Progress by Department',
          subtitle: 'Track progress by department',
          onTap: () =>
              Navigator.of(context).pushNamed('/admin/training-progress'),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Icons.history,
          title: 'Activity History',
          subtitle: 'View system logs',
          onTap: () => Navigator.of(context).pushNamed('/admin/activity-logs'),
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
