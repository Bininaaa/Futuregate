import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CompanyDashboardPalette {
  CompanyDashboardPalette._();

  static Color get primary => AppColors.current.primary;
  static Color get primaryDark => AppColors.current.primaryDeep;
  static Color get primarySoft => AppColors.current.primarySoft;
  static Color get secondary => AppColors.current.secondary;
  static Color get secondaryDark => AppColors.current.secondaryDeep;
  static Color get accent => AppColors.current.accent;
  static Color get background => AppColors.current.background;
  static Color get surface => AppColors.current.surface;
  static Color get border => AppColors.current.border;
  static Color get textPrimary => AppColors.current.textPrimary;
  static Color get textSecondary => AppColors.current.textSecondary;
  static Color get textMuted => AppColors.current.textMuted;
  static Color get success => AppColors.current.success;
  static Color get warning => AppColors.current.warning;
  static Color get error => AppColors.current.danger;
  static Color get info => AppColors.current.info;
}
