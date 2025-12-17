import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A responsive scaffold that handles common layout issues
/// - Constrains max width on large screens
/// - Prevents horizontal overflow
/// - Adds proper padding for different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final double maxWidth;
  final bool centerContent;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.maxWidth = 1400,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > maxWidth;
          
          Widget content = body;
          
          if (isWideScreen && centerContent) {
            content = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: body,
              ),
            );
          }
          
          return content;
        },
      ),
    );
  }
}

/// Extension to add safe text that won't overflow
extension SafeTextExtension on String {
  /// Returns a Text widget that handles overflow gracefully
  Widget safeText({
    TextStyle? style,
    int maxLines = 1,
    TextAlign? textAlign,
  }) {
    return Text(
      this,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

/// A responsive container that adjusts padding based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets padding;
        
        if (constraints.maxWidth >= 1200) {
          padding = desktopPadding ?? const EdgeInsets.all(32);
        } else if (constraints.maxWidth >= 768) {
          padding = tabletPadding ?? const EdgeInsets.all(24);
        } else {
          padding = mobilePadding ?? const EdgeInsets.all(16);
        }
        
        Widget content = Padding(
          padding: padding,
          child: child,
        );
        
        if (maxWidth != null && constraints.maxWidth > maxWidth!) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: content,
            ),
          );
        }
        
        return content;
      },
    );
  }
}

/// A responsive grid that adjusts columns based on screen width
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.childAspectRatio = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        double aspectRatio = childAspectRatio;
        
        if (constraints.maxWidth >= 1200) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= 768) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
          // Adjust aspect ratio for mobile to prevent overflow
          aspectRatio = childAspectRatio * 1.1;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Helper class for responsive breakpoints
class ScreenBreakpoints {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Returns appropriate value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
}
