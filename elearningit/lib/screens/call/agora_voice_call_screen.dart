// screens/call/agora_voice_call_screen.dart
import 'package:flutter/material.dart';
import '../../services/agora_service.dart';
import '../../services/call_service.dart';
import '../../services/socket_service.dart'; // Add this import
import '../../models/user.dart';
import 'dart:async';

class AgoraVoiceCallScreen extends StatefulWidget {
  final String channelName;
  final User otherUser;
  final bool isIncoming;
  final String? callId; // Add callId parameter

  const AgoraVoiceCallScreen({
    required this.channelName,
    required this.otherUser,
    this.isIncoming = false,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  State<AgoraVoiceCallScreen> createState() => _AgoraVoiceCallScreenState();
}

class _AgoraVoiceCallScreenState extends State<AgoraVoiceCallScreen> {
  final AgoraService _agoraService = AgoraService();
  Timer? _callTimer;
  int _seconds = 0;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      print('📞 Initializing voice call...');

      await _agoraService.initialize();
      await _agoraService.joinVoiceChannel(widget.channelName);

      // Listen for remote user
      _agoraService.remoteUid.listen((uid) {
        setState(() {
          _isConnected = true;
        });
        _startTimer();
      });

      // Listen for connection state
      _agoraService.connectionState.listen((state) {
        if (state == 'ended') {
          _endCall();
        }
      });
    } catch (e) {
      print('❌ Error initializing call: $e');
      _showError('Failed to start call: $e');
    }
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();

    // Notify other user via socket that call ended
    if (widget.callId != null) {
      final socketService = SocketService();
      socketService.notifyCallEnded(widget.callId!, widget.otherUser.id);
    }

    // Notify backend that call ended
    if (widget.callId != null) {
      try {
        final callService = CallService();
        await callService.endCall(widget.callId!);
        print('✅ Backend notified: Call ${widget.callId} ended');
      } catch (e) {
        print('⚠️ Error notifying backend: $e');
      }
    }

    await _agoraService.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Call timer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_seconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // User avatar and info
              CircleAvatar(
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
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                widget.otherUser.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConnected ? 'Connected' : 'Calling...',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const Spacer(),

              // Control buttons
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
                      label: _agoraService.isMuted ? 'Unmute' : 'Mute',
                      onPressed: () async {
                        await _agoraService.toggleMicrophone();
                        setState(() {});
                      },
                      color: _agoraService.isMuted ? Colors.red : Colors.white,
                    ),
                    _buildControlButton(
                      icon: _agoraService.isSpeakerOn
                          ? Icons.volume_up
                          : Icons.volume_down,
                      label: 'Speaker',
                      onPressed: () async {
                        await _agoraService.toggleSpeaker();
                        setState(() {});
                      },
                      color: _agoraService.isSpeakerOn
                          ? Colors.blue
                          : Colors.white,
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

  @override
  void dispose() {
    _callTimer?.cancel();
    _agoraService.dispose();
    super.dispose();
  }
}
