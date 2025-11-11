// screens/call/platform_incoming_call_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'agora_incoming_call_screen.dart';
// Conditional import for web
import 'web_incoming_call_screen_stub.dart'
    if (dart.library.html) 'web_incoming_call_screen.dart';

class PlatformIncomingCallScreen extends StatelessWidget {
  final User caller;
  final String channelName;
  final bool isVideoCall;
  final String? callId; // Add callId parameter

  const PlatformIncomingCallScreen({
    required this.caller,
    required this.channelName,
    required this.isVideoCall,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebIncomingCallScreen(
        caller: caller,
        channelName: channelName,
        isVideoCall: isVideoCall,
        callId: callId, // Pass callId
      );
    } else {
      return AgoraIncomingCallScreen(
        caller: caller,
        channelName: channelName,
        isVideoCall: isVideoCall,
        callId: callId, // Pass callId
      );
    }
  }
}
