import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/semester_service.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/semester.dart';
import '../screens/course_detail_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _authService = AuthService();
  final _courseService = CourseService();
  final _semesterService = SemesterService();

  User? _currentUser;
  List<Course> _courses = [];
  List<Semester> _semesters = [];
  Semester? _selectedSemester;
  bool _isLoading = true;
  String? _errorMessage;

  // Stats
  int _totalCourses = 0;
  int _completedAssignments = 12;
  int _pendingTasks = 4;
  int _notifications = 2;

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

      // Load courses for active semester
      List<Course> courses = [];
      if (activeSemester != null) {
        courses = await _courseService.getCourses(semester: activeSemester.id);
      }

      setState(() {
        _semesters = semesters;
        _selectedSemester = activeSemester;
        _courses = courses;
        _totalCourses = courses.length;
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

  Future<void> _loadCoursesForSemester(Semester semester) async {
    setState(() => _isLoading = true);

    try {
      final courses = await _courseService.getCourses(semester: semester.id);

      setState(() {
        _selectedSemester = semester;
        _courses = courses;
        _totalCourses = courses.length;
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
              'Error loading data',
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
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsCards(),
            const SizedBox(height: 32),

            // Courses Section with Semester Filter
            _buildCoursesHeader(),
            const SizedBox(height: 16),

            // Courses Grid
            _buildCoursesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).primaryColor,
          backgroundImage: _currentUser?.profilePicture != null
              ? NetworkImage(_currentUser!.profilePicture!)
              : null,
          child: _currentUser?.profilePicture == null
              ? Text(
                  _currentUser?.username.substring(0, 2).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                _currentUser?.fullName ?? 'Student',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 1200) crossAxisCount = 2;
        if (constraints.maxWidth < 600) crossAxisCount = 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.school,
              label: 'Courses',
              value: _totalCourses.toString(),
              color: Colors.blue,
              iconColor: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.check_circle,
              label: 'Completed',
              value: _completedAssignments.toString(),
              color: Colors.green,
              iconColor: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.pending_actions,
              label: 'Pending',
              value: _pendingTasks.toString(),
              color: Colors.orange,
              iconColor: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.notifications,
              label: 'Notifications',
              value: _notifications.toString(),
              color: Colors.purple,
              iconColor: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Courses',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (_semesters.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Semester>(
                value: _selectedSemester,
                icon: const Icon(Icons.arrow_drop_down),
                items: _semesters.map((Semester semester) {
                  return DropdownMenuItem<Semester>(
                    value: semester,
                    child: Text(
                      semester.displayName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (Semester? newSemester) {
                  if (newSemester != null) {
                    _loadCoursesForSemester(newSemester);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCoursesGrid() {
    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No courses enrolled',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your instructor to join courses',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1400) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 1000) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: _courses.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(_courses[index]);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(Course course) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    final color = colors[course.id.hashCode % colors.length];

    // Check if semester is read-only (past semester)
    final isReadOnly =
        _selectedSemester != null && !_selectedSemester!.isActive;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CourseDetailScreen(course: course, isReadOnly: isReadOnly),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient color
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Course Code
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Read-only badge for past semesters
                      if (isReadOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'READ ONLY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Course Title
                  Text(
                    course.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Course Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructor Name
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.instructorName ?? 'Unknown Instructor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Student Count
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.studentCount} students enrolled',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.assignment, size: 20),
                          onPressed: isReadOnly ? null : () {},
                          tooltip: 'Assignments',
                          color: Colors.grey.shade700,
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder, size: 20),
                          onPressed: () {},
                          tooltip: 'Materials',
                          color: Colors.grey.shade700,
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: () {},
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
