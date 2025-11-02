import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import 'create_attendance_session_screen.dart';
import 'attendance_records_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const AttendanceScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sessions = await AttendanceService.getCourseSessions(
        widget.courseId,
      );

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _createSession() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAttendanceSessionScreen(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    );

    if (result == true) {
      _loadSessions();
    }
  }

  Future<void> _viewSessionRecords(AttendanceSession session) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceRecordsScreen(session: session),
      ),
    );
  }

  Future<void> _showQRCode(AttendanceSession session) async {
    print('QR Code Data: ${session.qrCode}');
    print('QR Code length: ${session.qrCode.length}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.qrCode.isNotEmpty)
              QrImageView(
                data: session.qrCode,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              )
            else
              const Text(
                'QR code not generated',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            Text(
              'Session: ${DateFormat('MMM dd, yyyy • h:mm a').format(session.startTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              session.isSessionActive
                  ? 'Active - Students can check in'
                  : 'Session not active',
              style: TextStyle(
                color: session.isSessionActive ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSession(AttendanceSession session) async {
    try {
      await AttendanceService.updateSession(
        sessionId: session.id,
        isActive: !session.isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              session.isActive ? '✓ Session closed' : '✓ Session reopened',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadSessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Upcoming':
        return Colors.blue;
      case 'Ended':
        return Colors.grey;
      case 'Closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance - ${widget.courseName}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        icon: const Icon(Icons.add),
        label: const Text('Create Session'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading sessions'),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadSessions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance sessions yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first session to track attendance',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _viewSessionRecords(session),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'EEEE, MMM dd, yyyy',
                                        ).format(session.sessionDate),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${DateFormat('h:mm a').format(session.startTime)} - ${DateFormat('h:mm a').format(session.endTime)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      session.statusText,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        session.statusText,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    session.statusText,
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        session.statusText,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Statistics
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.check_circle,
                                  label: 'Present',
                                  value: session.presentCount.toString(),
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  icon: Icons.schedule,
                                  label: 'Late',
                                  value: session.lateCount.toString(),
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  icon: Icons.cancel,
                                  label: 'Absent',
                                  value: session.absentCount.toString(),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Progress bar
                            LinearProgressIndicator(
                              value: session.attendanceRate / 100,
                              backgroundColor: Colors.grey[300],
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.attendanceRate}% attendance (${session.presentCount + session.lateCount}/${session.totalStudents})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showQRCode(session),
                                    icon: const Icon(Icons.qr_code, size: 20),
                                    label: const Text('Show QR'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _viewSessionRecords(session),
                                    icon: const Icon(Icons.people, size: 20),
                                    label: const Text('Records'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _toggleSession(session),
                                  icon: Icon(
                                    session.isActive
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                  ),
                                  color: session.isActive
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
