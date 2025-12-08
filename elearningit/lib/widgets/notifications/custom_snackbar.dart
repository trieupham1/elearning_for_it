import 'package:flutter/material.dart';
import 'package:elearningit/theme/design_tokens.dart';

/// Custom styled snackbars with icons and colors for different message types.
/// 
/// Provides a consistent and visually appealing way to show notifications,
/// success messages, errors, warnings, and info messages to users.
/// 
/// Example:
/// ```dart
/// CustomSnackbar.showSuccess(context, 'Assignment submitted successfully!');
/// CustomSnackbar.showError(context, 'Failed to load course data');
/// ```
class CustomSnackbar {
  CustomSnackbar._();

  /// Shows a success message with green color and checkmark icon
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Shows an error message with red color and error icon
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade600,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel ?? 'Retry',
    );
  }

  /// Shows a warning message with orange color and warning icon
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_outlined,
      backgroundColor: Colors.orange.shade700,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Shows an info message with blue color and info icon
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blue.shade700,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Shows a custom message with specified icon and color
  static void showCustom(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Internal method to show the snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // Hide any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: DesignTokens.iconMedium,
            ),
            SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontMedium,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        margin: EdgeInsets.all(DesignTokens.space16),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
              )
            : null,
      ),
    );
  }

  /// Shows a loading snackbar that doesn't auto-dismiss
  static void showLoading(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: DesignTokens.iconSmall,
              height: DesignTokens.iconSmall,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: DesignTokens.space16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        margin: EdgeInsets.all(DesignTokens.space16),
        duration: const Duration(days: 365), // Effectively indefinite
      ),
    );
  }

  /// Hides the current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

/// Extension on BuildContext for easier snackbar access
extension SnackbarExtension on BuildContext {
  /// Shows a success snackbar
  void showSuccessSnackbar(String message) {
    CustomSnackbar.showSuccess(this, message);
  }

  /// Shows an error snackbar
  void showErrorSnackbar(String message) {
    CustomSnackbar.showError(this, message);
  }

  /// Shows a warning snackbar
  void showWarningSnackbar(String message) {
    CustomSnackbar.showWarning(this, message);
  }

  /// Shows an info snackbar
  void showInfoSnackbar(String message) {
    CustomSnackbar.showInfo(this, message);
  }

  /// Hides current snackbar
  void hideSnackbar() {
    CustomSnackbar.hide(this);
  }
}
