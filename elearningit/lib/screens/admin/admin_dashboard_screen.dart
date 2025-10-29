import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user.dart';
import '../../models/admin_dashboard.dart';
import '../../services/auth_service.dart';
import '../../services/admin_dashboard_service.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  User? _currentUser;
  AdminDashboardOverview? _overview;
  UserGrowthData? _userGrowth;
  List<CompletionRate> _completionRates = [];
  List<TopPerformer> _topPerformers = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();

      setState(() {
        _currentUser = user;
      });

      // Load data with individual error handling
      try {
        final overview = await _dashboardService.getOverview();
        setState(() => _overview = overview);
      } catch (e) {
        print('Error loading overview: $e');
      }

      try {
        final userGrowth = await _dashboardService.getUserGrowth(
          period: _selectedPeriod,
        );
        setState(() => _userGrowth = userGrowth);
      } catch (e) {
        print('Error loading user growth: $e');
      }

      try {
        final completionRates = await _dashboardService.getCompletionRates();
        setState(() => _completionRates = completionRates);
      } catch (e) {
        print('Error loading completion rates: $e');
      }

      try {
        final topPerformers = await _dashboardService.getTopPerformers(
          limit: 5,
        );
        setState(() => _topPerformers = topPerformers);
      } catch (e) {
        print('Error loading top performers: $e');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: _currentUser != null
          ? AdminDrawer(currentUser: _currentUser!)
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildUserGrowthSection(),
                    const SizedBox(height: 24),
                    _buildCompletionRatesSection(),
                    const SizedBox(height: 24),
                    _buildTopPerformersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    if (_overview == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Users',
              _overview!.totalUsers.toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Courses',
              _overview!.totalCourses.toString(),
              Icons.book,
              Colors.green,
            ),
            _buildStatCard(
              'Departments',
              _overview!.totalDepartments.toString(),
              Icons.business,
              Colors.orange,
            ),
            _buildStatCard(
              'Active Courses',
              _overview!.activeCourses.toString(),
              Icons.school,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildUserBreakdownCard(),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildUserBreakdownCard() {
    if (_overview == null) return const SizedBox.shrink();

    final breakdown = _overview!.userBreakdown;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUserCount('Students', breakdown.students, Colors.blue),
                _buildUserCount(
                  'Instructors',
                  breakdown.instructors,
                  Colors.green,
                ),
                _buildUserCount('Admins', breakdown.admins, Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Active Users: ${breakdown.activeUsers}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildUserGrowthSection() {
    if (_userGrowth == null || _userGrowth!.data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Growth',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                      _loadDashboardData();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _userGrowth!.data.length) {
                            return const Text('');
                          }
                          // Generate label from the id Map
                          final point = _userGrowth!.data[index];
                          String label = '';
                          if (point.id.containsKey('month')) {
                            label = 'T${point.id['month']}';
                          } else if (point.id.containsKey('week')) {
                            label = 'W${point.id['week']}';
                          } else if (point.id.containsKey('day')) {
                            label = '${point.id['day']}';
                          }
                          return Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _userGrowth!.data
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value.count.toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
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

  Widget _buildCompletionRatesSection() {
    if (_completionRates.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Completion Rates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _completionRates.length > 5
                  ? 5
                  : _completionRates.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final course = _completionRates[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(course.courseTitle),
                  subtitle: Text(
                    '${course.completedStudents}/${course.totalStudents} students',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCompletionColor(course.completionRate),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${course.completionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    if (_topPerformers.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topPerformers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final performer = _topPerformers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(index),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(performer.student.fullName),
                  subtitle: Text(
                    performer.student.department ?? performer.student.email,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        performer.averageScore.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}
