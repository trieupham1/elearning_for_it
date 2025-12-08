import 'package:flutter/material.dart';
import 'package:elearningit/theme/design_tokens.dart';

/// A shimmer loading widget that displays an animated shimmer effect.
/// 
/// This widget is used to show a loading state with a smooth animation
/// that gives users visual feedback while content is being loaded.
/// 
/// Example:
/// ```dart
/// ShimmerLoading(
///   width: 200,
///   height: 20,
///   borderRadius: BorderRadius.circular(8),
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  /// Width of the shimmer widget
  final double? width;
  
  /// Height of the shimmer widget
  final double? height;
  
  /// Border radius of the shimmer widget
  final BorderRadius? borderRadius;
  
  /// Base color of the shimmer (defaults to theme-based color)
  final Color? baseColor;
  
  /// Highlight color of the shimmer (defaults to theme-based color)
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(DesignTokens.radiusSmall),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton loader widget for card-like items.
/// 
/// Displays a shimmer loading effect in a card layout, commonly used
/// for loading course cards, assignment cards, etc.
/// 
/// Example:
/// ```dart
/// SkeletonLoader()
/// ```
class SkeletonLoader extends StatelessWidget {
  /// Whether to show the avatar/image section
  final bool showImage;
  
  /// Number of lines to show
  final int lines;
  
  /// Padding around the skeleton
  final EdgeInsets? padding;

  const SkeletonLoader({
    super.key,
    this.showImage = true,
    this.lines = 3,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space8,
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.all(DesignTokens.cardPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showImage) ...[
              ShimmerLoading(
                width: double.infinity,
                height: 150,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              SizedBox(height: DesignTokens.space16),
            ],
            ShimmerLoading(
              width: double.infinity,
              height: 20,
            ),
            SizedBox(height: DesignTokens.space12),
            ShimmerLoading(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
            ),
            if (lines > 2) ...[
              SizedBox(height: DesignTokens.space8),
              ShimmerLoading(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A skeleton loader for list items.
/// 
/// Shows a shimmer effect for a single list item with optional leading icon.
/// 
/// Example:
/// ```dart
/// SkeletonListTile(showLeading: true)
/// ```
class SkeletonListTile extends StatelessWidget {
  /// Whether to show the leading icon/avatar
  final bool showLeading;
  
  /// Whether to show the trailing section
  final bool showTrailing;

  const SkeletonListTile({
    super.key,
    this.showLeading = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space12,
      ),
      child: Row(
        children: [
          if (showLeading) ...[
            ShimmerLoading(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
            ),
            SizedBox(width: DesignTokens.space16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                ),
                SizedBox(height: DesignTokens.space8),
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            SizedBox(width: DesignTokens.space16),
            ShimmerLoading(
              width: 60,
              height: 32,
            ),
          ],
        ],
      ),
    );
  }
}

/// A skeleton grid loader for grid layouts.
/// 
/// Shows multiple skeleton cards in a grid pattern.
/// 
/// Example:
/// ```dart
/// SkeletonGrid(itemCount: 6)
/// ```
class SkeletonGrid extends StatelessWidget {
  /// Number of skeleton items to show
  final int itemCount;
  
  /// Number of columns in the grid
  final int crossAxisCount;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(DesignTokens.space16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: DesignTokens.space16,
        mainAxisSpacing: DesignTokens.space16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                ),
                SizedBox(height: DesignTokens.space12),
                ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                ),
                SizedBox(height: DesignTokens.space8),
                ShimmerLoading(
                  width: 80,
                  height: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
