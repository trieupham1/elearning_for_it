// screens/call/platform_voice_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user.dart';
import 'agora_voice_call_screen.dart';
// Conditional import for web
import 'web_voice_call_screen_stub.dart'
    if (dart.library.html) 'web_voice_call_screen.dart';

/// Platform-aware voice call screen
/// - Uses Agora on native platforms (Android, iOS, Windows, etc.)
/// - Uses WebRTC on web browsers
class PlatformVoiceCallScreen extends StatelessWidget {
  final String channelName;
  final User otherUser;
  final bool isIncoming;
  final String? callId; // Add callId parameter

  const PlatformVoiceCallScreen({
    required this.channelName,
    required this.otherUser,
    this.isIncoming = false,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      print('🌐 Loading web voice call screen');
      return WebVoiceCallScreen(
        channelName: channelName,
        otherUser: otherUser,
        isIncoming: isIncoming,
        callId: callId, // Pass callId
      );
    } else {
      print('📱 Loading Agora voice call screen');
      return AgoraVoiceCallScreen(
        channelName: channelName,
        otherUser: otherUser,
        isIncoming: isIncoming,
        callId: callId, // Pass callId
      );
    }
  }
}
