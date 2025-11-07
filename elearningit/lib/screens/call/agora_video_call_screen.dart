// screens/call/agora_video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../services/agora_service.dart';
import '../../services/call_service.dart';
import '../../services/socket_service.dart'; // Add this import
import '../../models/user.dart';
import 'dart:async';

class AgoraVideoCallScreen extends StatefulWidget {
  final String channelName;
  final User otherUser;
  final bool isIncoming;
  final String? callId; // Add callId parameter

  const AgoraVideoCallScreen({
    required this.channelName,
    required this.otherUser,
    this.isIncoming = false,
    this.callId, // Optional callId
    Key? key,
  }) : super(key: key);

  @override
  State<AgoraVideoCallScreen> createState() => _AgoraVideoCallScreenState();
}

class _AgoraVideoCallScreenState extends State<AgoraVideoCallScreen> {
  final AgoraService _agoraService = AgoraService();
  int? _remoteUid;
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
      print('🎥 Initializing video call...');

      await _agoraService.initialize();
      await _agoraService.joinVideoChannel(widget.channelName);

      // Listen for remote user
      _agoraService.remoteUid.listen((uid) {
        setState(() {
          _remoteUid = uid;
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          Center(
            child: _remoteUid != null && _agoraService.engine != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _agoraService.engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : _buildWaitingScreen(),
          ),

          // Local video (picture-in-picture)
          if (_agoraService.engine != null)
            Positioned(
              top: 60,
              right: 20,
              child: GestureDetector(
                onTap: () => _agoraService.switchCamera(),
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _agoraService.isVideoEnabled
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _agoraService.engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),

          // Call timer
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 20),
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
          ),

          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
                      label: 'Mic',
                      onPressed: () async {
                        await _agoraService.toggleMicrophone();
                        setState(() {});
                      },
                      isActive: !_agoraService.isMuted,
                    ),
                    _buildControlButton(
                      icon: _agoraService.isVideoEnabled
                          ? Icons.videocam
                          : Icons.videocam_off,
                      label: 'Camera',
                      onPressed: () async {
                        await _agoraService.toggleCamera();
                        setState(() {});
                      },
                      isActive: _agoraService.isVideoEnabled,
                    ),
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Switch',
                      onPressed: () => _agoraService.switchCamera(),
                      isActive: true,
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
                      isActive: _agoraService.isSpeakerOn,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.call_end,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.blue,
          backgroundImage: widget.otherUser.profilePicture != null
              ? NetworkImage(widget.otherUser.profilePicture!)
              : null,
          child: widget.otherUser.profilePicture == null
              ? Text(
                  widget.otherUser.fullName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 48, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(height: 24),
        Text(
          widget.otherUser.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isConnected ? 'Connected' : 'Calling...',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: isActive ? Colors.white : Colors.red,
            size: 28,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white24,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
