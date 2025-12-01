import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final _notificationService = NotificationService();
  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  int _unreadNotificationCount = 0;

  // Filters
  String _searchQuery = '';
  String? _selectedRole;
  String? _selectedDepartment;
  bool? _isActiveFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() => _currentUser = user);
      
      // Load notification count
      try {
        final count = await _notificationService.getUnreadCount();
        setState(() => _unreadNotificationCount = count);
      } catch (e) {
        print('Error loading notification count: $e');
      }
    } catch (e) {
      // Handle error silently
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Messages feature coming soon')),
          );
        },
      ),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
        tooltip: 'Profile',
        offset: const Offset(0, 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final result = await _adminService.getUsers(
        page: _currentPage,
        limit: 10,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole,
        department: _selectedDepartment,
        isActive: _isActiveFilter,
      );

      final pagination = result['pagination'] as Map<String, dynamic>?;

      setState(() {
        _users = result['users'] as List<User>? ?? [];
        _currentPage = (pagination?['currentPage'] as int?) ?? 1;
        _totalPages = (pagination?['totalPages'] as int?) ?? 1;
        _totalUsers = (pagination?['totalItems'] as int?) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController();
    String selectedRole = user.role;
    bool isActive = user.isActive;
    bool changePassword = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit User: ${user.fullName}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'instructor',
                        child: Text('Instructor'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Account Status
                  SwitchListTile(
                    title: const Text('Account Active'),
                    subtitle: Text(
                      isActive
                          ? 'User can access the system'
                          : 'User is suspended',
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() => isActive = value);
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                  const Divider(),

                  // Password Change Section
                  CheckboxListTile(
                    title: const Text('Reset Password'),
                    subtitle: const Text('Check to reset user password'),
                    value: changePassword,
                    onChanged: (value) {
                      setDialogState(() {
                        changePassword = value ?? false;
                        if (!changePassword) {
                          passwordController.clear();
                        }
                      });
                    },
                  ),

                  if (changePassword) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        hintText: 'Enter new password',
                      ),
                      obscureText: true,
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    '* Required fields',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Delete button (left side)
            TextButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete User'),
                    content: Text(
                      'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _adminService.deleteUser(user.id);

                    // Close the edit dialog first
                    if (mounted) {
                      Navigator.pop(context);
                    }

                    // Show success message and refresh
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadUsers(); // Refresh list
                    }
                  } catch (e) {
                    // Close the edit dialog first
                    if (mounted) {
                      Navigator.pop(context);
                    }

                    // Show error message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting user: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            const Spacer(), // Push other buttons to the right
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (fullNameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                if (changePassword && passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a new password'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  // Update user profile (name, email, username, role, status)
                  await _adminService.updateUser(
                    userId: user.id,
                    fullName: fullNameController.text.trim(),
                    email: emailController.text.trim(),
                    username: usernameController.text.trim(),
                    role: selectedRole,
                    isActive: isActive,
                  );

                  // Reset password if requested
                  if (changePassword && passwordController.text.isNotEmpty) {
                    await _adminService.resetUserPassword(
                      user.id,
                      passwordController.text,
                    );
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUsers();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating user: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    fullNameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Bulk Import',
            onPressed: () =>
                Navigator.of(context).pushNamed('/admin/users/bulk-import'),
          ),
          ..._buildAppBarActions(context),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      drawer: _currentUser != null
          ? AdminDrawer(currentUser: _currentUser!)
          : null,
      body: Column(
        children: [
          _buildFilters(),
          _buildUserStats(),
          Expanded(child: _buildUserList()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search (name, email, username)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text;
                      _currentPage = 1;
                    });
                    _loadUsers();
                  },
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
                _loadUsers();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'instructor',
                        child: Text('Instructor'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        _currentPage = 1;
                      });
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: _isActiveFilter,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: true, child: Text('Active')),
                      DropdownMenuItem(value: false, child: Text('Suspended')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isActiveFilter = value;
                        _currentPage = 1;
                      });
                      _loadUsers();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Total: $_totalUsers users',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: user.profilePicture != null
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? Text(user.fullName.isNotEmpty ? user.fullName[0] : 'U')
                    : null,
              ),
              title: Text(user.fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  const SizedBox(height: 4),
                  _buildRoleBadge(user.role),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditUserDialog(user),
                tooltip: 'Edit User',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;
    switch (role) {
      case 'admin':
        color = Colors.red;
        label = 'Admin';
        break;
      case 'instructor':
        color = Colors.green;
        label = 'Instructor';
        break;
      default:
        color = Colors.blue;
        label = 'Student';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadUsers();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            'Page $_currentPage / $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadUsers();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(iconAlignment: IconAlignment.end),
          ),
        ],
      ),
    );
  }
}
