// services/agora_web_service.dart
@JS()
library agora_web;

import 'dart:async';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/agora_config.dart';

/// Agora Web SDK service using JavaScript interop
/// This uses the AgoraRTC JavaScript SDK loaded in index.html
class AgoraWebService {
  dynamic _client;
  dynamic _localAudioTrack;
  dynamic _localVideoTrack;
  dynamic _remoteVideoTrack;
  dynamic _remoteUser;

  final StreamController<int> _remoteUidController =
      StreamController<int>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();

  Stream<int> get remoteUid => _remoteUidController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isVideoEnabled = false;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isVideoEnabled => _isVideoEnabled;

  Future<void> initialize() async {
    if (!kIsWeb) {
      throw Exception('AgoraWebService can only be used on web platform');
    }

    print('🌐 Initializing Agora Web SDK...');

    try {
      // Create Agora client using JavaScript interop
      _client = AgoraRTC.createClient(ClientConfig(mode: 'rtc', codec: 'vp8'));

      // Register event handlers
      js_util.callMethod(_client, 'on', [
        'user-published',
        allowInterop((user, mediaType) async {
          print(
            '👤 Remote user published: ${js_util.getProperty(user, 'uid')}, mediaType: $mediaType',
          );

          await promiseToFuture(
            js_util.callMethod(_client, 'subscribe', [user, mediaType]),
          );
          print(
            '✅ Subscribed to remote user ${js_util.getProperty(user, 'uid')}',
          );

          if (mediaType == 'audio') {
            final remoteAudioTrack = js_util.getProperty(user, 'audioTrack');
            if (remoteAudioTrack != null) {
              js_util.callMethod(remoteAudioTrack, 'play', []);
            }
            _remoteUidController.add(js_util.getProperty(user, 'uid') as int);
          }

          if (mediaType == 'video') {
            // Store remote video track for rendering
            _remoteVideoTrack = js_util.getProperty(user, 'videoTrack');
            _remoteUser = user;
            print('📹 Remote video track received, ready to render');
            _remoteUidController.add(js_util.getProperty(user, 'uid') as int);
          }
        }),
      ]);

      js_util.callMethod(_client, 'on', [
        'user-unpublished',
        allowInterop((user, mediaType) {
          print(
            '👋 Remote user unpublished: ${js_util.getProperty(user, 'uid')}, mediaType: $mediaType',
          );
          // Don't end call on unpublish - user might just be muting/toggling
          // Only log the event
        }),
      ]);

      js_util.callMethod(_client, 'on', [
        'user-left',
        allowInterop((user, reason) {
          print(
            '👋 Remote user left: ${js_util.getProperty(user, 'uid')}, reason: $reason',
          );
          // Only end call when user actually leaves (not just unpublishes tracks)
          _connectionStateController.add('ended');
        }),
      ]);

      print('✅ Agora Web SDK initialized');
    } catch (e) {
      print('❌ Error initializing Agora Web SDK: $e');
      rethrow;
    }
  }

  Future<void> joinVoiceChannel(String channelName, {String? token}) async {
    print('🎤 Joining voice channel: $channelName');
    if (token != null) {
      print('🔐 Using authentication token');
    }

    try {
      // Join the channel
      await promiseToFuture(
        js_util.callMethod(_client, 'join', [
          AgoraConfig.appId,
          channelName,
          token, // Use provided token or null
          null, // uid (null for auto-assign)
        ]),
      );
      print('✅ Joined channel successfully');

      // Create and publish local audio track
      _localAudioTrack = await promiseToFuture(
        AgoraRTC.createMicrophoneAudioTrack(),
      );
      await promiseToFuture(
        js_util.callMethod(_client, 'publish', [
          js_util.jsify([_localAudioTrack]),
        ]),
      );

      _isVideoEnabled = false;
      _connectionStateController.add('connected');

      print('✅ Published local audio track');
    } catch (e) {
      print('❌ Error joining voice channel: $e');
      rethrow;
    }
  }

