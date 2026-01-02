// screens/call/web_video_call_screen.dart
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
  // Use different service based on platform
  AgoraWebService? _webService;
  UnifiedAgoraService? _nativeService;

  Timer? _callTimer;
  int _seconds = 0;
  bool _isConnected = false;
  int? _remoteUid;

  // Stream subscriptions for cleanup
  StreamSubscription? _remoteUidSubscription;
  StreamSubscription? _connectionStateSubscription;

  // HTML element view IDs for web video rendering
  static const String _remoteVideoViewId = 'remote-video-view';
  static const String _localVideoViewId = 'local-video-view';
  bool _videoElementsRegistered = false;

  bool get _isMuted => kIsWeb
      ? (_webService?.isMuted ?? false)
      : (_nativeService?.isMuted ?? false);

  bool get _isCameraOff => kIsWeb
      ? !(_webService?.isVideoEnabled ?? true)
      : !(_nativeService?.isVideoEnabled ?? true);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerVideoViews();
    }
    _initializeCall();
  }

  // Register HTML elements for video rendering on web
  void _registerVideoViews() {
    if (_videoElementsRegistered || !kIsWeb) return;

    // Register remote video view
    ui_web.platformViewRegistry.registerViewFactory(_remoteVideoViewId, (
      int viewId,
    ) {
      final element = html.DivElement()
        ..id = 'remote-video-container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.pointerEvents = 'none'; // Don't block clicks
      return element;
    });

    // Register local video view
    ui_web.platformViewRegistry.registerViewFactory(_localVideoViewId, (
      int viewId,
    ) {
      final element = html.DivElement()
        ..id = 'local-video-container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.pointerEvents = 'none'; // Don't block clicks
      return element;
    });

    _videoElementsRegistered = true;
    print('✅ Video view elements registered');
  }

  Future<void> _initializeCall() async {
    try {
      // Step 1: Generate Agora token from backend
      print('🎫 Requesting Agora token for channel: ${widget.channelName}');
      final callService = CallService();
      final tokenData = await callService.generateAgoraToken(
        channelName: widget.channelName,
        uid: 0,
        role: 'publisher',
      );
      final agoraToken = tokenData['token'] as String;
      print('✅ Received Agora token');

      // Step 2: Join channel with token
      if (kIsWeb) {
        print('WEB: Initializing Agora Web SDK for video call...');
        _webService = AgoraWebService();
        await _webService!.initialize();
        await _webService!.joinVideoChannel(
          widget.channelName,
          token: agoraToken,
        );

        // Set connected immediately after joining (we're in the call)
        if (mounted) {
          setState(() {
            _isConnected = true;
          });
          _startTimer();
        }

        // Play local video immediately
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_webService != null) {
            _webService!.playLocalVideo('local-video-container');
            print('📹 Local video started playing');
          }
        });

        // Listen for remote user joining
        _remoteUidSubscription = _webService!.remoteUid.listen((uid) {
          print('👥 Remote user joined with uid: $uid');
          if (mounted) {
            setState(() {
              _remoteUid = uid;
            });
            // Play remote video when user joins
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_webService != null && _remoteUid != null) {
                _webService!.playRemoteVideo(_remoteUid!, 'remote-video-container');
                print('📹 Remote video started playing');
              }
            });
          }
        });

        _connectionStateSubscription = _webService!.connectionState.listen((
          state,
        ) {
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

        // Set connected immediately after joining (we're in the call)
        if (mounted) {
          setState(() {
            _isConnected = true;
          });
          _startTimer();
        }

        // Listen for remote user joining
        _remoteUidSubscription = _nativeService!.remoteUid.listen((uid) {
          print('👥 Remote user joined with uid: $uid');
          if (mounted) {
            setState(() {
              _remoteUid = uid;
            });
          }
        });

        _connectionStateSubscription = _nativeService!.connectionState.listen((
          state,
        ) {
          if (state == 'ended' && mounted) {
            _endCall();
          }
        });
      }
    } catch (e) {
      print('❌ Error initializing video call: $e');
      _showError('Failed to start video call: $e');
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _endCall() async {
    final socketService = SocketService();
    final callService = CallService();

    // Notify other user via socket
    if (widget.callId != null) {
      socketService.notifyCallEnded(widget.callId!, widget.otherUser.id);
      print('📤 Socket event sent: call_ended');
    }

    // Update backend with call duration
    if (widget.callId != null) {
      try {
        await callService.endCall(widget.callId!, duration: _seconds);
        print(
          '✅ Backend notified: Call ${widget.callId} ended (duration: $_seconds seconds)',
        );
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
    } else {
      await _nativeService?.toggleMicrophone();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleCamera() async {
    if (kIsWeb) {
      await _webService?.toggleCamera();
      // Force UI rebuild to reflect camera state change
      if (mounted) {
        setState(() {});
      }
    } else {
      await _nativeService?.toggleCamera();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Column layout to avoid HtmlElementView z-index issues on web
    // Video area and controls are in separate non-overlapping regions
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with local video preview and timer
            Container(
              height: 100,
              color: Colors.black,
              child: Stack(
                children: [
                  // Local video preview (top-left corner)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildLocalVideoPreview(),
                        ),
                      ),
                    ),
                  ),

                  // Timer badge (top-right corner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
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
                  ),
                ],
              ),
            ),

            // Remote video area (takes remaining space minus controls)
            Expanded(
              child: _buildRemoteVideo(),
            ),

            // Bottom controls - separate from video so no overlap
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    onPressed: _toggleMicrophone,
                    color: _isMuted ? Colors.red : Colors.white,
                  ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    label: 'Video',
                    onPressed: _toggleCamera,
                    color: _isCameraOff ? Colors.red : Colors.white,
                  ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    onPressed: _endCall,
                    color: Colors.red,
                    size: 64,
                  ),
                ],
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
    required Color color,
    double size = 56,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white24,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: size * 0.45),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    // Cancel timer
    _callTimer?.cancel();

    // Cancel stream subscriptions to prevent memory leaks
    _remoteUidSubscription?.cancel();
    _connectionStateSubscription?.cancel();

    // Dispose services
    if (kIsWeb) {
      _webService?.dispose();
    } else {
      _nativeService?.dispose();
    }

    super.dispose();
  }

  Widget _buildRemoteVideo() {
    // If remote user hasn't joined yet, show placeholder
    if (_remoteUid == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.blue,
              child: Text(
                widget.otherUser.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
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
              _isConnected ? 'Connecting video...' : 'Calling...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    if (kIsWeb) {
      // On web, use HtmlElementView to render remote video
      return const HtmlElementView(viewType: _remoteVideoViewId);
    } else {
      // On native platforms, show avatar placeholder (or use AgoraVideoView)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.blue,
              child: Text(
                widget.otherUser.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
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
          ],
        ),
      );
    }
  }

  Widget _buildVerticalControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _buildCircularButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          onPressed: _toggleMicrophone,
          backgroundColor: _isMuted ? Colors.red : Colors.grey[700]!,
        ),
        const SizedBox(height: 20),
        
        // Stop video button
        _buildCircularButton(
          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
          onPressed: _toggleCamera,
          backgroundColor: _isCameraOff ? Colors.red : Colors.grey[700]!,
        ),
        const SizedBox(height: 20),
        
        // End call button
        _buildCircularButton(
          icon: Icons.call_end,
          onPressed: _endCall,
          backgroundColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildLocalVideoPreview() {
    final bool isCameraOn = kIsWeb
        ? (_webService?.isVideoEnabled ?? false)
        : (_nativeService?.isVideoEnabled ?? false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isCameraOn
            ? Stack(
                key: ValueKey('local-video-on-$isCameraOn'),
                children: [
                  // On web, show actual video feed
                  if (kIsWeb)
                    const Positioned.fill(
                      child: HtmlElementView(viewType: _localVideoViewId),
                    )
                  else
                    // On native, show camera icon placeholder
                    Center(
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white.withOpacity(0.5),
                        size: 40,
                      ),
                    ),
                  // You label
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      color: Colors.white.withOpacity(0.7),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera Off',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
