import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class ChatThemePalette {
  static Color get primary => AppColors.current.primary;
  static Color get primaryDark => AppColors.current.primaryDeep;
  static Color get secondary => AppColors.current.secondary;
  static Color get accent => AppColors.current.accent;
  static Color get background => AppColors.current.background;
  static Color get surface => AppColors.current.surface;
  static Color get surfaceMuted => AppColors.current.surfaceMuted;
  static Color get textPrimary => AppColors.current.textPrimary;
  static Color get textSecondary => AppColors.current.textSecondary;
  static Color get border => AppColors.current.border;
  static Color get success => AppColors.current.success;
  static Color get warning => AppColors.current.warning;
  static Color get error => AppColors.current.danger;

  static LinearGradient get primaryGradient =>
      AppColors.current.primaryGradient;

  static LinearGradient get fabGradient {
    return LinearGradient(
      colors: AppColors.isDark
          ? [primaryDark, primary, secondary.withValues(alpha: 0.92)]
          : [primaryDark, primary, const Color(0xFF5C3BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get canvasGradient {
    return LinearGradient(
      colors: AppColors.isDark
          ? [AppColors.current.backgroundAlt, background]
          : [const Color(0xFFFFFFFF), background],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient get headerGradient {
    return LinearGradient(
      colors: AppColors.isDark
          ? [surface, surfaceMuted, AppColors.current.surfaceSoft]
          : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC), surfaceMuted],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get heroGradient {
    return LinearGradient(
      colors: AppColors.isDark
          ? [surfaceElevated, surface, AppColors.current.secondarySoft]
          : [
              const Color(0xFFFFFFFF),
              const Color(0xFFF8FAFC),
              const Color(0xFFF0FDFA),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color get surfaceElevated => AppColors.current.surfaceElevated;
}

class ChatThemeStyles {
  static TextStyle title([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: color ?? ChatThemePalette.textPrimary,
      letterSpacing: 0,
      height: 1.12,
    );
  }

  static TextStyle sectionLabel([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color ?? ChatThemePalette.textSecondary,
      letterSpacing: 0,
    );
  }

  static TextStyle cardTitle([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 15.2,
      fontWeight: FontWeight.w600,
      color: color ?? ChatThemePalette.textPrimary,
      letterSpacing: 0,
      height: 1.18,
    );
  }

  static TextStyle dialogTitle([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color ?? ChatThemePalette.textPrimary,
      letterSpacing: 0,
      height: 1.16,
    );
  }

  static TextStyle body([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 13.4,
      fontWeight: FontWeight.w500,
      color: color ?? ChatThemePalette.textPrimary,
      height: 1.45,
    );
  }

  static TextStyle actionLabel([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? ChatThemePalette.textPrimary,
      letterSpacing: 0,
      height: 1.2,
    );
  }

  static TextStyle meta([Color? color]) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: color ?? ChatThemePalette.textSecondary,
      letterSpacing: 0,
    );
  }

  static List<BoxShadow> softShadow([double opacity = 0.08]) {
    return [
      BoxShadow(
        color: AppColors.current.primary.withValues(
          alpha: AppColors.isDark ? opacity * 0.34 : opacity * 0.14,
        ),
        blurRadius: AppColors.isDark ? 36 : 32,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: AppColors.current.shadow.withValues(
          alpha: AppColors.isDark ? opacity * 2.2 : opacity * 0.16,
        ),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
