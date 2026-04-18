import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class InnovationHubPalette {
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
  static Color get searchTint => AppColors.isDark
      ? AppColors.current.surfaceSoft
      : const Color(0xFFF2EFFF);
  static Color get chipTint => AppColors.current.primarySoft;
  static Color get cardTint => AppColors.isDark
      ? AppColors.current.surfaceElevated
      : const Color(0xFFF8F7FF);

  static LinearGradient get primaryGradient =>
      AppColors.current.primaryGradient;

  static LinearGradient get featuredGradient =>
      AppColors.current.primaryGradient;

  static List<BoxShadow> softShadow([double opacity = 0.08]) {
    return [
      BoxShadow(
        color: AppColors.current.shadow.withValues(
          alpha: AppColors.isDark ? opacity * 2.6 : opacity,
        ),
        blurRadius: AppColors.isDark ? 28 : 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

class InnovationHubTypography {
  static TextStyle title({Color? color, double size = 30}) {
    return AppTypography.innovationTitle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.08,
      color: color ?? InnovationHubPalette.textPrimary,
    );
  }

  static TextStyle section({Color? color, double size = 18}) {
    return AppTypography.innovationTitle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.12,
      color: color ?? InnovationHubPalette.textPrimary,
    );
  }

  static TextStyle body({
    Color? color,
    double size = 14,
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
  }) {
    return AppTypography.innovationBody(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? InnovationHubPalette.textSecondary,
    );
  }

  static TextStyle label({
    Color? color,
    double size = 12,
    FontWeight weight = FontWeight.w700,
  }) {
    return AppTypography.innovationBody(
      fontSize: size,
      fontWeight: weight,
      color: color ?? InnovationHubPalette.textSecondary,
      letterSpacing: 0.1,
    );
  }
}

const List<String> innovationHubDefaultCategories = <String>[
  'AI',
  'Business',
  'Tech',
  'Design',
  'Fintech',
  'EdTech',
  'Health',
  'Sustainability',
  'Social Impact',
];

const List<String> innovationHubStageOptions = <String>[
  'Concept',
  'Research',
  'MVP',
  'Prototype',
  'Beta',
];

const List<String> innovationHubRoleOptions = <String>[
  'Developer',
  'Designer',
  'Marketer',
  'Business Lead',
  'Researcher',
];

const List<String> innovationHubSkillSuggestions = <String>[
  'Flutter',
  'UI/UX',
  'Product Strategy',
  'Data Science',
  'Brand Design',
  'Pitching',
  'Research',
  'Marketing',
  'Backend',
  'No-Code',
];

IconData innovationCategoryIcon(String value) {
  switch (value.trim().toLowerCase()) {
    case 'ai':
      return Icons.auto_awesome_rounded;
    case 'business':
      return Icons.insights_rounded;
    case 'tech':
      return Icons.memory_rounded;
    case 'design':
      return Icons.palette_outlined;
    case 'fintech':
      return Icons.account_balance_wallet_outlined;
    case 'edtech':
      return Icons.school_outlined;
    case 'health':
      return Icons.favorite_border_rounded;
    case 'sustainability':
      return Icons.eco_outlined;
    case 'social impact':
      return Icons.groups_2_outlined;
    default:
      return Icons.lightbulb_outline_rounded;
  }
}

Color innovationCategoryColor(String value) {
  switch (value.trim().toLowerCase()) {
    case 'ai':
      return InnovationHubPalette.primary;
    case 'business':
      return InnovationHubPalette.accent;
    case 'tech':
      return InnovationHubPalette.primaryDark;
    case 'design':
      return const Color(0xFFEC4899);
    case 'fintech':
      return InnovationHubPalette.secondary;
    case 'edtech':
      return const Color(0xFF0EA5E9);
    case 'health':
      return InnovationHubPalette.success;
    case 'sustainability':
      return const Color(0xFF16A34A);
    case 'social impact':
      return const Color(0xFFF43F5E);
    default:
      return InnovationHubPalette.primary;
  }
}

Color innovationStageColor(String value) {
  switch (value.trim().toLowerCase()) {
    case 'beta':
      return InnovationHubPalette.success;
    case 'mvp':
      return InnovationHubPalette.secondary;
    case 'prototype':
      return InnovationHubPalette.accent;
    case 'research':
      return const Color(0xFF8B5CF6);
    default:
      return InnovationHubPalette.primary;
  }
}

Color innovationStatusColor(String value) {
  switch (value.trim().toLowerCase()) {
    case 'approved':
      return InnovationHubPalette.success;
    case 'rejected':
      return InnovationHubPalette.error;
    default:
      return InnovationHubPalette.warning;
  }
}

String academicLevelLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'bac':
      return 'Bachelor';
    case 'licence':
      return 'Licence';
    case 'master':
      return 'Master';
    case 'doctorat':
      return 'Doctorate';
    default:
      return value.trim();
  }
}

String innovationCategoryLabel(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context)!;
  switch (value.trim().toLowerCase()) {
    case 'ai':
      return l10n.ideaCategoryAi;
    case 'business':
      return l10n.uiBusiness;
    case 'tech':
      return l10n.uiTech;
    case 'design':
      return l10n.uiDesign;
    case 'fintech':
      return l10n.ideaCategoryFintech;
    case 'edtech':
      return l10n.ideaCategoryEdTech;
    case 'health':
      return l10n.uiHealth;
    case 'sustainability':
      return l10n.ideaCategorySustainability;
    case 'social impact':
      return l10n.ideaCategorySocialImpact;
    default:
      final trimmed = value.trim();
      return trimmed.isEmpty ? l10n.ideaCategoryInnovation : trimmed;
  }
}

String innovationStageLabel(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context)!;
  switch (value.trim().toLowerCase()) {
    case 'concept':
      return l10n.ideaStageConcept;
    case 'research':
      return l10n.uiResearch;
    case 'mvp':
      return l10n.ideaStageMvp;
    case 'prototype':
      return l10n.ideaStagePrototype;
    case 'beta':
      return l10n.ideaStageBeta;
    default:
      final trimmed = value.trim();
      return trimmed.isEmpty ? l10n.ideaStageConcept : trimmed;
  }
}

String innovationVisibilityLabel(BuildContext context, bool isPublic) {
  final l10n = AppLocalizations.of(context)!;
  return isPublic ? l10n.ideaPublicLabel : l10n.ideaPrivateLabel;
}

String academicLevelDisplayLabel(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context)!;
  switch (value.trim().toLowerCase()) {
    case 'bac':
      return l10n.academicLevelBachelor;
    case 'licence':
      return l10n.academicLevelLicence;
    case 'master':
      return l10n.academicLevelMaster;
    case 'doctorat':
      return l10n.academicLevelDoctorat;
    default:
      return value.trim();
  }
}
