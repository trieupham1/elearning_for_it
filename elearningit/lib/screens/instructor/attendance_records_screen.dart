import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  final AttendanceSession session;

  const AttendanceRecordsScreen({super.key, required this.session});

  @override
  State<AttendanceRecordsScreen> createState() =>
      _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final records = await AttendanceService.getSessionRecords(
        widget.session.id,
      );

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading records: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Don't show error message to user if records already loaded
          if (_records.isEmpty) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  Future<void> _markAttendance(
    AttendanceRecord record,
    String newStatus,
  ) async {
    try {
      await AttendanceService.markAttendance(
        sessionId: widget.session.id,
        studentId: record.studentIdString,
        status: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Attendance updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Delay slightly before reloading to prevent race condition
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _loadRecords();
        }
      }
    } catch (e) {
      print('Error marking attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_filterStatus == 'all') return _records;
    return _records.where((r) => r.status == _filterStatus).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      case 'excused':
        return Icons.event_busy;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filterStatus,
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'present', child: Text('Present')),
              const PopupMenuItem(value: 'late', child: Text('Late')),
              const PopupMenuItem(value: 'absent', child: Text('Absent')),
              const PopupMenuItem(value: 'excused', child: Text('Excused')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Session info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, MMM dd, yyyy',
                              ).format(widget.session.sessionDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${DateFormat('h:mm a').format(widget.session.startTime)} - ${DateFormat('h:mm a').format(widget.session.endTime)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.session.attendanceRate}%',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: widget.session.attendanceRate >= 75
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatBox(
                        'Present',
                        widget.session.presentCount.toString(),
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        'Late',
                        widget.session.lateCount.toString(),
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        'Absent',
                        widget.session.absentCount.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // QR Code card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Scan QR Code to Check In',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: widget.session.qrCode,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Session ID: ${widget.session.id}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Records list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text('Error: $_errorMessage'))
                : _filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'all'
                              ? 'No records yet'
                              : 'No $_filterStatus records',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: ListView.builder(
                      itemCount: _filteredRecords.length,
                      itemBuilder: (context, index) {
                        try {
                          final record = _filteredRecords[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(record.status),
                                child: Icon(
                                  _getStatusIcon(record.status),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                record.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (record.studentEmail.isNotEmpty)
                                    Text(record.studentEmail),
                                  if (record.checkInTime != null)
                                    Text(
                                      'Checked in: ${DateFormat('h:mm a').format(record.checkInTime!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) =>
                                    _markAttendance(record, value),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'present',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Present'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'late',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Late'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'absent',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Absent'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'excused',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Excused'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          // Handle any errors in rendering this record
                          print('Error rendering record at index $index: $e');
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            color: Colors.red.shade50,
                            child: ListTile(
                              leading: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                              title: const Text('Error loading student'),
                              subtitle: Text('Index: $index'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
