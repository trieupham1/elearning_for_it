// screens/video_call/web_course_video_call_screen.dart
import 'package:flutter/material.dart';
import '../../services/agora_web_service_export.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../services/video_call_service.dart';
import '../../config/agora_config.dart';
import '../../config/api_config.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
// Conditional imports for web
import 'dart:html' as html show DivElement;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart' show HtmlElementView;

// Temporary chat message model (only exists during call)
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

class WebCourseVideoCallScreen extends StatefulWidget {
  final Course course;
  final User currentUser;

  const WebCourseVideoCallScreen({
    super.key,
    required this.course,
    required this.currentUser,
  });

  @override
  State<WebCourseVideoCallScreen> createState() =>
      _WebCourseVideoCallScreenState();
}

class _WebCourseVideoCallScreenState extends State<WebCourseVideoCallScreen> {
  AgoraWebService? _webService;
  final VideoCallService _callService = VideoCallService();

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isLoading = true;
  bool _showSidebar = false;
  bool _isWaitingForOthers = false;

  List<int> _remoteUsers = [];
  Map<int, String> _userNames = {};
  Map<int, String?> _userProfilePictures = {};
  Map<int, Map<String, bool>> _userStatuses = {}; // {uid: {isMuted: bool, isCameraOff: bool}}
  List<ChatMessage> _chatMessages = [];
  IO.Socket? _socket;
  int? _screenSharingUid; // UID of user currently sharing screen
  bool _isSharingScreen = false; // Whether local user is sharing
  bool _screenShareWithAudio = false; // Whether screen share includes audio

  String? _channelName;
  String? _token;
  Timer? _aloneTimer;
  DateTime? _aloneStartTime;
  Timer? _userInfoTimer;

  // Stream subscriptions
  StreamSubscription<int>? _remoteUidSubscription;
  StreamSubscription<int>? _remoteUserLeftSubscription;
  StreamSubscription<String>? _connectionStateSubscription;
  StreamSubscription<int>? _remoteVideoPublishedSubscription;

