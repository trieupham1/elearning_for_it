// screens/call/web_incoming_call_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/socket_service.dart';
import '../../services/call_service.dart';
import 'platform_voice_call_screen.dart';
import 'platform_video_call_screen.dart';

class WebIncomingCallScreen extends StatefulWidget {
  final User caller;
  final String channelName;
  final bool isVideoCall;
  final String? callId; // Add callId parameter

  const WebIncomingCallScreen({
    required this.caller,
    required this.channelName,
    required this.isVideoCall,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  State<WebIncomingCallScreen> createState() => _WebIncomingCallScreenState();
}

class _WebIncomingCallScreenState extends State<WebIncomingCallScreen>
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _acceptCall() {
    _animationController.stop();

    if (widget.isVideoCall) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlatformVideoCallScreen(
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
          builder: (context) => PlatformVoiceCallScreen(
            channelName: widget.channelName,
            otherUser: widget.caller,
            isIncoming: true,
            callId: widget.callId, // Pass callId
          ),
        ),
      );
    }
  }

  void _rejectCall() async {
    _animationController.stop();

    // Notify caller via socket and backend
    final socketService = SocketService();
    final callService = CallService();

    if (widget.callId != null) {
      // Notify via socket immediately
      socketService.notifyCallRejected(widget.callId!, widget.caller.id);

      // Update backend
      try {
        await callService.updateCallStatus(widget.callId!, 'rejected');
        print('✅ Call rejected in backend');
      } catch (e) {
        print('⚠️ Error updating call status: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _getInitials() {
    final firstName = widget.caller.firstName ?? '';
    final lastName = widget.caller.lastName ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }
    return '?';
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
                              _getInitials(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
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
                '${widget.caller.firstName} ${widget.caller.lastName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isVideoCall
                        ? 'Incoming video call'
                        : 'Incoming voice call',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),

              const Spacer(),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          onPressed: _rejectCall,
                          backgroundColor: Colors.red,
                          heroTag: 'reject',
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),

                  // Accept button
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          onPressed: _acceptCall,
                          backgroundColor: Colors.green,
                          heroTag: 'accept',
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
