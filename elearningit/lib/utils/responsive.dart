import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Utility class for responsive design breakpoints and adaptive values.
/// 
/// Provides methods to determine device type and return appropriate values
/// based on screen size for creating responsive layouts.
/// 
/// Example:
/// ```dart
/// final columns = Responsive.value(
///   context: context,
///   mobile: 1,
///   tablet: 2,
///   desktop: 3,
/// );
/// ```
class Responsive {
  Responsive._();

  /// Returns true if the device is mobile sized (< 768px width)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < DesignTokens.breakpointMobile;
  }

  /// Returns true if the device is tablet sized (768px - 1200px width)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= DesignTokens.breakpointMobile &&
        width < DesignTokens.breakpointDesktop;
  }

  /// Returns true if the device is desktop sized (>= 1200px width)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= DesignTokens.breakpointDesktop;
  }

  /// Returns true if the device is large desktop sized (>= 1440px width)
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >=
        DesignTokens.breakpointLargeDesktop;
  }

  /// Returns an appropriate value based on the current screen size.
  /// 
  /// Provide values for different screen sizes, and the method will return
  /// the most appropriate one. If a value is not provided for a screen size,
  /// it will fall back to the next smaller size.
  /// 
  /// Example:
  /// ```dart
  /// final padding = Responsive.value(
  ///   context: context,
  ///   mobile: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Returns the number of columns for a grid based on screen size.
  /// 
  /// Example:
  /// ```dart
  /// GridView.builder(
  ///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  ///     crossAxisCount: Responsive.gridColumns(context),
  ///   ),
  /// )
  /// ```
  static int gridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Returns the current screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Returns the current screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Returns the maximum content width constrained by the design system
  static double maxContentWidth(BuildContext context) {
    final screenWidth = width(context);
    return screenWidth > DesignTokens.maxContentWidth
        ? DesignTokens.maxContentWidth
        : screenWidth;
  }

  /// Returns responsive padding based on screen size
  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.all(
      value(
        context: context,
        mobile: DesignTokens.space16,
        tablet: DesignTokens.space24,
        desktop: DesignTokens.space32,
      ),
    );
  }

  /// Returns responsive horizontal padding based on screen size
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value(
        context: context,
        mobile: DesignTokens.space16,
        tablet: DesignTokens.space24,
        desktop: DesignTokens.space32,
      ),
    );
  }

  /// Returns device type as a string (useful for debugging)
  static String deviceType(BuildContext context) {
    if (isLargeDesktop(context)) return 'Large Desktop';
    if (isDesktop(context)) return 'Desktop';
    if (isTablet(context)) return 'Tablet';
    return 'Mobile';
  }

  /// Returns true if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Returns true if the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
}

/// A responsive container that centers content and applies max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Color? color;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
          ),
          padding: padding ?? Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// A responsive row that changes to column on mobile
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool reverseOnMobile;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16.0,
    this.reverseOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final effectiveChildren = isMobile && reverseOnMobile
        ? children.reversed.toList()
        : children;

    if (isMobile) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _addSpacing(effectiveChildren, spacing, true),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacing(effectiveChildren, spacing, false),
    );
  }

  List<Widget> _addSpacing(List<Widget> children, double spacing, bool isColumn) {
    if (children.isEmpty) return children;
    
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(isColumn
            ? SizedBox(height: spacing)
            : SizedBox(width: spacing));
      }
    }
    return result;
  }
}

/// A responsive grid view that automatically adjusts columns
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}
