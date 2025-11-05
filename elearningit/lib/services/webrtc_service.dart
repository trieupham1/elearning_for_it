// services/webrtc_service.dart
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import 'dart:async';

class IncomingCallData {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerUsername;
  final String? callerAvatar;
  final String callType;
  final dynamic offer; // Add offer for WebRTC

  IncomingCallData({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerUsername,
    this.callerAvatar,
    required this.callType,
    this.offer,
  });
}

class WebRTCService {
  IO.Socket? _socket;
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;

  final StreamController<webrtc.MediaStream> _remoteStreamController =
      StreamController<webrtc.MediaStream>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();
  final StreamController<IncomingCallData> _incomingCallController =
      StreamController<IncomingCallData>.broadcast();

  Stream<webrtc.MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;
  Stream<IncomingCallData> get incomingCalls => _incomingCallController.stream;

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

      // Emit incoming call event for UI to handle
      final incomingCall = IncomingCallData(
        callId: data['callId'],
        callerId: data['callerId'],
        callerName: data['callerName'] ?? 'Unknown',
        callerUsername: data['callerUsername'],
        callerAvatar: data['callerAvatar'],
        callType: data['type'] ?? 'video',
        offer: data['offer'], // Pass the WebRTC offer
      );
      
      _incomingCallController.add(incomingCall);
      print('✅ Incoming call emitted to stream');
      print('👤 Caller: ${incomingCall.callerName} (@${incomingCall.callerUsername})');
    });

    // Call answered
    _socket!.on('call_answered', (data) async {
      print('✅ Call answered event received');
      print('📞 Setting remote description (answer)...');
      final answer = webrtc.RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection?.setRemoteDescription(answer);
      print('✅ Remote description (answer) set successfully');
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
        final candidate = webrtc.RTCIceCandidate(
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
    // Use the flutter_webrtc package function with proper import
    _peerConnection = await webrtc.createPeerConnection(_configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (_otherUserId != null) {
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
        print('📹 Setting remote stream from track event');
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };

    // Also handle onAddStream for compatibility
    _peerConnection!.onAddStream = (stream) {
      print('📹 Received remote stream via onAddStream');
      _remoteStream = stream;
      _remoteStreamController.add(_remoteStream!);
    };

    _peerConnection!.onConnectionState = (state) {
      print('🔗 Connection state: $state');
      _connectionStateController.add(state.toString());
    };
  }

  // Initialize local media (audio/video)
  Future<webrtc.MediaStream> initializeLocalMedia({
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

    _localStream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

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
    print('📞 answerCall START - callId: $callId, callerId: $callerId');
    print('📞 Offer received: ${offer != null}');
    
    _currentCallId = callId;
    _otherUserId = callerId;

    print('📞 Creating peer connection...');
    await createPeerConnection();
    
    print('📞 Initializing local media...');
    await initializeLocalMedia(video: true, audio: true);

    // Set remote description from offer
    print('📞 Setting remote description (offer)...');
    final rtcOffer = webrtc.RTCSessionDescription(offer['sdp'], offer['type']);
    await _peerConnection!.setRemoteDescription(rtcOffer);
    print('✅ Remote description set');

    // Create answer
    print('📞 Creating answer...');
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    print('✅ Answer created and set as local description');

    // Send answer via socket
    print('📞 Sending answer via socket...');
    _socket!.emit('call_accepted', {
      'callId': callId,
      'callerId': callerId,
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
    print('✅ answerCall COMPLETE - answer sent');
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
      await webrtc.Helper.switchCamera(videoTrack);
    }
  }

  // Enable speaker
  void enableSpeaker(bool enabled) {
    webrtc.Helper.setSpeakerphoneOn(enabled);
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    final screenStream = await webrtc.navigator.mediaDevices.getDisplayMedia({
      'video': true,
    });

    // Replace video track
    if (_peerConnection != null && _localStream != null) {
      final senders = await _peerConnection!.getSenders();
      final sender = senders.firstWhere(
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
      final senders = await _peerConnection!.getSenders();
      final sender = senders.firstWhere(
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
  webrtc.MediaStream? get localStream => _localStream;

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
