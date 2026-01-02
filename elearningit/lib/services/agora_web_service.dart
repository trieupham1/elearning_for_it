// services/agora_web_service.dart
@JS()
library agora_web;

import 'dart:async';
import 'dart:html' as html;
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
  dynamic _localScreenTrack;
  dynamic _remoteVideoTrack;
  dynamic _remoteUser;
  final Map<int, dynamic> _remoteVideoTracks = {}; // Store tracks per user

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
  int? get localUid => _localUid;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isVideoEnabled = true;
  bool _isSharingScreen = false;
  bool _wasVideoEnabledBeforeScreenShare = false;
  int? _localUid;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSharingScreen => _isSharingScreen;
  dynamic get localScreenTrack => _localScreenTrack;

  Future<void> initialize() async {
    if (!kIsWeb) {
      throw Exception('AgoraWebService can only be used on web platform');
    }

    print('🌐 Initializing Agora Web SDK...');

    try {
      // Create Agora client using JavaScript interop
      _client = AgoraRTC.createClient(ClientConfig(mode: 'rtc', codec: 'vp8'));

      // Register event handlers
      // Listen for user joining (even if they don't publish tracks yet)
      js_util.callMethod(_client, 'on', [
        'user-joined',
        allowInterop((user) {
          final uid = js_util.getProperty(user, 'uid') as int;
          print('👤 Remote user joined: $uid');
          _remoteUidController.add(uid);
        }),
      ]);

      js_util.callMethod(_client, 'on', [
        'user-published',
        allowInterop((user, mediaType) async {
          final uid = js_util.getProperty(user, 'uid') as int;
          print(
            '👤 Remote user published: $uid, mediaType: $mediaType',
          );

          await promiseToFuture(
            js_util.callMethod(_client, 'subscribe', [user, mediaType]),
          );
          print(
            '✅ Subscribed to remote user $uid',
          );

          if (mediaType == 'audio') {
            final remoteAudioTrack = js_util.getProperty(user, 'audioTrack');
            if (remoteAudioTrack != null) {
              js_util.callMethod(remoteAudioTrack, 'play', []);
            }
            // UID already added by user-joined event
          }

          if (mediaType == 'video') {
            // Store remote video track for rendering (both in single var and map)
            final videoTrack = js_util.getProperty(user, 'videoTrack');
            _remoteVideoTrack = videoTrack;
            _remoteUser = user;
            _remoteVideoTracks[uid] = videoTrack; // Store by UID
            print('📹 Remote video track received for UID $uid');

            // Notify that video is published so UI can refresh
            _remoteVideoPublishedController.add(uid);

            // Auto-play the video track in the remote video container
            if (videoTrack != null) {
              // Delay slightly to ensure container exists
              Future.delayed(const Duration(milliseconds: 200), () {
                try {
                  final containerId = 'remote-video-container-$uid';
                  js_util.callMethod(videoTrack, 'play', [containerId]);
                  print('▶️ Auto-playing remote video in container: $containerId');
                  // Disable pointer events so Flutter controls remain clickable
                  _disablePointerEventsOnContainer(containerId);
                } catch (e) {
                  print('⚠️ Could not play video for UID $uid: $e');
                }
              });
            }
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
          final uid = js_util.getProperty(user, 'uid') as int;
          print('👋 Remote user left: $uid, reason: $reason');
          // Notify about user leaving but don't end the call
          _remoteUserLeftController.add(uid);
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
      // Join the channel and get assigned UID
      _localUid = await promiseToFuture(
        js_util.callMethod(_client, 'join', [
          AgoraConfig.appId,
          channelName,
          token, // Use provided token or null
          null, // uid
        ]),
      );
      print('✅ Joined channel successfully with UID: $_localUid');

      // Create local audio track (required)
      _localAudioTrack = await promiseToFuture(
        AgoraRTC.createMicrophoneAudioTrack(),
      );

      // Try to create video track (optional - like Google Meet)
      try {
        _localVideoTrack = await promiseToFuture(
          AgoraRTC.createCameraVideoTrack(),
        );
        print('✅ Camera track created successfully');
      } catch (e) {
        print('⚠️ Camera not available: $e');
        print('📹 Continuing without camera (audio-only mode)');
        _localVideoTrack = null;
        _isCameraOff = true;
        _isVideoEnabled = false;
      }

      // Publish available tracks
      final tracksToPublish = <Object>[];
      if (_localAudioTrack != null) tracksToPublish.add(_localAudioTrack!);
      if (_localVideoTrack != null) tracksToPublish.add(_localVideoTrack!);

      if (tracksToPublish.isNotEmpty) {
        await promiseToFuture(
          js_util.callMethod(_client, 'publish', [
            js_util.jsify(tracksToPublish),
          ]),
        );
      }

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
    if (_localVideoTrack == null) {
      print('⚠️ Camera not available - cannot toggle');
      return;
    }

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
    _remoteUserLeftController.close();
    _connectionStateController.close();
    _screenShareStateController.close();
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
      // Disable pointer events on the video container so controls remain clickable
      _disablePointerEventsOnContainer(elementId);
    }
  }

  // Play remote video in HTML element for a specific user
  void playRemoteVideo(int uid, String elementId) {
    final track = _remoteVideoTracks[uid];
    if (track != null) {
      try {
        js_util.callMethod(track, 'play', [elementId]);
        print('▶️ Playing remote video for UID $uid in element: $elementId');
        _disablePointerEventsOnContainer(elementId);
        // Re-apply constraints after Agora fully renders (it creates elements async)
        Future.delayed(const Duration(milliseconds: 300), () {
          _disablePointerEventsOnContainer(elementId);
        });
      } catch (e) {
        print('⚠️ Error playing remote video for UID $uid: $e');
      }
    } else if (_remoteVideoTrack != null) {
      // Fallback to single track
      print('▶️ Playing remote video (fallback) in element: $elementId');
      js_util.callMethod(_remoteVideoTrack, 'play', [elementId]);
      _disablePointerEventsOnContainer(elementId);
      Future.delayed(const Duration(milliseconds: 300), () {
        _disablePointerEventsOnContainer(elementId);
      });
    } else {
      print('⚠️ No video track found for UID $uid');
    }
  }

  // Disable pointer events and constrain video size in container
  void _disablePointerEventsOnContainer(String elementId) {
    try {
      final element = html.document.getElementById(elementId);
      if (element != null) {
        // Make container constrain its children
        element.style.pointerEvents = 'none';
        element.style.position = 'relative';
        element.style.overflow = 'hidden';
        
        // Constrain all child divs (Agora creates wrapper divs)
        final divs = element.querySelectorAll('div');
        for (final div in divs) {
          (div as html.Element).style
            ..position = 'relative'
            ..width = '100%'
            ..height = '100%'
            ..pointerEvents = 'none';
        }
        
        // Constrain all video elements
        final videos = element.querySelectorAll('video');
        for (final video in videos) {
          (video as html.Element).style
            ..position = 'relative'
            ..width = '100%'
            ..height = '100%'
            ..objectFit = 'cover'
            ..pointerEvents = 'none';
        }
        print('✅ Constrained video in $elementId');
      }
    } catch (e) {
      print('⚠️ Could not constrain video: $e');
    }
  }

  // Check if we have a video track for a user
  bool hasRemoteVideoTrack(int uid) {
    return _remoteVideoTracks.containsKey(uid) && _remoteVideoTracks[uid] != null;
  }

  // Toggle screen sharing
  Future<void> toggleScreenShare({bool includeAudio = false}) async {
    if (_isSharingScreen) {
      // Stop screen sharing
      await stopScreenShare();
    } else {
      // Start screen sharing
      await startScreenShare(includeAudio: includeAudio);
    }
  }

  // Start screen sharing
  Future<void> startScreenShare({bool includeAudio = false}) async {
    try {
      print(
        '🖥️ Starting screen share (audio: ${includeAudio ? "enabled" : "disabled"})...',
      );

      // Save current camera state before screen share
      _wasVideoEnabledBeforeScreenShare = !_isCameraOff && _localVideoTrack != null;
      print('📹 Camera was ${_wasVideoEnabledBeforeScreenShare ? "ON" : "OFF"} before screen share');

      // STEP 1: ALWAYS unpublish camera video FIRST to avoid CAN_NOT_PUBLISH_MULTIPLE_VIDEO_TRACKS error
      if (_localVideoTrack != null) {
        print('📹 Unpublishing camera video before screen share...');
        try {
          await promiseToFuture(
            js_util.callMethod(_client, 'unpublish', [
              js_util.jsify([_localVideoTrack]),
            ]),
          );
          print('✅ Camera video unpublished');
        } catch (e) {
          print('⚠️ Error unpublishing camera (may not be published): $e');
        }
      }

      // STEP 2: Create screen video track
      // Audio options: 'enable' = system audio, 'disable' = no audio, 'auto' = let user choose
      final audioConfig = includeAudio ? 'enable' : 'disable';

      print('🎬 Creating screen share track...');
      _localScreenTrack = await promiseToFuture(
        AgoraRTC.createScreenVideoTrack(
          js_util.jsify({
            'encoderConfig': '1080p_1',
            'optimizationMode': 'detail',
          }),
          audioConfig,
        ),
      );

      // If screen track is an array (video + audio), extract video track
      if (js_util.hasProperty(_localScreenTrack, 'length')) {
        final tracks = js_util.getProperty(_localScreenTrack, '0');
        _localScreenTrack = tracks;
      }

      // STEP 3: Publish screen track
      print('📤 Publishing screen share track...');
      await promiseToFuture(
        js_util.callMethod(_client, 'publish', [
          js_util.jsify([_localScreenTrack]),
        ]),
      );

      // Listen for screen share ended (user clicks "Stop sharing" in browser)
      js_util.callMethod(_localScreenTrack, 'on', [
        'track-ended',
        allowInterop(() {
          print('🛑 Screen share ended by user');
          stopScreenShare();
          _screenShareStateController.add(false);
        }),
      ]);

      _isSharingScreen = true;
      _screenShareStateController.add(true);

      // Auto-play screen share in local video container
      if (_localScreenTrack != null) {
        js_util.callMethod(_localScreenTrack, 'play', [
          'local-video-container',
        ]);
        print('▶️ Playing screen share in local container');
      }

      print('✅ Screen sharing started');
    } catch (e) {
      print('❌ Error starting screen share: $e');
      _isSharingScreen = false;
      rethrow;
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      print('🛑 Stopping screen share...');

      if (_localScreenTrack != null) {
        // Unpublish screen track
        try {
          await promiseToFuture(
            js_util.callMethod(_client, 'unpublish', [
              js_util.jsify([_localScreenTrack]),
            ]),
          );
          print('✅ Screen track unpublished');
        } catch (e) {
          print('⚠️ Error unpublishing screen track: $e');
        }

        // Close and clean up screen track
        try {
          await promiseToFuture(
            js_util.callMethod(_localScreenTrack, 'close', []),
          );
          print('✅ Screen track closed');
        } catch (e) {
          print('⚠️ Error closing screen track: $e');
        }
        
        _localScreenTrack = null;
      }

      _isSharingScreen = false;
      _screenShareStateController.add(false);

      // Re-publish camera video if camera was on before screen share
      if (_localVideoTrack != null && _wasVideoEnabledBeforeScreenShare) {
        print('📹 Re-publishing camera video after screen share (was enabled before)...');
        
        // Wait a bit to ensure screen track is fully unpublished
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          await promiseToFuture(
            js_util.callMethod(_client, 'publish', [
              js_util.jsify([_localVideoTrack]),
            ]),
          );
          
          // Play the camera video again in local container
          playLocalVideo('local-video-container');
          
          // Reset camera off state since camera is now back on
          _isCameraOff = false;
          
          print('✅ Camera video re-published and playing');
        } catch (e) {
          print('⚠️ Error re-publishing camera: $e');
        }
      } else {
        print('📹 Camera was off before screen share, not republishing');
      }

      print('✅ Screen sharing stopped');
    } catch (e) {
      print('❌ Error stopping screen share: $e');
      _isSharingScreen = false;
      _screenShareStateController.add(false);
    }
  }

  // Play screen share in HTML element
  void playScreenShare(String elementId) {
    if (_localScreenTrack != null) {
      print('▶️ Playing screen share in element: $elementId');
      js_util.callMethod(_localScreenTrack, 'play', [elementId]);
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
  external dynamic createScreenVideoTrack(
    dynamic config,
    String screenAudioConfig,
  );
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
