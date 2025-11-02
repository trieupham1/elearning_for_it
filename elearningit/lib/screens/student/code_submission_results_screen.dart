import 'package:flutter/material.dart';
import '../../models/code_assignment.dart';

class CodeSubmissionResultsScreen extends StatelessWidget {
  final CodeSubmission submission;
  final CodeAssignment assignment;

  const CodeSubmissionResultsScreen({
    Key? key,
    required this.submission,
    required this.assignment,
  }) : super(key: key);

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'passed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'timeout':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(submission.totalScore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Results'),
        actions: [
          if (submission.isBestSubmission)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Chip(
                avatar: Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text('Best', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Score header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scoreColor, scoreColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    submission.scoreText,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submission.testSummary,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    submission.statusText,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Submission info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Submitted',
                    value: _formatDateTime(submission.submittedAt),
                  ),
                  if (submission.gradedAt != null)
                    _buildInfoItem(
                      icon: Icons.check_circle,
                      label: 'Graded',
                      value: _formatDateTime(submission.gradedAt!),
                    ),
                  _buildInfoItem(
                    icon: Icons.code,
                    label: 'Language',
                    value:
                        ProgrammingLanguage.fromKey(
                          submission.language,
                        )?.displayName ??
                        submission.language,
                  ),
                ],
              ),
            ),

            // Execution summary
            if (submission.executionSummary != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Execution Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          'Total Time',
                          submission.executionSummary!.totalTimeText,
                        ),
                        _buildSummaryRow(
                          'Average Time',
                          submission.executionSummary!.averageTimeText,
                        ),
                        _buildSummaryRow(
                          'Max Memory',
                          submission.executionSummary!.maxMemoryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Test results
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Results',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...submission.testResults.asMap().entries.map((entry) {
                    final index = entry.key;
                    final result = entry.value;
                    final isHidden = result.testCaseId == null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: result.passed
                          ? Colors.green[50]
                          : result.failed
                          ? Colors.red[50]
                          : Colors.orange[50],
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(result.status),
                          child: Text(
                            result.statusIcon,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          isHidden
                              ? 'Hidden Test ${index + 1}'
                              : 'Test ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${result.status.toUpperCase()} • ${result.executionTimeText} • ${result.memoryUsedText}',
                        ),
                        trailing: Text(
                          'Weight: ${result.weight}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isHidden) ...[
                                  _buildTestDetailSection(
                                    'Input',
                                    result.input,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTestDetailSection(
                                    'Expected Output',
                                    result.expectedOutput,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                _buildTestDetailSection(
                                  'Your Output',
                                  result.actualOutput.isEmpty
                                      ? '(no output)'
                                      : result.actualOutput,
                                  color: result.passed
                                      ? Colors.green
                                      : Colors.red,
                                ),

                                if (result.errorMessage != null &&
                                    result.errorMessage!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildTestDetailSection(
                                    'Error',
                                    result.errorMessage!,
                                    color: Colors.red,
                                  ),
                                ],

                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildMetricChip(
                                      icon: Icons.timer,
                                      label: 'Time',
                                      value: result.executionTimeText,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildMetricChip(
                                      icon: Icons.memory,
                                      label: 'Memory',
                                      value: result.memoryUsedText,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Code view
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: ExpansionTile(
                  title: const Text(
                    'View Submitted Code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[900],
                      child: Text(
                        submission.code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.edit),
        label: const Text('Try Again'),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTestDetailSection(String title, String content, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: color != null
                ? Border.all(color: color.withOpacity(0.3))
                : null,
          ),
          child: Text(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
