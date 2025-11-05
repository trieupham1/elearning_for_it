// services/call_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user.dart';
import '../models/call.dart';

class CallNotificationService {
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Callback for when user taps on notification
  Function(String callId, String callerId)? onIncomingCallTapped;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permission (Android 13+)
    await Permission.notification.request();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final parts = response.payload!.split('|');
          if (parts.length == 2) {
            final callId = parts[0];
            final callerId = parts[1];
            onIncomingCallTapped?.call(callId, callerId);
          }
        }
      },
    );

    _isInitialized = true;
    print('✅ Call notification service initialized');
  }

  Future<void> showIncomingCallNotification({
    required String callId,
    required User caller,
    required String callType,
  }) async {
    await initialize();

    final callerName = '${caller.firstName} ${caller.lastName}';
    final title = callType == 'video' ? '📹 Incoming Video Call' : '📞 Incoming Voice Call';
    final body = '$callerName is calling you...';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'calls_channel',
      'Calls',
      channelDescription: 'Incoming call notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'answer',
          'Answer',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject',
          'Reject',
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      callId.hashCode,
      title,
      body,
      notificationDetails,
      payload: '$callId|${caller.id}',
    );

    print('✅ Incoming call notification shown for $callerName');
  }

  Future<void> cancelIncomingCallNotification(String callId) async {
    await _notificationsPlugin.cancel(callId.hashCode);
    print('✅ Cancelled incoming call notification for $callId');
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
