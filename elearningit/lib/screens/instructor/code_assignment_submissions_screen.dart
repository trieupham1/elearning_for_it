import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/code_assignment.dart';
import '../../services/code_assignment_service.dart';

class CodeAssignmentSubmissionsScreen extends StatefulWidget {
  final CodeAssignment assignment;

  const CodeAssignmentSubmissionsScreen({Key? key, required this.assignment})
    : super(key: key);

  @override
  State<CodeAssignmentSubmissionsScreen> createState() =>
      _CodeAssignmentSubmissionsScreenState();
}

class _CodeAssignmentSubmissionsScreenState
    extends State<CodeAssignmentSubmissionsScreen> {
  final CodeAssignmentService _service = CodeAssignmentService();
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final submissions = await _service.getAllSubmissions(
        widget.assignment.id,
      );
      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submissions'),
            Text(
              widget.assignment.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading submissions',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubmissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No submissions yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics Card
        _buildStatisticsCard(),

        // Submissions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              final submission = _submissions[index];
              return _buildSubmissionCard(submission);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final totalSubmitted = _submissions.length;
    final averageScore = totalSubmitted > 0
        ? _submissions
                  .map((s) => (s['totalScore'] ?? 0.0) as num)
                  .reduce((a, b) => a + b) /
              totalSubmitted
        : 0.0;

    final passed = _submissions.where((s) {
      final score = (s['totalScore'] ?? 0.0) as num;
      return score >= 70; // 70% passing threshold
    }).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Submitted',
              totalSubmitted.toString(),
              Icons.upload,
              Colors.blue,
            ),
            _buildStatItem(
              'Passed',
              passed.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatItem(
              'Avg Score',
              '${averageScore.toStringAsFixed(1)}%',
              Icons.analytics,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final student = submission['student'] as Map<String, dynamic>?;
    final studentName = student?['fullName'] ?? 'Unknown Student';
    final studentEmail = student?['email'] ?? '';
    final profilePicture = student?['profilePicture'] as String?;
    final totalScore = (submission['totalScore'] ?? 0.0) as num;
    final passedTests = submission['passedTests'] ?? 0;
    final totalTests = submission['totalTests'] ?? 0;
    final submittedAt = submission['submittedAt'] != null
        ? DateTime.parse(submission['submittedAt'])
        : null;

    // Check if late
    final isLate =
        submittedAt != null && submittedAt.isAfter(widget.assignment.deadline);

    // Determine score color
    Color scoreColor;
    if (totalScore >= 90) {
      scoreColor = Colors.green;
    } else if (totalScore >= 70) {
      scoreColor = Colors.lightGreen;
    } else if (totalScore >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scoreColor.withOpacity(0.2),
                    backgroundImage:
                        profilePicture != null && profilePicture.isNotEmpty
                        ? NetworkImage(profilePicture)
                        : null,
                    child: profilePicture == null || profilePicture.isEmpty
                        ? Text(
                            studentName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (studentEmail.isNotEmpty)
                          Text(
                            studentEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor, width: 2),
                    ),
                    child: Text(
                      '${totalScore.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Test Results
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tests: $passedTests / $totalTests passed',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Submission Time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    submittedAt != null
                        ? 'Submitted ${DateFormat('MMM d, y h:mm a').format(submittedAt)}'
                        : 'No submission time',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  if (isLate) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
