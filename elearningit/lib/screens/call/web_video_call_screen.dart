// screens/call/web_video_call_screen.dart
// Copied exact pattern from course_video_call for proper video containment
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/agora_web_service.dart';
import '../../services/unified_agora_service.dart';
import '../../services/call_service.dart';
import '../../services/socket_service.dart';
import '../../models/user.dart';
import 'dart:async';
// Conditional imports for web
import 'dart:html' as html show DivElement;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart' show HtmlElementView;

class WebVideoCallScreen extends StatefulWidget {
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
  State<WebVideoCallScreen> createState() => _WebVideoCallScreenState();
}

class _WebVideoCallScreenState extends State<WebVideoCallScreen> {
  AgoraWebService? _webService;
  UnifiedAgoraService? _nativeService;

  Timer? _callTimer;
  int _seconds = 0;
  bool _isConnected = false;
  bool _isLoading = true;
  int? _remoteUid;

  bool _isMuted = false;
  bool _isVideoEnabled = true;

  // Stream subscriptions for cleanup
  StreamSubscription? _remoteUidSubscription;
  StreamSubscription? _connectionStateSubscription;

  // HTML element view IDs - EXACT same pattern as course_video_call
  final Map<int, String> _remoteVideoViewIds = {};
  static const String _localVideoViewId = 'call-local-video-view';
  bool _localVideoRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerLocalVideoView();
    }
    _initializeCall();
  }

  // EXACT same as course_video_call
  void _registerLocalVideoView() {
    if (_localVideoRegistered) return;

    ui_web.platformViewRegistry.registerViewFactory(_localVideoViewId, (int viewId) {
      final element = html.DivElement()
        ..id = 'local-video-container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return element;
    });

    _localVideoRegistered = true;
  }

  // EXACT same as course_video_call
  void _registerRemoteVideoView(int uid) {
    final viewId = 'call-remote-video-$uid';
    if (_remoteVideoViewIds.containsKey(uid)) return;

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final element = html.DivElement()
        ..id = 'remote-video-container-$uid'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return element;
    });

    _remoteVideoViewIds[uid] = viewId;
  }

  Future<void> _initializeCall() async {
    try {
      print('🎫 Requesting Agora token for channel: ${widget.channelName}');
      final callService = CallService();
      final tokenData = await callService.generateAgoraToken(
        channelName: widget.channelName,
        uid: 0,
        role: 'publisher',
      );
      final agoraToken = tokenData['token'] as String;
      print('✅ Received Agora token');

      if (kIsWeb) {
        print('WEB: Initializing Agora Web SDK for video call...');
        _webService = AgoraWebService();
        await _webService!.initialize();
        await _webService!.joinVideoChannel(
          widget.channelName,
          token: agoraToken,
        );

        if (mounted) {
          setState(() {
            _isConnected = true;
            _isLoading = false;
            _isMuted = _webService?.isMuted ?? false;
            _isVideoEnabled = _webService?.isVideoEnabled ?? true;
          });
          _startTimer();
        }

        // Play local video
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_webService != null) {
            _webService!.playLocalVideo('local-video-container');
            print('📹 Local video started playing');
          }
        });

        // Listen for remote user joining - EXACT same pattern as course_video_call
        _remoteUidSubscription = _webService!.remoteUid.listen((uid) {
          print('👥 Remote user joined with uid: $uid');
          if (mounted && _remoteUid == null) {
            _registerRemoteVideoView(uid);
            setState(() {
              _remoteUid = uid;
            });
            // Play remote video when user joins
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_webService != null && _remoteUid != null) {
                _webService!.playRemoteVideo(_remoteUid!, 'remote-video-container-$_remoteUid');
                print('📹 Remote video started playing');
              }
            });
          }
        });

        _connectionStateSubscription = _webService!.connectionState.listen((state) {
          if (state == 'ended' && mounted) {
            _endCall();
          }
        });
      } else {
        print('NATIVE: Initializing Agora Native SDK for video call...');
        _nativeService = UnifiedAgoraService();
        await _nativeService!.initialize();
        await _nativeService!.joinVideoChannel(
          widget.channelName,
          token: agoraToken,
        );

        if (mounted) {
          setState(() {
            _isConnected = true;
            _isLoading = false;
          });
          _startTimer();
        }

        _remoteUidSubscription = _nativeService!.remoteUid.listen((uid) {
          print('👥 Remote user joined with uid: $uid');
          if (mounted) {
            setState(() {
              _remoteUid = uid;
            });
          }
        });

        _connectionStateSubscription = _nativeService!.connectionState.listen((state) {
          if (state == 'ended' && mounted) {
            _endCall();
          }
        });
      }
    } catch (e) {
      print('❌ Error initializing video call: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start video call: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    final socketService = SocketService();
    final callService = CallService();

    if (widget.callId != null) {
      socketService.notifyCallEnded(widget.callId!, widget.otherUser.id);
      try {
        await callService.endCall(widget.callId!, duration: _seconds);
      } catch (e) {
        print('⚠️ Error notifying backend: $e');
      }
    }

    if (kIsWeb) {
      await _webService?.leaveChannel();
    } else {
      await _nativeService?.leaveChannel();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleMicrophone() async {
    if (kIsWeb) {
      await _webService?.toggleMicrophone();
      setState(() {
        _isMuted = _webService?.isMuted ?? false;
      });
    } else {
      await _nativeService?.toggleMicrophone();
      setState(() {
        _isMuted = _nativeService?.isMuted ?? false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (kIsWeb) {
      await _webService?.toggleCamera();
      setState(() {
        _isVideoEnabled = _webService?.isVideoEnabled ?? true;
      });
    } else {
      await _nativeService?.toggleCamera();
      setState(() {
        _isVideoEnabled = _nativeService?.isVideoEnabled ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call with ${widget.otherUser.fullName}'),
        backgroundColor: Colors.black87,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_seconds),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // Video grid - EXACT same pattern as course_video_call
                _buildVideoGrid(),
                
                // Controls at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildControls(),
                ),
              ],
            ),
    );
  }

  // EXACT same pattern as course_video_call _buildVideoGrid
  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLocalVideoCard();
        } else {
          return _buildRemoteVideo();
        }
      },
    );
  }

  // EXACT same pattern as course_video_call _buildLocalVideoCard
  Widget _buildLocalVideoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _isVideoEnabled
                ? const HtmlElementView(viewType: _localVideoViewId)
                : Container(
                    color: Colors.grey[850],
                    child: const Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue,
                        child: Text(
                          'Y',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          // Name label at bottom
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Mute indicator
          if (_isMuted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_off,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // EXACT same pattern as course_video_call _buildRemoteVideo
  Widget _buildRemoteVideo() {
    final userName = widget.otherUser.fullName;
    final viewId = _remoteUid != null ? _remoteVideoViewIds[_remoteUid] : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: viewId != null
                ? HtmlElementView(viewType: viewId)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[700],
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isConnected ? 'Connecting video...' : 'Calling...',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onPressed: _toggleMicrophone,
            isActive: !_isMuted,
          ),
          const SizedBox(width: 24),
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: _isVideoEnabled ? 'Stop Video' : 'Start Video',
            onPressed: _toggleCamera,
            isActive: _isVideoEnabled,
          ),
          const SizedBox(width: 24),
          _buildEndCallButton(),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive ? Colors.grey[700] : Colors.red,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.red,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _endCall,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: const Icon(Icons.call_end, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('End', style: TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _remoteUidSubscription?.cancel();
    _connectionStateSubscription?.cancel();

    if (kIsWeb) {
      _webService?.dispose();
    } else {
      _nativeService?.dispose();
    }

    super.dispose();
  }
}
