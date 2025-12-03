// lib/utils/logger_service.dart
import 'package:flutter/foundation.dart';

/// Centralized logging service for the application.
/// 
/// Provides structured logging with different severity levels.
/// Logs are only printed in debug mode to avoid cluttering production logs.
/// 
/// Example:
/// ```dart
/// LoggerService.info('User logged in successfully');
/// LoggerService.error('Failed to load courses', error, stackTrace);
/// LoggerService.network('GET /api/courses - Status: 200');
/// ```
class LoggerService {
  static const bool _isDebugMode = kDebugMode;
  static const String _prefix = '🎓 E-Learning';

  /// Logs informational messages.
  /// 
  /// Use for general information about app state changes.
  /// 
  /// [message] - The message to log
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.info('Course created successfully');
  /// ```
  static void info(String message) {
    if (_isDebugMode) {
      print('$_prefix ℹ️ $message');
    }
  }

  /// Logs error messages with optional error object and stack trace.
  /// 
  /// Use for exceptions and error conditions.
  /// 
  /// [message] - Error description
  /// [error] - The error/exception object (optional)
  /// [stack] - Stack trace for debugging (optional)
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await service.getData();
  /// } catch (e, stack) {
  ///   LoggerService.error('Failed to fetch data', e, stack);
  /// }
  /// ```
  static void error(String message, [Object? error, StackTrace? stack]) {
    if (_isDebugMode) {
      print('$_prefix ❌ $message');
      if (error != null) print('   Error: $error');
      if (stack != null) print('   Stack: $stack');
    }
  }

  /// Logs network-related messages.
  /// 
  /// Use for HTTP requests, responses, and API interactions.
  /// 
  /// [message] - Network operation description
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.network('POST /api/courses - Status: 201');
  /// ```
  static void network(String message) {
    if (_isDebugMode) {
      print('$_prefix 🌐 $message');
    }
  }

  /// Logs warning messages.
  /// 
  /// Use for non-critical issues that don't prevent functionality.
  /// 
  /// [message] - Warning description
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.warning('Cache miss, fetching from network');
  /// ```
  static void warning(String message) {
    if (_isDebugMode) {
      print('$_prefix ⚠️ $message');
    }
  }

  /// Logs success messages.
  /// 
  /// Use for successful operations completion.
  /// 
  /// [message] - Success message
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.success('Assignment submitted successfully');
  /// ```
  static void success(String message) {
    if (_isDebugMode) {
      print('$_prefix ✅ $message');
    }
  }

  /// Logs debug messages with detailed information.
  /// 
  /// Use for verbose debugging information during development.
  /// 
  /// [message] - Debug message
  /// [data] - Additional data to log (optional)
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.debug('User data loaded', user.toJson());
  /// ```
  static void debug(String message, [Object? data]) {
    if (_isDebugMode) {
      print('$_prefix 🔍 $message');
      if (data != null) print('   Data: $data');
    }
  }

  /// Logs performance-related messages.
  /// 
  /// Use for tracking operation timing and performance metrics.
  /// 
  /// [message] - Performance metric description
  /// 
  /// Example:
  /// ```dart
  /// final stopwatch = Stopwatch()..start();
  /// await someOperation();
  /// LoggerService.performance('Operation took ${stopwatch.elapsedMilliseconds}ms');
  /// ```
  static void performance(String message) {
    if (_isDebugMode) {
      print('$_prefix ⚡ $message');
    }
  }
}
