// services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../screens/call/platform_incoming_call_screen.dart';
import '../config/agora_config.dart';
import '../main.dart'; // Import for navigatorKey

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _currentUserId;
  Function(dynamic)? _messageCallback; // Callback for new messages

  bool get isConnected => _socket?.connected ?? false;

  /// Initialize socket connection with user authentication
  Future<void> connect(String userId, BuildContext context) async {
    if (_socket?.connected == true) {
      print('🔌 Socket already connected');
      return;
    }

    _currentUserId = userId;

    try {
      print('🔌 Connecting to socket server at ${ApiConfig.baseUrl}');

      _socket = IO.io(
        ApiConfig.baseUrl,
        IO.OptionBuilder()
            // Use both polling and websocket - polling as fallback for mobile browsers
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        print('✅ Socket connected successfully');
        // Register user with their socket
        _socket!.emit('register', userId);
        print('📝 Registered user: $userId');
      });

      _socket!.onReconnect((_) {
        print('🔄 Socket reconnected - re-registering user');
        // Re-register user after reconnection
        _socket!.emit('register', userId);
        print('📝 Re-registered user: $userId');
      });

      _socket!.onDisconnect((_) {
        print('❌ Socket disconnected');
      });

      _socket!.onConnectError((error) {
        print('⚠️ Socket connection error: $error');
      });

      _socket!.onError((error) {
        print('⚠️ Socket error: $error');
      });

      // Listen for incoming calls
      _socket!.on('incoming_call', (data) {
        print('📞 Incoming call received: $data');
        _handleIncomingCall(data);
      });

      // Listen for call accepted
      _socket!.on('call_accepted', (data) {
        print('✅ Call accepted: $data');
        // Could add notification or update UI
      });

      // Listen for call rejected
      _socket!.on('call_rejected', (data) {
        print('❌ Call rejected: $data');

        // Close the call screen immediately
        try {
          final navigator = navigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            print('✅ Call screen closed - call was rejected/declined');
          } else {
            print('⚠️ Cannot pop - no navigator or already at root');
          }
        } catch (e) {
          print('⚠️ Error closing call screen: $e');
        }
      });

      // Listen for call ended
      _socket!.on('call_ended', (data) {
        print('📴 Call ended by other user: $data');

        // Simply pop the current screen (the call screen)
        try {
          final navigator = navigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            print('✅ Call screen closed due to remote hangup');
          } else {
            print('⚠️ Cannot pop - no navigator or already at root');
          }
        } catch (e) {
          print('⚠️ Error closing call screen: $e');
        }
      });

      // Listen for new messages (for real-time chat)
      _socket!.on('new_message', (data) {
        print('💬 New message received: $data');
        // Call the registered callback if it exists
        if (_messageCallback != null) {
          _messageCallback!(data);
        }
      });
    } catch (e) {
      print('⚠️ Error initializing socket: $e');
    }
  }

  /// Notify other user that call ended
  void notifyCallEnded(String callId, String otherUserId) {
    if (_socket?.connected == true) {
      _socket!.emit('call_ended', {
        'callId': callId,
        'otherUserId': otherUserId,
      });
      print('📤 Emitted call_ended for callId: $callId to user: $otherUserId');
    } else {
      print('⚠️ Cannot emit call_ended - socket not connected');
    }
  }

  /// Notify other user that call was rejected
  void notifyCallRejected(String callId, String otherUserId) {
    if (_socket?.connected == true) {
      _socket!.emit('call_rejected', {
        'callId': callId,
        'otherUserId': otherUserId,
      });
      print(
        '📤 Emitted call_rejected for callId: $callId to user: $otherUserId',
      );
    } else {
      print('⚠️ Cannot emit call_rejected - socket not connected');
    }
  }

  /// Handle incoming call event
  void _handleIncomingCall(dynamic data) {
    // Use global navigator key instead of stored context
    final currentContext = navigatorKey.currentContext;

    if (currentContext == null) {
      print('⚠️ No navigator context available to show incoming call');
      return;
    }

    try {
      print('🔍 Parsing incoming call data...');

      // Parse caller information
      final callId = data['callId'] as String?; // Get callId from backend
      final callerId = data['callerId'] as String?;
      final callerName = data['callerName'] as String? ?? 'Unknown';
      final callType = data['type'] as String? ?? 'voice';
      final channelName = data['channelName'] as String?;
      final callerData = data['caller'];

      print(
        '📋 Call details: callId=$callId, callerId=$callerId, type=$callType, channel=$channelName',
      );

      if (callerId == null || channelName == null) {
        print('⚠️ Missing caller ID or channel name');
        return;
      }

      // Don't show incoming call if it's from yourself
      if (callerId == _currentUserId) {
        print('⚠️ Ignoring call from self');
        return;
      }

      // Create User object from caller data
      User caller;
      if (callerData != null && callerData is Map) {
        print('📦 Creating User from caller data...');
        // Use User.fromJson to properly handle all fields
        caller = User.fromJson(Map<String, dynamic>.from(callerData));
      } else {
        print('📦 Creating fallback User from caller name...');
        // Fallback if caller data not provided
        final nameParts = callerName.split(' ');
        caller = User(
          id: callerId,
          email: '',
          firstName: nameParts.isNotEmpty ? nameParts[0] : 'Unknown',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          username: callerName,
          role: 'student',
        );
      }

      print(
        '📞 Showing incoming call screen for ${caller.firstName} ${caller.lastName}',
      );

      // Show incoming call screen using global navigator
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => PlatformIncomingCallScreen(
            caller: caller,
            channelName: channelName,
            isVideoCall: callType == 'video',
            callId: callId, // Pass callId
          ),
          fullscreenDialog: true,
        ),
      );

      print('✅ Incoming call screen pushed to navigator');
    } catch (e, stackTrace) {
      print('⚠️ Error handling incoming call: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Emit a custom event
  void emit(String event, dynamic data) {
    if (_socket?.connected == true) {
      _socket!.emit(event, data);
      print('📤 Emitted event: $event with data: $data');
    } else {
      print('⚠️ Cannot emit event - socket not connected');
    }
  }

  /// Listen to a custom event
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove listener for an event
  void off(String event) {
    _socket?.off(event);
  }

  /// Listen for new messages in a specific conversation
  void onNewMessage(Function(dynamic) callback) {
    print('📝 Registering new message callback');
    _messageCallback = callback;
  }

  /// Remove new message listener
  void offNewMessage() {
    print('🗑️ Removing new message callback');
    _messageCallback = null;
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket?.connected == true) {
      _socket!.disconnect();
      print('🔌 Socket disconnected');
    }
    _currentUserId = null;
  }

  /// Ensure socket is connected, reconnect if needed
  /// Call this when app comes back to foreground on mobile
  Future<void> ensureConnected() async {
    if (_currentUserId == null) {
      print('⚠️ Cannot reconnect - no user ID stored');
      return;
    }
    
    if (_socket == null) {
      print('⚠️ Socket not initialized - cannot reconnect');
      return;
    }
    
    if (!_socket!.connected) {
      print('🔄 Socket disconnected - attempting to reconnect...');
      _socket!.connect();
      
      // Wait a bit for connection
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_socket!.connected) {
        print('✅ Socket reconnected successfully');
        _socket!.emit('register', _currentUserId);
        print('📝 Re-registered user: $_currentUserId');
      } else {
        print('⚠️ Socket reconnection still pending...');
      }
    } else {
      print('✅ Socket already connected');
    }
  }

  /// Force reconnect the socket
  void forceReconnect() {
    if (_currentUserId != null && _socket != null) {
      print('🔄 Force reconnecting socket...');
      _socket!.disconnect();
      _socket!.connect();
    }
  }

  /// Get current socket connection status
  String getConnectionStatus() {
    if (_socket == null) {
      return '❌ Socket not initialized';
    } else if (_socket!.connected) {
      return '✅ Socket connected (User ID: $_currentUserId)';
    } else {
      return '⚠️ Socket disconnected';
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _currentUserId;
  }

  /// Update context (no longer needed with global navigator key)
  @Deprecated('Use global navigatorKey instead')
  void updateContext(BuildContext context) {
    // No-op: Using global navigator key now
  }
}
