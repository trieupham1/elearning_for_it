import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/department.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/department_service.dart';
import '../../services/admin_service.dart';
import '../../services/course_service.dart';
import '../../widgets/admin_drawer.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final DepartmentService _departmentService = DepartmentService();
  User? _currentUser;
  List<Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() => _currentUser = user);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);

    try {
      // Load all departments (hard delete means only active ones exist)
      final departments = await _departmentService.getDepartments();
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading departments: $e')),
        );
      }
    }
  }

  Future<void> _showCreateDepartmentDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Department'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Department Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true &&
        nameController.text.isNotEmpty &&
        codeController.text.isNotEmpty) {
      try {
        await _departmentService.createDepartment(
          name: nameController.text,
          code: codeController.text,
          description: descriptionController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department created successfully')),
          );
          _loadDepartments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating department: $e')),
          );
        }
      }
    }

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditDepartmentDialog(Department department) async {
    final nameController = TextEditingController(text: department.name);
    final codeController = TextEditingController(text: department.code);
    final descriptionController = TextEditingController(
      text: department.description,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Department Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await _departmentService.updateDepartment(
          id: department.id,
          name: nameController.text,
          code: codeController.text,
          description: descriptionController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department updated successfully')),
          );
          _loadDepartments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating department: $e')),
          );
        }
      }
    }

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteDepartment(Department department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${department.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _departmentService.deleteDepartment(department.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Department deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await _loadDepartments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting department: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddEmployeeDialog(Department department) async {
    final AdminService adminService = AdminService();
    List<User> availableUsers = [];
    List<User> filteredUsers = [];
    String searchQuery = '';
    bool isLoading = true;
    User? selectedUser;

    // Show dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Employee to ${department.name}'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search users',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      searchQuery = value.toLowerCase();
                      filteredUsers = availableUsers.where((user) {
                        return user.fullName.toLowerCase().contains(
                              searchQuery,
                            ) ||
                            user.email.toLowerCase().contains(searchQuery) ||
                            user.username.toLowerCase().contains(searchQuery);
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // User list
                Expanded(
                  child: FutureBuilder(
                    future: isLoading
                        ? adminService.getUsers(limit: 100).then((result) {
                            setDialogState(() {
                              availableUsers = result['users'] as List<User>;
                              // Filter out users already in this department
                              filteredUsers = availableUsers.where((user) {
                                return !department.employeeIds.contains(
                                  user.id,
                                );
                              }).toList();
                              isLoading = false;
                            });
                            return filteredUsers;
                          })
                        : Future.value(filteredUsers),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final users = snapshot.data ?? [];

                      if (users.isEmpty) {
                        return const Center(
                          child: Text(
                            'No available users to add',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isSelected = selectedUser?.id == user.id;

                          // Create display name with fallback
                          final displayName = user.fullName.isNotEmpty
                              ? user.fullName
                              : user.email.split('@')[0];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Theme.of(context).primaryColor
                                  : _getAvatarColor(displayName),
                              backgroundImage:
                                  user.profilePicture != null &&
                                      user.profilePicture!.isNotEmpty
                                  ? NetworkImage(user.profilePicture!)
                                  : null,
                              child:
                                  user.profilePicture == null ||
                                      user.profilePicture!.isEmpty
                                  ? Text(
                                      displayName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(displayName),
                            subtitle: Text(user.email),
                            trailing: Chip(
                              label: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: _getRoleColor(
                                user.role,
                              ).withOpacity(0.2),
                            ),
                            selected: isSelected,
                            onTap: () {
                              setDialogState(() {
                                selectedUser = user;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUser == null
                  ? null
                  : () async {
                      Navigator.pop(context); // Close selection dialog

                      // Show loading
                      showDialog(
                        context: this.context,
                        barrierDismissible: false,
                        builder: (loadingContext) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await _departmentService.addEmployee(
                          department.id,
                          selectedUser!.id,
                        );

                        if (mounted) {
                          Navigator.of(this.context).pop(); // Close loading

                          final successName = selectedUser!.fullName.isNotEmpty
                              ? selectedUser!.fullName
                              : selectedUser!.email.split('@')[0];

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✓ $successName added to department',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _loadDepartments();
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(this.context).pop(); // Close loading
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding employee: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Add Employee'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCourseDialog(Department department) async {
    final CourseService courseService = CourseService();
    List<Course> availableCourses = [];
    List<Course> filteredCourses = [];
    String searchQuery = '';
    bool isLoading = true;
    Course? selectedCourse;

    // Show dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Course to ${department.name}'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search courses',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      searchQuery = value.toLowerCase();
                      filteredCourses = availableCourses.where((course) {
                        return course.name.toLowerCase().contains(
                              searchQuery,
                            ) ||
                            course.code.toLowerCase().contains(searchQuery);
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Course list
                Expanded(
                  child: FutureBuilder(
                    future: isLoading
                        ? courseService.getCourses().then((courses) {
                            availableCourses = courses;
                            // Filter out courses already in this department
                            filteredCourses = availableCourses.where((course) {
                              return !department.courseIds.contains(course.id);
                            }).toList();
                            isLoading = false;
                            return filteredCourses;
                          })
                        : Future.value(filteredCourses),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final courses = snapshot.data ?? [];

                      if (courses.isEmpty) {
                        return const Center(
                          child: Text(
                            'No available courses to add',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          final isSelected = selectedCourse?.id == course.id;

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.book,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.green,
                              ),
                            ),
                            title: Text(
                              course.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('Code: ${course.code}'),
                            selected: isSelected,
                            onTap: () {
                              setDialogState(() {
                                selectedCourse = course;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCourse == null
                  ? null
                  : () async {
                      Navigator.pop(context); // Close selection dialog

                      // Show loading
                      showDialog(
                        context: this.context,
                        barrierDismissible: false,
                        builder: (loadingContext) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await _departmentService.addCourse(
                          department.id,
                          selectedCourse!.id,
                        );

                        if (mounted) {
                          Navigator.of(this.context).pop(); // Close loading
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✓ ${selectedCourse!.name} added to department',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _loadDepartments();
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(this.context).pop(); // Close loading
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding course: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDepartmentDetails(Department department) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch detailed department data
      final detailed = await _departmentService.getDepartmentById(
        department.id,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (!mounted) return;

      // Show details dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 700,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detailed.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Code: ${detailed.code}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Employees Section
                        _buildDetailSection(
                          title: 'Employees (${detailed.employees.length})',
                          icon: Icons.people,
                          color: Colors.blue,
                          child: detailed.employees.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No employees in this department yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: detailed.employees.map((employee) {
                                    // Create display name with fallback
                                    final displayName =
                                        (employee.fullName != null &&
                                            employee.fullName!.isNotEmpty)
                                        ? employee.fullName!
                                        : employee.email.split('@')[0];

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getAvatarColor(
                                          displayName,
                                        ),
                                        backgroundImage:
                                            employee.profilePicture != null &&
                                                employee
                                                    .profilePicture!
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                employee.profilePicture!,
                                              )
                                            : null,
                                        child:
                                            employee.profilePicture == null ||
                                                employee.profilePicture!.isEmpty
                                            ? Text(
                                                displayName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(displayName),
                                      subtitle: Text(employee.email),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Chip(
                                            label: Text(
                                              employee.role.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            backgroundColor: _getRoleColor(
                                              employee.role,
                                            ).withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: _getRoleColor(
                                                employee.role,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Remove from department',
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Remove Employee',
                                                  ),
                                                  content: Text(
                                                    'Remove $displayName from ${detailed.name}?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            ctx,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            ctx,
                                                            true,
                                                          ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        'Remove',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                try {
                                                  await _departmentService
                                                      .removeEmployee(
                                                        detailed.id,
                                                        employee.id,
                                                      );

                                                  // Close dialog first
                                                  if (mounted &&
                                                      Navigator.canPop(
                                                        context,
                                                      )) {
                                                    Navigator.pop(context);
                                                  }

                                                  // Show success message and refresh
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Employee removed successfully',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                    _loadDepartments(); // Refresh
                                                  }
                                                } catch (e) {
                                                  // Close dialog first
                                                  if (mounted &&
                                                      Navigator.canPop(
                                                        context,
                                                      )) {
                                                    Navigator.pop(context);
                                                  }

                                                  // Show error message
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error: $e',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Courses Section
                        _buildDetailSection(
                          title: 'Courses (${detailed.courses.length})',
                          icon: Icons.book,
                          color: Colors.green,
                          child: detailed.courses.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No courses assigned to this department yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: detailed.courses.map((course) {
                                    final courseTitle =
                                        course.title ??
                                        course.code ??
                                        'Untitled Course';
                                    final courseCode = course.code ?? 'N/A';

                                    return ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.book,
                                          color: Colors.green,
                                        ),
                                      ),
                                      title: Text(
                                        courseTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text('Code: $courseCode'),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Remove from department',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Remove Course',
                                              ),
                                              content: Text(
                                                'Remove $courseTitle from ${detailed.name}?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await _departmentService
                                                  .removeCourse(
                                                    detailed.id,
                                                    course.id,
                                                  );

                                              // Close dialog first
                                              if (mounted &&
                                                  Navigator.canPop(context)) {
                                                Navigator.pop(context);
                                              }

                                              // Show success message and refresh
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Course removed successfully',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                _loadDepartments(); // Refresh
                                              }
                                            } catch (e) {
                                              // Close dialog first
                                              if (mounted &&
                                                  Navigator.canPop(context)) {
                                                Navigator.pop(context);
                                              }

                                              // Show error message
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error loading department details: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading department details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'instructor':
        return Colors.orange;
      case 'student':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Generate a color based on the user's name for avatar
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.cyan.shade400,
      Colors.amber.shade400,
      Colors.deepOrange.shade400,
    ];

    // Use the hash of the name to consistently pick a color
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Department',
            onPressed: _showCreateDepartmentDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
          ),
        ],
      ),
      drawer: _currentUser != null
          ? AdminDrawer(currentUser: _currentUser!)
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadDepartments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final department = _departments[index];
                  return _buildDepartmentCard(department);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No departments yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateDepartmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Department'),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.business, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          department.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Code: ${department.code}'),
            if (department.description != null &&
                department.description!.isNotEmpty)
              Text(
                department.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Employees', department.employeeIds.length),
                const SizedBox(height: 8),
                _buildStatRow('Courses', department.courseIds.length),
                const SizedBox(height: 16),

                // Show detailed employees and courses
                ElevatedButton.icon(
                  onPressed: () => _showDepartmentDetails(department),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Employees & Courses'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 12),

                // Add Employee and Add Course buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddEmployeeDialog(department),
                        icon: const Icon(Icons.person_add, color: Colors.blue),
                        label: const Text('Add Employee'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddCourseDialog(department),
                        icon: const Icon(Icons.add_box, color: Colors.green),
                        label: const Text('Add Course'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDepartmentDialog(department),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteDepartment(department),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
