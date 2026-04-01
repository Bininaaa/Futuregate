import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatThemePalette {
  static const Color primary = Color(0xFF3B22F6);
  static const Color primaryDark = Color(0xFF23146B);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFF97316);
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFF);
  static const Color textPrimary = Color(0xFF111627);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFDCE4F0);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [primaryDark, primary, Color(0xFF5C3BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient canvasGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FF), Color(0xFFF2F6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF), Color(0xFFF4FBFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ChatThemeStyles {
  static TextStyle title([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.55,
    );
  }

  static TextStyle sectionLabel([
    Color color = ChatThemePalette.textSecondary,
  ]) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.4,
    );
  }

  static TextStyle cardTitle([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.poppins(
      fontSize: 15.2,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.2,
    );
  }

  static TextStyle dialogTitle([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.35,
    );
  }

  static TextStyle body([Color color = ChatThemePalette.textPrimary]) {
    return GoogleFonts.poppins(
      fontSize: 13.4,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.45,
    );
  }

  static TextStyle meta([Color color = ChatThemePalette.textSecondary]) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.24,
    );
  }

  static List<BoxShadow> softShadow([double opacity = 0.08]) {
    return [
      BoxShadow(
        color: ChatThemePalette.primary.withValues(alpha: opacity * 0.14),
        blurRadius: 32,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: opacity * 0.16),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
