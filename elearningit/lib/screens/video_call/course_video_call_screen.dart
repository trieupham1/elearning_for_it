import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../services/video_call_service.dart';

class CourseVideoCallScreen extends StatefulWidget {
  final Course course;
  final User currentUser;

  const CourseVideoCallScreen({
    super.key,
    required this.course,
    required this.currentUser,
  });

  @override
  State<CourseVideoCallScreen> createState() => _CourseVideoCallScreenState();
}

class _CourseVideoCallScreenState extends State<CourseVideoCallScreen> {
  late RtcEngine _engine;
  final VideoCallService _callService = VideoCallService();
  
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSharingScreen = false;
  bool _isLoading = true;
  
  List<int> _remoteUsers = [];
  Map<int, String> _userNames = {};
  
  String? _channelName;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create Agora engine
    _engine = createAgoraRtcEngine();
    
    await _engine.initialize(const RtcEngineContext(
      appId: 'afa109d795eb450db1793f9f0b5f0ec9',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Local user ${connection.localUid} joined');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user $remoteUid joined');
          setState(() {
            _remoteUsers.add(remoteUid);
          });
          _fetchUserName(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('Remote user $remoteUid left channel');
          setState(() {
            _remoteUsers.remove(remoteUid);
            _userNames.remove(remoteUid);
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('Left channel');
          setState(() {
            _remoteUsers.clear();
            _userNames.clear();
          });
        },
      ),
    );

    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    // Join channel
    await _joinChannel();
  }

