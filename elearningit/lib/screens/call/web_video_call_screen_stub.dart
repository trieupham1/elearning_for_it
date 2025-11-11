// Stub for non-web platforms
import 'package:flutter/material.dart';
import '../../models/user.dart';

class WebVideoCallScreen extends StatelessWidget {
  final String channelName;
  final User otherUser;
  final bool isIncoming;
  final String? callId;

  const WebVideoCallScreen({
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
        child: Text('Web video call not available on this platform'),
      ),
    );
  }
}
