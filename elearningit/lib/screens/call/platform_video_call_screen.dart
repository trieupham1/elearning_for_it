// screens/call/platform_video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user.dart';
import 'agora_video_call_screen.dart';
// Conditional import for web
import 'web_video_call_screen_stub.dart'
    if (dart.library.html) 'web_video_call_screen.dart';

/// Platform-aware video call screen
/// - Uses Agora on native platforms (Android, iOS, Windows, etc.)
/// - Uses WebRTC on web browsers
class PlatformVideoCallScreen extends StatelessWidget {
  final String channelName;
  final User otherUser;
  final bool isIncoming;
  final String? callId; // Add callId parameter

  const PlatformVideoCallScreen({
    required this.channelName,
    required this.otherUser,
    this.isIncoming = false,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      print('🌐 Loading web video call screen');
      return WebVideoCallScreen(
        channelName: channelName,
        otherUser: otherUser,
        isIncoming: isIncoming,
        callId: callId, // Pass callId
      );
    } else {
      print('📱 Loading Agora video call screen');
      return AgoraVideoCallScreen(
        channelName: channelName,
        otherUser: otherUser,
        isIncoming: isIncoming,
        callId: callId, // Pass callId
      );
    }
  }
}
