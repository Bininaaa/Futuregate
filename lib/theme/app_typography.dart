import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/content_language.dart';
import 'locale_controller.dart';

class AppTypography {
  const AppTypography._();

  static bool get isArabic =>
      ContentLanguage.isArabicCode(LocaleController.activeLanguageCode);

  static String? get _arabicFallbackFamily =>
      GoogleFonts.notoSansArabic().fontFamily;

  static List<String>? get _arabicFallback => _arabicFallbackFamily == null
      ? null
      : <String>[_arabicFallbackFamily!];

  static TextStyle product({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextStyle? textStyle,
  }) {
    return isArabic
        ? GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: _mergeArabicFallback(textStyle),
          )
        : GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: textStyle,
          );
  }

  static TextStyle display({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextStyle? textStyle,
  }) {
    return isArabic
        ? GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: _mergeArabicFallback(textStyle),
          )
        : GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: textStyle,
          );
  }

  static TextStyle innovationTitle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextStyle? textStyle,
  }) {
    return isArabic
        ? GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: _mergeArabicFallback(textStyle),
          )
        : GoogleFonts.sora(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: textStyle,
          );
  }

  static TextStyle innovationBody({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextStyle? textStyle,
  }) {
    return isArabic
        ? GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: _mergeArabicFallback(textStyle),
          )
        : GoogleFonts.manrope(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
            textStyle: textStyle,
          );
  }

  static TextStyle withArabicFallback(TextStyle style) {
    if (!isArabic) {
      return style;
    }

    return _mergeArabicFallback(style);
  }

  static TextStyle _mergeArabicFallback(TextStyle? textStyle) {
    final currentFallbacks = textStyle?.fontFamilyFallback ?? const <String>[];
    final mergedFallbacks = <String>[
      ...?_arabicFallback,
      ...currentFallbacks.where(
        (value) => value.trim().isNotEmpty && value != _arabicFallbackFamily,
      ),
    ];

    return (textStyle ?? const TextStyle()).copyWith(
      fontFamilyFallback: mergedFallbacks.isEmpty ? null : mergedFallbacks,
    );
  }
}
