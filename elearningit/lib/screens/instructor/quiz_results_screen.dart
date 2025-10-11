import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:html' as html show document, AnchorElement, Blob, Url;
import '../../services/quiz_service.dart';

class QuizResultsScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final QuizService _quizService = QuizService();
  
  Map<String, dynamic>? _resultsData;
  bool _isLoading = true;
  String? _error;
  
  // Filter and sort options
  String _sortBy = 'submissionTime'; // submissionTime, score, studentName
  bool _sortAscending = false;
  String _filterStatus = 'all'; // all, completed, in_progress
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _quizService.getAllQuizAttempts(widget.quizId);
      
      setState(() {
        _resultsData = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredAndSortedAttempts() {
    if (_resultsData == null) return [];
    
    List<dynamic> attempts = List.from(_resultsData!['attempts'] ?? []);
    
    // Filter by status
    if (_filterStatus != 'all') {
      attempts = attempts.where((attempt) {
        final status = attempt['status'] ?? '';
        if (_filterStatus == 'completed') {
          return ['submitted', 'auto_submitted'].contains(status);
        } else if (_filterStatus == 'in_progress') {
          return status == 'in_progress';
        }
        return true;
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      attempts = attempts.where((attempt) {
        final studentName = attempt['studentId']?['name']?.toString().toLowerCase() ?? '';
        final studentEmail = attempt['studentId']?['email']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return studentName.contains(query) || studentEmail.contains(query);
      }).toList();
    }
    
    // Sort attempts
    attempts.sort((a, b) {
      dynamic aValue, bValue;
      
      switch (_sortBy) {
        case 'studentName':
          aValue = a['studentId']?['name'] ?? '';
          bValue = b['studentId']?['name'] ?? '';
          break;
        case 'score':
          aValue = a['score'] ?? 0;
          bValue = b['score'] ?? 0;
          break;
        case 'submissionTime':
          aValue = a['submissionTime'] ?? a['createdAt'] ?? '';
          bValue = b['submissionTime'] ?? b['createdAt'] ?? '';
          break;
        default:
          aValue = a['createdAt'] ?? '';
          bValue = b['createdAt'] ?? '';
      }
      
      int comparison = 0;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return attempts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results: ${widget.quizTitle}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadResults,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Results',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Cleanup Expired'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Quiz Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildResultsContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load results',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadResults,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    final attempts = _getFilteredAndSortedAttempts();
    
    return Column(
      children: [
        // Summary cards
        _buildSummaryCards(),
        
        // Filters and search
        _buildFiltersAndSearch(),
        
        // Results list
        Expanded(
          child: attempts.isEmpty
              ? _buildEmptyState()
              : _buildAttemptsList(attempts),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    if (_resultsData == null) return const SizedBox();
    
    final totalAttempts = _resultsData!['totalAttempts'] ?? 0;
    final uniqueStudents = _resultsData!['uniqueStudents'] ?? 0;
    final completedAttempts = _resultsData!['completedAttempts'] ?? 0;
    final averageScore = _resultsData!['averageScore'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Attempts',
              totalAttempts.toString(),
              Icons.quiz,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Students',
              uniqueStudents.toString(),
              Icons.people,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Completed',
              completedAttempts.toString(),
              Icons.check_circle,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Avg Score',
              '${averageScore}%',
              Icons.star,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Filter and sort options
          Row(
            children: [
              // Status filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Sort by
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'submissionTime', child: Text('Submission Time')),
                    DropdownMenuItem(value: 'score', child: Text('Score')),
                    DropdownMenuItem(value: 'studentName', child: Text('Student Name')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              // Sort direction
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Ascending' : 'Descending',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No quiz attempts found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students haven\'t taken this quiz yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsList(List<dynamic> attempts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        return _buildAttemptCard(attempt);
      },
    );
  }

  Widget _buildAttemptCard(Map<String, dynamic> attempt) {
    final student = attempt['studentId'] ?? {};
    
    // Extract student name properly from User model structure
    final firstName = student['firstName'] ?? '';
    final lastName = student['lastName'] ?? '';
    final username = student['username'] ?? '';
    
    String studentName = 'Unknown Student';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      studentName = '$firstName $lastName'.trim();
    } else if (username.isNotEmpty) {
      studentName = username;
    }
    final studentEmail = student['email'] ?? '';
    final score = attempt['score'] ?? 0;
    final status = attempt['status'] ?? 'unknown';
    final attemptNumber = attempt['attemptNumber'] ?? 1;
    final submissionTime = attempt['submissionTime'];
    final timeSpent = attempt['timeSpent'] ?? 0;
    final correctAnswers = attempt['correctAnswers'] ?? 0;
    final totalQuestions = attempt['totalQuestions'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Student info
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
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Status badge
                _buildStatusBadge(status),
                const SizedBox(width: 12),
                
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getScoreColor(score).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${score}%',
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details row
            Row(
              children: [
                _buildDetailChip(
                  Icons.repeat,
                  'Attempt $attemptNumber',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  Icons.check_circle,
                  '$correctAnswers/$totalQuestions correct',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  Icons.timer,
                  _formatDuration(timeSpent),
                  Colors.orange,
                ),
              ],
            ),
            
            // Submission time
            if (submissionTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted: ${_formatDateTime(submissionTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            
            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewAttemptDetails(attempt),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'in_progress')
                  TextButton.icon(
                    onPressed: () => _handleExpiredAttempt(attempt),
                    icon: const Icon(Icons.warning, size: 16),
                    label: const Text('Check Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'submitted':
        color = Colors.green;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case 'auto_submitted':
        color = Colors.orange;
        label = 'Auto-submitted';
        icon = Icons.timer;
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'In Progress';
        icon = Icons.play_circle;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportResults();
        break;
      case 'cleanup':
        _cleanupExpiredAttempts();
        break;
      case 'settings':
        _openQuizSettings();
        break;
    }
  }

  Future<void> _exportResults() async {
    try {
      setState(() => _isLoading = true);
      
      final csvContent = await _quizService.exportQuizResults(widget.quizId);
      
      // For web, create a download
      if (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android) {
        // On mobile, show the CSV content or save to downloads
        _showCsvDialog(csvContent);
      } else {
        // For web, trigger download
        _downloadCsv(csvContent);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz results exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupExpiredAttempts() async {
    try {
      await _quizService.autoCloseExpiredQuizzes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expired quizzes closed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadResults(); // Refresh the results
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to close expired quizzes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewAttemptDetails(Map<String, dynamic> attempt) {
    // TODO: Navigate to detailed attempt view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${attempt['studentId']?['name'] ?? 'student'}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleExpiredAttempt(Map<String, dynamic> attempt) {
    // TODO: Handle expired attempt checking/auto-submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking attempt status...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCsvDialog(String csvContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Export'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              csvContent,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Copy to clipboard functionality could be added here
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _downloadCsv(String csvContent) async {
    try {
      // Create filename with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filename = '${widget.quizTitle.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '_')}_results_$timestamp.csv';
      
      if (kIsWeb) {
        // Web platform - create downloadable file
        final bytes = utf8.encode(csvContent);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = filename;
        
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        print('📁 CSV file downloaded: $filename');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📁 CSV file "$filename" downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Mobile platforms - use share functionality
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(csvContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Quiz Results CSV Export',
        );
        
        print('CSV file shared: $filename');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV file "$filename" ready to share!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('CSV download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Fallback to dialog
      _showCsvDialog(csvContent);
    }
  }

  Future<void> _openQuizSettings() async {
    try {
      print('🔧 Opening quiz settings for quiz: ${widget.quizId}');
      final result = await Navigator.pushNamed(
        context,
        '/quiz-settings',
        arguments: {
          'quizId': widget.quizId,
        },
      );
      
      print('🔧 Quiz settings result: $result');
      if (result == true) {
        // Settings were updated, refresh the results
        _loadResults();
      }
    } catch (e) {
      print('❌ Error opening quiz settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open quiz settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}