import 'package:flutter/material.dart';

/// Collection of custom page transitions for smooth navigation.
/// 
/// These transitions can be used instead of the default Material page route
/// to provide more polished and engaging navigation experiences.
/// 
/// Example:
/// ```dart
/// Navigator.push(
///   context,
///   SlideRightRoute(page: CourseDetailScreen()),
/// );
/// ```

/// Slide from right transition (Material Design style)
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Slide from left transition
class SlideLeftRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideLeftRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Slide from bottom transition (good for modals)
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
}

/// Fade transition (subtle and elegant)
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

/// Scale transition (zoom in effect)
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            
            var scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            
            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Rotation and fade transition (unique effect)
class RotationRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  RotationRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            
            var rotationAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            
            return FadeTransition(
              opacity: animation,
              child: RotationTransition(
                turns: rotationAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
}

/// Slide and fade combined transition (smooth and polished)
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset begin;
  
  SlideFadeRoute({
    required this.page,
    this.begin = const Offset(0.3, 0.0),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            const end = Offset.zero;
            
            var slideTween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Size transition (expands from center)
class SizeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SizeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return Align(
              alignment: Alignment.center,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// No transition (instant navigation)
class NoTransitionRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  NoTransitionRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

/// Extension on BuildContext for easier navigation with transitions
extension NavigationExtension on BuildContext {
  /// Navigate with slide right transition
  Future<T?> pushSlideRight<T extends Object?>(Widget page) {
    return Navigator.push<T>(this, SlideRightRoute<T>(page: page));
  }
  
  /// Navigate with slide left transition
  Future<T?> pushSlideLeft<T extends Object?>(Widget page) {
    return Navigator.push<T>(this, SlideLeftRoute<T>(page: page));
  }
  
  /// Navigate with slide up transition
  Future<T?> pushSlideUp<T extends Object?>(Widget page) {
    return Navigator.push<T>(this, SlideUpRoute<T>(page: page));
  }
  
  /// Navigate with fade transition
  Future<T?> pushFade<T extends Object?>(Widget page) {
    return Navigator.push<T>(this, FadeRoute<T>(page: page));
  }
  
  /// Navigate with scale transition
  Future<T?> pushScale<T extends Object?>(Widget page) {
    return Navigator.push<T>(this, ScaleRoute<T>(page: page));
  }
  
  /// Navigate with slide and fade transition
  Future<T?> pushSlideFade<T extends Object?>(Widget page) {
    return Navigator.push<T>(this, SlideFadeRoute<T>(page: page));
  }
  
  /// Replace current route with slide right transition
  Future<T?> pushReplacementSlideRight<T extends Object?, TO extends Object?>(Widget page) {
    return Navigator.pushReplacement<T, TO>(
      this,
      SlideRightRoute<T>(page: page),
    );
  }
}
