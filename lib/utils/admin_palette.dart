import 'package:flutter/material.dart';

class AdminPalette {
  AdminPalette._();

  static const Color primary = Color(0xFF3B22F6);
  static const Color primaryDark = Color(0xFF2A1B93);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondarySoft = Color(0xFFE8FFFB);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFFF4D8);
  static const Color background = Color(0xFFF4F7FB);
  static const Color backgroundAlt = Color(0xFFEFF4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFF);
  static const Color border = Color(0xFFDCE3F1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color success = Color(0xFF179D6C);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFE24A4A);
  static const Color info = Color(0xFF2563EB);
  static const Color activity = Color(0xFF7C3AED);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: const Color(0xFF3B22F6).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static const LinearGradient shellGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6F9FF), Color(0xFFF4F7FB), Color(0xFFEDF5FF)],
  );

  static LinearGradient heroGradient(Color accentColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryDark, primary, accentColor.withValues(alpha: 0.92)],
    );
  }
}
