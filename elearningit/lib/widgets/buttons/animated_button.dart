import 'package:flutter/material.dart';

/// An animated button widget that provides visual feedback with scale animation
/// and optional loading state.
///
/// Features:
/// - Scale animation on press
/// - Loading state with spinner
/// - Ripple effect
/// - Customizable colors and styles
///
/// Example:
/// ```dart
/// AnimatedButton(
///   onPressed: () async {
///     await submitForm();
///   },
///   text: 'Submit',
///   icon: Icons.send,
/// )
/// ```
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final EdgeInsetsGeometry padding;

  const AnimatedButton({
    super.key,
    this.onPressed,
    this.onPressedAsync,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : assert(
          onPressed != null || onPressedAsync != null,
          'Either onPressed or onPressedAsync must be provided',
        );

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isProcessing || widget.isLoading) return;

    // Animate button press
    await _controller.forward();
    await _controller.reverse();

    // Handle async operations
    if (widget.onPressedAsync != null) {
      setState(() => _isProcessing = true);
      try {
        await widget.onPressedAsync!();
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } else if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = widget.onPressed == null && widget.onPressedAsync == null;
    final bool showLoading = widget.isLoading || _isProcessing;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ElevatedButton(
          onPressed: isDisabled || showLoading ? null : _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? theme.primaryColor,
            foregroundColor: widget.foregroundColor ?? Colors.white,
            padding: widget.padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            elevation: 2,
            shadowColor: theme.primaryColor.withOpacity(0.4),
          ),
          child: showLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// An animated outlined button variant
class AnimatedOutlinedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final String text;
  final IconData? icon;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const AnimatedOutlinedButton({
    super.key,
    this.onPressed,
    this.onPressedAsync,
    required this.text,
    this.icon,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.isLoading = false,
  });

  @override
  State<AnimatedOutlinedButton> createState() => _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<AnimatedOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isProcessing || widget.isLoading) return;

    await _controller.forward();
    await _controller.reverse();

    if (widget.onPressedAsync != null) {
      setState(() => _isProcessing = true);
      try {
        await widget.onPressedAsync!();
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } else if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool showLoading = widget.isLoading || _isProcessing;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: OutlinedButton(
          onPressed: showLoading ? null : _handlePress,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.foregroundColor ?? theme.primaryColor,
            side: BorderSide(
              color: widget.borderColor ?? theme.primaryColor,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          child: showLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? theme.primaryColor,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A floating action button with scale animation
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: _handlePress,
        tooltip: widget.tooltip,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        child: Icon(widget.icon),
      ),
    );
  }
}
