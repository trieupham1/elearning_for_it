import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/activity_log.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_drawer.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final AdminService _adminService = AdminService();
  User? _currentUser;
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _selectedAction;
  String? _selectedUserId;
  final int _limit = 20;

  final List<String> _actionTypes = [
    'All',
    'login',
    'logout',
    'course_enrollment',
    'course_completion',
    'assignment_submission',
    'quiz_attempt',
    'profile_update',
    'password_change',
    'account_suspended',
    'account_activated',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      setState(() => _currentUser = user);

      await _loadLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLogs() async {
    try {
      final response = await _adminService.getAllActivityLogs(
        page: _currentPage,
        limit: _limit,
        action: _selectedAction == 'All' ? null : _selectedAction,
        userId: _selectedUserId,
      );

      setState(() {
        _logs = response.logs;
        _totalPages = response.pagination.totalPages;
      });
    } catch (e) {
      debugPrint('Error loading logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: _currentUser != null ? AdminDrawer(currentUser: _currentUser!) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedAction != null || _selectedUserId != null)
                  _buildActiveFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _logs.isEmpty
                        ? const Center(child: Text('No activity logs found'))
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return _buildLogItem(log);
                            },
                          ),
                  ),
                ),
                _buildPagination(),
              ],
            ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Text('Filters: ', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_selectedAction != null && _selectedAction != 'All')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(_selectedAction!),
                onDeleted: () {
                  setState(() {
                    _selectedAction = null;
                    _currentPage = 1;
                  });
                  _loadLogs();
                },
              ),
            ),
          if (_selectedUserId != null)
            Chip(
              label: const Text('Filtered by User'),
              onDeleted: () {
                setState(() {
                  _selectedUserId = null;
                  _currentPage = 1;
                });
                _loadLogs();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogItem(ActivityLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(log.action),
          child: Icon(
            _getActionIcon(log.action),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          log.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (log.user != null)
              Text(
                log.user!.fullName,
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              timeago.format(log.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getActionColor(log.action).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            log.actionDisplayName,
            style: TextStyle(
              fontSize: 11,
              color: _getActionColor(log.action),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Action Type', log.action),
                _buildDetailRow('Timestamp', log.timestamp.toString()),
                if (log.user != null) ...[
                  const Divider(),
                  const Text(
                    'User Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Name', log.user!.fullName),
                  _buildDetailRow('Email', log.user!.email),
                  _buildDetailRow('Role', log.user!.role),
                ],
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Additional Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...log.metadata!.entries.map(
                    (entry) => _buildDetailRow(
                      entry.key,
                      entry.value.toString(),
                    ),
                  ),
                ],
                if (log.ipAddress != null)
                  _buildDetailRow('IP Address', log.ipAddress!),
                if (log.userAgent != null)
                  _buildDetailRow('User Agent', log.userAgent!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage = 1);
                    _loadLogs();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadLogs();
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadLogs();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage = _totalPages);
                    _loadLogs();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activity Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedAction ?? 'All',
              decoration: const InputDecoration(
                labelText: 'Action Type',
                border: OutlineInputBorder(),
              ),
              items: _actionTypes.map((action) {
                return DropdownMenuItem(
                  value: action,
                  child: Text(action),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAction = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAction = null;
                _selectedUserId = null;
                _currentPage = 1;
              });
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Clear Filters'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentPage = 1);
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.grey;
      case 'course_enrollment':
        return Colors.blue;
      case 'course_completion':
        return Colors.purple;
      case 'assignment_submission':
        return Colors.orange;
      case 'quiz_attempt':
        return Colors.teal;
      case 'profile_update':
        return Colors.indigo;
      case 'password_change':
        return Colors.amber;
      case 'account_suspended':
        return Colors.red;
      case 'account_activated':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'course_enrollment':
        return Icons.school;
      case 'course_completion':
        return Icons.check_circle;
      case 'assignment_submission':
        return Icons.assignment_turned_in;
      case 'quiz_attempt':
        return Icons.quiz;
      case 'profile_update':
        return Icons.person;
      case 'password_change':
        return Icons.lock;
      case 'account_suspended':
        return Icons.block;
      case 'account_activated':
        return Icons.check;
      default:
        return Icons.info;
    }
  }
}
