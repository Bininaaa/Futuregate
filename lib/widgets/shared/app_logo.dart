import 'package:flutter/material.dart';

/// Shared branding widget. Renders the FutureGate logo PNG with a consistent
/// aspect ratio so it can be dropped into headers, auth flows, about screens
/// and drawers without worrying about stretching or odd padding.
class AppLogo extends StatelessWidget {
  final double height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final String? semanticLabel;

  const AppLogo({
    super.key,
    this.height = 48,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'FutureGate',
  });

  static const String assetPath = 'assets/images/branding/futuregate_logo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );

    if (backgroundColor == null && padding == EdgeInsets.zero) {
      return image;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: image,
    );
  }
}

/// Compact square logo mark used in pills, nav bars, and dense headers.
/// Wraps the wide logo inside a square tile so the proportions stay balanced.
class AppLogoMark extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double padding;

  const AppLogoMark({
    super.key,
    this.size = 32,
    this.backgroundColor,
    this.borderRadius,
    this.padding = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.24),
      ),
      child: Image.asset(
        AppLogo.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
