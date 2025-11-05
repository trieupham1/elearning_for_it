import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/webrtc_service.dart';
import '../services/call_notification_service.dart';
import '../models/user.dart';
import '../models/call.dart';
import '../screens/instructor_dashboard.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/call/incoming_call_screen.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  final _webrtcService = WebRTCService();
  final _callNotificationService = CallNotificationService();
  User? _currentUser;
  int _unreadCount = 0;
  StreamSubscription? _incomingCallSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
    _initializeWebRTC(); // ⬅️ Initialize WebRTC for incoming calls
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    super.dispose();
  }

  // ⬅️ NEW METHOD: Initialize WebRTC socket connection
  Future<void> _initializeWebRTC() async {
    try {
      // Get current user
      final user = await _authService.getCurrentUser();
      if (user == null) {
        print('❌ Cannot initialize WebRTC: No user');
        return;
      }

      final userId = user.id;
      print('🔌 Initializing WebRTC for instructor: $userId');
      
      // Initialize WebRTC socket
      await _webrtcService.initializeSocket(userId);
      
      // Initialize notification service
      await _callNotificationService.initialize();
      
      print('✅ WebRTC socket initialized successfully');

      // Listen for incoming calls
      _incomingCallSubscription = _webrtcService.incomingCalls.listen(
        (incomingCall) async {
          print('🔔 INCOMING CALL from: ${incomingCall.callerName}');
          
          try {
            // Create User object from incoming call data
            final caller = User(
              id: incomingCall.callerId,
              firstName: incomingCall.callerName.split(' ').first,
              lastName: incomingCall.callerName.split(' ').length > 1
                  ? incomingCall.callerName.split(' ').sublist(1).join(' ')
                  : '',
              username: incomingCall.callerUsername ?? incomingCall.callerId,
              email: '${incomingCall.callerId}@example.com',
              role: 'student',
              profilePicture: incomingCall.callerAvatar,
            );

            final calleeUser = User(
              id: userId,
              firstName: user.firstName,
              lastName: user.lastName,
              username: user.username,
              email: user.email,
              role: user.role,
            );

            print('✅ Caller info: ${caller.firstName} ${caller.lastName} (@${caller.username})');

            // Show notification
            await _callNotificationService.showIncomingCallNotification(
              callId: incomingCall.callId,
              caller: caller,
              callType: incomingCall.callType,
            );

            // Create Call object
            final call = Call(
              id: incomingCall.callId,
              caller: caller,
              callee: calleeUser,
              type: incomingCall.callType,
              status: 'initiated',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            // Navigate to incoming call screen (only if app is in foreground)
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncomingCallScreen(
                    call: call,
                    caller: caller,
                    webrtcService: _webrtcService,
                    currentUserId: userId,
                    offer: incomingCall.offer, // Pass the WebRTC offer
                  ),
                ),
              );
            }
          } catch (e) {
            print('❌ Error handling incoming call: $e');
          }
        },
      );
    } catch (e) {
      print('❌ Error initializing WebRTC: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      // Load current user
      _currentUser = await _authService.getCurrentUser();
      setState(() {});
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Notification icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  // Reload unread count when returning from notifications screen
                  _loadUnreadCount();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Profile icon
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: _currentUser?.profilePicture != null
                  ? NetworkImage(_currentUser!.profilePicture!)
                  : null,
              child: _currentUser?.profilePicture == null
                  ? Text(
                      _currentUser?.username.substring(0, 2).toUpperCase() ??
                          'I',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: const InstructorDashboard(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.fullName ?? 'Loading...'),
            accountEmail: Text(_currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _currentUser?.username.substring(0, 2).toUpperCase() ?? 'I',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('Notifications'),
            trailing: _unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _loadUnreadCount();
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/messages');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
