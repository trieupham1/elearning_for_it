import 'package:flutter/material.dart';
import '../../models/code_assignment.dart';
import '../../services/code_assignment_service.dart';

class CreateCodeAssignmentScreen extends StatefulWidget {
  final String courseId;

  const CreateCodeAssignmentScreen({Key? key, required this.courseId})
    : super(key: key);

  @override
  State<CreateCodeAssignmentScreen> createState() =>
      _CreateCodeAssignmentScreenState();
}

class _CreateCodeAssignmentScreenState
    extends State<CreateCodeAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CodeAssignmentService _service = CodeAssignmentService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _starterCodeController = TextEditingController();
  final _solutionCodeController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');

  String _selectedLanguage = 'python';
  DateTime? _deadline;
  List<TestCaseInput> _testCases = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _starterCodeController.text = _getDefaultCode(_selectedLanguage);
    // Add one default test case
    _testCases.add(TestCaseInput());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _starterCodeController.dispose();
    _solutionCodeController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

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

  void _addTestCase() {
    setState(() {
      _testCases.add(TestCaseInput());
    });
  }

  void _removeTestCase(int index) {
    setState(() {
      _testCases.removeAt(index);
    });
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      if (time != null) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_testCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one test case'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate all test cases
    for (var tc in _testCases) {
      if (!tc.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all test case fields'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      await _service.createAssignment(
        courseId: widget.courseId,
        title: _titleController.text,
        description: _descriptionController.text,
        language: _selectedLanguage,
        deadline: _deadline!,
        starterCode: _starterCodeController.text.isEmpty
            ? null
            : _starterCodeController.text,
        solutionCode: _solutionCodeController.text.isEmpty
            ? null
            : _solutionCodeController.text,
        testCases: _testCases.map((tc) => tc.toJson()).toList(),
        points: int.tryParse(_pointsController.text) ?? 100,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code assignment created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create assignment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Code Assignment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Language selector
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Programming Language',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              items: ProgrammingLanguage.allLanguages.map((lang) {
                return DropdownMenuItem(
                  value: lang.key,
                  child: Text(lang.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                    if (_starterCodeController.text ==
                        _getDefaultCode(_selectedLanguage)) {
                      _starterCodeController.text = _getDefaultCode(value);
                    }
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Points and deadline
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.stars),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDeadline,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _deadline == null
                          ? 'Set Deadline'
                          : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Starter code
            const Text(
              'Starter Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _starterCodeController,
                decoration: const InputDecoration(
                  hintText: 'Code that students will start with...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Solution code
            const Text(
              'Solution Code (Hidden from students)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _solutionCodeController,
                decoration: const InputDecoration(
                  hintText: 'Your solution code...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Test cases header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Test Cases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addTestCase,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Test'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Test cases list
            ..._testCases.asMap().entries.map((entry) {
              final index = entry.key;
              final testCase = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Test Case ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_testCases.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeTestCase(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Test Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) => testCase.name = value,
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Input',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        onChanged: (value) => testCase.input = value,
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Expected Output',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        onChanged: (value) => testCase.expectedOutput = value,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Weight',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) =>
                                  testCase.weight = int.tryParse(value) ?? 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Hidden',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: testCase.isHidden,
                              onChanged: (value) {
                                setState(() {
                                  testCase.isHidden = value ?? false;
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Create button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Assignment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class TestCaseInput {
  String name = '';
  String input = '';
  String expectedOutput = '';
  int weight = 1;
  bool isHidden = false;

  bool isValid() {
    return name.isNotEmpty && input.isNotEmpty && expectedOutput.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'input': input,
      'expectedOutput': expectedOutput,
      'weight': weight,
      'isHidden': isHidden,
    };
  }
}
