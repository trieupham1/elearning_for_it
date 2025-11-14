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

      final progress = await _dashboardService.getTrainingProgressByDepartment();
      setState(() {
        _departments = progress;
        _sortDepartments();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortDepartments() {
    switch (_sortBy) {
      case 'name':
        _departments.sort((a, b) => a.departmentName.compareTo(b.departmentName));
        break;
      case 'completion':
        _departments.sort((a, b) => b.overallCompletionRate.compareTo(a.overallCompletionRate));
        break;
      case 'employees':
        _departments.sort((a, b) => b.totalEmployees.compareTo(a.totalEmployees));
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
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: _currentUser != null ? AdminDrawer(currentUser: _currentUser!) : null,
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
            dept.departmentCode.isNotEmpty
                ? dept.departmentCode.substring(0, 2).toUpperCase()
                : 'D',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          dept.departmentName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                  dept.departmentCode,
                  Colors.purple,
                ),
                const Divider(height: 24),
                const Text(
                  'Course Progress Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                  ...dept.coursesProgress.map((course) => _buildCourseProgress(course)),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
                  Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Enrolled: ${course.enrolledEmployees}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: progressColor),
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
}
