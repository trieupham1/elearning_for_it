// screens/call/video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import '../../models/call.dart';
import '../../models/user.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final Call call;
  final User otherUser;
  final WebRTCService webrtcService;
  final String currentUserId;

  const VideoCallScreen({
    Key? key,
    required this.call,
    required this.otherUser,
    required this.webrtcService,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallService _callService = CallService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeaker = true;
  bool _isScreenSharing = false;
  int _duration = 0;
  Timer? _timer;
  String _connectionStatus = 'Connecting...';
  StreamSubscription? _remoteStreamSubscription;
  StreamSubscription? _connectionStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startTimer();
    _setupListeners();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Set local stream
    if (widget.webrtcService.localStream != null) {
      _localRenderer.srcObject = widget.webrtcService.localStream;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _setupListeners() {
    // Listen to remote stream
    _remoteStreamSubscription = widget.webrtcService.remoteStream.listen((
      stream,
    ) {
      print('📹 Received remote stream');
      _remoteRenderer.srcObject = stream;
      if (mounted) {
        setState(() {});
      }
    });

    // Listen to connection state changes
    _connectionStateSubscription = widget.webrtcService.connectionState.listen((
      state,
    ) {
      print('📹 Video call connection state: $state');
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

  Future<void> _toggleVideo() async {
    try {
      await widget.webrtcService.toggleCamera(_isVideoEnabled);
      setState(() {
        _isVideoEnabled = !_isVideoEnabled;
      });
    } catch (e) {
      print('❌ Error toggling video: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await widget.webrtcService.switchCamera();
    } catch (e) {
      print('❌ Error switching camera: $e');
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

  Future<void> _toggleScreenShare() async {
    try {
      if (_isScreenSharing) {
        await widget.webrtcService.stopScreenShare();
        await _callService.toggleScreenShare(widget.call.id, false);
      } else {
        await widget.webrtcService.startScreenShare();
        await _callService.toggleScreenShare(widget.call.id, true);
      }
      setState(() {
        _isScreenSharing = !_isScreenSharing;
      });
    } catch (e) {
      print('❌ Error toggling screen share: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screen sharing not available: $e'),
          backgroundColor: Colors.orange,
        ),
      );
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
    _remoteStreamSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
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
        body: Stack(
          children: [
            // Remote video (full screen)
            _remoteRenderer.srcObject != null
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue,
                            backgroundImage:
                                widget.otherUser.profilePicture != null
                                ? NetworkImage(widget.otherUser.profilePicture!)
                                : null,
                            child: widget.otherUser.profilePicture == null
                                ? Text(
                                    widget.otherUser.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 20),
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
                            _connectionStatus,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            // Local video (picture-in-picture)
            Positioned(
              top: 60,
              right: 20,
              child: GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _isVideoEnabled && _localRenderer.srcObject != null
                        ? RTCVideoView(
                            _localRenderer,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                            mirror: true,
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

            // Timer
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 20),
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
            ),

            // Controls at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    // First row of controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: 'Mic',
                          onPressed: _toggleMute,
                          isActive: !_isMuted,
                        ),
                        _buildControlButton(
                          icon: _isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label: 'Camera',
                          onPressed: _toggleVideo,
                          isActive: _isVideoEnabled,
                        ),
                        _buildControlButton(
                          icon: Icons.flip_camera_ios,
                          label: 'Switch',
                          onPressed: _switchCamera,
                          isActive: true,
                        ),
                        _buildControlButton(
                          icon: _isSpeaker
                              ? Icons.volume_up
                              : Icons.volume_down,
                          label: 'Speaker',
                          onPressed: _toggleSpeaker,
                          isActive: _isSpeaker,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // End call button
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
            ),
          ],
        ),
      ),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
