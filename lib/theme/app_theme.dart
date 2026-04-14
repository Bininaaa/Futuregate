import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/shared/app_feedback.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light);

  static ThemeData get dark => _build(AppColors.dark);

  static ThemeData _build(AppColors colors) {
    final scheme = colors.toColorScheme();
    final isDark = colors.brightness == Brightness.dark;
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(
      base.textTheme,
    ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      focusColor: colors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      hoverColor: colors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
      highlightColor: colors.primary.withValues(alpha: isDark ? 0.13 : 0.08),
      splashColor: colors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
      disabledColor: colors.textMuted.withValues(alpha: isDark ? 0.36 : 0.42),
      dividerColor: colors.border,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        AppFeedbackTheme(
          info: colors.info,
          success: colors.success,
          warning: colors.warning,
          error: colors.danger,
          neutral: colors.textSecondary,
        ),
      ],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface.withValues(alpha: isDark ? 0.82 : 0.96),
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actionsIconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shadowColor: colors.shadow.withValues(alpha: isDark ? 0.34 : 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors.border.withValues(alpha: isDark ? 0.88 : 0.55),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 8,
        shadowColor: colors.shadow.withValues(alpha: isDark ? 0.45 : 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBackgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 8,
        modalElevation: isDark ? 0 : 12,
        shadowColor: colors.shadow.withValues(alpha: isDark ? 0.48 : 0.16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: colors.overlay,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        actionTextColor: colors.primary,
        disabledActionTextColor: colors.textMuted,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 8,
        shadowColor: colors.shadow.withValues(alpha: isDark ? 0.40 : 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
            colors.surfaceElevated,
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          shadowColor: WidgetStatePropertyAll<Color>(
            colors.shadow.withValues(alpha: isDark ? 0.42 : 0.12),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(colors),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 48)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.primary.withValues(alpha: isDark ? 0.34 : 0.38);
            }
            return colors.brandPrimary;
          }),
          foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          overlayColor: WidgetStatePropertyAll<Color>(
            Colors.white.withValues(alpha: 0.10),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            GoogleFonts.poppins(fontSize: 13.2, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 48)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.surfaceMuted;
            }
            return colors.brandPrimary;
          }),
          foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          shadowColor: WidgetStatePropertyAll<Color>(
            colors.brandPrimary.withValues(alpha: isDark ? 0.28 : 0.18),
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            GoogleFonts.poppins(fontSize: 13.2, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            return isDark ? 0 : 2;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 46)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted.withValues(alpha: 0.54);
            }
            return colors.textPrimary;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            final opacity = states.contains(WidgetState.disabled) ? 0.52 : 1.0;
            return BorderSide(color: colors.border.withValues(alpha: opacity));
          }),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted.withValues(alpha: 0.52);
            }
            return colors.primary;
          }),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        selectedColor: colors.primarySoft,
        disabledColor: colors.surfaceMuted.withValues(alpha: 0.5),
        deleteIconColor: colors.textSecondary,
        secondarySelectedColor: colors.secondarySoft,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        brightness: colors.brightness,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface.withValues(alpha: isDark ? 0.94 : 0.98),
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primarySoft,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? colors.primary : colors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.textMuted,
            size: selected ? 24 : 22,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textMuted,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: colors.primary,
        labelColor: colors.primary,
        unselectedLabelColor: colors.textMuted,
        overlayColor: WidgetStatePropertyAll<Color>(
          colors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) return colors.textMuted;
          if (states.contains(WidgetState.selected)) return colors.onPrimary;
          return colors.surfaceElevated;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.border.withValues(alpha: 0.6);
          }
          if (states.contains(WidgetState.selected)) return colors.brandPrimary;
          return colors.surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return colors.borderStrong;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: _selectableFill(colors),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        side: BorderSide(color: colors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(fillColor: _selectableFill(colors)),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceMuted,
        circularTrackColor: colors.surfaceMuted,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          colors.textMuted.withValues(alpha: isDark ? 0.50 : 0.42),
        ),
        trackColor: WidgetStatePropertyAll<Color>(colors.surfaceMuted),
        radius: const Radius.circular(999),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(AppColors colors) {
    final isDark = colors.isDarkMode;
    final fillColor = isDark ? colors.surfaceMuted : colors.surface;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hoverColor: colors.primary.withValues(alpha: isDark ? 0.10 : 0.05),
      hintStyle: GoogleFonts.poppins(
        fontSize: 12.8,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.4,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        fontSize: 12.4,
        fontWeight: FontWeight.w700,
        color: colors.primary,
      ),
      helperStyle: GoogleFonts.poppins(
        fontSize: 11.4,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
      ),
      errorStyle: GoogleFonts.poppins(
        fontSize: 11.6,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: colors.danger,
      ),
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      prefixIconColor: colors.textMuted,
      suffixIconColor: colors.textMuted,
      iconColor: colors.textMuted,
      border: border(colors.border),
      enabledBorder: border(colors.border),
      focusedBorder: border(colors.primary, 1.5),
      errorBorder: border(colors.danger),
      focusedErrorBorder: border(colors.danger, 1.5),
      disabledBorder: border(colors.border.withValues(alpha: 0.54)),
    );
  }

  static WidgetStateProperty<Color?> _selectableFill(AppColors colors) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return colors.textMuted.withValues(alpha: 0.34);
      }
      if (states.contains(WidgetState.selected)) {
        return colors.brandPrimary;
      }
      return Colors.transparent;
    });
  }
}
