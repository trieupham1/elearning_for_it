import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/semester_service.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/semester.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final _authService = AuthService();
  final _courseService = CourseService();
  final _semesterService = SemesterService();

  List<Course> _courses = [];
  List<Semester> _semesters = [];
  Semester? _selectedSemester;
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;

  // Semester-specific metrics
  int _totalCourses = 0;
  int _totalGroups = 0;
  int _totalStudents = 0;
  int _totalAssignments = 0;
  int _totalQuizzes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load current user
      _currentUser = await _authService.getCurrentUser();

      // Load semesters
      final semesters = await _semesterService.getSemesters();

      // Get active semester or first semester
      Semester? activeSemester;
      try {
        activeSemester = semesters.firstWhere((s) => s.isActive);
      } catch (e) {
        activeSemester = semesters.isNotEmpty ? semesters.first : null;
      }

      // Load data for active semester
      if (activeSemester != null) {
        await _loadSemesterData(activeSemester);
      }

      setState(() {
        _semesters = semesters;
        _selectedSemester = activeSemester;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSemesterData(Semester semester) async {
    try {
      // Load courses for selected semester
      final courses = await _courseService.getCourses(semester: semester.id);

      print(
        '=== DEBUG: Loaded ${courses.length} courses for semester ${semester.displayName}',
      );

      // Calculate statistics from courses
      // Use a Set to track unique students if they appear in multiple courses
      Set<String> uniqueStudentIds = {};

      for (var course in courses) {
        print(
          'Course: ${course.name}, Students count: ${course.students.length}',
        );
        // Add student IDs from each course
        if (course.students.isNotEmpty) {
          uniqueStudentIds.addAll(course.students);
        }
      }

      print('Total unique students: ${uniqueStudentIds.length}');

      // Use the count of unique students
      final studentCount = uniqueStudentIds.length;

      setState(() {
        _courses = courses;
        _totalCourses = courses.length;
        _totalStudents = studentCount;
        // For groups, assignments, and quizzes, we'll show 0 for now
        // These would need separate API calls or be included in the course data
        _totalGroups = 0;
        _totalAssignments = 0;
        _totalQuizzes = 0;
        _selectedSemester = semester;
      });
    } catch (e) {
      print('Error loading semester data: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeSemester(Semester semester) async {
    setState(() => _isLoading = true);
    await _loadSemesterData(semester);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester Selector Card
            if (_semesters.isNotEmpty) _buildSemesterSelector(),
            const SizedBox(height: 16),
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildCoursesSection(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Semester:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Semester>(
                  value: _selectedSemester,
                  icon: const Icon(Icons.arrow_drop_down),
                  isExpanded: true,
                  items: _semesters.map((Semester semester) {
                    return DropdownMenuItem<Semester>(
                      value: semester,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(semester.displayName),
                          if (semester.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (Semester? newSemester) {
                    if (newSemester != null) {
                      _changeSemester(newSemester);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_currentUser?.fullName ?? 'Instructor'}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your courses and track student progress',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSemester != null
                  ? '${_selectedSemester!.displayName} Overview'
                  : 'Semester Overview',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_selectedSemester != null && !_selectedSemester!.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Past Semester',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 900
              ? 5
              : MediaQuery.of(context).size.width > 600
              ? 3
              : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              'Courses',
              '$_totalCourses',
              Icons.school,
              Colors.blue,
            ),
            _buildStatCard(
              'Groups',
              '$_totalGroups',
              Icons.group,
              Colors.green,
            ),
            _buildStatCard(
              'Students',
              '$_totalStudents',
              Icons.people,
              Colors.orange,
            ),
            _buildStatCard(
              'Assignments',
              '$_totalAssignments',
              Icons.assignment,
              Colors.purple,
            ),
            _buildStatCard('Quizzes', '$_totalQuizzes', Icons.quiz, Colors.red),
          ],
        ),
        const SizedBox(height: 24),
        _buildProgressCharts(),
      ],
    );
  }

  Widget _buildProgressCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildProgressIndicator(
                    'Assignment Completion',
                    0.75,
                    '75%',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildProgressIndicator(
                    'Quiz Participation',
                    0.68,
                    '68%',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildProgressIndicator(
                    'Student Engagement',
                    0.82,
                    '82%',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    String label,
    double value,
    String percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Courses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showCreateCourseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Course'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _courses.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text('No courses yet'),
                      const SizedBox(height: 8),
                      const Text('Create your first course to get started'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateCourseDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Course'),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return _buildCourseCard(course);
                },
              ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
    ];
    final color = colors[course.id.hashCode % colors.length];

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to course detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course detail for ${course.name} coming soon!'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text('${course.studentCount} students'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditCourseDialog(context, course);
                      break;
                    case 'students':
                      _showStudentsList(context, course);
                      break;
                    case 'assignments':
                      _showAssignments(context, course);
                      break;
                    case 'materials':
                      _showMaterials(context, course);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Course'),
                  ),
                  const PopupMenuItem(
                    value: 'students',
                    child: Text('View Students'),
                  ),
                  const PopupMenuItem(
                    value: 'assignments',
                    child: Text('Assignments'),
                  ),
                  const PopupMenuItem(
                    value: 'materials',
                    child: Text('Materials'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  Icons.assignment_turned_in,
                  'New submission',
                  'John Doe submitted Assignment 3 in Mobile Development',
                  '2 hours ago',
                  Colors.green,
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.message,
                  'New message',
                  'Jane Smith posted in the course forum',
                  '4 hours ago',
                  Colors.blue,
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.person_add,
                  'New student',
                  'Mike Johnson joined Web Development course',
                  '1 day ago',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String description,
    String time,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  void _showCreateCourseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Course'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
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
              // TODO: Implement create course
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Create course feature coming soon!'),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit ${course.name} coming soon!')));
  }

  void _showStudentsList(BuildContext context, Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Students list for ${course.name} coming soon!')),
    );
  }

  void _showAssignments(BuildContext context, Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assignments for ${course.name} coming soon!')),
    );
  }

  void _showMaterials(BuildContext context, Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Materials for ${course.name} coming soon!')),
    );
  }
}
