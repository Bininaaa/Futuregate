import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsFlowPalette {
  static const Color primary = Color(0xFF3B22F6);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFF97316);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111627);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color surfaceTint = Color(0xFFF1F5FF);
  static const Color mintTint = Color(0xFFF0FDFA);
  static const Color dangerTint = Color(0xFFFEF2F2);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, Color(0xFF6D5EF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF0F9F96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
      color: SettingsFlowPalette.textPrimary.withValues(alpha: opacity),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  static BorderRadius radius(double value) => BorderRadius.circular(value);
}