  Future<void> joinVideoChannel(String channelName, {String? token}) async {
    print('📹 Joining video channel: $channelName');
    if (token != null) {
      print('🔐 Using authentication token');
    }

    try {
      // Join the channel
      await promiseToFuture(
        js_util.callMethod(_client, 'join', [
          AgoraConfig.appId,
          channelName,
          token, // Use provided token or null
          null, // uid
        ]),
      );
      print('✅ Joined channel successfully');

      // Create local audio and video tracks
      _localAudioTrack = await promiseToFuture(
        AgoraRTC.createMicrophoneAudioTrack(),
      );
      _localVideoTrack = await promiseToFuture(
        AgoraRTC.createCameraVideoTrack(),
      );

      // Publish tracks
      await promiseToFuture(
        js_util.callMethod(_client, 'publish', [
          js_util.jsify([_localAudioTrack, _localVideoTrack]),
        ]),
      );

      _isVideoEnabled = true;
      _isCameraOff = false; // Camera starts ON
      _connectionStateController.add('connected');

      print('✅ Published local audio and video tracks');
    } catch (e) {
      print('❌ Error joining video channel: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    print('📴 Leaving Agora channel...');
    print('📍 Stack trace: ${StackTrace.current}');

    try {
      // Close local tracks
      if (_localAudioTrack != null) {
        js_util.callMethod(_localAudioTrack, 'close', []);
      }
      if (_localVideoTrack != null) {
        js_util.callMethod(_localVideoTrack, 'close', []);
      }

      // Leave the channel
      if (_client != null) {
        await promiseToFuture(js_util.callMethod(_client, 'leave', []));
      }

      _localAudioTrack = null;
      _localVideoTrack = null;

      print('✅ Left channel');
    } catch (e) {
      print('❌ Error leaving channel: $e');
    }
  }

  Future<void> toggleMicrophone() async {
    print(
      '🔧 toggleMicrophone called - current state: ${_isMuted ? "muted" : "unmuted"}',
    );
    _isMuted = !_isMuted;
    if (_localAudioTrack != null) {
      print('🔧 Calling setEnabled(${!_isMuted}) on audio track');
      await promiseToFuture(
        js_util.callMethod(_localAudioTrack, 'setEnabled', [!_isMuted]),
      );
      print('🎤 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
    } else {
      print('⚠️ WARNING: localAudioTrack is null!');
    }
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    _isVideoEnabled = !_isCameraOff;
    if (_localVideoTrack != null) {
      await promiseToFuture(
        js_util.callMethod(_localVideoTrack, 'setEnabled', [_isVideoEnabled]),
      );

      // If re-enabling camera, replay the video to the container
      if (_isVideoEnabled) {
        print('🔄 Re-playing local video after re-enabling camera');
        // Small delay to ensure track is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          playLocalVideo('local-video-container');
        });
      }
    }
    print('📹 Camera ${_isVideoEnabled ? 'enabled' : 'disabled'}');
  }

  Future<void> switchCamera() async {
    // Not applicable for web (user can select camera via browser permissions)
    print('🔄 Camera switching not supported on web');
  }

  Future<void> toggleSpeaker() async {
    // Speaker control handled by browser on web
    print('🔊 Speaker control handled by browser');
  }

  Future<void> dispose() async {
    print('🧹 Disposing Agora Web service...');
    await leaveChannel();
    _remoteUidController.close();
    _connectionStateController.close();
    print('✅ Agora Web service disposed');
  }

  // Getters for tracks (for video rendering)
  dynamic get localVideoTrack => _localVideoTrack;
  dynamic get remoteVideoTrack => _remoteVideoTrack;
  dynamic get client => _client;

  // Play local video in HTML element
  void playLocalVideo(String elementId) {
    if (_localVideoTrack != null) {
      print('▶️ Playing local video in element: $elementId');
      js_util.callMethod(_localVideoTrack, 'play', [elementId]);
    }
  }

  // Play remote video in HTML element
  void playRemoteVideo(String elementId) {
    if (_remoteVideoTrack != null) {
      print('▶️ Playing remote video in element: $elementId');
      js_util.callMethod(_remoteVideoTrack, 'play', [elementId]);
    }
  }
}

// JavaScript interop definitions
@JS('AgoraRTC')
external AgoraRTCType get AgoraRTC;

@JS()
@anonymous
class AgoraRTCType {
  external dynamic createClient(ClientConfig config);
  external dynamic createMicrophoneAudioTrack();
  external dynamic createCameraVideoTrack();
}

@JS()
@anonymous
class ClientConfig {
  external String get mode;
  external String get codec;

  external factory ClientConfig({String mode, String codec});
}

// Helper to convert JavaScript Promise to Dart Future
Future<T> promiseToFuture<T>(dynamic jsPromise) {
  return js_util.promiseToFuture<T>(jsPromise);
}
