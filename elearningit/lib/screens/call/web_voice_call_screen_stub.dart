// Stub for non-web platforms
import 'package:flutter/material.dart';
import '../../models/user.dart';

class WebVoiceCallScreen extends StatelessWidget {
  final String channelName;
  final User otherUser;
  final bool isIncoming;
  final String? callId;

  const WebVoiceCallScreen({
    required this.channelName,
    required this.otherUser,
    this.isIncoming = false,
    this.callId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Web voice call not available on this platform'),
      ),
    );
  }
}