  Future<void> _joinChannel() async {
    try {
      // Get token from backend
      final tokenData = await _callService.getAgoraToken(
        channelName: 'course_${widget.course.id}',
        uid: widget.currentUser.id.hashCode,
      );

      setState(() {
        _channelName = tokenData['channelName'];
        _token = tokenData['token'];
        _isLoading = false;
      });

      // Join the channel
      await _engine.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: widget.currentUser.id.hashCode,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Notify backend that user joined
      await _callService.joinCall(
        courseId: widget.course.id,
        channelName: _channelName!,
      );
    } catch (e) {
      debugPrint('Error joining channel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _fetchUserName(int uid) async {
    try {
      final userName = await _callService.getUserNameByUid(uid);
      setState(() {
        _userNames[uid] = userName;
      });
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    await _engine.muteLocalVideoStream(!_isVideoEnabled);
  }

  Future<void> _toggleScreenShare() async {
    if (_isSharingScreen) {
      // Stop screen sharing
      await _engine.stopScreenCapture();
      await _engine.startPreview();
      setState(() {
        _isSharingScreen = false;
      });
    } else {
      // Start screen sharing
      await _engine.stopPreview();
      await _engine.startScreenCapture(const ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
      ));
      setState(() {
        _isSharingScreen = true;
      });
    }
  }

  Future<void> _switchCamera() async {
    await _engine.switchCamera();
  }

  Future<void> _leaveChannel() async {
    try {
      await _callService.leaveCall(
        courseId: widget.course.id,
        channelName: _channelName!,
      );
      await _engine.leaveChannel();
      await _engine.release();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() async {
    try {
      if (_channelName != null) {
        await _callService.leaveCall(
          courseId: widget.course.id,
          channelName: _channelName!,
        );
      }
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint('Error during disposal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.name} - Video Call'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _showParticipantsList,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              children: [
                // Remote users grid
                if (_remoteUsers.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Waiting for others to join...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 60,
                      bottom: 120,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _remoteUsers.length > 4 ? 3 : (_remoteUsers.length > 1 ? 2 : 1),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _remoteUsers.length,
                    itemBuilder: (context, index) {
                      return _buildRemoteVideo(_remoteUsers[index]);
                    },
                  ),

                // Local preview (top-right corner)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildLocalPreviewSmall(),
                ),

                // Participant badge (top-left corner)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildParticipantBadge(),
                ),

                // Bottom controls
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

  Widget _buildLocalPreviewSmall() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isVideoEnabled && !_isSharingScreen
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Text(
                        (widget.currentUser.firstName?.isNotEmpty ?? false)
                            ? widget.currentUser.firstName![0].toUpperCase()
                            : 'Y',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_isMuted)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_off,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isVideoEnabled && !_isSharingScreen
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      child: Text(
                        (widget.currentUser.firstName?.isNotEmpty ?? false)
                            ? widget.currentUser.firstName![0].toUpperCase()
                            : 'Y',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isMuted) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.mic_off,
                      color: Colors.red,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isSharingScreen)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sharing Screen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo(int uid) {
    final userName = _userNames[uid] ?? 'User $uid';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: uid),
                connection: RtcConnection(channelId: _channelName),
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Note for web users about camera switch
          if (Theme.of(context).platform == TargetPlatform.windows ||
              Theme.of(context).platform == TargetPlatform.macOS ||
              Theme.of(context).platform == TargetPlatform.linux)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.blue[200],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Camera switch is available on mobile devices',
                      style: TextStyle(
                        color: Colors.blue[200],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: 'Mute',
                onPressed: _toggleMute,
                color: Colors.white,
                backgroundColor: _isMuted ? Colors.red : Colors.grey[800]!,
              ),
              _buildControlButton(
                icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                label: 'Stop Video',
                onPressed: _toggleVideo,
                color: Colors.white,
                backgroundColor: _isVideoEnabled ? Colors.grey[800]! : Colors.red,
              ),
              // Only show camera switch on mobile platforms
              if (Theme.of(context).platform == TargetPlatform.android ||
                  Theme.of(context).platform == TargetPlatform.iOS)
                _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Switch Camera',
                  onPressed: _switchCamera,
                  color: Colors.white,
                  backgroundColor: Colors.grey[800]!,
                ),
              _buildControlButton(
                icon: Icons.call_end,
                label: 'End',
                onPressed: _leaveChannel,
                color: Colors.white,
                backgroundColor: Colors.red,
                isEndCall: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _buildCircularButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          onPressed: _toggleMute,
          backgroundColor: _isMuted ? Colors.red : Colors.grey[700]!,
        ),
        const SizedBox(height: 20),
        
        // Stop video button
        _buildCircularButton(
          icon: !_isVideoEnabled ? Icons.videocam_off : Icons.videocam,
          onPressed: _toggleVideo,
          backgroundColor: !_isVideoEnabled ? Colors.red : Colors.grey[700]!,
        ),
        const SizedBox(height: 20),
        
        // Screen share button
        _buildCircularButton(
          icon: _isSharingScreen ? Icons.stop_screen_share : Icons.screen_share,
          onPressed: _toggleScreenShare,
          backgroundColor: _isSharingScreen ? Colors.green : Colors.grey[700]!,
        ),
        const SizedBox(height: 20),
        
        // Switch camera (mobile only)
        if (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS)
          _buildCircularButton(
            icon: Icons.switch_camera,
            onPressed: _switchCamera,
            backgroundColor: Colors.grey[700]!,
          ),
        if (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS)
          const SizedBox(height: 20),
        
        // End call button
        _buildCircularButton(
          icon: Icons.call_end,
          onPressed: _leaveChannel,
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    Color? backgroundColor,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor ?? (isEndCall ? Colors.red : Colors.grey[800]),
          borderRadius: BorderRadius.circular(50),
          elevation: 2,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantBadge() {
    final totalParticipants = _remoteUsers.length + 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            '$totalParticipants',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showParticipantsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants (${_remoteUsers.length + 1})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    (widget.currentUser.firstName?.isNotEmpty ?? false)
                        ? widget.currentUser.firstName![0].toUpperCase()
                        : 'Y',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''} (You)',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isMuted)
                      const Icon(Icons.mic_off, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    if (!_isVideoEnabled)
                      const Icon(Icons.videocam_off, color: Colors.red, size: 18),
                  ],
                ),
              ),
              ..._remoteUsers.map((uid) {
                final userName = _userNames[uid] ?? 'User $uid';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[700],
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
