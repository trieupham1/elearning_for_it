import 'package:flutter/material.dart';
import '../../models/admin_dashboard.dart';
import '../../models/user.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_drawer.dart';

class TrainingProgressScreen extends StatefulWidget {
  const TrainingProgressScreen({super.key});

  @override
  State<TrainingProgressScreen> createState() => _TrainingProgressScreenState();
}

class _TrainingProgressScreenState extends State<TrainingProgressScreen> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  User? _currentUser;
  List<DepartmentProgress> _departments = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // name, completion, employees

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() => _currentUser = user);

      final progress = await _dashboardService
          .getTrainingProgressByDepartment();
      setState(() {
        _departments = progress;
        _sortDepartments();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortDepartments() {
    switch (_sortBy) {
      case 'name':
        _departments.sort(
          (a, b) => a.departmentName.compareTo(b.departmentName),
        );
        break;
      case 'completion':
        _departments.sort(
          (a, b) => b.overallCompletionRate.compareTo(a.overallCompletionRate),
        );
        break;
      case 'employees':
        _departments.sort(
          (a, b) => b.totalEmployees.compareTo(a.totalEmployees),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Progress by Department'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortDepartments();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(
                value: 'completion',
                child: Text('Sort by Completion Rate'),
              ),
              const PopupMenuItem(
                value: 'employees',
                child: Text('Sort by Employee Count'),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      drawer: _currentUser != null
          ? AdminDrawer(currentUser: _currentUser!)
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _departments.isEmpty
                  ? const Center(child: Text('No department data available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _departments.length,
                      itemBuilder: (context, index) {
                        final dept = _departments[index];
                        return _buildDepartmentCard(dept);
                      },
                    ),
            ),
    );
  }

  Widget _buildDepartmentCard(DepartmentProgress dept) {
    final completionRate = dept.overallCompletionRate;
    final progressColor = _getCompletionColor(completionRate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: progressColor,
          child: Text(
            dept.departmentCode != null && dept.departmentCode!.isNotEmpty
                ? dept.departmentCode!.substring(0, 2).toUpperCase()
                : 'D',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dept.departmentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // View Details Button
            TextButton.icon(
              onPressed: () => _showUserDetailsDialog(dept),
              icon: const Icon(Icons.people_outline, size: 18),
              label: const Text('User Details', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '${completionRate.toStringAsFixed(1)}% Overall Completion',
              style: TextStyle(
                fontSize: 12,
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  Icons.people,
                  'Total Employees',
                  dept.totalEmployees.toString(),
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  Icons.school,
                  'Total Courses',
                  dept.totalCourses.toString(),
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  Icons.code,
                  'Department Code',
                  dept.departmentCode ?? 'N/A',
                  Colors.purple,
                ),
                const Divider(height: 24),
                const Text(
                  'Course Progress Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (dept.coursesProgress.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No course data available'),
                    ),
                  )
                else
                  ...dept.coursesProgress.map(
                    (course) => _buildCourseProgress(course),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseProgress(CourseProgress course) {
    final progressColor = _getCompletionColor(course.completionRate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseTitle ?? 'Unknown Course',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      course.courseCode ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${course.completionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: course.completionRate / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Enrolled: ${course.enrolledEmployees}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: progressColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed: ${course.completedEmployees}',
                    style: TextStyle(fontSize: 12, color: progressColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    if (rate >= 40) return Colors.amber;
    return Colors.red;
  }

  // Show detailed user statistics dialog
  Future<void> _showUserDetailsDialog(DepartmentProgress dept) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.departmentName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'User Training Statistics',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Content
              Expanded(
                child: FutureBuilder<DepartmentUserProgress?>(
                  future: _dashboardService.getDepartmentUserProgress(
                    dept.departmentId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading user details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'This feature requires backend API implementation:\nGET /api/admin-dashboard/training-progress/:id/users',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final userProgress = snapshot.data;
                    if (userProgress == null || userProgress.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No user data available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Backend API needs implementation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: userProgress.users.length,
                      itemBuilder: (context, index) {
                        final user = userProgress.users[index];
                        return _buildUserCard(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserTrainingProgress user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          backgroundImage:
              user.profilePicture != null && user.profilePicture!.isNotEmpty
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null || user.profilePicture!.isEmpty
              ? Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.courses.length} course${user.courses.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (user.courses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No courses enrolled',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...user.courses.map((course) => _buildCourseDetail(course)),
        ],
      ),
    );
  }

  Widget _buildCourseDetail(UserCourseDetail course) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      course.courseCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Attendance Section
          if (course.attendance != null) ...[
            const SizedBox(height: 16),
            _buildAttendanceSection(course.attendance!),
          ],

          // Scores Section
          if (course.scores != null) ...[
            const SizedBox(height: 16),
            _buildScoresSection(course.scores!),
          ],

          // No Data Available
          if (course.attendance == null && course.scores == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No attendance or score data available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(AttendanceProgress attendance) {
    final attendanceColor = attendance.percentage >= 80
        ? Colors.green
        : attendance.percentage >= 60
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_available, size: 16, color: attendanceColor),
            const SizedBox(width: 8),
            const Text(
              'Attendance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${attendance.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: attendanceColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: attendance.percentage / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(attendanceColor),
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildAttendanceStat(
              '✅ Attended',
              attendance.attended,
              Colors.green,
            ),
            _buildAttendanceStat('⏰ Late', attendance.late, Colors.orange),
            _buildAttendanceStat('❌ Absent', attendance.absent, Colors.red),
            _buildAttendanceStat(
              '📊 Total',
              attendance.totalSessions,
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceStat(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection(ScoreProgress scores) {
    final avgColor = scores.averageScore >= 8
        ? Colors.green
        : scores.averageScore >= 6
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grade, size: 16, color: avgColor),
            const SizedBox(width: 8),
            const Text(
              'Scores',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Spacer(),
            Text(
              'Avg: ${scores.averageScore.toStringAsFixed(1)}/10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: avgColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${scores.totalAssessments} assessment${scores.totalAssessments != 1 ? 's' : ''}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),

        // Score Distribution
        if (scores.scoreDistribution.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Score Distribution:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...scores.scoreDistribution.entries.map((entry) {
            final score = entry.key;
            final count = entry.value;
            final maxCount = scores.scoreDistribution.values.reduce(
              (a, b) => a > b ? a : b,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$score:',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: count / maxCount,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getScoreColor(double.parse(score)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],

        // Assessment Details
        if (scores.quizzes.isNotEmpty || scores.assignments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Assessment Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            children: [
              if (scores.quizzes.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Quizzes:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                ...scores.quizzes.map((quiz) => _buildAssessmentItem(quiz)),
              ],
              if (scores.assignments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Assignments:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                ...scores.assignments.map(
                  (assignment) => _buildAssessmentItem(assignment),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAssessmentItem(Assessment assessment) {
    final percentage = (assessment.score / assessment.maxScore) * 100;
    final scoreColor = percentage >= 80
        ? Colors.green
        : percentage >= 60
        ? Colors.orange
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(assessment.title, style: const TextStyle(fontSize: 11)),
          ),
          Text(
            '${assessment.score.toStringAsFixed(1)}/${assessment.maxScore.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 9) return Colors.green;
    if (score >= 7) return Colors.lightGreen;
    if (score >= 5) return Colors.orange;
    return Colors.red;
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
}
