import 'package:flutter/material.dart';

/// Transition styles for different navigation contexts.
enum PageTransitionType {
  /// Slide in from the right (standard forward navigation).
  slideRight,

  /// Slide in from the bottom (modal-style screens).
  slideUp,

  /// Scale up from center (root-level replacements like login → home).
  scale,
}

/// A premium [PageRouteBuilder] that replaces [MaterialPageRoute] with
/// smooth, eased tween animations.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    PageTransitionType type = PageTransitionType.slideRight,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         opaque: true,
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 150),
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildTransition(
             type: type,
             animation: animation,
             secondaryAnimation: secondaryAnimation,
             child: child,
           );
         },
       );

  static Widget _buildTransition({
    required PageTransitionType type,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    switch (type) {
      case PageTransitionType.slideRight:
        return _slideRightTransition(animation, secondaryAnimation, child);
      case PageTransitionType.slideUp:
        return _slideUpTransition(animation, child);
      case PageTransitionType.scale:
        return _scaleTransition(animation, child);
    }
  }

  /// Slide from right — only the incoming page animates; the page below stays
  static Widget _slideRightTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutExpo;

    final inTween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: curve));

    return SlideTransition(position: inTween.animate(animation), child: child);
  }

  /// Slide up from bottom (modal feel).
  static Widget _slideUpTransition(Animation<double> animation, Widget child) {
    final inTween = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutExpo));

    return SlideTransition(position: inTween.animate(animation), child: child);
  }

  /// Subtle scale up from center (for root-level replacements).
  static Widget _scaleTransition(Animation<double> animation, Widget child) {
    final scaleTween = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOutExpo));

    return ScaleTransition(scale: scaleTween.animate(animation), child: child);
  }
}
