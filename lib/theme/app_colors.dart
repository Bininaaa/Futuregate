import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Brightness brightness;
  final Color brandPrimary;
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color secondary;
  final Color secondaryDeep;
  final Color secondarySoft;
  final Color accent;
  final Color accentSoft;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color surfaceSoft;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color activity;
  final Color overlay;
  final Color shadow;

  const AppColors({
    required this.brightness,
    required this.brandPrimary,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.secondary,
    required this.secondaryDeep,
    required this.secondarySoft,
    required this.accent,
    required this.accentSoft,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.surfaceSoft,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.activity,
    required this.overlay,
    required this.shadow,
  });

  static const AppColors light = AppColors(
    brightness: Brightness.light,
    brandPrimary: Color(0xFF3B22F6),
    primary: Color(0xFF3B22F6),
    primaryDeep: Color(0xFF2A1B93),
    primarySoft: Color(0xFFEEF2FF),
    secondary: Color(0xFF14B8A6),
    secondaryDeep: Color(0xFF0F9E90),
    secondarySoft: Color(0xFFE8FFFB),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0xFFFFF4D8),
    background: Color(0xFFF4F7FB),
    backgroundAlt: Color(0xFFEFF4FF),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF8FAFF),
    surfaceSoft: Color(0xFFEEF2FF),
    border: Color(0xFFDCE3F1),
    borderStrong: Color(0xFFC7D2EA),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    success: Color(0xFF179D6C),
    successSoft: Color(0xFFE8F8F0),
    warning: Color(0xFFD97706),
    warningSoft: Color(0xFFFFF4D8),
    danger: Color(0xFFE24A4A),
    dangerSoft: Color(0xFFFEF2F2),
    info: Color(0xFF2563EB),
    infoSoft: Color(0xFFEFF6FF),
    activity: Color(0xFF7C3AED),
    overlay: Color(0x660F172A),
    shadow: Color(0xFF0F172A),
  );

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    brandPrimary: Color(0xFF3B22F6),
    primary: Color(0xFF7566FF),
    primaryDeep: Color(0xFF3B22F6),
    primarySoft: Color(0xFF211A52),
    secondary: Color(0xFF2DD4BF),
    secondaryDeep: Color(0xFF14B8A6),
    secondarySoft: Color(0xFF0E2F34),
    accent: Color(0xFFFBBF24),
    accentSoft: Color(0xFF3C2A10),
    background: Color(0xFF070B1A),
    backgroundAlt: Color(0xFF0B1024),
    surface: Color(0xFF10162A),
    surfaceElevated: Color(0xFF151D35),
    surfaceMuted: Color(0xFF1A2340),
    surfaceSoft: Color(0xFF1D2445),
    border: Color(0xFF2A3552),
    borderStrong: Color(0xFF3A4668),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    success: Color(0xFF34D399),
    successSoft: Color(0xFF0E3028),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF3C2A10),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF3A1A24),
    info: Color(0xFF60A5FA),
    infoSoft: Color(0xFF102B4C),
    activity: Color(0xFFA78BFA),
    overlay: Color(0xCC020617),
    shadow: Color(0xFF020617),
  );

  static AppColors _current = light;

  static AppColors get current => _current;

  static bool get isDark => _current.brightness == Brightness.dark;

  bool get isDarkMode => brightness == Brightness.dark;

  static void syncBrightness(Brightness brightness) {
    _current = brightness == Brightness.dark ? dark : light;
  }

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
    _current = colors;
    return colors;
  }

  Color get onPrimary => Colors.white;

  Color get splashBackground =>
      isDarkMode ? background : const Color(0xFF070B1A);

  LinearGradient get shellGradient {
    if (isDarkMode) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[background, backgroundAlt, const Color(0xFF0E1730)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFF6F9FF), Color(0xFFF4F7FB), Color(0xFFEDF5FF)],
    );
  }

  LinearGradient get primaryGradient {
    if (isDarkMode) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[primaryDeep, primary, const Color(0xFF2DD4BF)],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[primaryDeep, brandPrimary],
    );
  }

  LinearGradient get secondaryGradient {
    if (isDarkMode) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[secondaryDeep, secondary],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[secondary, secondaryDeep],
    );
  }

  LinearGradient heroGradient(Color accentColor) {
    if (isDarkMode) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFF17103E),
          primaryDeep,
          Color.alphaBlend(accentColor.withValues(alpha: 0.72), surfaceMuted),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[primaryDeep, brandPrimary, accentColor],
    );
  }

  List<BoxShadow> softShadow([double opacity = 0.08]) {
    if (isDarkMode) {
      return <BoxShadow>[
        BoxShadow(
          color: shadow.withValues(alpha: opacity * 2.8),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: primaryDeep.withValues(alpha: opacity * 0.75),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ];
    }

    return <BoxShadow>[
      BoxShadow(
        color: shadow.withValues(alpha: opacity),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: brandPrimary.withValues(alpha: opacity * 0.8),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Color tintedSurface(Color tone, [double opacity = 0.1]) {
    return Color.alphaBlend(tone.withValues(alpha: opacity), surface);
  }

  Color mutedSurface(Color tone, [double opacity = 0.08]) {
    return Color.alphaBlend(tone.withValues(alpha: opacity), surfaceMuted);
  }

  Color stateLayer(
    Color tone, {
    double lightOpacity = 0.1,
    double darkOpacity = 0.16,
  }) {
    return tone.withValues(alpha: isDarkMode ? darkOpacity : lightOpacity);
  }

  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primarySoft,
      onPrimaryContainer: isDarkMode ? textPrimary : primaryDeep,
      secondary: secondary,
      onSecondary: isDarkMode ? const Color(0xFF042F2E) : Colors.white,
      secondaryContainer: secondarySoft,
      onSecondaryContainer: isDarkMode ? textPrimary : const Color(0xFF0F766E),
      tertiary: accent,
      onTertiary: isDarkMode ? const Color(0xFF2A1900) : Colors.white,
      tertiaryContainer: accentSoft,
      onTertiaryContainer: isDarkMode ? textPrimary : const Color(0xFF92400E),
      error: danger,
      onError: Colors.white,
      errorContainer: dangerSoft,
      onErrorContainer: isDarkMode ? textPrimary : const Color(0xFF991B1B),
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: isDarkMode ? background : surface,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceElevated,
      surfaceContainerHigh: surfaceMuted,
      surfaceContainerHighest: surfaceSoft,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: borderStrong,
      shadow: shadow,
      scrim: overlay,
      inverseSurface: isDarkMode
          ? const Color(0xFFE2E8F0)
          : const Color(0xFF111827),
      onInverseSurface: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      inversePrimary: isDarkMode ? brandPrimary : const Color(0xFF9A8CFF),
    );
  }

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? brandPrimary,
    Color? primary,
    Color? primaryDeep,
    Color? primarySoft,
    Color? secondary,
    Color? secondaryDeep,
    Color? secondarySoft,
    Color? accent,
    Color? accentSoft,
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? surfaceSoft,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
    Color? activity,
    Color? overlay,
    Color? shadow,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      secondaryDeep: secondaryDeep ?? this.secondaryDeep,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      activity: activity ?? this.activity,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryDeep: Color.lerp(secondaryDeep, other.secondaryDeep, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundAlt: Color.lerp(backgroundAlt, other.backgroundAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      activity: Color.lerp(activity, other.activity, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppColorsBuildContextX on BuildContext {
  AppColors get appColors => AppColors.of(this);
}
