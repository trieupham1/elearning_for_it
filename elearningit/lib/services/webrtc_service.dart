// services/webrtc_service.dart
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import 'dart:async';

class WebRTCService {
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;

  String? _currentUserId;
  String? _otherUserId;
  String? _currentCallId;

  // ICE servers configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  // Initialize socket connection
  Future<void> initializeSocket(String userId) async {
    _currentUserId = userId;

    _socket = IO.io(
      ApiConfig.getBaseUrl(),
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('🔌 Socket connected for WebRTC');
      _socket!.emit('register', userId);
    });

    _socket!.on('disconnect', (_) {
      print('🔌 Socket disconnected');
    });

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Incoming call
    _socket!.on('incoming_call', (data) async {
      print('📞 Incoming call: $data');
      _currentCallId = data['callId'];
      _otherUserId = data['callerId'];

      // This should trigger UI to show incoming call screen
      // You'll need to handle this in your call state management
    });

    // Call answered
    _socket!.on('call_answered', (data) async {
      print('✅ Call answered: $data');
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection?.setRemoteDescription(answer);
    });

    // Call rejected
    _socket!.on('call_rejected', (data) {
      print('❌ Call rejected');
      _connectionStateController.add('rejected');
      dispose();
    });

    // Call ended
    _socket!.on('call_ended', (data) {
      print('📴 Call ended by other user');
      _connectionStateController.add('ended');
      dispose();
    });

    // ICE candidate
    _socket!.on('ice_candidate', (data) async {
      print('🧊 Received ICE candidate');
      if (data['candidate'] != null) {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    });

    // Screen sharing started
    _socket!.on('screen_share_started', (data) {
      print('🖥️ Screen sharing started by other user');
      _connectionStateController.add('screen_sharing_started');
    });

    // Screen sharing stopped
    _socket!.on('screen_share_stopped', (data) {
      print('🖥️ Screen sharing stopped by other user');
      _connectionStateController.add('screen_sharing_stopped');
    });

    // Quality update
    _socket!.on('quality_update', (data) {
      print('📊 Quality update: ${data['quality']}');
    });
  }

  // Create peer connection
  Future<void> createPeerConnection() async {
    _peerConnection = await createPeerConnection(_configuration, _constraints);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null && _otherUserId != null) {
        _socket!.emit('ice_candidate', {
          'otherUserId': _otherUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      print('📹 Received remote track');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      print('🔗 Connection state: $state');
      _connectionStateController.add(state.toString());
    };
  }

  // Initialize local media (audio/video)
  Future<MediaStream> initializeLocalMedia({
    bool video = true,
    bool audio = true,
  }) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': audio,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // Add local stream tracks to peer connection
    if (_peerConnection != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    return _localStream!;
  }

  // Make a call
  Future<void> makeCall(String callId, String calleeId, String type) async {
    _currentCallId = callId;
    _otherUserId = calleeId;

    await createPeerConnection();
    await initializeLocalMedia(video: type == 'video', audio: true);

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send offer via socket
    _socket!.emit('call_initiated', {
      'callId': callId,
      'calleeId': calleeId,
      'callerName': 'User', // Pass actual name from user object
      'type': type,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  // Answer a call
  Future<void> answerCall(String callId, String callerId, dynamic offer) async {
    _currentCallId = callId;
    _otherUserId = callerId;

    await createPeerConnection();
    await initializeLocalMedia(video: true, audio: true);

    // Set remote description from offer
    final rtcOffer = RTCSessionDescription(offer['sdp'], offer['type']);
    await _peerConnection!.setRemoteDescription(rtcOffer);

    // Create answer
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Send answer via socket
    _socket!.emit('call_accepted', {
      'callId': callId,
      'callerId': callerId,
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  // Reject a call
  void rejectCall(String callId, String callerId) {
    _socket!.emit('call_rejected', {'callId': callId, 'callerId': callerId});
  }

  // End a call
  void endCall() {
    if (_currentCallId != null && _otherUserId != null) {
      _socket!.emit('call_ended', {
        'callId': _currentCallId,
        'otherUserId': _otherUserId,
      });
    }
    dispose();
  }

  // Toggle microphone
  Future<void> toggleMicrophone(bool enabled) async {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  // Toggle camera
  Future<void> toggleCamera(bool enabled) async {
    if (_localStream != null) {
      _localStream!.getVideoTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      await Helper.switchCamera(videoTrack);
    }
  }

  // Enable speaker
  void enableSpeaker(bool enabled) {
    Helper.setSpeakerphoneOn(enabled);
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    final screenStream = await navigator.mediaDevices.getDisplayMedia({
      'video': true,
    });

    // Replace video track
    if (_peerConnection != null && _localStream != null) {
      final sender = _peerConnection!.getSenders().firstWhere(
        (sender) => sender.track?.kind == 'video',
      );

      await sender.replaceTrack(screenStream.getVideoTracks()[0]);

      _socket!.emit('screen_share_started', {
        'callId': _currentCallId,
        'otherUserId': _otherUserId,
      });
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    if (_peerConnection != null && _localStream != null) {
      final sender = _peerConnection!.getSenders().firstWhere(
        (sender) => sender.track?.kind == 'video',
      );

      await sender.replaceTrack(_localStream!.getVideoTracks()[0]);

      _socket!.emit('screen_share_stopped', {
        'callId': _currentCallId,
        'otherUserId': _otherUserId,
      });
    }
  }

  // Get local stream
  MediaStream? get localStream => _localStream;

  // Dispose and cleanup
  void dispose() {
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _otherUserId = null;
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
