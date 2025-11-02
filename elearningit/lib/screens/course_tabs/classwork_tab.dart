import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../services/classwork_service.dart';
import '../../services/assignment_service.dart';
import '../../services/attendance_service.dart';
import '../../services/code_assignment_service.dart';
import '../instructor/create_assignment_screen.dart';
import '../student/assignment_detail_screen.dart';
import '../instructor/assignment_tracking_screen.dart';
import '../student/quiz_detail_screen.dart';
import '../instructor/quiz_management_screen.dart';
import '../instructor/create_material_screen.dart';
import '../instructor/material_detail_screen.dart';
import '../instructor/material_management_screen.dart';
import '../instructor/attendance_records_screen.dart';
import '../student/attendance_detail_screen.dart';
import '../instructor/video_analytics_screen.dart';
import '../instructor/code_assignment_submissions_screen.dart';
import '../../services/material_service.dart';

enum ClassworkType {
  all,
  assignments,
  quizzes,
  materials,
  videos,
  attendance,
  codeAssignments,
}

class ClassworkTab extends StatefulWidget {
  final Course course;
  final User? currentUser;

  const ClassworkTab({super.key, required this.course, this.currentUser});

  @override
  State<ClassworkTab> createState() => _ClassworkTabState();
}

class _ClassworkTabState extends State<ClassworkTab> {
  final ClassworkService _classworkService = ClassworkService();
  ClassworkType _filter = ClassworkType.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<ClassworkItem> _items = [];
  bool _isLoading = false;

