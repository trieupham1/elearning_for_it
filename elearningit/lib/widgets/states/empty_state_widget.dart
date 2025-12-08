import 'package:flutter/material.dart';
import 'package:elearningit/theme/design_tokens.dart';

/// A widget to display when a list or view is empty.
/// 
/// Provides a visually appealing empty state with an icon, title, message,
/// and optional action button to guide users on what to do next.
/// 
/// Example:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.assignment_outlined,
///   title: 'No Assignments Yet',
///   message: 'Your assignments will appear here once your instructor posts them.',
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display (typically from Icons)
  final IconData icon;
  
  /// Title text to display
  final String title;
  
  /// Descriptive message explaining why it's empty
  final String message;
  
  /// Optional action button callback
  final VoidCallback? onAction;
  
  /// Optional action button label
  final String? actionLabel;
  
  /// Icon color (defaults to theme's disabled color)
  final Color? iconColor;
  
  /// Icon size
  final double iconSize;
  
  /// Whether to show the illustration in a colored container
  final bool showBackground;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
    this.iconColor,
    this.iconSize = 80.0,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.onSurface.withOpacity(0.3);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with optional background
            if (showBackground)
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              )
            else
              Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            
            SizedBox(height: DesignTokens.space24),
            
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: DesignTokens.space12),
            
            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action button (if provided)
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: DesignTokens.space32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space24,
                    vertical: DesignTokens.space16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Preset empty state for common scenarios.
class EmptyStates {
  EmptyStates._();

  /// Empty state for no courses
  static Widget noCourses({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.school_outlined,
      title: 'No Courses Available',
      message:
          'You haven\'t enrolled in any courses yet. Browse available courses to get started.',
      actionLabel: 'Browse Courses',
      onAction: onAction,
    );
  }

  /// Empty state for no assignments
  static Widget noAssignments({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.assignment_outlined,
      title: 'No Assignments Yet',
      message:
          'Your assignments will appear here once your instructor posts them.',
      actionLabel: onAction != null ? 'Refresh' : null,
      onAction: onAction,
    );
  }

  /// Empty state for no quizzes
  static Widget noQuizzes({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.quiz_outlined,
      title: 'No Quizzes Available',
      message: 'Quizzes will be listed here when they become available.',
      actionLabel: onAction != null ? 'Refresh' : null,
      onAction: onAction,
    );
  }

  /// Empty state for no materials
  static Widget noMaterials({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.folder_outlined,
      title: 'No Materials Found',
      message:
          'Course materials like documents and videos will appear here.',
      actionLabel: onAction != null ? 'Refresh' : null,
      onAction: onAction,
    );
  }

  /// Empty state for no messages
  static Widget noMessages({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.message_outlined,
      title: 'No Messages',
      message: 'Start a conversation to see your messages here.',
      actionLabel: onAction != null ? 'New Message' : null,
      onAction: onAction,
    );
  }

  /// Empty state for no notifications
  static Widget noNotifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_outlined,
      title: 'All Caught Up!',
      message: 'You don\'t have any notifications at the moment.',
      showBackground: true,
    );
  }

  /// Empty state for no search results
  static Widget noSearchResults(String query) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching "$query"',
      showBackground: false,
    );
  }

  /// Empty state for no students
  static Widget noStudents({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No Students Enrolled',
      message: 'Students will appear here once they enroll in your course.',
      actionLabel: onAction != null ? 'Invite Students' : null,
      onAction: onAction,
    );
  }

  /// Empty state for no submissions
  static Widget noSubmissions() {
    return const EmptyStateWidget(
      icon: Icons.upload_file_outlined,
      title: 'No Submissions Yet',
      message: 'Student submissions will appear here after the deadline.',
    );
  }

  /// Empty state for no data/generic error
  static Widget noData({String? message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.inbox_outlined,
      title: 'No Data Available',
      message: message ?? 'There\'s nothing to show here right now.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  /// Empty state for network error
  static Widget networkError({required VoidCallback onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'Connection Error',
      message:
          'Unable to load data. Please check your internet connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }

  /// Empty state for error
  static Widget error({required String message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      message: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}
