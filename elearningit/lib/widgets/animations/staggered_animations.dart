import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// A wrapper widget that adds staggered fade and slide animations to list items.
///
/// Features:
/// - Automatic staggered animation for ListView, GridView
/// - Configurable animation duration and delay
/// - Multiple animation styles (fade, slide, scale)
/// - Customizable animation direction
///
/// Example:
/// ```dart
/// AnimatedListView(
///   itemCount: items.length,
///   itemBuilder: (context, index) => ItemCard(items[index]),
/// )
/// ```
class AnimatedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Duration duration;
  final double verticalOffset;
  final AnimationStyle style;

  const AnimatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.duration = const Duration(milliseconds: 375),
    this.verticalOffset = 50.0,
    this.style = AnimationStyle.fadeSlide,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        controller: controller,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: duration,
            child: _buildAnimatedItem(
              itemBuilder(context, index),
              style,
              verticalOffset,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedItem(Widget child, AnimationStyle style, double offset) {
    switch (style) {
      case AnimationStyle.fadeSlide:
        return SlideAnimation(
          verticalOffset: offset,
          child: FadeInAnimation(child: child),
        );
      case AnimationStyle.scale:
        return ScaleAnimation(child: FadeInAnimation(child: child));
      case AnimationStyle.fade:
        return FadeInAnimation(child: child);
      case AnimationStyle.slideOnly:
        return SlideAnimation(verticalOffset: offset, child: child);
    }
  }
}

/// Animated grid view with staggered animations
class AnimatedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Duration duration;

  const AnimatedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.childAspectRatio = 1.0,
    this.controller,
    this.padding,
    this.duration = const Duration(milliseconds: 375),
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: GridView.builder(
        controller: controller,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: duration,
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated column with staggered children animations
class AnimatedColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration duration;
  final double verticalOffset;

  const AnimatedColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.duration = const Duration(milliseconds: 375),
    this.verticalOffset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: AnimationConfiguration.toStaggeredList(
          duration: duration,
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: verticalOffset,
            child: FadeInAnimation(child: widget),
          ),
          children: children,
        ),
      ),
    );
  }
}

/// A simple animated container that fades and slides in when built
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.slideOffset = const Offset(0, 50),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: _slideAnimation.value,
        child: widget.child,
      ),
    );
  }
}

/// Helper extension for easy animated wrapping
extension AnimatedWidgetExtension on Widget {
  /// Wraps widget with fade and slide animation
  Widget animateOnPageLoad({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 600),
    Offset slideOffset = const Offset(0, 50),
  }) {
    return AnimatedEntrance(
      delay: delay,
      duration: duration,
      slideOffset: slideOffset,
      child: this,
    );
  }
}

/// Animation style options
enum AnimationStyle {
  fadeSlide,
  scale,
  fade,
  slideOnly,
}

/// Staggered list wrapper for existing ListViews
class StaggeredListWrapper extends StatelessWidget {
  final Widget child;
  final int itemCount;
  final Duration duration;

  const StaggeredListWrapper({
    super.key,
    required this.child,
    required this.itemCount,
    this.duration = const Duration(milliseconds: 375),
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: child,
    );
  }
}

/// Helper widget for staggered item in a list
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final AnimationStyle style;
  final double verticalOffset;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 375),
    this.style = AnimationStyle.fadeSlide,
    this.verticalOffset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      child: _buildAnimatedItem(child, style, verticalOffset),
    );
  }

  Widget _buildAnimatedItem(Widget child, AnimationStyle style, double offset) {
    switch (style) {
      case AnimationStyle.fadeSlide:
        return SlideAnimation(
          verticalOffset: offset,
          child: FadeInAnimation(child: child),
        );
      case AnimationStyle.scale:
        return ScaleAnimation(child: FadeInAnimation(child: child));
      case AnimationStyle.fade:
        return FadeInAnimation(child: child);
      case AnimationStyle.slideOnly:
        return SlideAnimation(verticalOffset: offset, child: child);
    }
  }
}
