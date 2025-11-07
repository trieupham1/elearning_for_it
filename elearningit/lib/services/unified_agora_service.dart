// services/unified_agora_service.dart
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../config/agora_config.dart';

/// Unified Agora service that works on ALL platforms (web, mobile, desktop)
/// Agora RTC Engine 6.x supports web platform natively!
class UnifiedAgoraService {
  RtcEngine? _engine;
  final StreamController<int> _remoteUidController =
      StreamController<int>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();

  Stream<int> get remoteUid => _remoteUidController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isVideoEnabled = false;
  bool _isSpeakerOn = true;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  RtcEngine? get engine => _engine;

  Future<void> initialize() async {
    print('🎯 Initializing Unified Agora SDK (works on ALL platforms)...');

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ Successfully joined channel: ${connection.channelId}');
          _connectionStateController.add('connected');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('👤 Remote user joined: $remoteUid');
          _remoteUidController.add(remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              print('👋 Remote user left: $remoteUid');
              _connectionStateController.add('ended');
            },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora error: $err - $msg');
        },
        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              print('🔗 Connection state changed: $state (reason: $reason)');
            },
      ),
    );

    print('✅ Unified Agora SDK initialized');
  }

  Future<void> joinVoiceChannel(String channelName, {String? token}) async {
    print('🎤 Joining voice channel: $channelName');
    if (token != null) {
      print('🔐 Using authentication token');
    }

    // Enable audio
    await _engine!.enableAudio();

    // Join channel with user ID 0 (auto-assigned)
    await _engine!.joinChannel(
      token: token ?? '', // Use provided token or empty string
      channelId: channelName,
      uid: 0, // 0 means auto-assign
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );

    _isVideoEnabled = false;
    print('✅ Joined voice channel successfully');
  }

  Future<void> joinVideoChannel(String channelName, {String? token}) async {
    print('📹 Joining video channel: $channelName');
    if (token != null) {
      print('🔐 Using authentication token');
    }

    // Enable video and audio
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();

    // Join channel
    await _engine!.joinChannel(
      token: token ?? '', // Use provided token or empty string
      channelId: channelName,
      uid: 0, // 0 means auto-assign
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );

    _isVideoEnabled = true;
    _isCameraOff = false; // Camera starts ON
    print('✅ Joined video channel successfully');
  }

  Future<void> leaveChannel() async {
    print('📴 Leaving Agora channel...');
    await _engine?.leaveChannel();
    print('✅ Left channel');
  }

  Future<void> toggleMicrophone() async {
    _isMuted = !_isMuted;
    await _engine?.muteLocalAudioStream(_isMuted);
    print('🎤 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    _isVideoEnabled = !_isCameraOff;
    await _engine?.muteLocalVideoStream(_isCameraOff);
    print('📹 Camera ${_isVideoEnabled ? 'enabled' : 'disabled'}');
  }

  Future<void> switchCamera() async {
    print('🔄 Switching camera...');
    await _engine?.switchCamera();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine?.setEnableSpeakerphone(_isSpeakerOn);
    print('🔊 Speaker ${_isSpeakerOn ? 'on' : 'off'}');
  }

  Future<void> dispose() async {
    print('🧹 Disposing Unified Agora service...');
    await _engine?.leaveChannel();
    await _engine?.release();
    _remoteUidController.close();
    _connectionStateController.close();
    print('✅ Unified Agora service disposed');
  }
}
