import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user.dart';
import '../../models/department.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/department_service.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin_drawer.dart';
import '../../utils/web_download.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final DepartmentService _departmentService = DepartmentService();
  final AdminService _adminService = AdminService();
  final _notificationService = NotificationService();

  User? _currentUser;
  List<Department> _departments = [];
  List<User> _users = [];
  bool _isLoading = false;
  int _unreadNotificationCount = 0;

  String _reportType = 'department';
  String _format = 'excel';
  String? _selectedDepartmentId;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDepartments();
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
          Navigator.pushNamed(context, '/messages');
        },
      ),
      const SizedBox(width: 8),
      // Profile icon with dropdown
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

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getDepartments();
      setState(() => _departments = departments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading departments: $e')),
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getUsers(limit: 1000);
      setState(() {
        _users = result['users'] as List<User>;
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

  Future<void> _generateReport() async {
    if (_reportType == 'department' && _selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    if (_reportType == 'individual' && _selectedUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a user')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_reportType == 'department') {
        await _reportService.generateDepartmentReport(
          departmentId: _selectedDepartmentId!,
          format: _format,
          onSuccess: _saveFile,
        );
      } else if (_reportType == 'individual') {
        await _reportService.generateIndividualReport(
          userId: _selectedUserId!,
          format: _format,
          onSuccess: _saveFile,
        );
      } else {
        await _reportService.exportAllUsers(onSuccess: _saveFile);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  Future<void> _saveFile(List<int> bytes, String filename) async {
    try {
      if (kIsWeb) {
        // Web platform: trigger browser download
        downloadFileWeb(bytes, filename);
        
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report downloaded: $filename'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Mobile platform will never reach here when compiled for web
        throw UnsupportedError('File system not supported on web');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Data Export'),
        actions: _buildAppBarActions(context),
      ),
      drawer: _currentUser != null
          ? AdminDrawer(currentUser: _currentUser!)
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReportTypeSection(),
            const SizedBox(height: 24),
            _buildFormatSection(),
            const SizedBox(height: 24),
            if (_reportType == 'department') _buildDepartmentSelector(),
            if (_reportType == 'individual') _buildUserSelector(),
            if (_reportType != 'all_users') const SizedBox(height: 24),
            _buildGenerateButton(),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              _buildLoadingIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Department Report'),
              subtitle: const Text('Training progress by department'),
              value: 'department',
              groupValue: _reportType,
              onChanged: (value) {
                setState(() {
                  _reportType = value!;
                  _selectedUserId = null;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Individual Report'),
              subtitle: const Text('Learning progress of a user'),
              value: 'individual',
              groupValue: _reportType,
              onChanged: (value) {
                setState(() {
                  _reportType = value!;
                  _selectedDepartmentId = null;
                });
                if (_users.isEmpty) {
                  _loadUsers();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Export All Users'),
              subtitle: const Text('Complete user list (Excel)'),
              value: 'all_users',
              groupValue: _reportType,
              onChanged: (value) {
                setState(() {
                  _reportType = value!;
                  _selectedDepartmentId = null;
                  _selectedUserId = null;
                  _format = 'excel'; // All users export is always Excel
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSection() {
    if (_reportType == 'all_users') {
      return const SizedBox.shrink(); // All users export is always Excel
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Excel'),
                    subtitle: const Text('.xlsx'),
                    value: 'excel',
                    groupValue: _format,
                    onChanged: (value) {
                      setState(() => _format = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('PDF'),
                    subtitle: const Text('.pdf'),
                    value: 'pdf',
                    groupValue: _format,
                    onChanged: (value) {
                      setState(() => _format = value!);
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

  Widget _buildDepartmentSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Department',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              value: _selectedDepartmentId,
              items: _departments.map((dept) {
                return DropdownMenuItem(
                  value: dept.id,
                  child: Text('${dept.name} (${dept.code})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDepartmentId = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_users.isEmpty && !_isLoading)
              const Text(
                'Loading user list...',
                style: TextStyle(color: Colors.grey),
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'User',
                  border: OutlineInputBorder(),
                ),
                value: _selectedUserId,
                items: _users.map((user) {
                  return DropdownMenuItem(
                    value: user.id,
                    child: Text('${user.fullName} (${user.email})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    String buttonText = 'Generate Report';
    if (_reportType == 'all_users') {
      buttonText = 'Export Data';
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _generateReport,
      icon: const Icon(Icons.download),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Generating report...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Please wait a moment', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
