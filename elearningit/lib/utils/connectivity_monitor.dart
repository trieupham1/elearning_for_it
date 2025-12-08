import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../utils/logger_service.dart';

/// Service for monitoring network connectivity status.
///
/// Features:
/// - Real-time connectivity monitoring
/// - Connection type detection (WiFi, Mobile, None)
/// - Stream of connectivity changes
/// - Helper methods for checking connection status
///
/// Example:
/// ```dart
/// final monitor = ConnectivityMonitor();
/// 
/// // Check current status
/// if (await monitor.isConnected) {
///   // Make API call
/// }
/// 
/// // Listen to changes
/// monitor.onConnectivityChanged.listen((isConnected) {
///   if (!isConnected) {
///     showOfflineMessage();
///   }
/// });
/// ```
class ConnectivityMonitor {
  static final ConnectivityMonitor _instance = ConnectivityMonitor._internal();
  factory ConnectivityMonitor() => _instance;
  ConnectivityMonitor._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Stream of connection status changes (true = connected, false = disconnected)
  Stream<bool> get onConnectivityChanged => _connectionStatusController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Current connection type
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  /// Check if connected to WiFi
  bool get isWiFi => _connectionStatus.contains(ConnectivityResult.wifi);

  /// Check if connected to mobile data
  bool get isMobile => _connectionStatus.contains(ConnectivityResult.mobile);

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Get initial connection status
      _connectionStatus = await _connectivity.checkConnectivity();
      _isConnected = !_connectionStatus.contains(ConnectivityResult.none);
      
      LoggerService.info('Initial connectivity status: $_connectionStatus');

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged
          .listen(_updateConnectionStatus);
    } catch (e) {
      LoggerService.error('Error initializing connectivity monitor', e);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectionStatus = results;
    final wasConnected = _isConnected;
    _isConnected = !results.contains(ConnectivityResult.none);

    LoggerService.info('Connectivity changed: $results (Connected: $_isConnected)');

    // Only emit if status actually changed
    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
      LoggerService.info(
        _isConnected ? 'Device is now online' : 'Device is now offline',
      );
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _connectionStatus = results;
      _isConnected = !results.contains(ConnectivityResult.none);
      return _isConnected;
    } catch (e) {
      LoggerService.error('Error checking connectivity', e);
      return false;
    }
  }

  /// Get detailed connection info as string
  String getConnectionType() {
    if (!_isConnected) return 'No Connection';
    if (isWiFi) return 'WiFi';
    if (isMobile) return 'Mobile Data';
    return 'Connected';
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}

/// A widget that shows connection status banner
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final String offlineMessage;
  final String onlineMessage;
  final Duration showDuration;
  final bool showOnlineMessage;

  const ConnectivityBanner({
    super.key,
    required this.child,
    this.offlineMessage = 'No internet connection',
    this.onlineMessage = 'Back online',
    this.showDuration = const Duration(seconds: 3),
    this.showOnlineMessage = true,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final ConnectivityMonitor _monitor = ConnectivityMonitor();
  bool _showBanner = false;
  bool _isOnline = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _monitor.initialize();
    _monitor.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(bool isConnected) {
    setState(() {
      _isOnline = isConnected;
      _showBanner = true;
    });

    // Hide banner after duration
    if (isConnected && widget.showOnlineMessage) {
      _hideTimer?.cancel();
      _hideTimer = Timer(widget.showDuration, () {
        if (mounted) {
          setState(() => _showBanner = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _showBanner ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              child: Material(
                elevation: 4,
                color: _isOnline ? Colors.green : Colors.red,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _isOnline ? Icons.wifi : Icons.wifi_off,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isOnline ? widget.onlineMessage : widget.offlineMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!_isOnline)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() => _showBanner = false);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A widget that conditionally renders based on connectivity status
class ConnectivityBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isConnected) builder;

  const ConnectivityBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<ConnectivityBuilder> createState() => _ConnectivityBuilderState();
}

class _ConnectivityBuilderState extends State<ConnectivityBuilder> {
  final ConnectivityMonitor _monitor = ConnectivityMonitor();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _monitor.initialize().then((_) {
      setState(() => _isConnected = _monitor.isConnected);
    });
    _monitor.onConnectivityChanged.listen((isConnected) {
      setState(() => _isConnected = isConnected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isConnected);
  }
}
