import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/javascript.dart';
import '../../models/code_assignment.dart';
import '../../services/code_assignment_service.dart';

class CodeEditorScreen extends StatefulWidget {
  final CodeAssignment assignment;
  final List<TestCase> testCases;

  const CodeEditorScreen({
    Key? key,
    required this.assignment,
    required this.testCases,
  }) : super(key: key);

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen>
    with SingleTickerProviderStateMixin {
  final CodeAssignmentService _service = CodeAssignmentService();
  late CodeController _codeController;
  late TabController _tabController;

  String _selectedLanguage = 'python';
  bool _isSubmitting = false;
  bool _isTesting = false;
  String _testOutput = '';
  String _testError = '';
  String _testInput = '';
  List<CodeSubmission> _submissionHistory = [];
  CodeSubmission? _bestSubmission;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set default language and starter code
    if (widget.assignment.codeConfig != null) {
      _selectedLanguage = widget.assignment.codeConfig!.language;
      _codeController = CodeController(
        text:
            widget.assignment.codeConfig!.starterCode ??
            _getDefaultCode(_selectedLanguage),
        language: _getHighlightLanguage(_selectedLanguage),
      );
    } else {
      _codeController = CodeController(
        text: _getDefaultCode(_selectedLanguage),
        language: python,
      );
    }

    _loadSubmissionHistory();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Get highlight.js language for syntax highlighting
  dynamic _getHighlightLanguage(String lang) {
    switch (lang) {
      case 'python':
        return python;
      case 'java':
        return java;
      case 'cpp':
        return cpp;
      case 'javascript':
        return javascript;
      case 'c':
        return cpp; // Use cpp for C language
      default:
        return python;
    }
  }

  // Get default starter code
  String _getDefaultCode(String lang) {
    switch (lang) {
      case 'python':
        return '# Write your code here\n\n';
      case 'java':
        return 'public class Main {\n    public static void main(String[] args) {\n        // Write your code here\n    }\n}\n';
      case 'cpp':
        return '#include <iostream>\nusing namespace std;\n\nint main() {\n    // Write your code here\n    return 0;\n}\n';
      case 'javascript':
        return '// Write your code here\n\n';
      case 'c':
        return '#include <stdio.h>\n\nint main() {\n    // Write your code here\n    return 0;\n}\n';
      default:
        return '// Write your code here\n';
    }
  }

  Future<void> _loadSubmissionHistory() async {
    try {
      final submissions = await _service.getMySubmissions(widget.assignment.id);
      setState(() {
        _submissionHistory = submissions;
        _bestSubmission = submissions
            .where((s) => s.isBestSubmission)
            .firstOrNull;
      });
    } catch (e) {
      // Ignore errors, history is optional
    }
  }

  Future<void> _testCode() async {
    setState(() {
      _isTesting = true;
      _testOutput = '';
      _testError = '';
    });

    try {
      final result = await _service.testCode(
        assignmentId: widget.assignment.id,
        code: _codeController.text,
        language: _selectedLanguage,
        input: _testInput,
      );

      setState(() {
        _testOutput = result['output'] ?? '';
        _testError = result['error'] ?? '';
        _isTesting = false;
      });

      if (_testError.isEmpty) {
        _showSnackBar('Code executed successfully!', Colors.green);
      } else {
        _showSnackBar('Code has errors', Colors.orange);
      }
    } catch (e) {
      setState(() {
        _testError = e.toString();
        _isTesting = false;
      });
      _showSnackBar('Test failed: $e', Colors.red);
    }
  }

  Future<void> _submitCode() async {
    if (_codeController.text.trim().isEmpty) {
      _showSnackBar('Please write some code before submitting', Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Code?'),
        content: Text(
          'Submit your code for grading?\n\n'
          'Points: ${widget.assignment.points}\n'
          'Time remaining: ${widget.assignment.timeRemainingText}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      print('🚀 Starting code submission...');
      final result = await _service.submitCode(
        assignmentId: widget.assignment.id,
        code: _codeController.text,
        language: _selectedLanguage,
      );

      final submissionId = result['submissionId'];
      print('✅ Code submitted successfully. Submission ID: $submissionId');

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Running tests...'),
            ],
          ),
        ),
      );

      print('⏳ Polling for submission results...');
      // Poll for results
      final submission = await _service.pollSubmissionStatus(submissionId);
      print(
        '✅ Results received: ${submission.status}, Score: ${submission.totalScore}',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      setState(() => _isSubmitting = false);

      // Navigate to results screen
      print('📱 Navigating to results screen...');
      Navigator.pushNamed(
        context,
        '/code-submission-results',
        arguments: {'submission': submission, 'assignment': widget.assignment},
      ).then((_) {
        print('✅ Returned from results screen');
        _loadSubmissionHistory();
      });
    } catch (e, stackTrace) {
      print('❌ Submission error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        // Try to close loading dialog if it's open
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      setState(() => _isSubmitting = false);
      _showSnackBar('Submission failed: $e', Colors.red);
    }
  }

  void _changeLanguage(String newLang) {
    if (!widget.assignment.codeConfig!.allowedLanguages.contains(newLang)) {
      _showSnackBar(
        'Language $newLang not allowed for this assignment',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _selectedLanguage = newLang;
      final currentCode = _codeController.text;
      _codeController.dispose();

      // Keep current code or use starter code
      final newCode =
          currentCode.trim().isEmpty ||
              currentCode == _getDefaultCode(_selectedLanguage)
          ? _getDefaultCode(newLang)
          : currentCode;

      _codeController = CodeController(
        text: newCode,
        language: _getHighlightLanguage(newLang),
      );
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildCodeTab() {
    return Column(
      children: [
        // Language selector
        if (widget.assignment.codeConfig!.allowedLanguages.length > 1)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Text(
                  'Language: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: widget.assignment.codeConfig!.allowedLanguages.map((
                    lang,
                  ) {
                    final langObj = ProgrammingLanguage.fromKey(lang);
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(langObj?.displayName ?? lang),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      value != null ? _changeLanguage(value) : null,
                ),
                const Spacer(),
                Text(
                  'Time Limit: ${widget.assignment.codeConfig!.timeLimitText}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  'Memory: ${widget.assignment.codeConfig!.memoryLimitText}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Code editor
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting || _isSubmitting ? null : _testCode,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isTesting ? 'Testing...' : 'Test Code'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting || _isTesting ? null : _submitCode,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting
                        ? 'Submitting...'
                        : 'Submit (${widget.assignment.points} pts)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Input',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Enter test input here (one value per line)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _testInput = value,
                ),

                const SizedBox(height: 24),

                if (_testOutput.isNotEmpty) ...[
                  const Text(
                    'Output',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _testOutput,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],

                if (_testError.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Errors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _testError,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Text(
                  'Visible Test Cases',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...widget.testCases
                    .where((tc) => !tc.isHidden)
                    .map(
                      (tc) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tc.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (tc.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  tc.description!,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text('Input: ${tc.input}'),
                              Text('Expected Output: ${tc.expectedOutput}'),
                              Text(
                                'Weight: ${tc.weight}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                if (widget.testCases.where((tc) => tc.isHidden).isNotEmpty)
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.testCases.where((tc) => tc.isHidden).length} hidden test case(s)',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_submissionHistory.isEmpty) {
      return const Center(child: Text('No submissions yet'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_bestSubmission != null)
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Best Submission',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Score: ${_bestSubmission!.scoreText}'),
                  Text(_bestSubmission!.testSummary),
                  Text('Submitted: ${_bestSubmission!.submittedAt}'),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),
        const Text(
          'Submission History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ..._submissionHistory.map(
          (submission) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: submission.isCompleted
                    ? Colors.green
                    : submission.hasError
                    ? Colors.red
                    : Colors.orange,
                child: Text(
                  '${submission.totalScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(submission.testSummary),
              subtitle: Text(
                '${submission.statusText} • ${submission.submittedAt}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: submission.isBestSubmission
                  ? const Icon(Icons.star, color: Colors.amber)
                  : null,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/code-submission-results',
                  arguments: {
                    'submission': submission,
                    'assignment': widget.assignment,
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.code), text: 'Code'),
            Tab(icon: Icon(Icons.science), text: 'Test'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Assignment info bar
          Container(
            padding: const EdgeInsets.all(12),
            color: widget.assignment.isOverdue
                ? Colors.red[50]
                : Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  widget.assignment.isOverdue ? Icons.error : Icons.timer,
                  color: widget.assignment.isOverdue ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.assignment.timeRemainingText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.assignment.isOverdue
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                ),
                Text(
                  '${widget.assignment.points} points',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCodeTab(), _buildTestTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }
}
