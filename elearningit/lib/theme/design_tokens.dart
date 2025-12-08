/// Design tokens for consistent spacing, sizing, and styling across the app.
/// 
/// This provides a centralized location for all design constants to ensure
/// visual consistency and make it easier to update the design system.

import 'package:flutter/material.dart';

class DesignTokens {
  // Prevent instantiation
  DesignTokens._();

  // ============================================================
  // SPACING
  // ============================================================
  
  /// Extra small spacing: 4px
  static const double space4 = 4.0;
  
  /// Small spacing: 8px
  static const double space8 = 8.0;
  
  /// Medium-small spacing: 12px
  static const double space12 = 12.0;
  
  /// Medium spacing: 16px (most common)
  static const double space16 = 16.0;
  
  /// Medium-large spacing: 20px
  static const double space20 = 20.0;
  
  /// Large spacing: 24px
  static const double space24 = 24.0;
  
  /// Extra large spacing: 32px
  static const double space32 = 32.0;
  
  /// XXL spacing: 48px
  static const double space48 = 48.0;
  
  /// XXXL spacing: 64px
  static const double space64 = 64.0;

  // ============================================================
  // BORDER RADIUS
  // ============================================================
  
  /// Extra small radius: 4px
  static const double radiusXSmall = 4.0;
  
  /// Small radius: 8px
  static const double radiusSmall = 8.0;
  
  /// Medium radius: 12px (most common)
  static const double radiusMedium = 12.0;
  
  /// Large radius: 16px
  static const double radiusLarge = 16.0;
  
  /// Extra large radius: 20px
  static const double radiusXLarge = 20.0;
  
  /// XXL radius: 24px
  static const double radiusXXLarge = 24.0;
  
  /// Circular radius: 999px
  static const double radiusCircular = 999.0;

  // ============================================================
  // ELEVATION (Shadow depth)
  // ============================================================
  
  /// No elevation
  static const double elevationNone = 0.0;
  
  /// Small elevation: 2px
  static const double elevationSmall = 2.0;
  
  /// Medium elevation: 4px
  static const double elevationMedium = 4.0;
  
  /// Large elevation: 8px
  static const double elevationLarge = 8.0;
  
  /// Extra large elevation: 12px
  static const double elevationXLarge = 12.0;
  
  /// XXL elevation: 16px
  static const double elevationXXLarge = 16.0;

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================
  
  /// Extra fast duration: 100ms
  static const Duration durationXFast = Duration(milliseconds: 100);
  
  /// Fast duration: 200ms
  static const Duration durationFast = Duration(milliseconds: 200);
  
  /// Normal duration: 300ms (most common)
  static const Duration durationNormal = Duration(milliseconds: 300);
  
  /// Slow duration: 500ms
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  /// Extra slow duration: 800ms
  static const Duration durationXSlow = Duration(milliseconds: 800);

  // ============================================================
  // ICON SIZES
  // ============================================================
  
  /// Extra small icon: 16px
  static const double iconXSmall = 16.0;
  
  /// Small icon: 20px
  static const double iconSmall = 20.0;
  
  /// Medium icon: 24px (default)
  static const double iconMedium = 24.0;
  
  /// Large icon: 32px
  static const double iconLarge = 32.0;
  
  /// Extra large icon: 48px
  static const double iconXLarge = 48.0;
  
  /// XXL icon: 64px
  static const double iconXXLarge = 64.0;

  // ============================================================
  // FONT SIZES
  // ============================================================
  
  /// Extra small text: 10px
  static const double fontXSmall = 10.0;
  
  /// Small text: 12px
  static const double fontSmall = 12.0;
  
  /// Regular text: 14px (body text)
  static const double fontRegular = 14.0;
  
  /// Medium text: 16px
  static const double fontMedium = 16.0;
  
  /// Large text: 18px
  static const double fontLarge = 18.0;
  
  /// Extra large text: 20px
  static const double fontXLarge = 20.0;
  
  /// Heading 4: 24px
  static const double fontH4 = 24.0;
  
  /// Heading 3: 28px
  static const double fontH3 = 28.0;
  
  /// Heading 2: 32px
  static const double fontH2 = 32.0;
  
  /// Heading 1: 36px
  static const double fontH1 = 36.0;

  // ============================================================
  // FONT WEIGHTS
  // ============================================================
  
  /// Light weight: 300
  static const FontWeight fontWeightLight = FontWeight.w300;
  
  /// Regular weight: 400
  static const FontWeight fontWeightRegular = FontWeight.w400;
  
  /// Medium weight: 500
  static const FontWeight fontWeightMedium = FontWeight.w500;
  
  /// Semi-bold weight: 600
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  
  /// Bold weight: 700
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  /// Extra bold weight: 800
  static const FontWeight fontWeightXBold = FontWeight.w800;

  // ============================================================
  // OPACITY
  // ============================================================
  
  /// Disabled opacity: 38%
  static const double opacityDisabled = 0.38;
  
  /// Medium opacity: 54%
  static const double opacityMedium = 0.54;
  
  /// High opacity: 87%
  static const double opacityHigh = 0.87;

  // ============================================================
  // BUTTON SIZES
  // ============================================================
  
  /// Small button height: 32px
  static const double buttonHeightSmall = 32.0;
  
  /// Medium button height: 40px
  static const double buttonHeightMedium = 40.0;
  
  /// Large button height: 48px
  static const double buttonHeightLarge = 48.0;
  
  /// Extra large button height: 56px
  static const double buttonHeightXLarge = 56.0;

  // ============================================================
  // CARD SIZES
  // ============================================================
  
  /// Small card padding: 12px
  static const double cardPaddingSmall = 12.0;
  
  /// Medium card padding: 16px
  static const double cardPaddingMedium = 16.0;
  
  /// Large card padding: 20px
  static const double cardPaddingLarge = 20.0;
  
  /// Card border width: 1px
  static const double cardBorderWidth = 1.0;

  // ============================================================
  // BREAKPOINTS (for responsive design)
  // ============================================================
  
  /// Mobile breakpoint: 768px
  static const double breakpointMobile = 768.0;
  
  /// Tablet breakpoint: 1024px
  static const double breakpointTablet = 1024.0;
  
  /// Desktop breakpoint: 1200px
  static const double breakpointDesktop = 1200.0;
  
  /// Large desktop breakpoint: 1440px
  static const double breakpointLargeDesktop = 1440.0;

  // ============================================================
  // CONSTRAINTS
  // ============================================================
  
  /// Maximum content width: 1200px
  static const double maxContentWidth = 1200.0;
  
  /// Maximum dialog width: 600px
  static const double maxDialogWidth = 600.0;
  
  /// Maximum form width: 480px
  static const double maxFormWidth = 480.0;
  
  /// Minimum touch target: 44px
  static const double minTouchTarget = 44.0;

  // ============================================================
  // APP BAR
  // ============================================================
  
  /// App bar height: 56px
  static const double appBarHeight = 56.0;
  
  /// Bottom navigation height: 56px
  static const double bottomNavHeight = 56.0;

  // ============================================================
  // DIVIDER
  // ============================================================
  
  /// Divider thickness: 1px
  static const double dividerThickness = 1.0;
  
  /// Divider indent: 16px
  static const double dividerIndent = 16.0;
}

/// Extension on num to make spacing more readable
extension SpacingExtension on num {
  /// Returns a SizedBox with width
  Widget get horizontalBox => SizedBox(width: toDouble());
  
  /// Returns a SizedBox with height
  Widget get verticalBox => SizedBox(height: toDouble());
}
