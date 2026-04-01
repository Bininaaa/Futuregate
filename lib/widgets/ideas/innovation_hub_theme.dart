import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InnovationHubPalette {
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
  static const Color searchTint = Color(0xFFF2EFFF);
  static const Color chipTint = Color(0xFFEEF2FF);
  static const Color cardTint = Color(0xFFF8F7FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> softShadow([double opacity = 0.08]) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

class InnovationHubTypography {
  static TextStyle title({
    Color color = InnovationHubPalette.textPrimary,
    double size = 30,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.08,
      color: color,
    );
  }

  static TextStyle section({
    Color color = InnovationHubPalette.textPrimary,
    double size = 18,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.12,
      color: color,
    );
  }

  static TextStyle body({
    Color color = InnovationHubPalette.textSecondary,
    double size = 14,
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  static TextStyle label({
    Color color = InnovationHubPalette.textSecondary,
    double size = 12,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
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
