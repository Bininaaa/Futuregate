import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/opportunity_dashboard_palette.dart';
import 'shared/app_directional.dart';
import 'shared/app_feedback.dart';
import 'student/student_search_field.dart';

class StudentOpportunityHubPalette {
  StudentOpportunityHubPalette._();

  static Color get primary => OpportunityDashboardPalette.primary;
  static Color get primaryDark => OpportunityDashboardPalette.primaryDark;
  static Color get secondary => OpportunityDashboardPalette.secondary;
  static Color get accent => OpportunityDashboardPalette.accent;
  static Color get surface => OpportunityDashboardPalette.surface;
  static Color get surfaceElevated => AppColors.current.surfaceElevated;
  static Color get surfaceMuted => AppColors.current.surfaceMuted;
  static Color get surfaceAlt => OpportunityDashboardPalette.background;
  static Color get textPrimary => OpportunityDashboardPalette.textPrimary;
  static Color get textSecondary => OpportunityDashboardPalette.textSecondary;
  static Color get textMuted => AppColors.current.textMuted;
  static Color get border => OpportunityDashboardPalette.border;
  static Color get success => OpportunityDashboardPalette.success;
  static Color get warning => OpportunityDashboardPalette.warning;
  static Color get error => OpportunityDashboardPalette.error;
  static Color get primarySoft => AppColors.current.primarySoft;
  static Color get secondarySoft => AppColors.current.secondarySoft;
  static Color get accentSoft => AppColors.current.accentSoft;
  static Color get errorSoft => AppColors.current.dangerSoft;
  static bool get isDark => AppColors.isDark;
}

class StudentOpportunityHeroStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StudentOpportunityHeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class StudentOpportunityHubHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<StudentOpportunityHeroStat> stats;
  final String? eyebrow;

  const StudentOpportunityHubHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            StudentOpportunityHubPalette.primaryDark,
            StudentOpportunityHubPalette.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -16,
            right: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: -34,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((eyebrow ?? '').trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    eyebrow!,
                    style: AppTypography.product(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AppDirectionalIcon(
                      icon,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.product(
                            fontSize: 22,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppTypography.product(
                            fontSize: 12.5,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: stats
                      .map(
                        (stat) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: stat == stats.last ? 0 : 10,
                            ),
                            child: _HeroStatCard(stat: stat),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final StudentOpportunityHeroStat stat;

  const _HeroStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(stat.icon, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            style: AppTypography.product(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: AppTypography.product(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentOpportunitySearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const StudentOpportunitySearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StudentSearchField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
    );
  }
}

class StudentOpportunityFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const StudentOpportunityFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : StudentOpportunityHubPalette.surface.withValues(
                  alpha: StudentOpportunityHubPalette.isDark ? 0.96 : 1,
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.24)
                : StudentOpportunityHubPalette.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.product(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? color
                : StudentOpportunityHubPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class StudentOpportunityMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tone;

  const StudentOpportunityMetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTone = tone ?? StudentOpportunityHubPalette.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: StudentOpportunityHubPalette.surface.withValues(
          alpha: StudentOpportunityHubPalette.isDark ? 0.92 : 0.86,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: StudentOpportunityHubPalette.border.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDirectionalIcon(icon, size: 14, color: resolvedTone),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone == null
                  ? StudentOpportunityHubPalette.textSecondary
                  : resolvedTone,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentOpportunityLoadingState extends StatelessWidget {
  final String title;
  final String message;

  const StudentOpportunityLoadingState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    StudentOpportunityHubPalette.primaryDark,
                    StudentOpportunityHubPalette.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.6,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppTypography.product(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: StudentOpportunityHubPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTypography.product(
                fontSize: 12.5,
                height: 1.5,
                color: StudentOpportunityHubPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class StudentOpportunityEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StudentOpportunityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Center(
        child: AppEmptyStateNotice(
          type: AppFeedbackType.neutral,
          icon: icon,
          title: title,
          message: message,
          accentColor: StudentOpportunityHubPalette.primary,
          padding: const EdgeInsets.all(28),
          action: (actionLabel ?? '').trim().isNotEmpty && onAction != null
              ? AppFeedbackButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  icon: Icons.north_east_rounded,
                  accentColor: StudentOpportunityHubPalette.primary,
                )
              : null,
        ),
      ),
    );
  }
}
