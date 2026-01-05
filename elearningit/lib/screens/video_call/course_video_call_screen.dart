import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../services/video_call_service.dart';
import '../../config/api_config.dart';
import 'dart:async';

// Chat message model for video call
class ChatMessage {
  final String senderName;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.senderName,
    required this.message,
    required this.timestamp,
  });
}

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
  bool _showSidebar = false;
  bool _isWaitingForOthers = true;
  
  List<int> _remoteUsers = [];
  Map<int, String> _userNames = {};
  Map<int, String?> _userProfilePictures = {};
  Map<int, Map<String, bool>> _userStatuses = {};
  List<ChatMessage> _chatMessages = [];
  
  IO.Socket? _socket;
  String? _channelName;
  String? _token;
  Timer? _aloneTimer;

  final TextEditingController _chatController = TextEditingController();

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
          _checkIfAlone();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user $remoteUid joined');
          setState(() {
            _remoteUsers.add(remoteUid);
            _isWaitingForOthers = false;
          });
          _cancelAloneTimer();
          _fetchUserName(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('Remote user $remoteUid left channel');
          setState(() {
            _remoteUsers.remove(remoteUid);
            _userNames.remove(remoteUid);
            _userProfilePictures.remove(remoteUid);
            _userStatuses.remove(remoteUid);
          });
          _checkIfAlone();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('Left channel');
          setState(() {
            _remoteUsers.clear();
            _userNames.clear();
            _userProfilePictures.clear();
            _userStatuses.clear();
          });
        },
      ),
    );

    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    // Join channel
    await _joinChannel();
    
    // Initialize socket for chat
    _initializeSocket();
  }

  void _initializeSocket() {
    try {
      final socketUrl = ApiConfig.baseUrl.replaceAll('/api', '');
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.connect();

      _socket?.on('connect', (_) {
        debugPrint('✅ Socket connected: ${_socket?.id}');
        
        _socket?.emit('join_group_call', {
          'channelName': _channelName,
          'userId': widget.currentUser.id,
          'userName': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
          'userProfile': widget.currentUser.profilePicture,
        });
      });

      // Listen for existing participants
      _socket?.on('existing_participants', (data) {
        if (mounted && data['participants'] != null) {
          for (var participant in data['participants']) {
            final rawAgoraUid = participant['agoraUid'];
            if (rawAgoraUid != null) {
              final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
              if (agoraUid != null) {
                setState(() {
                  _userNames[agoraUid] = participant['userName'] ?? 'Unknown User';
                  _userProfilePictures[agoraUid] = participant['userProfile'];
                  _userStatuses[agoraUid] = {'isMuted': true, 'isCameraOff': true};
                });
              }
            }
          }
        }
      });

      // Listen for Agora UID mapping
      _socket?.on('agora_uid_mapped', (data) {
        final rawAgoraUid = data['agoraUid'];
        final userName = data['userName'];
        final userProfile = data['userProfile'];
        
        if (mounted && rawAgoraUid != null) {
          final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
          if (agoraUid != null) {
            setState(() {
              _userNames[agoraUid] = userName ?? 'Unknown User';
              _userProfilePictures[agoraUid] = userProfile;
              if (!_userStatuses.containsKey(agoraUid)) {
                _userStatuses[agoraUid] = {'isMuted': true, 'isCameraOff': true};
              }
            });
          }
        }
      });

      // Listen for chat messages
      _socket?.on('new_group_message', (data) {
        if (mounted) {
          setState(() {
            _chatMessages.add(ChatMessage(
              senderName: data['senderName'],
              message: data['message'],
              timestamp: DateTime.parse(data['timestamp']),
            ));
          });
        }
      });

      // Listen for user status updates
      _socket?.on('user_status_update', (data) {
        final rawAgoraUid = data['agoraUid'];
        if (mounted && rawAgoraUid != null) {
          final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
          if (agoraUid != null) {
            setState(() {
              _userStatuses[agoraUid] = {
                'isMuted': data['isMuted'] ?? true,
                'isCameraOff': data['isCameraOff'] ?? true,
              };
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  void _checkIfAlone() {
    if (_remoteUsers.isEmpty) {
      setState(() {
        _isWaitingForOthers = true;
      });
    }
  }

  void _cancelAloneTimer() {
    _aloneTimer?.cancel();
    _aloneTimer = null;
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
    
    // Notify others of status change
    _socket?.emit('user_status_update', {
      'channelName': _channelName,
      'agoraUid': widget.currentUser.id.hashCode,
      'isMuted': _isMuted,
      'isCameraOff': !_isVideoEnabled,
    });
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    await _engine.muteLocalVideoStream(!_isVideoEnabled);
    
    // Notify others of status change
    _socket?.emit('user_status_update', {
      'channelName': _channelName,
      'agoraUid': widget.currentUser.id.hashCode,
      'isMuted': _isMuted,
      'isCameraOff': !_isVideoEnabled,
    });
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

  void _sendChatMessage(String message) {
    if (message.trim().isEmpty) return;
    
    final timestamp = DateTime.now();
    final senderName = '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim();
    
    // Add to local messages immediately
    setState(() {
      _chatMessages.add(ChatMessage(
        senderName: senderName,
        message: message.trim(),
        timestamp: timestamp,
      ));
    });
    
    // Send via socket
    _socket?.emit('send_group_message', {
      'channelName': _channelName,
      'message': message.trim(),
      'senderName': senderName,
      'senderId': widget.currentUser.id,
      'timestamp': timestamp.toIso8601String(),
    });
    
    _chatController.clear();
  }

  Future<void> _leaveChannel() async {
    try {
      _socket?.emit('leave_group_call', {
        'channelName': _channelName,
        'userId': widget.currentUser.id,
      });
      
      await _callService.leaveCall(
        courseId: widget.course.id,
        channelName: _channelName!,
      );
      
      _socket?.disconnect();
      _socket?.dispose();
      
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
    _chatController.dispose();
    _cancelAloneTimer();
    _socket?.disconnect();
    _socket?.dispose();
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
            icon: Icon(_showSidebar ? Icons.close_fullscreen : Icons.people),
            onPressed: () {
              setState(() {
                _showSidebar = !_showSidebar;
              });
            },
            tooltip: _showSidebar ? 'Hide sidebar' : 'Show people & chat',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 600;
                
                if (isLargeScreen) {
                  // Tablet/Desktop: Side by side layout
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMainContent(),
                      ),
                      if (_showSidebar) _buildSidebar(),
                    ],
                  );
                } else {
                  // Phone: Stack with overlay sidebar
                  return Stack(
                    children: [
                      _buildMainContent(),
                      if (_showSidebar)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: _buildSidebar(),
                        ),
                    ],
                  );
                }
              },
            ),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // Video grid or waiting message
        _isWaitingForOthers && _remoteUsers.isEmpty
            ? Center(
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
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              )
            : _buildVideoGrid(),
        
        // Participant badge (top-left corner)
        if (!_showSidebar)
          Positioned(
            top: 16,
            left: 16,
            child: _buildParticipantBadge(),
          ),
        
        // Camera switch note
        Positioned(
          bottom: 110,
          left: 0,
          right: 0,
          child: Center(
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
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[200]),
                  const SizedBox(width: 6),
                  Text(
                    'Camera switching is available on mobile app',
                    style: TextStyle(color: Colors.blue[200], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.grey[900],
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Tab header
            Container(
              color: Colors.grey[850],
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 18),
                        const SizedBox(width: 4),
                        Text('People (${_remoteUsers.length + 1})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat, size: 18),
                        const SizedBox(width: 4),
                        Text('Chat (${_chatMessages.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildPeopleTab(),
                  _buildChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleTab() {
    final allParticipants = <Map<String, dynamic>>[
      {
        'uid': 0,
        'name': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
        'isYou': true,
        'profilePicture': widget.currentUser.profilePicture,
      },
      ..._remoteUsers.map((uid) => <String, dynamic>{
          'uid': uid,
          'name': _userNames[uid] ?? 'User $uid',
          'isYou': false,
          'profilePicture': _userProfilePictures[uid],
        }),
    ];

    return ListView.builder(
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        final name = participant['name'] as String;
        final isYou = participant['isYou'] as bool;
        final uid = participant['uid'] as int;
        final profilePicture = participant['profilePicture'] as String?;
        
        final isMuted = isYou ? _isMuted : (_userStatuses[uid]?['isMuted'] ?? true);
        final isCameraOff = isYou ? !_isVideoEnabled : (_userStatuses[uid]?['isCameraOff'] ?? true);

        return ListTile(
          leading: profilePicture != null && profilePicture.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(profilePicture),
                  backgroundColor: Colors.grey[700],
                )
              : CircleAvatar(
                  backgroundColor: isYou ? Colors.blue : Colors.grey[700],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isYou)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMuted)
                Icon(Icons.mic_off, color: Colors.red[400], size: 16),
              const SizedBox(width: 4),
              if (isCameraOff)
                Icon(Icons.videocam_off, color: Colors.red[400], size: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, 
                           size: 48, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final isMe = message.senderName == 
                        '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: isMe 
                            ? CrossAxisAlignment.end 
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              message.senderName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.message,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Text(
                            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Chat input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(top: BorderSide(color: Colors.grey[700]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: _sendChatMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _sendChatMessage(_chatController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoGrid() {
    // Calculate total participants (local user + remote users)
    final totalParticipants = _remoteUsers.length + 1;
    
    // Determine grid layout based on participant count
    int crossAxisCount;
    double childAspectRatio;
    
    if (totalParticipants == 1) {
      crossAxisCount = 1;
      childAspectRatio = 0.75;
    } else if (totalParticipants == 2) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
    } else if (totalParticipants <= 4) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
    } else if (totalParticipants <= 9) {
      crossAxisCount = 3;
      childAspectRatio = 0.75;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 0.75;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: totalParticipants,
      itemBuilder: (context, index) {
        if (index == 0) {
          // First card is local user
          return _buildLocalVideoCard();
        } else {
          // Other cards are remote users
          return _buildRemoteVideo(_remoteUsers[index - 1]);
        }
      },
    );
  }

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
              child: Text(
                'You',
                style: const TextStyle(
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
          // Screen sharing indicator
          if (_isSharingScreen)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.screen_share,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Sharing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
            borderRadius: BorderRadius.circular(10),
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: uid),
                connection: RtcConnection(channelId: _channelName),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            onPressed: _toggleMute,
            isActive: !_isMuted,
            activeColor: Colors.grey[800]!,
            inactiveColor: Colors.red,
          ),
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: _isVideoEnabled ? 'Stop Video' : 'No camera',
            onPressed: _toggleVideo,
            isActive: _isVideoEnabled,
            activeColor: Colors.grey[800]!,
            inactiveColor: Colors.amber,
          ),
          _buildControlButton(
            icon: _isSharingScreen ? Icons.stop_screen_share : Icons.screen_share,
            label: 'Share screen',
            onPressed: _toggleScreenShare,
            isActive: !_isSharingScreen,
            activeColor: Colors.grey[800]!,
            inactiveColor: Colors.green,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            onPressed: _leaveChannel,
            isActive: false,
            activeColor: Colors.red,
            inactiveColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(50),
          elevation: 2,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
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
}
