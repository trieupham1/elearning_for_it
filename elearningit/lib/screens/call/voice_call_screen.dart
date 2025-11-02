// screens/call/voice_call_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/call.dart';
import '../../models/user.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final Call call;
  final User otherUser;
  final WebRTCService webrtcService;
  final String currentUserId;

  const VoiceCallScreen({
    Key? key,
    required this.call,
    required this.otherUser,
    required this.webrtcService,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final CallService _callService = CallService();
  bool _isMuted = false;
  bool _isSpeaker = false;
  int _duration = 0;
  Timer? _timer;
  String _connectionStatus = 'Connecting...';
  StreamSubscription? _connectionStateSubscription;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to connection state changes
    _connectionStateSubscription = widget.webrtcService.connectionState.listen((
      state,
    ) {
      print('📞 Voice call connection state: $state');
      setState(() {
        switch (state) {
          case 'connected':
            _connectionStatus = 'Connected';
            break;
          case 'connecting':
            _connectionStatus = 'Connecting...';
            break;
          case 'disconnected':
            _connectionStatus = 'Disconnected';
            break;
          case 'ended':
          case 'rejected':
            _endCall();
            break;
          default:
            _connectionStatus = state;
        }
      });
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration++;
        });
      }
    });
  }

  Future<void> _toggleMute() async {
    try {
      await widget.webrtcService.toggleMicrophone(_isMuted);
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      print('❌ Error toggling mute: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      widget.webrtcService.enableSpeaker(!_isSpeaker);
      setState(() {
        _isSpeaker = !_isSpeaker;
      });
    } catch (e) {
      print('❌ Error toggling speaker: $e');
    }
  }

  Future<void> _endCall() async {
    _timer?.cancel();

    try {
      // End call via WebRTC
      widget.webrtcService.endCall();

      // Update call status in backend
      await _callService.endCall(widget.call.id);
    } catch (e) {
      print('❌ Error ending call: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header with timer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // User info
              Hero(
                tag: 'caller_avatar_${widget.otherUser.id}',
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.blue,
                  backgroundImage: widget.otherUser.profilePicture != null
                      ? NetworkImage(widget.otherUser.profilePicture!)
                      : null,
                  child: widget.otherUser.profilePicture == null
                      ? Text(
                          widget.otherUser.fullName[0].toUpperCase(),
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

              Text(
                widget.otherUser.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                _connectionStatus,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),

              const Spacer(),

              // Controls
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      onPressed: _toggleMute,
                      color: _isMuted ? Colors.red : Colors.white,
                    ),
                    _buildControlButton(
                      icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      onPressed: _toggleSpeaker,
                      color: _isSpeaker ? Colors.blue : Colors.white,
                    ),
                  ],
                ),
              ),

              // End call button
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: FloatingActionButton(
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.call_end,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.white24,
          heroTag: label,
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
