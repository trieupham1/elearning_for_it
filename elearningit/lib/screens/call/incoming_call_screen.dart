// screens/call/incoming_call_screen.dart
import 'package:flutter/material.dart';
import '../../models/call.dart';
import '../../models/user.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_service.dart';
import '../../config/api_config.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final Call call;
  final User caller;
  final WebRTCService webrtcService;
  final String currentUserId;
  final dynamic offer; // WebRTC offer

  const IncomingCallScreen({
    Key? key,
    required this.call,
    required this.caller,
    required this.webrtcService,
    required this.currentUserId,
    required this.offer,
  }) : super(key: key);

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final CallService _callService = CallService();
  bool _isProcessing = false;

  String? get _profileImageUrl {
    if (widget.caller.profilePicture == null || 
        widget.caller.profilePicture!.isEmpty) {
      return null;
    }
    
    final pic = widget.caller.profilePicture!;
    // If it's already a full URL, return it
    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      return pic;
    }
    // Otherwise, construct full URL
    return '${ApiConfig.baseUrl}${pic.startsWith('/') ? '' : '/'}$pic';
  }

  @override
  void initState() {
    super.initState();
    // Debug log caller information
    print('🔍 IncomingCallScreen - Caller Info:');
    print('   ID: ${widget.caller.id}');
    print('   Name: ${widget.caller.fullName}');
    print('   Username: ${widget.caller.username}');
    print('   Profile Picture Raw: ${widget.caller.profilePicture}');
    print('   Profile Picture URL: $_profileImageUrl');
    print('   Offer available: ${widget.offer != null}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during incoming call
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Call type indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.call.isVideoCall ? Icons.videocam : Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.call.isVideoCall ? 'Video Call' : 'Voice Call',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Caller avatar
              Hero(
                tag: 'caller_avatar_${widget.caller.id}',
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.blue,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  onBackgroundImageError: _profileImageUrl != null
                      ? (exception, stackTrace) {
                          print('❌ Error loading profile image: $exception');
                        }
                      : null,
                  child: _profileImageUrl == null
                      ? Text(
                          widget.caller.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 12),

              // Incoming call text
              const Text(
                'Incoming call...',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),

              const Spacer(),

              // Accept/Reject buttons
              if (!_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 60,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reject button
                      _buildActionButton(
                        icon: Icons.call_end,
                        label: 'Reject',
                        color: Colors.red,
                        onPressed: _rejectCall,
                      ),

                      // Accept button
                      _buildActionButton(
                        icon: widget.call.isVideoCall
                            ? Icons.videocam
                            : Icons.phone,
                        label: 'Accept',
                        color: Colors.green,
                        onPressed: _acceptCall,
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          heroTag: label,
          child: Icon(icon, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print('📞 Accepting call: ${widget.call.id}');

      // Update call status to accepted
      await _callService.updateCallStatus(widget.call.id, 'accepted');

      // Answer the call via WebRTC - THIS IS CRITICAL!
      print('📞 Calling answerCall with offer: ${widget.offer != null}');
      await widget.webrtcService.answerCall(
        widget.call.id,
        widget.caller.id,
        widget.offer,
      );
      print('✅ answerCall completed');

      // Navigate to appropriate call screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => widget.call.isVideoCall
                ? VideoCallScreen(
                    call: widget.call,
                    otherUser: widget.caller,
                    webrtcService: widget.webrtcService,
                    currentUserId: widget.currentUserId,
                  )
                : VoiceCallScreen(
                    call: widget.call,
                    otherUser: widget.caller,
                    webrtcService: widget.webrtcService,
                    currentUserId: widget.currentUserId,
                  ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print('📞 Rejecting call: ${widget.call.id}');

      // Update call status to rejected
      await _callService.updateCallStatus(widget.call.id, 'rejected');

      // Reject via WebRTC (requires callId and callerId)
      widget.webrtcService.rejectCall(widget.call.id, widget.caller.id);

      // Close the screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error rejecting call: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
