import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/import_models.dart';
import '../services/student_service.dart';
import '../widgets/csv_import_dialog.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _studentService = StudentService();
  List<User> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _studentService.getStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  void _showCreateStudentDialog() {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final studentIdController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Student Account'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email*',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password (optional)',
                    hintText: 'Default: student123',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
                  firstNameController.text.trim().isEmpty ||
                  lastNameController.text.trim().isEmpty ||
                  studentIdController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _studentService.createStudent(
                  username: usernameController.text.trim(),
                  email: emailController.text.trim(),
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  studentId: studentIdController.text.trim(),
                  password: passwordController.text.trim().isEmpty
                      ? null
                      : passwordController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStudents(); // Reload list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(User student) {
    final emailController = TextEditingController(text: student.email);
    final phoneController = TextEditingController(
      text: student.phoneNumber ?? '',
    );
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password (optional)',
                  hintText: 'Leave empty to keep current',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _studentService.updateStudent(
                  id: student.id,
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  password: passwordController.text.trim().isEmpty
                      ? null
                      : passwordController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStudents(); // Reload list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(User student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete ${student.fullName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _studentService.deleteStudent(student.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStudents(); // Reload list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sendCourseInvitation(User student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Course Invitation'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send course invitation to ${student.fullName}'),
              const SizedBox(height: 16),
              const Text(
                'Select courses to invite the student to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // TODO: Add course selection list
              const ListTile(
                leading: Icon(Icons.school, color: Colors.blue),
                title: Text('Course selection coming soon'),
                subtitle: Text('Students will receive invitation notification'),
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement send invitation API call
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invitation sent to ${student.fullName}. They will receive a notification to accept or decline.',
                  ),
                ),
              );
            },
            child: const Text('Send Invitation'),
          ),
        ],
      ),
    );
  }

  void _showImportCsvDialog() {
    showDialog(
      context: context,
      builder: (context) => CsvImportDialog<StudentCsvData>(
        title: 'Import Students from CSV',
        entityName: 'Student',
        csvHeaders: const [
          'Username',
          'Email',
          'FirstName',
          'LastName',
          'StudentId',
          'Password',
          'Department',
          'PhoneNumber',
          'Year',
        ],
        csvTemplate:
            '''Username,Email,FirstName,LastName,StudentId,Password,Department,PhoneNumber,Year
john_doe,john.doe@fit.edu.vn,John,Doe,STU001,student123,Information Technology,0123456789,1
jane_smith,jane.smith@fit.edu.vn,Jane,Smith,STU002,student123,Information Technology,0987654321,2
bob_wilson,bob.wilson@fit.edu.vn,Bob,Wilson,STU003,student123,Information Technology,0111222333,1''',
        parseRow: (row) => StudentCsvData.fromCsvRow(row),
        validateData: (students) async {
          return await _studentService.previewImport(students);
        },
        importData: (items) async {
          return await _studentService.confirmImport(items);
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadStudents(); // Reload list after successful import
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No students yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Create your first student account'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              backgroundImage: student.profilePicture != null
                                  ? NetworkImage(student.profilePicture!)
                                  : null,
                              child: student.profilePicture == null
                                  ? Text(
                                      student.username
                                          .substring(0, 2)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${student.email}\nStudent ID: ${student.studentId ?? 'N/A'}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showEditStudentDialog(student);
                                    break;
                                  case 'invite':
                                    _sendCourseInvitation(student);
                                    break;
                                  case 'delete':
                                    _deleteStudent(student);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'invite',
                                  child: Row(
                                    children: [
                                      Icon(Icons.send, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Send Course Invitation'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'import_csv',
            onPressed: _showImportCsvDialog,
            child: const Icon(Icons.upload_file),
            tooltip: 'Import from CSV',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_student',
            onPressed: _showCreateStudentDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Student'),
          ),
        ],
      ),
    );
  }
}
