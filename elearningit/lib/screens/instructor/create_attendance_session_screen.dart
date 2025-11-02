import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';

class CreateAttendanceSessionScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CreateAttendanceSessionScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CreateAttendanceSessionScreen> createState() =>
      _CreateAttendanceSessionScreenState();
}

class _CreateAttendanceSessionScreenState
    extends State<CreateAttendanceSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );

  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = _combineDateAndTime(_selectedDate, _startTime);
    final endDateTime = _combineDateAndTime(_selectedDate, _endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await AttendanceService.createSession(
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sessionDate: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        allowedMethods: ['qr_code'],
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Attendance session created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance Session'),
        actions: [
          if (!_isCreating)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createSession,
              tooltip: 'Create',
            ),
        ],
      ),
      body: _isCreating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Course info
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.courseName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Session Title *',
                        hintText: 'e.g., Lecture 1 - Introduction',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional notes about this session',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),

                    // Date
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(
                          DateFormat(
                            'EEEE, MMMM dd, yyyy',
                          ).format(_selectedDate),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Start time
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Start Time'),
                        subtitle: Text(_startTime.format(context)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectStartTime,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // End time
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled),
                        title: const Text('End Time'),
                        subtitle: Text(_endTime.format(context)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectEndTime,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Attendance Information',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.blue.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• QR code will be generated automatically\n'
                              '• Students can check in during session time\n'
                              '• Late threshold: 15 minutes after start\n'
                              '• You can manually mark attendance anytime',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create button
                    ElevatedButton.icon(
                      onPressed: _createSession,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Create Session'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
