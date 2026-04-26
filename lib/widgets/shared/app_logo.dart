import 'package:flutter/material.dart';

/// Asset paths for the new FutureGate branding kit.
class AppBrandAssets {
  /// Full brand-name wordmark — use in major branding areas (auth headers,
  /// splash, onboarding, settings/about, welcome sections).
  static const String name = 'assets/pictures/NAME.png';

  /// Icon-only mark — use for launcher icon, about-page icon, and anywhere
  /// only the symbol is needed.
  static const String icon = 'assets/pictures/ICON.png';

  /// Compact / cleaner logo for tight spaces — narrow app bars, pill headers,
  /// drawer mini-brand, constrained containers.
  static const String clear = 'assets/pictures/CLEAR.png';

  /// Launch animation video asset.
  static const String animation = 'assets/pictures/ANIMATION.mp4';

  /// Optimized FutureGate logo for small square badges and about cards.
  static const String compact = 'assets/images/branding/futuregate_logo.png';

  /// First-open onboarding illustration: portal / journey.
  static const String getStartedPortal =
      'assets/pictures/get_started_portal.png';

  /// First-open onboarding illustration: profile / readiness.
  static const String getStartedProfile =
      'assets/pictures/get_started_profile.png';

  /// First-open onboarding illustration: opportunities / connection.
  static const String getStartedConnection =
      'assets/pictures/get_started_connection.png';

  const AppBrandAssets._();
}

/// Full brand-name logo widget.
///
/// Renders the FutureGate **name** wordmark with consistent aspect ratio.
/// Drop this into auth headers, splash branding, onboarding, about screens,
/// and any area where the full brand name should be prominent.
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

  /// Legacy constant kept for any external code that referenced it.
  static const String assetPath = AppBrandAssets.name;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppBrandAssets.name,
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

/// Compact clear logo for tight spaces — pill headers, nav bars, narrow
/// app-bar brand areas, drawer headers, and anywhere the full wordmark
/// would look crowded.
class AppLogoClear extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final String? semanticLabel;

  const AppLogoClear({
    super.key,
    this.height = 24,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'FutureGate',
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppBrandAssets.clear,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );
  }
}

/// Square icon mark for places where only the symbol is needed — about page
/// icon containers, small tiles, launcher icon previews.
class AppLogoMark extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double padding;

  const AppLogoMark({
    super.key,
    this.size = 48,
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
        AppBrandAssets.compact,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
