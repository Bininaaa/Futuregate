import 'package:flutter/material.dart';

/// Custom page transition: fade + subtle horizontal slide on enter,
/// gentle dim on the page being pushed behind.
class _AppFadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _AppFadeSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enterCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final leaveCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(enterCurve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0.0),
          end: Offset.zero,
        ).animate(enterCurve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.88).animate(leaveCurve),
          child: child,
        ),
      ),
    );
  }
}

const appPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: _AppFadeSlideTransitionsBuilder(),
    TargetPlatform.iOS: _AppFadeSlideTransitionsBuilder(),
    TargetPlatform.macOS: _AppFadeSlideTransitionsBuilder(),
    TargetPlatform.linux: _AppFadeSlideTransitionsBuilder(),
    TargetPlatform.windows: _AppFadeSlideTransitionsBuilder(),
    TargetPlatform.fuchsia: _AppFadeSlideTransitionsBuilder(),
  },
);
