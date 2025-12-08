import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elearningit/widgets/loading/shimmer_loading.dart';

/// Optimized network image widget with caching, placeholders, and error handling.
///
/// Features:
/// - Automatic caching
/// - Memory-optimized image resizing
/// - Shimmer loading placeholder
/// - Error fallback
/// - Fade-in animation
///
/// Example:
/// ```dart
/// OptimizedImage(
///   imageUrl: course.imageUrl,
///   width: 200,
///   height: 150,
/// )
/// ```
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? (width != null ? (width! * 2).toInt() : 800),
      memCacheHeight: memCacheHeight ?? (height != null ? (height! * 2).toInt() : null),
      placeholder: (context, url) => placeholder ?? ShimmerLoading(
        width: width ?? double.infinity,
        height: height ?? 200,
        borderRadius: borderRadius,
      ),
      errorWidget: (context, url, error) => errorWidget ?? Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Optimized circular avatar image with caching
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;
  final Color? textColor;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        child: Text(
          fallbackText?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        child: Text(
          fallbackText?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      memCacheWidth: (radius * 4).toInt(),
      memCacheHeight: (radius * 4).toInt(),
    );
  }
}

/// Image with aspect ratio and optimized caching
class OptimizedAspectImage extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OptimizedAspectImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: OptimizedImage(
        imageUrl: imageUrl,
        fit: fit,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Thumbnail image with fixed size and aggressive caching
class ThumbnailImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const ThumbnailImage({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
    );
  }
}

/// Hero image for course/content headers
class HeroImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final Widget? overlay;
  final Gradient? gradient;

  const HeroImage({
    super.key,
    required this.imageUrl,
    this.height = 200,
    this.overlay,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OptimizedImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
        ),
        if (gradient != null)
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: gradient,
            ),
          ),
        if (overlay != null)
          Positioned.fill(child: overlay!),
      ],
    );
  }
}

/// Image gallery item with zoom capability
class GalleryImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GalleryImage({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: imageUrl,
        child: OptimizedImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Helper extension for easy OptimizedImage usage
extension OptimizedImageExtension on String {
  /// Convert URL string to OptimizedImage widget
  Widget toOptimizedImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return OptimizedImage(
      imageUrl: this,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Convert URL string to OptimizedAvatar widget
  Widget toAvatar({
    double radius = 20,
    String? fallbackText,
  }) {
    return OptimizedAvatar(
      imageUrl: this,
      radius: radius,
      fallbackText: fallbackText,
    );
  }

  /// Convert URL string to ThumbnailImage widget
  Widget toThumbnail({
    double size = 64,
    BorderRadius? borderRadius,
  }) {
    return ThumbnailImage(
      imageUrl: this,
      size: size,
      borderRadius: borderRadius,
    );
  }
}
