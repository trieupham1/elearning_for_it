// screens/call/agora_incoming_call_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'agora_voice_call_screen.dart';
import 'agora_video_call_screen.dart';

class AgoraIncomingCallScreen extends StatefulWidget {
  final User caller;
  final String channelName;
  final bool isVideoCall;
  final String? callId; // Add callId parameter

  const AgoraIncomingCallScreen({
    required this.caller,
    required this.channelName,
    required this.isVideoCall,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  State<AgoraIncomingCallScreen> createState() =>
      _AgoraIncomingCallScreenState();
}

class _AgoraIncomingCallScreenState extends State<AgoraIncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _acceptCall() {
    _animationController.stop();

    if (widget.isVideoCall) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraVideoCallScreen(
            channelName: widget.channelName,
            otherUser: widget.caller,
            isIncoming: true,
            callId: widget.callId, // Pass callId
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraVoiceCallScreen(
            channelName: widget.channelName,
            otherUser: widget.caller,
            isIncoming: true,
            callId: widget.callId, // Pass callId
          ),
        ),
      );
    }
  }

  void _rejectCall() {
    _animationController.stop();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated avatar
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 160 + (_animationController.value * 20),
                    height: 160 + (_animationController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20 + (_animationController.value * 20),
                          spreadRadius: 5 + (_animationController.value * 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.blue,
                      backgroundImage: widget.caller.profilePicture != null
                          ? NetworkImage(widget.caller.profilePicture!)
                          : null,
                      child: widget.caller.profilePicture == null
                          ? Text(
                              widget.caller.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 56,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Caller name
              Text(
                widget.caller.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Call type
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isVideoCall ? Icons.videocam : Icons.phone,
                    color: Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isVideoCall
                        ? 'Incoming Video Call...'
                        : 'Incoming Voice Call...',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject button
                    Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'reject',
                          onPressed: _rejectCall,
                          backgroundColor: Colors.red,
                          child: const Icon(
                            Icons.call_end,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Decline',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),

                    // Accept button
                    Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'accept',
                          onPressed: _acceptCall,
                          backgroundColor: Colors.green,
                          child: Icon(
                            widget.isVideoCall ? Icons.videocam : Icons.phone,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