  bool get _isInstructor =>
      widget.currentUser?.role == 'instructor' ||
      widget.currentUser?.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadClasswork();
  }

  Future<void> _loadClasswork() async {
    setState(() => _isLoading = true);
    try {
      String? filterType;
      switch (_filter) {
        case ClassworkType.assignments:
          filterType = 'assignments';
          break;
        case ClassworkType.quizzes:
          filterType = 'quizzes';
          break;
        case ClassworkType.materials:
          filterType = 'materials';
          break;
        case ClassworkType.videos:
          filterType = 'videos';
          break;
        case ClassworkType.attendance:
          filterType = 'attendance';
          break;
        case ClassworkType.codeAssignments:
          filterType = 'code_assignments';
          break;
        default:
          filterType = null;
      }

      final items = await _classworkService.getClasswork(
        courseId: widget.course.id,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filter: filterType,
      );

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading classwork: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClassworkItem> get _filteredItems {
    // Filtering is now done on the backend
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search classwork...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _loadClasswork();
                  },
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', ClassworkType.all),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Assignments',
                        ClassworkType.assignments,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quizzes', ClassworkType.quizzes),
                      const SizedBox(width: 8),
                      _buildFilterChip('Materials', ClassworkType.materials),
                      const SizedBox(width: 8),
                      _buildFilterChip('Videos', ClassworkType.videos),
                      const SizedBox(width: 8),
                      _buildFilterChip('Attendance', ClassworkType.attendance),
                      const SizedBox(width: 8),
                      _buildFilterChip('Code', ClassworkType.codeAssignments),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Classwork List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No classwork yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _ClassworkCard(
                        item: item,
                        course: widget.course,
                        currentUser: widget.currentUser,
                        onRefresh: _loadClasswork,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isInstructor
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateMenu(context),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.orange),
              title: const Text('Create Assignment'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateAssignmentScreen(courseId: widget.course.id),
                  ),
                );
                if (result == true) {
                  _loadClasswork();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.red),
              title: const Text('Create Quiz'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(
                  context,
                  '/create-quiz',
                  arguments: {'courseId': widget.course.id},
                );

                if (result != null) {
                  // Quiz was created, refresh the classwork list
                  _loadClasswork();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quiz created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.purple),
              title: const Text('Create Question'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(
                  context,
                  '/create-question',
                  arguments: {
                    'courseId': widget.course.id,
                    'courseName': widget.course.name,
                  },
                );
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('Upload Material'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateMaterialScreen(course: widget.course),
                  ),
                );
                if (result == true) {
                  _loadClasswork();
                }
              },
            ),

            const Divider(),

            // NEW: Upload Video
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.teal),
              title: const Text('Upload Video'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(
                  context,
                  '/upload-video',
                  arguments: {'courseId': widget.course.id},
                );
                if (result == true && mounted) {
                  _loadClasswork();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video uploaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

            // NEW: Create Attendance Session
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
              title: const Text('Create Attendance Session'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(
                  context,
                  '/create-attendance-session',
                  arguments: {
                    'courseId': widget.course.id,
                    'courseName': widget.course.name,
                  },
                );
                if (result == true) {
                  _loadClasswork();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance session created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

            // NEW: Create Code Assignment
            ListTile(
              leading: const Icon(Icons.code, color: Colors.indigo),
              title: const Text('Create Code Assignment'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(
                  context,
                  '/create-code-assignment',
                  arguments: {'courseId': widget.course.id},
                );
                if (result == true) {
                  _loadClasswork();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code assignment created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ClassworkType type) {
    final isSelected = _filter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = type;
        });
        _loadClasswork();
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _ClassworkCard extends StatelessWidget {
  final ClassworkItem item;
  final Course course;
  final User? currentUser;
  final VoidCallback onRefresh;

  _ClassworkCard({
    required this.item,
    required this.course,
    required this.currentUser,
    required this.onRefresh,
  });

  bool get _isInstructor =>
      currentUser?.role == 'instructor' || currentUser?.role == 'admin';

  // Create service instance for fetching assignment data
  final AssignmentService _assignmentService = AssignmentService();
  final MaterialService _materialService = MaterialService();
  final CodeAssignmentService _codeAssignmentService = CodeAssignmentService();

  IconData get _icon {
    switch (item.type) {
      case 'assignment':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'material':
        return Icons.folder;
      case 'video':
        return Icons.play_circle;
      case 'attendance':
        return Icons.qr_code_scanner;
      case 'code_assignment':
        return Icons.code;
      default:
        return Icons.article;
    }
  }

  Color get _color {
    switch (item.type) {
      case 'assignment':
        return Colors.orange;
      case 'quiz':
        return Colors.red;
      case 'material':
        return Colors.blue;
      case 'video':
        return Colors.teal;
      case 'attendance':
        return Colors.green;
      case 'code_assignment':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String get _typeLabel {
    switch (item.type) {
      case 'assignment':
        return 'Assignment';
      case 'quiz':
        return 'Quiz';
      case 'material':
        return 'Material';
      case 'video':
        return 'Video';
      case 'attendance':
        return 'Attendance';
      case 'code_assignment':
        return 'Code Assignment';
      default:
        return 'Item';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleCardTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                backgroundColor: _color.withOpacity(0.1),
                child: Icon(_icon, color: _color),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type label
                    Text(
                      _typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: _color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Metadata
                    Wrap(
                      spacing: 16,
                      children: [
                        if (item.dueDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Due ${_formatDate(item.dueDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing: Completion status for students or action buttons for instructors
              if (!_isInstructor &&
                  item.type == 'quiz' &&
                  item.isCompleted == true)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                )
              else if (!_isInstructor &&
                  item.type == 'attendance' &&
                  item.isCompleted == true)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                )
              else if (!_isInstructor &&
                  item.type == 'attendance' &&
                  item.dueDate != null &&
                  DateTime.now().isAfter(item.dueDate!))
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                )
              else if (_isInstructor && item.type == 'assignment')
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  onPressed: () => _navigateToTracking(context),
                  tooltip: 'View Submissions',
                )
              else if (_isInstructor && item.type == 'video')
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () => _navigateToVideoAnalytics(context),
                  tooltip: 'View Watch Analytics',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCardTap(BuildContext context) async {
    if (item.type == 'assignment') {
      if (_isInstructor) {
        // Instructor: Fetch assignment and navigate to edit mode
        try {
          final assignment = await _assignmentService.getAssignment(item.id);
          if (!context.mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAssignmentScreen(
                courseId: course.id,
                assignment: assignment, // Pass the assignment for editing
              ),
            ),
          );
          if (result == true) {
            onRefresh();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading assignment: $e')),
            );
          }
        }
      } else {
        // Student: Navigate to assignment detail
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssignmentDetailScreen(assignmentId: item.id),
          ),
        );
        if (result == true) {
          onRefresh();
        }
      }
    } else if (item.type == 'quiz') {
      if (_isInstructor) {
        // Instructor: Navigate to quiz management
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizManagementScreen(quizId: item.id),
          ),
        );
        if (result == true) {
          onRefresh();
        }
      } else {
        // Student: Navigate to quiz detail
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizDetailScreen(quizId: item.id),
          ),
        );
        if (result == true) {
          onRefresh();
        }
      }
    } else if (item.type == 'material') {
      // Navigate to material detail by fetching the material first
      _navigateToMaterial(context, item.id);
    }
    // NEW: Video handling
    else if (item.type == 'video') {
      final result = await Navigator.pushNamed(
        context,
        '/video-player',
        arguments: {'videoId': item.id},
      );
      if (result == true) {
        onRefresh();
      }
    }
    // NEW: Attendance handling
    else if (item.type == 'attendance') {
      if (_isInstructor) {
        // Instructor: Fetch the full attendance session and navigate to records
        try {
          final session = await AttendanceService.getSession(item.id);
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceRecordsScreen(session: session),
            ),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading attendance session: $e')),
            );
          }
        }
      } else {
        // Student: Navigate to attendance detail screen
        try {
          final session = await AttendanceService.getSession(item.id);
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceDetailScreen(session: session),
            ),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading attendance session: $e')),
            );
          }
        }
      }
    }
    // NEW: Code Assignment handling
    else if (item.type == 'code_assignment') {
      if (_isInstructor) {
        // Instructor: View submissions and grading
        try {
          final assignmentData = await _codeAssignmentService.getAssignment(
            item.id,
          );
          if (!context.mounted) return;

          // Navigate to code assignment submissions screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CodeAssignmentSubmissionsScreen(
                assignment: assignmentData['assignment'],
              ),
            ),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading code assignment: $e')),
            );
          }
        }
      } else {
        // Student: Open code editor
        try {
          // Fetch the full assignment with test cases
          final assignmentData = await _codeAssignmentService.getAssignment(
            item.id,
          );
          if (!context.mounted) return;

          final result = await Navigator.pushNamed(
            context,
            '/code-editor',
            arguments: {
              'assignment': assignmentData['assignment'],
              'testCases': assignmentData['testCases'],
            },
          );
          if (result == true) {
            onRefresh();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading code assignment: $e')),
            );
          }
        }
      }
    }
  }

  void _navigateToTracking(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentTrackingScreen(assignmentId: item.id),
      ),
    );
    onRefresh();
  }

  void _navigateToVideoAnalytics(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoAnalyticsScreen(videoId: item.id, videoTitle: item.title),
      ),
    );
  }

  void _navigateToMaterial(BuildContext context, String materialId) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch the material
      final material = await _materialService.getMaterial(materialId);

      // Hide loading
      Navigator.pop(context);

      // Navigate to material detail screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MaterialDetailScreen(material: material, course: course),
        ),
      );

      if (result == true) {
        onRefresh();
      }
    } catch (e) {
      // Hide loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading material: $e')));
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'tomorrow';
    } else if (diff.inDays < 0) {
      return '${diff.inDays.abs()} days ago';
    } else {
      return 'in ${diff.inDays} days';
    }
  }
}

// Announcement Card Widget
