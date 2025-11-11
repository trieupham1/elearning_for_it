// Stub for non-web platforms
import 'package:flutter/material.dart';
import '../../models/user.dart';

class WebIncomingCallScreen extends StatelessWidget {
  final User caller;
  final String channelName;
  final bool isVideoCall;
  final String? callId;

  const WebIncomingCallScreen({
    required this.caller,
    required this.channelName,
    required this.isVideoCall,
    this.callId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Web incoming call not available on this platform'),
      ),
    );
  }
}
