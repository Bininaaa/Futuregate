import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatThemePalette {
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

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [primaryDark, Color(0xFF4C32FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient canvasGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ChatThemeStyles {
  static TextStyle title([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle sectionLabel([
    Color color = ChatThemePalette.textSecondary,
  ]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.3,
    );
  }

  static TextStyle cardTitle([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.28,
    );
  }

  static TextStyle body([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13.2,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.45,
    );
  }

  static TextStyle meta([Color color = ChatThemePalette.textSecondary]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.18,
    );
  }

  static List<BoxShadow> softShadow([double opacity = 0.08]) {
    return [
      BoxShadow(
        color: ChatThemePalette.primary.withValues(alpha: opacity * 0.12),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: opacity * 0.16),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
