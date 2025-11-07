// services/agora_service.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../config/agora_config.dart';

class AgoraService {
  // Agora App ID from config
  static String get appId => AgoraConfig.appId;

  RtcEngine? _engine;
  final StreamController<int> _remoteUidController =
      StreamController<int>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();

  Stream<int> get remoteUid => _remoteUidController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;

  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  String? _currentChannel;

  // Getters
  bool get isJoined => _isJoined;
  int? get remoteUserId => _remoteUid;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  RtcEngine? get engine => _engine;

  /// Initialize Agora engine
  Future<void> initialize() async {
    print('🎥 Initializing Agora SDK...');

    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    print('✅ Agora engine initialized');

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ Joined channel: ${connection.channelId}');
          _isJoined = true;
          _currentChannel = connection.channelId;
          _connectionStateController.add('connected');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('👤 Remote user joined: $remoteUid');
          _remoteUid = remoteUid;
          _remoteUidController.add(remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              print('👋 Remote user left: $remoteUid (reason: $reason)');
              if (_remoteUid == remoteUid) {
                _remoteUid = null;
                _connectionStateController.add('ended');
              }
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('📴 Left channel');
          _isJoined = false;
          _remoteUid = null;
          _currentChannel = null;
          _connectionStateController.add('disconnected');
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora error: $err - $msg');
        },
      ),
    );

    print('✅ Event handlers registered');
  }

  /// Join a channel for video call
  Future<void> joinVideoChannel(String channelName) async {
    if (_engine == null) {
      print('❌ Engine not initialized');
      return;
    }

    print('📞 Joining video channel: $channelName');

    // Enable video
    await _engine!.enableVideo();
    await _engine!.startPreview();

    // Join channel
    await _engine!.joinChannel(
      token: '', // Empty for testing, use token server in production
      channelId: channelName,
      uid: 0, // Auto-assign UID
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );

    print('✅ Joined video channel');
  }

  /// Join a channel for voice call (audio only)
  Future<void> joinVoiceChannel(String channelName) async {
    if (_engine == null) {
      print('❌ Engine not initialized');
      return;
    }

    print('📞 Joining voice channel: $channelName');

    // Disable video for voice call
    await _engine!.disableVideo();
    _isVideoEnabled = false;

    // Join channel
    await _engine!.joinChannel(
      token: '', // Empty for testing
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
      ),
    );

    print('✅ Joined voice channel');
  }

  /// Leave current channel
  Future<void> leaveChannel() async {
    if (_engine == null) return;

    print('📴 Leaving channel...');
    await _engine!.leaveChannel();
    _isJoined = false;
    _remoteUid = null;
    _currentChannel = null;
  }

  /// Toggle microphone on/off
  Future<void> toggleMicrophone() async {
    if (_engine == null) return;

    _isMuted = !_isMuted;
    await _engine!.muteLocalAudioStream(_isMuted);
    print('🎤 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
  }

  /// Toggle camera on/off
  Future<void> toggleCamera() async {
    if (_engine == null) return;

    _isVideoEnabled = !_isVideoEnabled;
    await _engine!.muteLocalVideoStream(!_isVideoEnabled);
    print('📹 Camera ${_isVideoEnabled ? 'enabled' : 'disabled'}');
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_engine == null) return;

    await _engine!.switchCamera();
    print('🔄 Camera switched');
  }

  /// Toggle speaker on/off
  Future<void> toggleSpeaker() async {
    if (_engine == null) return;

    _isSpeakerOn = !_isSpeakerOn;
    await _engine!.setEnableSpeakerphone(_isSpeakerOn);
    print('🔊 Speaker ${_isSpeakerOn ? 'on' : 'off'}');
  }

  /// Dispose and release resources
  Future<void> dispose() async {
    print('🧹 Disposing Agora service...');

    await _engine?.leaveChannel();
    await _engine?.release();

    _remoteUidController.close();
    _connectionStateController.close();

    _engine = null;
    _isJoined = false;
    _remoteUid = null;
    _currentChannel = null;

    print('✅ Agora service disposed');
  }
}
