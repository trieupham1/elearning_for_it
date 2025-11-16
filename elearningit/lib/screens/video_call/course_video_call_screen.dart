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
                // Main video grid
                _buildVideoGrid(),
                
                // Controls at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildControls(),
                ),
                
                // Participant count badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildParticipantBadge(),
                ),
              ],
            ),
    );
  }

  Widget _buildVideoGrid() {
    final totalUsers = _remoteUsers.length + 1; // +1 for local user
    
    if (_remoteUsers.isEmpty) {
      // Only local user
      return Center(
        child: _buildLocalPreview(),
      );
    }
    
    // Grid layout for multiple users
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: totalUsers > 4 ? 3 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: totalUsers,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLocalPreview();
        }
        return _buildRemoteVideo(_remoteUsers[index - 1]);
      },
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onPressed: _toggleMute,
            color: _isMuted ? Colors.red : Colors.white,
          ),
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: _isVideoEnabled ? 'Stop Video' : 'Start Video',
            onPressed: _toggleVideo,
            color: _isVideoEnabled ? Colors.white : Colors.red,
          ),
          _buildControlButton(
            icon: _isSharingScreen ? Icons.stop_screen_share : Icons.screen_share,
            label: _isSharingScreen ? 'Stop Share' : 'Share Screen',
            onPressed: _toggleScreenShare,
            color: _isSharingScreen ? Colors.green : Colors.white,
          ),
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Switch',
            onPressed: _switchCamera,
            color: Colors.white,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            onPressed: _leaveChannel,
            color: Colors.red,
            isEndCall: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isEndCall ? Colors.red : Colors.white24,
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
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
