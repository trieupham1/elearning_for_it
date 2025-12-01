import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin_drawer.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({Key? key}) : super(key: key);

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final AdminService _adminService = AdminService();
  final _notificationService = NotificationService();
  User? _currentUser;
  PlatformFile? _platformFile; // Use PlatformFile for all platforms
  bool _isUploading = false;
  Map<String, dynamic>? _importResult;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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
      IconButton(
        icon: const Icon(Icons.person_add),
        tooltip: 'Add User Manually',
        onPressed: _showAddUserDialog,
      ),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true, // Important for web - loads file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        setState(() {
          _platformFile = pickedFile; // Store the PlatformFile
          _importResult = null; // Reset previous results
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${pickedFile.name}" selected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_platformFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() {
      _isUploading = true;
      _importResult = null;
    });

    try {
      Map<String, dynamic> result;

      // Use bytes for all platforms (works on web, mobile, desktop)
      if (_platformFile!.bytes != null) {
        // Use bytes method (works on all platforms)
        result = await _adminService.bulkImportUsersFromBytes(
          _platformFile!.bytes!,
          _platformFile!.name,
        );
      } else {
        throw Exception(
          'No file data available - please try selecting the file again',
        );
      }

      setState(() {
        _importResult = result;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${result['successful']} users',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import error: $e')));
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final departmentController = TextEditingController(
      text: 'Information Technology',
    );
    final studentIdController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'student';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                      hintText: 'e.g., johnsmith',
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
                      hintText: 'e.g., john@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Minimum 6 characters',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // First Name
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Last Name
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
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

                  // Department
                  TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student ID (optional)
                  TextField(
                    controller: studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                      hintText: 'For students only',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (usernameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await _adminService.createUser(
                    username: usernameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    firstName: firstNameController.text.trim().isNotEmpty
                        ? firstNameController.text.trim()
                        : null,
                    lastName: lastNameController.text.trim().isNotEmpty
                        ? lastNameController.text.trim()
                        : null,
                    role: selectedRole,
                    department: departmentController.text.trim().isNotEmpty
                        ? departmentController.text.trim()
                        : null,
                    studentId: studentIdController.text.trim().isNotEmpty
                        ? studentIdController.text.trim()
                        : null,
                    phoneNumber: phoneController.text.trim().isNotEmpty
                        ? phoneController.text.trim()
                        : null,
                  );

                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating user: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    departmentController.dispose();
    studentIdController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Import'),
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
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildInstructions(),
            const SizedBox(height: 24),
            _buildSampleTemplate(),
            const SizedBox(height: 24),
            _buildFileSelector(),
            const SizedBox(height: 24),
            if (_platformFile != null) _buildSelectedFile(),
            if (_platformFile != null) const SizedBox(height: 24),
            _buildUploadButton(),
            if (_isUploading) ...[
              const SizedBox(height: 24),
              _buildUploadingIndicator(),
            ],
            if (_importResult != null) ...[
              const SizedBox(height: 24),
              _buildImportResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Single User'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Bulk Import (CSV/Excel)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Download the sample template below\n'
              '2. Fill in user information in the Excel/CSV file\n'
              '3. Select the completed file\n'
              '4. Click "Start Import"\n'
              '5. View import results',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'File Format:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Col 1: username (required)\n'
              '• Col 2: email (required)\n'
              '• Col 3: password (required)\n'
              '• Col 4: firstName\n'
              '• Col 5: lastName\n'
              '• Col 6: role (student/instructor/admin)\n'
              '• Col 7: department\n'
              '• Col 8: studentId',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleTemplate() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Template',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Download sample template to reference format:'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _downloadSampleTemplate,
              icon: const Icon(Icons.download),
              label: const Text('Download Excel Template'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Import File',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Excel/CSV File'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFile() {
    if (_platformFile == null) return const SizedBox.shrink();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File đã chọn:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _platformFile!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _platformFile!.size > 0
                        ? '${(_platformFile!.size / 1024).toStringAsFixed(2)} KB'
                        : 'Size unknown',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isUploading
                  ? null
                  : () {
                      setState(() {
                        _platformFile = null;
                      });
                    },
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _isUploading || _platformFile == null ? null : _uploadFile,
      icon: const Icon(Icons.cloud_upload),
      label: Text(_isUploading ? 'Importing...' : 'Start Import'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang xử lý file...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng chờ trong giây lát',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportResults() {
    final total = _importResult!['total'] as int;
    final successful = _importResult!['successful'] as int;
    final failed = _importResult!['failed'] as int;
    final errors = _importResult!['errors'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  failed > 0 ? Icons.warning : Icons.check_circle,
                  color: failed > 0 ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Import Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultStat('Total', total, Colors.blue),
            const SizedBox(height: 8),
            _buildResultStat('Successful', successful, Colors.green),
            const SizedBox(height: 8),
            _buildResultStat('Failed', failed, Colors.red),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Error Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: errors.length,
                itemBuilder: (context, index) {
                  final error = errors[index] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${error['username']}: ${error['message']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _downloadSampleTemplate() {
    // Show info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Sample Template'),
        content: const Text(
          'To create a sample template, please create an Excel file with these columns:\n\n'
          'username | email | password | firstName | lastName | role | department | studentId\n\n'
          'Example:\n'
          'john123 | john@test.com | pass123 | John | Doe | student | IT | ST001',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
