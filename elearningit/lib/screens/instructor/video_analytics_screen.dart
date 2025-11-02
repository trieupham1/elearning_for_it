import 'package:flutter/material.dart';
import '../../services/video_service.dart';

class VideoAnalyticsScreen extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final Map<String, dynamic>? initialData;

  const VideoAnalyticsScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
    this.initialData,
  });

  @override
  State<VideoAnalyticsScreen> createState() => _VideoAnalyticsScreenState();
}

class _VideoAnalyticsScreenState extends State<VideoAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  String _filter = 'all'; // all, completed, not-watched
  String _sortBy = 'name'; // name, completion

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await VideoService.getVideoAnalytics(widget.videoId);
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
      }
    }
  }

  List<dynamic> get _filteredStudents {
    if (_analyticsData == null) return [];

    List<dynamic> students = List.from(_analyticsData!['students'] ?? []);

    // Apply filter
    switch (_filter) {
      case 'completed':
        students = students.where((s) => s['completed'] == true).toList();
        break;
      case 'not-watched':
        students = students.where((s) => s['watched'] == false).toList();
        break;
      case 'all':
      default:
        break;
    }

    // Apply sorting
    if (_sortBy == 'name') {
      students.sort(
        (a, b) => (a['studentName'] ?? '').toString().compareTo(
          (b['studentName'] ?? '').toString(),
        ),
      );
    } else if (_sortBy == 'completion') {
      students.sort((a, b) {
        final aComp = a['completionPercentage'] ?? 0;
        final bComp = b['completionPercentage'] ?? 0;
        return bComp.compareTo(aComp); // Descending
      });
    }

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null
          ? const Center(child: Text('No analytics data available'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  _buildStatsCards(),
                  _buildFiltersAndSort(),
                  _buildStudentList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.videoTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watch Analytics',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_analyticsData!['completionRate'] ?? 0) / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCompletionColor(_analyticsData!['completionRate'] ?? 0),
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${_analyticsData!['completionRate']?.toStringAsFixed(1) ?? '0'}% completion rate',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalStudents = _analyticsData!['totalStudents'] ?? 0;
    final studentsWatched = _analyticsData!['studentsWatched'] ?? 0;
    final studentsCompleted = _analyticsData!['studentsCompleted'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Students',
              totalStudents.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Watched',
              studentsWatched.toString(),
              Icons.play_arrow,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              studentsCompleted.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & Sort',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == 'all',
                onSelected: (selected) {
                  if (selected) setState(() => _filter = 'all');
                },
              ),
              ChoiceChip(
                label: const Text('Completed (≥75%)'),
                selected: _filter == 'completed',
                onSelected: (selected) {
                  if (selected) setState(() => _filter = 'completed');
                },
              ),
              ChoiceChip(
                label: const Text('Not Watched'),
                selected: _filter == 'not-watched',
                onSelected: (selected) {
                  if (selected) setState(() => _filter = 'not-watched');
                },
              ),
              const SizedBox(width: 16),
              const VerticalDivider(),
              ChoiceChip(
                label: const Text('Sort by Name'),
                selected: _sortBy == 'name',
                onSelected: (selected) {
                  if (selected) setState(() => _sortBy = 'name');
                },
              ),
              ChoiceChip(
                label: const Text('Sort by Progress'),
                selected: _sortBy == 'completion',
                onSelected: (selected) {
                  if (selected) setState(() => _sortBy = 'completion');
                },
              ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final students = _filteredStudents;

    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No students match the selected filter',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentName = student['studentName'] ?? 'Unknown Student';
    final studentEmail = student['email'] ?? '';
    final profilePicture = student['profilePicture'];
    final watched = student['watched'] ?? false;
    final completed = student['completed'] ?? false;
    final completionPercentage = (student['completionPercentage'] ?? 0)
        .toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 24,
              backgroundColor: completed
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              backgroundImage:
                  profilePicture != null && profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture == null || profilePicture.isEmpty
                  ? Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: completed
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (studentEmail.isNotEmpty)
                              Text(
                                studentEmail,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      if (completed)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        )
                      else if (watched)
                        const Icon(
                          Icons.hourglass_empty,
                          color: Colors.orange,
                          size: 24,
                        )
                      else
                        const Icon(Icons.close, color: Colors.red, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (watched) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCompletionColor(completionPercentage),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 45,
                          child: Text(
                            '${completionPercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getCompletionColor(
                                    completionPercentage,
                                  ),
                                ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Not watched yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 25) return Colors.amber;
    return Colors.red;
  }
}
