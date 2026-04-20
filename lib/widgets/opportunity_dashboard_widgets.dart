import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/opportunity_model.dart';
import '../theme/app_typography.dart';
import '../utils/application_status.dart';
import '../utils/display_text.dart';
import '../utils/opportunity_dashboard_palette.dart';
import '../utils/opportunity_type.dart';
import 'shared/app_feedback.dart';
import 'shared/app_loading.dart';

IconData _applicationStatusIcon(String status) {
  switch (ApplicationStatus.parse(status)) {
    case ApplicationStatus.accepted:
      return Icons.check_circle_rounded;
    case ApplicationStatus.rejected:
      return Icons.cancel_rounded;
    case ApplicationStatus.pending:
    default:
      return Icons.hourglass_top_rounded;
  }
}

String _opportunityBaseTitle(
  BuildContext context,
  OpportunityModel opportunity,
) {
  final l10n = AppLocalizations.of(context)!;
  final fallback = switch (OpportunityType.parse(opportunity.type)) {
    OpportunityType.internship => l10n.opportunityStudentInternshipFallback,
    OpportunityType.sponsoring => l10n.opportunitySponsoredFallback,
    OpportunityType.job => l10n.opportunityOpenJobFallback,
    _ => l10n.opportunityOpenFallback,
  };
  return DisplayText.opportunityTitle(opportunity.title, fallback: fallback);
}

class OpportunitySectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  const OpportunitySectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (accentColor != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTypography.product(
                  fontSize: 11.2,
                  height: 1.35,
                  color: OpportunityDashboardPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: OpportunityDashboardPalette.primary,
                backgroundColor: OpportunityDashboardPalette.surface,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: OpportunityDashboardPalette.primary.withValues(
                    alpha: 0.14,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: AppTypography.product(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_outward_rounded, size: 13),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TrendingOpportunitySectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const TrendingOpportunitySectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: OpportunityDashboardPalette.primary.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: OpportunityDashboardPalette.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.product(
                        fontSize: 11.2,
                        height: 1.35,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: OpportunityDashboardPalette.primary,
              backgroundColor: OpportunityDashboardPalette.surface,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: OpportunityDashboardPalette.primary.withValues(
                  alpha: 0.14,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: AppTypography.product(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_outward_rounded, size: 13),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OpportunityHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String supportingLabel;
  final IconData icon;
  final VoidCallback onTap;

  const OpportunityHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.supportingLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                OpportunityDashboardPalette.primary,
                OpportunityDashboardPalette.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: SizedBox(
            height: 202,
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -24,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -44,
                  left: -16,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 92, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.uiFeaturedDestination,
                          style: AppTypography.product(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: AppTypography.product(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTypography.product(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              supportingLabel,
                              style: AppTypography.product(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OpportunityCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String caption;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const OpportunityCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(
                  icon,
                  size: 66,
                  color: color.withValues(alpha: 0.14),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTypography.product(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: OpportunityDashboardPalette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 24,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        subtitle,
                        style: AppTypography.product(
                          fontSize: 9.8,
                          color: OpportunityDashboardPalette.textSecondary,
                          height: 1.18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    caption,
                    style: AppTypography.product(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrainingProgramsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final VoidCallback onTap;

  const TrainingProgramsCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: OpportunityDashboardPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: OpportunityDashboardPalette.secondary.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cast_for_education_outlined,
                  color: OpportunityDashboardPalette.secondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTypography.product(
                          fontSize: 11.5,
                          color: OpportunityDashboardPalette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeLabel != null && badgeLabel!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: OpportunityDashboardPalette.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: AppTypography.product(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: OpportunityDashboardPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityTypeTone {
  final Color accent;
  final Color strongAccent;
  final Color softBackground;
  final Color borderColor;
  final Color glowColor;

  const _OpportunityTypeTone({
    required this.accent,
    required this.strongAccent,
    required this.softBackground,
    required this.borderColor,
    required this.glowColor,
  });
}

_OpportunityTypeTone _toneForOpportunityType(String rawType) {
  switch (OpportunityType.parse(rawType)) {
    case OpportunityType.internship:
      return _OpportunityTypeTone(
        accent: OpportunityType.internshipColor,
        strongAccent: const Color(0xFF0F766E),
        softBackground: OpportunityType.softBackground(rawType),
        borderColor: OpportunityType.softBorder(rawType),
        glowColor: OpportunityType.internshipColor.withValues(alpha: 0.12),
      );
    case OpportunityType.sponsoring:
      return _OpportunityTypeTone(
        accent: OpportunityType.sponsoringColor,
        strongAccent: const Color(0xFFF97316),
        softBackground: OpportunityType.softBackground(rawType),
        borderColor: OpportunityType.softBorder(rawType),
        glowColor: OpportunityType.sponsoringColor.withValues(alpha: 0.12),
      );
    case OpportunityType.job:
    default:
      return _OpportunityTypeTone(
        accent: OpportunityType.jobColor,
        strongAccent: const Color(0xFF4F46E5),
        softBackground: OpportunityType.softBackground(rawType),
        borderColor: OpportunityType.softBorder(rawType),
        glowColor: OpportunityType.jobColor.withValues(alpha: 0.12),
      );
  }
}

class TrendingOpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final int rank;
  final String typeLabel;
  final String trendLabel;
  final String? companyName;
  final String? locationText;
  final List<String> detailChips;
  final String? compensationText;
  final String? applicationStatus;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onToggleSaved;

  const TrendingOpportunityCard({
    super.key,
    required this.opportunity,
    required this.rank,
    required this.typeLabel,
    required this.trendLabel,
    required this.companyName,
    required this.locationText,
    required this.detailChips,
    required this.compensationText,
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
    this.onToggleSaved,
    this.applicationStatus,
  });

  List<String> _metaItems() {
    final seen = <String>{};
    final result = <String>[];

    for (final item in [trendLabel, ...detailChips]) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      if (seen.add(trimmed.toLowerCase())) {
        result.add(trimmed);
      }

      if (result.length == 2) {
        break;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayTitle = _opportunityBaseTitle(context, opportunity);
    final tone = _toneForOpportunityType(opportunity.type);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isCompactLayout =
        MediaQuery.sizeOf(context).width < 380 || textScale > 1.08;
    final companyLabel = companyName?.trim().isNotEmpty == true
        ? companyName!.trim()
        : l10n.opportunityFutureGatePartner;
    final locationLabel = locationText?.trim();
    final metaItems = _metaItems();
    final cardWidth = isCompactLayout ? 206.0 : 220.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: cardWidth,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tone.borderColor),
            boxShadow: [
              BoxShadow(
                color: tone.glowColor.withValues(alpha: 0.48),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: tone.softBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$rank',
                      style: AppTypography.product(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        color: tone.strongAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _OpportunityAccentChip(
                      label: typeLabel,
                      foreground: tone.strongAccent,
                      background: tone.accent.withValues(alpha: 0.16),
                      icon: OpportunityType.icon(opportunity.type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: tone.softBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: tone.accent.withValues(alpha: 0.12),
                      ),
                    ),
                    child: _OpportunitySaveButton(
                      isBusy: isBusy,
                      isSaved: isSaved,
                      onPressed: onToggleSaved,
                      boxSize: 30,
                      iconSize: 16,
                      activeColor: tone.strongAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _OpportunityCompanyAvatar(
                    companyName: opportunity.companyName,
                    logoUrl: opportunity.companyLogo,
                    size: 36,
                    accentColor: tone.strongAccent,
                    backgroundColor: tone.accent.withValues(alpha: 0.11),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DisplayText.capitalizeDisplayValue(companyLabel),
                          style: AppTypography.product(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                            color: OpportunityDashboardPalette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (locationLabel != null &&
                            locationLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            DisplayText.capitalizeDisplayValue(locationLabel),
                            style: AppTypography.product(
                              fontSize: 10.1,
                              color: OpportunityDashboardPalette.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                displayTitle,
                style: AppTypography.product(
                  fontSize: 14.3,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.textPrimary,
                  height: 1.24,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (compensationText != null &&
                  compensationText!.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  DisplayText.capitalizeDisplayValue(compensationText!),
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tone.strongAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (metaItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 13,
                      color: tone.strongAccent,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _OpportunityMetadataText(
                        items: metaItems,
                        color: tone.strongAccent,
                        fontSize: 10.4,
                      ),
                    ),
                  ],
                ),
              ],
              if (applicationStatus != null) ...[
                const SizedBox(height: 8),
                _OpportunityAccentChip(
                  label: ApplicationStatus.label(applicationStatus, l10n),
                  foreground: ApplicationStatus.color(applicationStatus),
                  background: ApplicationStatus.color(
                    applicationStatus,
                  ).withValues(alpha: 0.14),
                  icon: _applicationStatusIcon(applicationStatus!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OpportunityListTile extends StatelessWidget {
  final OpportunityModel opportunity;
  final String typeLabel;
  final String companyLocationText;
  final List<String> detailChips;
  final String? compensationText;
  final String? badgeText;
  final Color? badgeColor;
  final Color? statusColor;
  final String? applicationStatus;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onToggleSaved;

  const OpportunityListTile({
    super.key,
    required this.opportunity,
    required this.typeLabel,
    required this.companyLocationText,
    required this.detailChips,
    required this.compensationText,
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
    this.onToggleSaved,
    this.badgeText,
    this.badgeColor,
    this.statusColor,
    this.applicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayTitle = _opportunityBaseTitle(context, opportunity);
    final tone = _toneForOpportunityType(opportunity.type);
    final effectiveBadgeColor =
        badgeColor ?? OpportunityDashboardPalette.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tone.borderColor),
            boxShadow: [
              BoxShadow(
                color: tone.glowColor.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Colored header strip --
              Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                decoration: BoxDecoration(
                  color: tone.softBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                ),
                child: Row(
                  children: [
                    _OpportunityAccentChip(
                      label: typeLabel,
                      foreground: tone.strongAccent,
                      background: tone.accent.withValues(alpha: 0.16),
                      icon: OpportunityType.icon(opportunity.type),
                    ),
                    if (badgeText != null && badgeText!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _OpportunityAccentChip(
                        label: badgeText!,
                        foreground: effectiveBadgeColor,
                        background: effectiveBadgeColor.withValues(alpha: 0.16),
                      ),
                    ],
                    if (applicationStatus != null) ...[
                      const SizedBox(width: 6),
                      _OpportunityAccentChip(
                        label: ApplicationStatus.label(applicationStatus, l10n),
                        foreground: ApplicationStatus.color(applicationStatus),
                        background: ApplicationStatus.color(
                          applicationStatus,
                        ).withValues(alpha: 0.14),
                        icon: _applicationStatusIcon(applicationStatus!),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: OpportunityDashboardPalette.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: tone.accent.withValues(alpha: 0.14),
                        ),
                      ),
                      child: _OpportunitySaveButton(
                        isBusy: isBusy,
                        isSaved: isSaved,
                        onPressed: onToggleSaved,
                        boxSize: 32,
                        iconSize: 16,
                        activeColor: tone.strongAccent,
                      ),
                    ),
                  ],
                ),
              ),
              // -- Main content --
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OpportunityCompanyAvatar(
                      companyName: opportunity.companyName,
                      logoUrl: opportunity.companyLogo,
                      size: 42,
                      accentColor: tone.strongAccent,
                      backgroundColor: tone.accent.withValues(alpha: 0.10),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayTitle,
                            style: AppTypography.product(
                              fontSize: 14.2,
                              fontWeight: FontWeight.w700,
                              color: OpportunityDashboardPalette.textPrimary,
                              height: 1.22,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 13,
                                color:
                                    OpportunityDashboardPalette.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  DisplayText.capitalizeDisplayValue(
                                    companyLocationText,
                                  ),
                                  style: AppTypography.product(
                                    fontSize: 11,
                                    color: OpportunityDashboardPalette
                                        .textSecondary,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (compensationText != null &&
                              compensationText!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tone.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    size: 13,
                                    color: tone.strongAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      DisplayText.capitalizeDisplayValue(
                                        compensationText!,
                                      ),
                                      style: AppTypography.product(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: tone.strongAccent,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (detailChips.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _OpportunityMetadataText(
                              items: detailChips,
                              color: OpportunityDashboardPalette.textSecondary,
                              fontSize: 10.4,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: tone.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OpportunityDashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const OpportunityDashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateNotice(
      type: AppFeedbackType.neutral,
      icon: icon,
      title: title,
      message: subtitle,
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    );
  }
}

class _OpportunityMetadataText extends StatelessWidget {
  final List<String> items;
  final Color color;
  final double fontSize;

  const _OpportunityMetadataText({
    required this.items,
    required this.color,
    this.fontSize = 10.6,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(2)
        .toList(growable: false);

    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final separator = ' ${String.fromCharCode(8226)} ';

    return Text(
      visibleItems.map(DisplayText.capitalizeDisplayValue).join(separator),
      style: AppTypography.product(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.25,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class OpportunityDashboardLoadingSkeleton extends StatelessWidget {
  const OpportunityDashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          AppSkeletonLine(widthFactor: 0.44, height: 28),
          SizedBox(height: 8),
          AppSkeletonLine(widthFactor: 0.86, height: 14),
          SizedBox(height: 6),
          AppSkeletonLine(widthFactor: 0.7, height: 14),
          SizedBox(height: 20),
          AppSkeletonBlock(height: 56, radius: 22),
          SizedBox(height: 12),
          AppSkeletonLine(widthFactor: 0.78, height: 14),
          SizedBox(height: 20),
          AppSkeletonBlock(height: 228, radius: 30),
          SizedBox(height: 14),
          SizedBox(
            height: 152,
            child: Row(
              children: [
                Expanded(child: AppSkeletonBlock(height: 152, radius: 24)),
                SizedBox(width: 12),
                Expanded(child: AppSkeletonBlock(height: 152, radius: 24)),
              ],
            ),
          ),
          SizedBox(height: 14),
          AppSkeletonBlock(height: 82, radius: 24),
          SizedBox(height: 28),
          AppSkeletonLine(widthFactor: 0.54, height: 18),
          SizedBox(height: 6),
          AppSkeletonLine(widthFactor: 0.62, height: 14),
          SizedBox(height: 14),
          SizedBox(
            height: 194,
            child: Row(
              children: [
                Expanded(child: AppSkeletonBlock(height: 194, radius: 22)),
                SizedBox(width: 12),
                Expanded(child: AppSkeletonBlock(height: 194, radius: 22)),
              ],
            ),
          ),
          SizedBox(height: 28),
          AppSkeletonLine(widthFactor: 0.48, height: 18),
          SizedBox(height: 14),
          AppSkeletonBlock(height: 108, radius: 20),
          SizedBox(height: 12),
          AppSkeletonBlock(height: 108, radius: 20),
        ],
      ),
    );
  }
}

class _OpportunityCompanyAvatar extends StatelessWidget {
  final String companyName;
  final String logoUrl;
  final double size;
  final Color? accentColor;
  final Color? backgroundColor;

  const _OpportunityCompanyAvatar({
    required this.companyName,
    required this.logoUrl,
    this.size = 48,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedName = companyName.trim();
    final label = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : 'A';
    final resolvedAccent = accentColor ?? OpportunityDashboardPalette.primary;
    final resolvedBackground =
        backgroundColor ??
        OpportunityDashboardPalette.primary.withValues(alpha: 0.08);

    return Container(
      width: size,
      height: size,
      padding: logoUrl.trim().isEmpty
          ? EdgeInsets.zero
          : EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: resolvedBackground,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.trim().isEmpty
          ? Center(
              child: Text(
                label,
                style: AppTypography.product(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w700,
                  color: resolvedAccent,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => Center(
                child: Text(
                  label,
                  style: AppTypography.product(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w700,
                    color: resolvedAccent,
                  ),
                ),
              ),
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: size * 0.32,
                  height: size * 0.32,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
    );
  }
}

class _OpportunitySaveButton extends StatelessWidget {
  final bool isBusy;
  final bool isSaved;
  final VoidCallback? onPressed;
  final double boxSize;
  final double iconSize;
  final Color? activeColor;

  const _OpportunitySaveButton({
    required this.isBusy,
    required this.isSaved,
    required this.onPressed,
    this.boxSize = 28,
    this.iconSize = 20,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return SizedBox(
        width: boxSize,
        height: boxSize,
        child: Center(
          child: SizedBox(
            width: iconSize - 2,
            height: iconSize - 2,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (onPressed == null) {
      return SizedBox(width: boxSize, height: boxSize);
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: isSaved ? 'Remove bookmark' : 'Save opportunity',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: boxSize, height: boxSize),
      splashRadius: boxSize * 0.7,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
        size: iconSize,
        color: isSaved
            ? (activeColor ?? OpportunityDashboardPalette.primary)
            : OpportunityDashboardPalette.textSecondary,
      ),
    );
  }
}

class _OpportunityAccentChip extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const _OpportunityAccentChip({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 8 : 7, 5, 8, 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            DisplayText.capitalizeDisplayValue(label),
            style: AppTypography.product(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: 0.12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
