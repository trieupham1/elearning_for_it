// services/agora_web_service_stub.dart
// Stub implementation for non-web platforms
import 'dart:async';

/// Stub for AgoraWebService on non-web platforms
class AgoraWebService {
  final StreamController<int> _remoteUidController =
      StreamController<int>.broadcast();
  final StreamController<int> _remoteUserLeftController =
      StreamController<int>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();
  final StreamController<bool> _screenShareStateController =
      StreamController<bool>.broadcast();
  final StreamController<int> _remoteVideoPublishedController =
      StreamController<int>.broadcast();

  Stream<int> get remoteUid => _remoteUidController.stream;
  Stream<int> get remoteUserLeft => _remoteUserLeftController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;
  Stream<bool> get screenShareState => _screenShareStateController.stream;
  Stream<int> get remoteVideoPublished => _remoteVideoPublishedController.stream;
  int? get localUid => null;

  bool get isMuted => false;
  bool get isCameraOff => false;
  bool get isVideoEnabled => true;
  bool get isSharingScreen => false;
  dynamic get localScreenTrack => null;

  Future<void> initialize() async {
    throw Exception('AgoraWebService can only be used on web platform');
  }

  Future<void> joinChannel(String channelName, {String? token}) async {
    throw Exception('AgoraWebService can only be used on web platform');
  }

  Future<void> joinVideoChannel(String channelName, {String? token}) async {
    throw Exception('AgoraWebService can only be used on web platform');
  }

  Future<void> leaveChannel() async {}

  Future<void> toggleMicrophone() async {}

  Future<void> toggleCamera() async {}

  Future<void> toggleScreenShare({bool includeAudio = false}) async {}

  Future<void> startScreenShare({bool includeAudio = false}) async {}

  Future<void> stopScreenShare() async {}

  void playLocalVideo(String elementId) {}

  void playRemoteVideo(int uid, String elementId) {}

  bool hasRemoteVideoTrack(int uid) => false;

  void dispose() {
    _remoteUidController.close();
    _remoteUserLeftController.close();
    _connectionStateController.close();
    _screenShareStateController.close();
    _remoteVideoPublishedController.close();
  }
}
