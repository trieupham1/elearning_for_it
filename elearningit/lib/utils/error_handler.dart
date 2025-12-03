// lib/utils/error_handler.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'logger_service.dart';

/// Centralized error handling utility.
/// 
/// Provides consistent error handling patterns across the application.
/// 
/// Example:
/// ```dart
/// final courses = await ErrorHandler.handleServiceError<List<Course>>(
///   'Load courses',
///   () => courseService.getCourses(),
///   fallback: [],
/// );
/// ```
class ErrorHandler {
  /// Handles service operation errors with optional fallback value.
  /// 
  /// Logs errors using [LoggerService] and optionally provides a fallback value.
  /// 
  /// [operation] - Description of the operation for logging
  /// [action] - The async function to execute
  /// [fallback] - Value to return on error (optional, if null, rethrows)
  /// 
  /// Returns the result of [action] or [fallback] on error.
  /// 
  /// Example:
  /// ```dart
  /// // With fallback (silent failure)
  /// final users = await ErrorHandler.handleServiceError<List<User>>(
  ///   'Fetch users',
  ///   () => adminService.getAllUsers(),
  ///   fallback: [],
  /// );
  /// 
  /// // Without fallback (propagates error)
  /// final user = await ErrorHandler.handleServiceError<User>(
  ///   'Create user',
  ///   () => adminService.createUser(userData),
  /// );
  /// ```
  static Future<T> handleServiceError<T>(
    String operation,
    Future<T> Function() action, {
    T? fallback,
  }) async {
    try {
      return await action();
    } on ApiException catch (e, stack) {
      LoggerService.error('$operation failed: ${e.message}', e, stack);
      if (fallback != null) return fallback;
      rethrow;
    } catch (e, stack) {
      LoggerService.error('$operation failed', e, stack);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  /// Shows error dialog to user with a user-friendly message.
  /// 
  /// [context] - BuildContext for showing dialog
  /// [title] - Dialog title
  /// [error] - The error object
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await service.deleteUser(userId);
  /// } catch (e) {
  ///   ErrorHandler.showErrorDialog(context, 'Delete Failed', e);
  /// }
  /// ```
  static void showErrorDialog(BuildContext context, String title, Object error) {
    final message = _getUserFriendlyMessage(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows error snackbar with brief error message.
  /// 
  /// [context] - BuildContext for showing snackbar
  /// [error] - The error object
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await service.updateCourse(courseId, data);
  /// } catch (e) {
  ///   ErrorHandler.showErrorSnackbar(context, e);
  /// }
  /// ```
  static void showErrorSnackbar(BuildContext context, Object error) {
    final message = _getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Converts technical error to user-friendly message.
  static String _getUserFriendlyMessage(Object error) {
    if (error is ApiException) {
      // API errors already have user-friendly messages
      return error.message;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || errorString.contains('network')) {
      return 'Cannot connect to server. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('format')) {
      return 'Invalid data format received from server.';
    }
    
    // Generic error message
    return 'An unexpected error occurred. Please try again later.';
  }

  /// Retries an operation with exponential backoff.
  /// 
  /// [operation] - Description for logging
  /// [action] - Function to retry
  /// [maxAttempts] - Maximum retry attempts (default: 3)
  /// [initialDelay] - Initial delay in seconds (default: 1)
  /// 
  /// Returns the result of successful [action].
  /// Throws the last error if all attempts fail.
  /// 
  /// Example:
  /// ```dart
  /// final data = await ErrorHandler.retryOperation(
  ///   'Fetch courses',
  ///   () => courseService.getCourses(),
  ///   maxAttempts: 3,
  /// );
  /// ```
  static Future<T> retryOperation<T>(
    String operation,
    Future<T> Function() action, {
    int maxAttempts = 3,
    int initialDelay = 1,
  }) async {
    int attempt = 0;
    
    while (true) {
      attempt++;
      try {
        LoggerService.info('$operation - Attempt $attempt/$maxAttempts');
        return await action();
      } catch (e, stack) {
        if (attempt >= maxAttempts) {
          LoggerService.error(
            '$operation failed after $maxAttempts attempts',
            e,
            stack,
          );
          rethrow;
        }
        
        final delaySeconds = initialDelay * attempt;
        LoggerService.warning(
          '$operation failed, retrying in ${delaySeconds}s... (Attempt $attempt/$maxAttempts)',
        );
        
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }
}
