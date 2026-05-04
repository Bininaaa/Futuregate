import 'package:flutter/material.dart';

/// Lightweight responsive sizing helpers.
///
/// Usage (screen-level):
///   final w = ResponsiveSize.width(context, 0.9);   // 90 % of screen
///   final h = ResponsiveSize.height(context, 0.12); // 12 % of screen
///
/// Usage (local, inside LayoutBuilder):
///   LayoutBuilder(builder: (ctx, box) {
///     final w = box.maxWidth * 0.45;
///     ...
///   })
class ResponsiveSize {
  const ResponsiveSize._();

  // ── Screen fractions ──────────────────────────────────────────────────────

  static double width(BuildContext context, double fraction) =>
      MediaQuery.sizeOf(context).width * fraction;

  static double height(BuildContext context, double fraction) =>
      MediaQuery.sizeOf(context).height * fraction;

  // ── Breakpoints ──────────────────────────────────────────────────────────

  /// Very small phones (< 360 px) — e.g. old Galaxy S, iPhone SE 1st gen.
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// Compact phones (360–414 px) — most Android / iPhone SE 2+.
  static bool isCompactPhone(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 360 && w < 414;
  }

  /// Large phones / small tablets (≥ 600 px).
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  // ── Adaptive values ───────────────────────────────────────────────────────

  /// Returns [small] on phones narrower than 360 px, [normal] otherwise.
  /// Optionally returns [large] on tablets (≥ 600 px).
  static double adaptive(
    BuildContext context, {
    required double small,
    required double normal,
    double? large,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (large != null && w >= 600) return large;
    if (w < 360) return small;
    return normal;
  }

  // ── Safe padding helpers ──────────────────────────────────────────────────

  static EdgeInsets symmetricH(BuildContext context, double fraction) {
    final pad = MediaQuery.sizeOf(context).width * fraction;
    return EdgeInsets.symmetric(horizontal: pad);
  }
}
