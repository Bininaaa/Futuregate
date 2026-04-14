import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminPalette {
  AdminPalette._();

  static Color get primary => AppColors.current.primary;
  static Color get primaryDark => AppColors.current.primaryDeep;
  static Color get primarySoft => AppColors.current.primarySoft;
  static Color get secondary => AppColors.current.secondary;
  static Color get secondarySoft => AppColors.current.secondarySoft;
  static Color get accent => AppColors.current.accent;
  static Color get accentSoft => AppColors.current.accentSoft;
  static Color get background => AppColors.current.background;
  static Color get backgroundAlt => AppColors.current.backgroundAlt;
  static Color get surface => AppColors.current.surface;
  static Color get surfaceMuted => AppColors.current.surfaceMuted;
  static Color get border => AppColors.current.border;
  static Color get textPrimary => AppColors.current.textPrimary;
  static Color get textSecondary => AppColors.current.textSecondary;
  static Color get textMuted => AppColors.current.textMuted;
  static Color get success => AppColors.current.success;
  static Color get warning => AppColors.current.warning;
  static Color get danger => AppColors.current.danger;
  static Color get info => AppColors.current.info;
  static Color get activity => AppColors.current.activity;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.current.shadow.withValues(
        alpha: AppColors.isDark ? 0.24 : 0.05,
      ),
      blurRadius: AppColors.isDark ? 34 : 28,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: primary.withValues(alpha: AppColors.isDark ? 0.06 : 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static LinearGradient get shellGradient => AppColors.current.shellGradient;

  static LinearGradient heroGradient(Color accentColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.isDark
          ? [
              const Color(0xFF151134),
              primaryDark,
              accentColor.withValues(alpha: 0.72),
            ]
          : [primaryDark, primary, accentColor.withValues(alpha: 0.92)],
    );
  }
}
