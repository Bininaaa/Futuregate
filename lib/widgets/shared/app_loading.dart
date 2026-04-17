import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum AppLoadingDensity { regular, compact }

class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration period;

  const AppShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1600),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final baseColor = _skeletonBaseColor(colors);
    final highlightColor = _skeletonHighlightColor(colors);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final width = math.max(bounds.width, 1);
            final travel = width * 1.6;
            final offset = (travel * _controller.value) - (width * 0.8);

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: const <double>[0, 0.32, 0.5, 0.68, 1],
              transform: _SlidingGradientTransform(offset),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slideX;

  const _SlidingGradientTransform(this.slideX);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slideX, 0, 0);
  }
}

class AppSkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  final AlignmentGeometry alignment;

  const AppSkeletonLine({
    super.key,
    required this.widthFactor,
    required this.height,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: widthFactor.clamp(0.0, 1.0),
        child: AppSkeletonBlock(height: height, radius: height / 2),
      ),
    );
  }
}

class AppSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _skeletonBaseColor(colors),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _skeletonBorderColor(colors)),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double maxContentWidth;
  final bool showTopPill;
  final bool showBottomBar;
  final AppLoadingDensity density;

  const AppLoadingView({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 28),
    this.maxContentWidth = 560,
    this.showTopPill = true,
    this.showBottomBar = false,
    this.density = AppLoadingDensity.regular,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: <Widget>[
          _AppLoadingContent(
            maxContentWidth: maxContentWidth,
            showTopPill: showTopPill,
            showBottomBar: showBottomBar,
            density: density,
          ),
        ],
      ),
    );
  }
}

class AppLoadingBody extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double maxContentWidth;
  final bool showTopPill;
  final bool showBottomBar;
  final AppLoadingDensity density;

  const AppLoadingBody({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 28),
    this.maxContentWidth = 560,
    this.showTopPill = true,
    this.showBottomBar = false,
    this.density = AppLoadingDensity.regular,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: padding,
        child: _AppLoadingContent(
          maxContentWidth: maxContentWidth,
          showTopPill: showTopPill,
          showBottomBar: showBottomBar,
          density: density,
        ),
      ),
    );
  }
}

class _AppLoadingContent extends StatelessWidget {
  final double maxContentWidth;
  final bool showTopPill;
  final bool showBottomBar;
  final AppLoadingDensity density;

  const _AppLoadingContent({
    required this.maxContentWidth,
    required this.showTopPill,
    required this.showBottomBar,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = density == AppLoadingDensity.compact;
    final primaryGap = isCompact ? 12.0 : 16.0;
    final secondaryGap = isCompact ? 8.0 : 10.0;
    final heroHeight = isCompact ? 82.0 : 92.0;
    final detailCardHeight = isCompact ? 164.0 : 196.0;
    final gridCardHeight = isCompact ? 108.0 : 122.0;
    final bottomCardHeight = isCompact ? 104.0 : 118.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (showTopPill) ...<Widget>[
              const Center(
                child: AppSkeletonBlock(width: 104, height: 18, radius: 999),
              ),
              SizedBox(height: primaryGap + 2),
            ] else
              SizedBox(height: secondaryGap),
            const AppSkeletonLine(
              widthFactor: 0.42,
              height: 12,
              alignment: Alignment.center,
            ),
            const SizedBox(height: 8),
            const AppSkeletonLine(
              widthFactor: 0.64,
              height: 12,
              alignment: Alignment.center,
            ),
            SizedBox(height: primaryGap + 6),
            AppSkeletonBlock(height: heroHeight, radius: 26),
            SizedBox(height: primaryGap),
            AppSkeletonBlock(height: detailCardHeight, radius: 30),
            SizedBox(height: primaryGap),
            SizedBox(
              height: gridCardHeight,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppSkeletonBlock(height: gridCardHeight, radius: 24),
                  ),
                  SizedBox(width: primaryGap),
                  Expanded(
                    child: AppSkeletonBlock(height: gridCardHeight, radius: 24),
                  ),
                ],
              ),
            ),
            SizedBox(height: primaryGap),
            AppSkeletonBlock(height: bottomCardHeight, radius: 28),
            SizedBox(height: secondaryGap),
            const AppSkeletonLine(widthFactor: 0.54, height: 12),
            const SizedBox(height: 8),
            const AppSkeletonLine(widthFactor: 0.72, height: 12),
            if (showBottomBar) ...<Widget>[
              SizedBox(height: primaryGap + 8),
              const AppSkeletonBlock(height: 62, radius: 999),
            ],
          ],
        ),
      ),
    );
  }
}

Color _skeletonBaseColor(AppColors colors) {
  if (colors.isDarkMode) {
    return Color.alphaBlend(
      colors.textPrimary.withValues(alpha: 0.05),
      colors.surfaceMuted,
    );
  }

  return Color.alphaBlend(
    colors.primary.withValues(alpha: 0.045),
    colors.surface,
  );
}

Color _skeletonHighlightColor(AppColors colors) {
  if (colors.isDarkMode) {
    return Color.alphaBlend(
      colors.textPrimary.withValues(alpha: 0.16),
      colors.surfaceElevated,
    );
  }

  return Color.alphaBlend(
    Colors.white.withValues(alpha: 0.88),
    colors.surfaceElevated,
  );
}

Color _skeletonBorderColor(AppColors colors) {
  return colors.isDarkMode
      ? colors.borderStrong.withValues(alpha: 0.5)
      : colors.border.withValues(alpha: 0.72);
}