  // HTML element view IDs for web video rendering
  final Map<int, String> _remoteVideoViewIds = {};
  static const String _localVideoViewId = 'local-video-course-view';
  bool _localVideoRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerLocalVideoView();
    _initializeCall();
  }

  void _registerLocalVideoView() {
    if (_localVideoRegistered) return;

    ui_web.platformViewRegistry.registerViewFactory(_localVideoViewId, (
      int viewId,
    ) {
      final element = html.DivElement()
        ..id = 'local-video-container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return element;
    });

    _localVideoRegistered = true;
  }

  void _registerRemoteVideoView(int uid) {
    final viewId = 'remote-video-$uid';
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
      // Generate channel name
      _channelName = 'course_${widget.course.id}';
      
      // Initialize Socket.IO connection
      _initializeSocket();
      
      // Get token from Agora config (uses /api/agora/generate-token)
      _token = await AgoraConfig.getToken(_channelName!, 0); // Use uid 0 for auto-assign
      
      if (_token == null) {
        throw Exception('Failed to get Agora token');
      }

      setState(() {
        // Token and channel name are already set
      });

      // Initialize Agora Web Service
      _webService = AgoraWebService();
      await _webService!.initialize();

      // Listen to remote user events via streams
      _remoteUidSubscription = _webService!.remoteUid.listen((uid) {
        debugPrint('🔵 Remote user detected via Agora: UID $uid (type: ${uid.runtimeType})');
        debugPrint('   - Current _userNames map: $_userNames');
        debugPrint('   - Map keys types: ${_userNames.keys.map((k) => '${k.runtimeType}').toList()}');
        debugPrint('   - Contains key check: ${_userNames.containsKey(uid)}');
        
        if (mounted && !_remoteUsers.contains(uid)) {
          setState(() {
            _remoteUsers.add(uid);
            _isWaitingForOthers = false;
          });
          _cancelAloneTimer();
          _registerRemoteVideoView(uid);
          
          // Check if we already have this user's info from Socket.IO
          if (_userNames[uid] == null) {
            debugPrint('⚠️ No user info yet for UID $uid, waiting for Socket.IO mapping...');
            debugPrint('   Available UIDs in map: ${_userNames.keys.toList()}');
            // We'll get their info via Socket.IO agora_uid_mapped event
          } else {
            debugPrint('✅ User info already available for UID $uid: ${_userNames[uid]}');
          }
          
          // Re-broadcast our own UID so the new user can see our name
          final myAgoraUid = _webService?.localUid;
          if (myAgoraUid != null) {
            debugPrint('📡 Re-broadcasting our UID for new user...');
            Future.delayed(const Duration(milliseconds: 300), () {
              _socket?.emit('share_agora_uid', {
                'channelName': _channelName,
                'agoraUid': myAgoraUid,
                'userId': widget.currentUser.id,
                'userName': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
                'userProfile': widget.currentUser.profilePicture,
              });
            });
          }
        }
      });

      _remoteUserLeftSubscription = _webService!.remoteUserLeft.listen((uid) {
        if (mounted) {
          setState(() {
            _remoteUsers.remove(uid);
            _remoteVideoViewIds.remove(uid);
            _userNames.remove(uid);
          });
          _checkIfAlone();
        }
      });

      _connectionStateSubscription = _webService!.connectionState.listen((state) {
        debugPrint('Connection state changed: $state');
        // Don't auto-leave when state changes - let user control when to leave
      });

      // Listen for remote video published events (for refreshing video after screen share etc.)
      _remoteVideoPublishedSubscription = _webService!.remoteVideoPublished.listen((uid) {
        debugPrint('📹 Remote video published for UID $uid - refreshing view');
        if (mounted) {
          // Update status to show camera is on
          setState(() {
            if (_userStatuses.containsKey(uid)) {
              _userStatuses[uid]!['isCameraOff'] = false;
            }
          });
          
          // Ensure video view is registered and manually play the video
          _registerRemoteVideoView(uid);
          
          // Use a longer delay and manually trigger play
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _remoteUsers.contains(uid)) {
              debugPrint('📹 Manually playing remote video for UID $uid');
              _webService?.playRemoteVideo(uid, 'remote-video-container-$uid');
            }
          });
        }
      });

      // Listen for screen share state changes (e.g., browser stop button)
      _webService!.screenShareState.listen((isSharing) async {
        final myUid = _webService!.localUid;
        if (mounted && myUid != null) {
          setState(() {
            _isSharingScreen = isSharing;
            if (!isSharing && _screenSharingUid == myUid) {
              _screenSharingUid = null;
            }
          });
          
          // Notify other users
          _socket?.emit('screen_share_status', {
            'channelName': _channelName,
            'agoraUid': myUid,
            'isSharing': isSharing,
          });
          
          // If we stopped sharing and camera is on, notify that camera is republished
          if (!isSharing && _isVideoEnabled) {
            debugPrint('📹 Screen share stopped, notifying about camera republish');
            // Wait a bit for the camera to be republished
            await Future.delayed(const Duration(milliseconds: 800));
            _socket?.emit('camera_republished', {
              'channelName': _channelName,
              'agoraUid': myUid,
              'userId': widget.currentUser.id,
            });
          }
        }
      });

      // Join channel (starts with mic/camera ON by default in Agora)
      await _webService!.joinVideoChannel(
        _channelName!,
        token: _token,
      );

      // Broadcast our Agora UID so others can map it
      final myAgoraUid = _webService!.localUid;
      debugPrint('📡 Preparing to broadcast Agora UID:');
      debugPrint('   - My Agora UID: $myAgoraUid (type: ${myAgoraUid.runtimeType})');
      debugPrint('   - My User ID: ${widget.currentUser.id}');
      debugPrint('   - My User Name: ${widget.currentUser.fullName}');
      debugPrint('   - Channel: $_channelName');
      
      if (myAgoraUid != null) {
        // Wait for socket to be connected before broadcasting
        int retryCount = 0;
        while (_socket?.connected != true && retryCount < 10) {
          debugPrint('⏳ Waiting for socket to connect... (attempt ${retryCount + 1})');
          await Future.delayed(const Duration(milliseconds: 200));
          retryCount++;
        }
        
        if (_socket?.connected == true) {
          // First ensure we're in the room
          _socket?.emit('join_group_call', {
            'channelName': _channelName,
            'userId': widget.currentUser.id,
            'userName': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
            'userProfile': widget.currentUser.profilePicture,
          });
          
          // Wait a bit for the room to be joined
          await Future.delayed(const Duration(milliseconds: 300));
          
          _socket?.emit('share_agora_uid', {
            'channelName': _channelName,
            'agoraUid': myAgoraUid,
            'userId': widget.currentUser.id,
            'userName': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
            'userProfile': widget.currentUser.profilePicture,
          });
          debugPrint('✅ Broadcasted Agora UID via Socket.IO');
          
          // Request all existing UIDs to refresh the mapping
          await Future.delayed(const Duration(milliseconds: 200));
          _socket?.emit('request_all_uids', {
            'channelName': _channelName,
          });
          debugPrint('📋 Requested all existing UIDs');
        } else {
          debugPrint('❌ Socket not connected after retries');
        }
        
        // Also store our own info locally
        setState(() {
          _userNames[myAgoraUid] = '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim();
          _userProfilePictures[myAgoraUid] = widget.currentUser.profilePicture;
        });
      } else {
        debugPrint('❌ Cannot broadcast - Agora UID is null!');
      }

      // Mute mic and turn off camera by default (like Google Meet/Zoom)
      await _webService!.toggleMicrophone(); // Mute mic
      
      // Only toggle camera if it's available
      if (_webService!.localVideoTrack != null) {
        await _webService!.toggleCamera(); // Turn off camera
      }
      
      setState(() {
        _isMuted = true;
        _isVideoEnabled = _webService!.localVideoTrack != null ? false : false;
      });

      // Notify backend
      await _callService.joinCall(
        courseId: widget.course.id,
        channelName: _channelName!,
      );

      setState(() {
        _isLoading = false;
      });
      
      // Check if user is alone after joining
      _checkIfAlone();
      
      // Start periodic timer to check for missing usernames
      _startUserInfoTimer();
    } catch (e) {
      debugPrint('Error initializing call: $e');
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
      final userInfo = await _callService.getUserInfoByUid(uid);
      if (mounted) {
        setState(() {
          _userNames[uid] = userInfo['userName'] ?? 'Unknown User';
          _userProfilePictures[uid] = userInfo['profilePicture'];
          // Initialize status for this user
          _userStatuses[uid] = {'isMuted': true, 'isCameraOff': true};
        });
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  void _startUserInfoTimer() {
    _userInfoTimer?.cancel();
    // Check every 2 seconds for users with missing names
    _userInfoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Check if any remote user has "User XXXX" as their name (indicating missing info)
      bool hasMissingInfo = false;
      for (final uid in _remoteUsers) {
        final userName = _userNames[uid];
        if (userName == null || userName.startsWith('User ')) {
          hasMissingInfo = true;
          debugPrint('⚠️ Missing user info for UID $uid, requesting...');
        }
      }
      
      if (hasMissingInfo && _channelName != null) {
        _socket?.emit('request_all_uids', {
          'channelName': _channelName,
        });
      } else if (!hasMissingInfo && _remoteUsers.isNotEmpty) {
        // All users have proper names, stop the timer
        debugPrint('✅ All user info received, stopping timer');
        timer.cancel();
        _userInfoTimer = null;
      }
    });
  }

  void _initializeSocket() {
    try {
      // Connect to Socket.IO server
      final socketUrl = ApiConfig.baseUrl.replaceAll('/api', '');
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.connect();

      _socket?.on('connect', (_) {
        debugPrint('✅ Socket connected: ${_socket?.id}');
        
        // Join the group call room with user info
        _socket?.emit('join_group_call', {
          'channelName': _channelName,
          'userId': widget.currentUser.id,
          'userName': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
          'userProfile': widget.currentUser.profilePicture,
        });
      });

      // Listen for existing participants when we join
      _socket?.on('existing_participants', (data) {
        debugPrint('📋 Received existing participants: ${data['participants']}');
        if (mounted && data['participants'] != null) {
          for (var participant in data['participants']) {
            final rawAgoraUid = participant['agoraUid'];
            if (rawAgoraUid != null) {
              // Convert to int to match Agora SDK's UID type
              final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
              if (agoraUid != null) {
                setState(() {
                  _userNames[agoraUid] = participant['userName'] ?? 'Unknown User';
                  _userProfilePictures[agoraUid] = participant['userProfile'];
                  _userStatuses[agoraUid] = {'isMuted': true, 'isCameraOff': true};
                });
                debugPrint('   - Stored existing user: UID $agoraUid -> ${participant['userName']}');
              }
            }
          }
        }
      });

      // Listen for other users joining
      _socket?.on('user_joined_call', (data) {
        debugPrint('👤 User joined via socket: ${data['userName']}');
        // We'll get their Agora UID later via agora_uid_mapped event
      });

      // Listen for Agora UID mapping
      _socket?.on('agora_uid_mapped', (data) {
        final rawAgoraUid = data['agoraUid'];
        final userName = data['userName'];
        final userProfile = data['userProfile'];
        
        debugPrint('🔗 Agora UID mapped received:');
        debugPrint('   - Raw Agora UID: $rawAgoraUid (type: ${rawAgoraUid.runtimeType})');
        debugPrint('   - User Name: $userName');
        debugPrint('   - Profile: $userProfile');
        
        if (mounted && rawAgoraUid != null) {
          // Convert to int to match Agora SDK's UID type
          final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
          
          if (agoraUid != null) {
            debugPrint('   - Converted UID: $agoraUid (type: ${agoraUid.runtimeType})');
            debugPrint('   - Current remote users: $_remoteUsers');
            debugPrint('   - Current userNames keys: ${_userNames.keys.toList()}');
            
            setState(() {
              _userNames[agoraUid] = userName ?? 'Unknown User';
              _userProfilePictures[agoraUid] = userProfile;
              if (!_userStatuses.containsKey(agoraUid)) {
                _userStatuses[agoraUid] = {'isMuted': true, 'isCameraOff': true};
              }
            });
            
            debugPrint('✅ Stored user info for UID $agoraUid');
            debugPrint('   - Stored userNames: $_userNames');
          } else {
            debugPrint('❌ Failed to convert Agora UID to int');
          }
        }
      });

      // Listen for new chat messages
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

      // Listen for user status updates (mic/camera)
      _socket?.on('user_status_updated', (data) {
        final rawAgoraUid = data['agoraUid'];
        if (mounted && rawAgoraUid != null) {
          // Convert to int to match Agora SDK's UID type
          final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
          if (agoraUid != null) {
            debugPrint('🔊 Status update for UID $agoraUid: muted=${data['isMuted']}, camera=${data['isCameraOff']}');
            setState(() {
              if (_userStatuses.containsKey(agoraUid)) {
                _userStatuses[agoraUid] = {
                  'isMuted': data['isMuted'] ?? true,
                  'isCameraOff': data['isCameraOff'] ?? true,
                };
              }
            });
          }
        }
      });

      // Listen for screen share status updates
      _socket?.on('screen_share_status', (data) {
        final rawAgoraUid = data['agoraUid'];
        final isSharing = data['isSharing'] ?? false;
        if (mounted && rawAgoraUid != null) {
          final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
          if (agoraUid != null) {
            debugPrint('🖥️ Screen share update: UID $agoraUid is ${isSharing ? 'sharing' : 'not sharing'}');
            setState(() {
              if (isSharing) {
                _screenSharingUid = agoraUid;
              } else if (_screenSharingUid == agoraUid) {
                _screenSharingUid = null;
              }
            });
          }
        }
      });
      
      // Listen for camera republished after screen share
      _socket?.on('camera_republished', (data) {
        final rawAgoraUid = data['agoraUid'];
        if (mounted && rawAgoraUid != null) {
          final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
          if (agoraUid != null) {
            debugPrint('📹 Camera republished notification for UID $agoraUid');
            // Force a rebuild to show the camera video
            setState(() {
              // Update user status to reflect camera is on
              if (_userStatuses.containsKey(agoraUid)) {
                _userStatuses[agoraUid]!['isCameraOff'] = false;
              }
            });
            
            // Try to play the video - Agora should have already received user-published event
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _remoteUsers.contains(agoraUid)) {
                debugPrint('📹 Attempting to play remote video for UID $agoraUid');
                _webService?.playRemoteVideo(agoraUid, 'remote-video-container-$agoraUid');
              }
            });
          }
        }
      });

      _socket?.on('disconnect', (_) {
        debugPrint('❌ Socket disconnected');
      });

    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  void _broadcastStatusUpdate() {
    final myAgoraUid = _webService?.localUid;
    if (myAgoraUid != null) {
      _socket?.emit('update_user_status', {
        'channelName': _channelName,
        'agoraUid': myAgoraUid,
        'userId': widget.currentUser.id,
        'isMuted': _isMuted,
        'isCameraOff': !_isVideoEnabled,
      });
      debugPrint('📡 Broadcasted status: muted=$_isMuted, camera=${!_isVideoEnabled}');
    }
  }

  void _checkIfAlone() {
    if (_remoteUsers.isEmpty) {
      setState(() {
        _isWaitingForOthers = true;
        _aloneStartTime = DateTime.now();
      });
      _startAloneTimer();
    }
  }

  void _startAloneTimer() {
    _cancelAloneTimer();
    _aloneTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _remoteUsers.isEmpty) {
        _showTimeoutDialog();
      }
    });
  }

  void _cancelAloneTimer() {
    _aloneTimer?.cancel();
    _aloneTimer = null;
    _aloneStartTime = null;
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Call Ending'),
        content: const Text(
          'You\'ve been alone in the call for 5 minutes. The call will now end.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveCall();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMute() async {
    if (_webService != null) {
      await _webService!.toggleMicrophone();
      setState(() {
        _isMuted = _webService!.isMuted;
      });
      _broadcastStatusUpdate();
    }
  }

  Future<void> _toggleVideo() async {
    if (_webService == null) return;
    
    // Check if camera is available
    if (_webService!.localVideoTrack == null) {
      // Show warning dialog like Google Meet
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Camera Not Available'),
            ],
          ),
          content: const Text(
            'Your camera could not be found or accessed. Please check your camera permissions and ensure it\'s not being used by another application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    await _webService!.toggleCamera();
    setState(() {
      _isVideoEnabled = _webService!.isVideoEnabled;
    });
    _broadcastStatusUpdate();
  }

  Future<void> _toggleScreenShare() async {
    try {
      // If currently sharing, just stop
      if (_isSharingScreen) {
        await _webService!.toggleScreenShare();
        final myUid = _webService!.localUid;
        
        setState(() {
          _isSharingScreen = false;
          _screenShareWithAudio = false;
          if (_screenSharingUid == myUid) {
            _screenSharingUid = null;
          }
        });
        
        // Notify other users
        if (myUid != null) {
          _socket?.emit('screen_share_status', {
            'channelName': _channelName,
            'agoraUid': myUid,
            'isSharing': false,
          });
        }
        return;
      }

      // Show dialog to choose audio option
      final includeAudio = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Screen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Do you want to share audio from your screen?'),
              SizedBox(height: 12),
              Text(
                'Note: System audio sharing is supported in Chrome and Edge browsers.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Screen Only'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Screen + Audio'),
            ),
          ],
        ),
      );

      if (includeAudio == null) return; // User cancelled

      await _webService!.startScreenShare(includeAudio: includeAudio);
      
      final isSharingNow = _webService!.isSharingScreen;
      final myUid = _webService!.localUid;
      
      setState(() {
        _isSharingScreen = isSharingNow;
        _screenShareWithAudio = includeAudio;
        if (isSharingNow && myUid != null) {
          _screenSharingUid = myUid;
        } else if (!isSharingNow && _screenSharingUid == myUid) {
          _screenSharingUid = null;
        }
      });
      
      // Notify other users via Socket.IO
      if (myUid != null) {
        _socket?.emit('screen_share_status', {
          'channelName': _channelName,
          'agoraUid': myUid,
          'isSharing': isSharingNow,
        });
      }
      
      // Re-render the video if we're sharing screen
      if (isSharingNow) {
        // Play screen share in local preview
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_webService?.localScreenTrack != null) {
            _webService!.playScreenShare('local-video-container');
          }
        });
      } else {
        // Resume camera video if it was on
        if (_webService?.localVideoTrack != null && _isVideoEnabled) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _webService!.playLocalVideo('local-video-container');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share screen: $e')),
        );
      }
    }
  }

  Future<void> _leaveCall() async {
    try {
      // Emit leave event via Socket.IO
      _socket?.emit('leave_group_call', {
        'channelName': _channelName,
        'userId': widget.currentUser.id,
      });
      
      if (_channelName != null) {
        await _callService.leaveCall(
          courseId: widget.course.id,
          channelName: _channelName!,
        );
      }
      
      // Disconnect socket
      _socket?.disconnect();
      _socket?.dispose();
      
      await _webService?.leaveChannel();
      await _webService?.dispose();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error leaving call: $e');
    }
  }

  @override
  void dispose() {
    _remoteUidSubscription?.cancel();
    _remoteUserLeftSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _remoteVideoPublishedSubscription?.cancel();
    _cancelAloneTimer();
    _userInfoTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _leaveCall();
    super.dispose();
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
          : Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Main video grid (all participants including local user)
                      _isWaitingForOthers
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
                          : (_screenSharingUid != null
                              ? _buildScreenShareLayout()
                              : _buildVideoGrid()),
                      
                      // Participant badge
                      if (!_showSidebar)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildParticipantBadge(),
                        ),
                      
                      // Controls at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildControls(),
                      ),
                    ],
                  ),
                ),
                if (_showSidebar) _buildSidebar(),
              ],
            ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 320,
      color: Colors.grey[900],
      child: Column(
        children: [
          // Tabs for People and Chat
          Container(
            color: Colors.grey[850],
            child: Row(
              children: [
                Expanded(
                  child: Tab(
                    text: 'People (${_remoteUsers.length + 1})',
                  ),
                ),
                Expanded(
                  child: Tab(
                    text: 'Chat (${_chatMessages.length})',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(icon: Icon(Icons.people), text: 'People'),
                      Tab(icon: Icon(Icons.chat), text: 'Chat'),
                    ],
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    final allParticipants = [
      {
        'uid': 0, 
        'name': '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(), 
        'isYou': true,
        'profilePicture': widget.currentUser.profilePicture,
      },
      ..._remoteUsers.map((uid) => {
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
        
        // Get status for this user
        final isMuted = isYou ? _isMuted : (_userStatuses[uid]?['isMuted'] ?? true);
        final isCameraOff = isYou ? !_isVideoEnabled : (_userStatuses[uid]?['isCameraOff'] ?? true);
        
        return ListTile(
          leading: profilePicture != null && profilePicture.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(profilePicture),
                  backgroundColor: Colors.grey[700],
                )
              : CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
          title: Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: isYou
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      size: 16,
                      color: isMuted ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isCameraOff ? Icons.videocam_off : Icons.videocam,
                      size: 16,
                      color: isCameraOff ? Colors.red : Colors.green,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    final TextEditingController chatController = TextEditingController();

    return Column(
      children: [
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation!',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final isMe = message.senderName == '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim();
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: const BoxConstraints(maxWidth: 250),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                message.senderName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              message.message,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(top: BorderSide(color: Colors.grey[700]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendChatMessage(text.trim());
                      chatController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () {
                  if (chatController.text.trim().isNotEmpty) {
                    _sendChatMessage(chatController.text.trim());
                    chatController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendChatMessage(String message) {
    final timestamp = DateTime.now();
    final senderName = '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim();
    
    // Broadcast message via Socket.IO to all participants
    _socket?.emit('send_group_message', {
      'channelName': _channelName,
      'message': message,
      'senderName': senderName,
      'senderId': widget.currentUser.id,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  Widget _buildVideoGrid() {
    // Calculate total participants (local user + remote users)
    final totalParticipants = _remoteUsers.length + 1;
    
    // Determine grid layout based on participant count
    int crossAxisCount;
    if (totalParticipants == 1) {
      crossAxisCount = 1;
    } else if (totalParticipants == 2) {
      crossAxisCount = 2;
    } else if (totalParticipants <= 4) {
      crossAxisCount = 2;
    } else if (totalParticipants <= 9) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3, // More rectangular cards like Google Meet
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
            child: _isVideoEnabled
                ? const HtmlElementView(viewType: _localVideoViewId)
                : Container(
                    color: Colors.grey[850],
                    child: Center(
                      child: widget.currentUser.profilePicture != null && widget.currentUser.profilePicture!.isNotEmpty
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: CachedNetworkImageProvider(widget.currentUser.profilePicture!),
                              backgroundColor: Colors.grey[700],
                            )
                          : CircleAvatar(
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

  Widget _buildScreenShareLayout() {
    final localUid = _webService?.localUid;
    
    return Row(
      children: [
        // Main screen share area - show the screen being shared
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: _buildScreenShareVideo(_screenSharingUid!),
            ),
          ),
        ),
        // Sidebar with ALL participants (including local user)
        Container(
          width: 200,
          color: Colors.grey[900],
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Show local user in sidebar
              if (localUid != null) _buildCompactVideo(localUid, isLocal: true),
              // Show all remote users in sidebar
              ..._remoteUsers.map((uid) => _buildCompactVideo(uid)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScreenShareVideo(int uid) {
    final localUid = _webService?.localUid;
    final isLocalSharing = uid == localUid;
    final presenterName = isLocalSharing
        ? 'You'
        : (_userNames[uid] ?? 'Unknown User');
    
    Widget videoWidget;
    
    if (isLocalSharing) {
      // Show local screen share
      videoWidget = HtmlElementView(
        key: ValueKey('screen-share-$uid'),
        viewType: _localVideoViewId,
      );
    } else {
      // Show remote screen share
      final viewId = _remoteVideoViewIds[uid];
      if (viewId == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading screen share...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      }
      
      videoWidget = HtmlElementView(
        key: ValueKey('screen-share-$uid'),
        viewType: viewId,
      );
    }
    
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(child: videoWidget),
          // Top presenter badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.screen_share,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$presenterName ${isLocalSharing ? "are" : "is"} presenting',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isLocalSharing && _screenShareWithAudio) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVideo(int uid, {bool isLocal = false}) {
    final isMuted = isLocal ? _isMuted : (_userStatuses[uid]?['isMuted'] ?? true);
    final userName = isLocal 
        ? '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim()
        : _userNames[uid] ?? 'User $uid';
    
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocal ? Colors.blue : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: isLocal ? _buildLocalCameraPreview() : _buildRemoteVideo(uid),
          ),
          // Name label at bottom
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMuted)
                    const Icon(
                      Icons.mic_off,
                      color: Colors.red,
                      size: 12,
                    ),
                  if (isMuted) const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildLocalCameraPreview() {
    // Show camera feed (not screen share) in compact view
    return _isVideoEnabled
        ? const HtmlElementView(viewType: _localVideoViewId)
        : Container(
            color: Colors.grey[850],
            child: Center(
              child: widget.currentUser.profilePicture != null && widget.currentUser.profilePicture!.isNotEmpty
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: CachedNetworkImageProvider(widget.currentUser.profilePicture!),
                      backgroundColor: Colors.grey[700],
                    )
                  : CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Text(
                        (widget.currentUser.firstName?.isNotEmpty ?? false)
                            ? widget.currentUser.firstName![0].toUpperCase()
                            : 'Y',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
            child: _isVideoEnabled
                ? const HtmlElementView(viewType: _localVideoViewId)
                : Container(
                    color: Colors.grey[850],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.currentUser.profilePicture != null && widget.currentUser.profilePicture!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: CachedNetworkImageProvider(widget.currentUser.profilePicture!),
                                  backgroundColor: Colors.grey[700],
                                )
                              : CircleAvatar(
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
                          const SizedBox(height: 8),
                          Text(
                            '${widget.currentUser.firstName ?? ''} ${widget.currentUser.lastName ?? ''}'.trim(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Screen sharing indicator
          if (_isSharingScreen)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.screen_share,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sharing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Mic status indicator
          if (_isMuted)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
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

  Widget _buildRemoteVideo(int uid) {
    final userName = _userNames[uid] ?? 'User $uid';
    final viewId = _remoteVideoViewIds[uid];
    final profilePicture = _userProfilePictures[uid];
    final isCameraOff = _userStatuses[uid]?['isCameraOff'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: viewId != null && !isCameraOff
                ? HtmlElementView(viewType: viewId)
                : Center(
                    child: profilePicture != null && profilePicture.isNotEmpty
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: CachedNetworkImageProvider(profilePicture),
                            backgroundColor: Colors.grey[700],
                          )
                        : CircleAvatar(
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
          // Mic mute indicator for remote user
          if (_userStatuses[uid]?['isMuted'] == true)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
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
          icon: _webService?.localVideoTrack == null
              ? Icons.videocam_off_outlined
              : (_isVideoEnabled ? Icons.videocam : Icons.videocam_off),
          onPressed: _toggleVideo,
          backgroundColor: _webService?.localVideoTrack == null
              ? Colors.orange
              : (!_isVideoEnabled ? Colors.red : Colors.grey[700]!),
        ),
        const SizedBox(height: 20),
        
        // Screen share button
        _buildCircularButton(
          icon: _isSharingScreen ? Icons.stop_screen_share : Icons.screen_share,
          onPressed: (_screenSharingUid != null && !_isSharingScreen) ? null : _toggleScreenShare,
          backgroundColor: _isSharingScreen
              ? Colors.green
              : (_screenSharingUid != null ? Colors.grey[600]! : Colors.grey[700]!),
        ),
        const SizedBox(height: 20),
        
        // End call button
        _buildCircularButton(
          icon: Icons.call_end,
          onPressed: _leaveCall,
          backgroundColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback? onPressed,
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
          child: Icon(
            icon, 
            color: onPressed == null ? Colors.grey : Colors.white, 
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
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
          Container(
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
                  'Camera switching is available on mobile app',
                  style: TextStyle(
                    color: Colors.blue[200],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: 'Mute',
                onPressed: _toggleMute,
                backgroundColor: _isMuted ? Colors.red : Colors.grey[800]!,
                iconColor: Colors.white,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: _webService?.localVideoTrack == null
                    ? Icons.videocam_off_outlined
                    : (_isVideoEnabled ? Icons.videocam : Icons.videocam_off),
                label: _webService?.localVideoTrack == null
                    ? 'No camera'
                    : 'Stop Video',
                onPressed: _toggleVideo,
                backgroundColor: _webService?.localVideoTrack == null
                    ? Colors.orange
                    : (!_isVideoEnabled ? Colors.red : Colors.grey[800]!),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: _isSharingScreen
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                label: _isSharingScreen
                    ? 'Stop sharing'
                    : (_screenSharingUid != null ? 'Someone sharing' : 'Share screen'),
                onPressed: (_screenSharingUid != null && !_isSharingScreen) ? null : _toggleScreenShare,
                backgroundColor: _isSharingScreen
                    ? Colors.green
                    : (_screenSharingUid != null ? Colors.grey[700]! : Colors.grey[800]!),
                iconColor: (_screenSharingUid != null && !_isSharingScreen) ? Colors.grey : Colors.white,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: Icons.call_end,
                label: 'End',
                onPressed: _leaveCall,
                backgroundColor: Colors.red,
                iconColor: Colors.white,
                isEndCall: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color iconColor,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          elevation: 2,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: iconColor, size: 26),
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
}
