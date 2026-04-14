import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class SettingsFlowPalette {
  static Color get primary => AppColors.current.primary;
  static Color get primaryDark => AppColors.current.primaryDeep;
  static Color get secondary => AppColors.current.secondary;
  static Color get accent => AppColors.current.accent;
  static Color get background => AppColors.current.background;
  static Color get surface => AppColors.current.surface;
  static Color get textPrimary => AppColors.current.textPrimary;
  static Color get textSecondary => AppColors.current.textSecondary;
  static Color get border => AppColors.current.border;
  static Color get success => AppColors.current.success;
  static Color get warning => AppColors.current.warning;
  static Color get error => AppColors.current.danger;

  static Color get surfaceTint => AppColors.current.surfaceSoft;
  static Color get mintTint => AppColors.current.secondarySoft;
  static Color get dangerTint => AppColors.current.dangerSoft;

  static LinearGradient get primaryGradient =>
      AppColors.current.primaryGradient;

  static LinearGradient get accentGradient {
    return LinearGradient(
      colors: AppColors.isDark
          ? [primaryDark, primary]
          : [primary, const Color(0xFF6D5EF9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get secondaryGradient =>
      AppColors.current.secondaryGradient;
}

class SettingsFlowTheme {
  static TextStyle appBarTitle([Color? color]) => GoogleFonts.poppins(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: color ?? SettingsFlowPalette.primary,
  );

  static TextStyle heroTitle([Color? color]) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color ?? SettingsFlowPalette.textPrimary,
    height: 1.1,
  );

  static TextStyle sectionTitle([Color? color]) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color ?? SettingsFlowPalette.textPrimary,
  );

  static TextStyle cardTitle([Color? color]) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? SettingsFlowPalette.textPrimary,
  );

  static TextStyle body([Color? color]) => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: color ?? SettingsFlowPalette.textPrimary,
  );

  static TextStyle caption([Color? color]) => GoogleFonts.poppins(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: color ?? SettingsFlowPalette.textSecondary,
    height: 1.45,
  );

  static TextStyle micro([Color? color]) => GoogleFonts.poppins(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: color ?? SettingsFlowPalette.textSecondary,
  );

  static List<BoxShadow> softShadow([double opacity = 0.08]) => [
    BoxShadow(
      color: AppColors.current.shadow.withValues(
        alpha: AppColors.isDark ? opacity * 2.6 : opacity,
      ),
      blurRadius: AppColors.isDark ? 34 : 30,
      offset: const Offset(0, 12),
    ),
  ];

  static BorderRadius radius(double value) => BorderRadius.circular(value);
}
