import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/course_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  final _courseService = CourseService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotifications(
        unreadOnly: false,
      );

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error marking as read: $e')));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }

  Future<void> _handleCourseInvitation(
    NotificationModel notification,
    bool accept,
  ) async {
    try {
      await _notificationService.respondToCourseInvitation(
        notificationId: notification.id,
        accept: accept,
      );

      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Course invitation accepted!'
                  : 'Course invitation declined',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleJoinRequest(
    NotificationModel notification,
    bool approve,
  ) async {
    try {
      final courseId = notification.data?['courseId'];
      if (courseId == null) {
        throw Exception('Course ID not found in notification');
      }

      // Call backend to approve/decline join request
      await _notificationService.respondToJoinRequest(
        courseId: courseId,
        notificationId: notification.id,
        approve: approve,
      );

      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Join request approved!' : 'Join request declined',
            ),
            backgroundColor: approve ? Colors.green : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleTeacherInvitation(
    NotificationModel notification,
    bool accept,
  ) async {
    try {
      final courseId = notification.data?['courseId'];
      if (courseId == null) {
        throw Exception('Course ID not found in notification');
      }

      await _courseService.respondToTeacherInvite(
        courseId: courseId,
        notificationId: notification.id,
        accept: accept,
      );

      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Course assignment accepted! You are now the instructor.'
                  : 'Course assignment declined',
            ),
            backgroundColor: accept ? Colors.green : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_filter == 'all') return _notifications;
    if (_filter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    if (_filter == 'read') {
      return _notifications.where((n) => n.isRead).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _notifications.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Unread',
                  'unread',
                  _notifications.where((n) => !n.isRead).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Read',
                  'read',
                  _notifications.where((n) => n.isRead).length,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _filteredNotifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (animValue * 0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Colors.white.withOpacity(0.9)
                          : Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filter = value;
                });
              },
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final color = Color(
      int.parse(notification.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset((1 - animValue) * 50, 0),
          child: Opacity(
            opacity: animValue,
            child: Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.redAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onDismissed: (direction) {
                _deleteNotification(notification.id);
              },
              child: InkWell(
                onTap: () {
                  _markAsRead(notification);
                },
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: notification.isRead ? 1 : 4,
                  shadowColor: notification.isRead ? null : color.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: notification.isRead 
                        ? Colors.transparent 
                        : color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Container(
                      decoration: BoxDecoration(
                        gradient: !notification.isRead ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.03),
                            Colors.transparent,
                          ],
                        ) : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(_getIconData(notification.iconName), color: color, size: 26),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.blue, Colors.lightBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                const SizedBox(height: 4),
                Text(notification.message),
                const SizedBox(height: 4),
                Text(
                  timeago.format(notification.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                // Course invitation action buttons (for students)
                if (notification.type == 'course_invite' &&
                    !notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _handleCourseInvitation(notification, true),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _handleCourseInvitation(notification, false),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Teacher invitation action buttons (for instructors)
                if (notification.type == 'teacher_invite' &&
                    !notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _handleTeacherInvitation(notification, true),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _handleTeacherInvitation(notification, false),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Course join request action buttons (for instructors)
                if (notification.type == 'course_join_request' &&
                    !notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _handleJoinRequest(notification, true),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _handleJoinRequest(notification, false),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: !notification.isRead
                          ? IconButton(
                              icon: const Icon(Icons.mark_email_read, size: 20),
                              onPressed: () => _markAsRead(notification),
                              tooltip: 'Mark as read',
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'assignment':
        return Icons.assignment;
      case 'folder':
        return Icons.folder;
      case 'quiz':
        return Icons.quiz;
      case 'forum':
        return Icons.forum;
      case 'campaign':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}
