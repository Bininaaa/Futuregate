import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/opportunity_model.dart';
import '../utils/opportunity_dashboard_palette.dart';
import '../utils/opportunity_type.dart';

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
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.45,
                  color: OpportunityDashboardPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: OpportunityDashboardPalette.primary,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(actionLabel!),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  height: 1.35,
                  color: OpportunityDashboardPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: OpportunityDashboardPalette.primary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(actionLabel),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                OpportunityDashboardPalette.primary,
                OpportunityDashboardPalette.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: OpportunityDashboardPalette.primary.withValues(
                  alpha: 0.24,
                ),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SizedBox(
            height: 228,
            child: Stack(
              children: [
                Positioned(
                  top: -44,
                  right: -26,
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -54,
                  left: -16,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  right: 22,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 104, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Featured destination',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              supportingLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 17,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 84,
                  color: color.withValues(alpha: 0.14),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: OpportunityDashboardPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: OpportunityDashboardPalette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caption,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: OpportunityDashboardPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: OpportunityDashboardPalette.secondary.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cast_for_education_outlined,
                  color: OpportunityDashboardPalette.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeLabel != null && badgeLabel!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: OpportunityDashboardPalette.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: OpportunityDashboardPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrendingOpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final String badgeLabel;
  final String? companyName;
  final String? locationText;
  final String? compensationText;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onToggleSaved;

  const TrendingOpportunityCard({
    super.key,
    required this.opportunity,
    required this.badgeLabel,
    required this.companyName,
    required this.locationText,
    required this.compensationText,
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
    this.onToggleSaved,
  });

  Color _badgeColor() {
    final normalized = badgeLabel.trim().toUpperCase();

    if (normalized.contains('TECH')) {
      return OpportunityDashboardPalette.secondary;
    }
    if (normalized.contains('DESIGN')) {
      return OpportunityDashboardPalette.primary;
    }
    if (normalized.contains('FINANCE')) {
      return OpportunityDashboardPalette.warning;
    }
    if (normalized.contains('BUSINESS')) {
      return OpportunityDashboardPalette.accent;
    }

    return switch (opportunity.type) {
      'internship' => OpportunityDashboardPalette.secondary,
      'sponsoring' => OpportunityDashboardPalette.accent,
      _ => OpportunityDashboardPalette.primary,
    };
  }

  String? _companyLocationLine() {
    final parts = [
      if (companyName != null && companyName!.trim().isNotEmpty)
        companyName!.trim(),
      if (locationText != null && locationText!.trim().isNotEmpty)
        locationText!.trim(),
    ];
    if (parts.isEmpty) {
      return null;
    }

    final separator = ' ${String.fromCharCode(8226)} ';
    return parts.join(separator);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor();
    final companyLine = _companyLocationLine();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 224,
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: OpportunityDashboardPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrendingIdentityCircle(
                companyName: opportunity.companyName,
                logoUrl: opportunity.companyLogo,
                fallbackIcon: OpportunityType.icon(opportunity.type),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                        height: 1.24,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (companyLine != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        companyLine,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: OpportunityDashboardPalette.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (compensationText != null &&
                            compensationText!.trim().isNotEmpty)
                          Expanded(
                            child: Text(
                              compensationText!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: OpportunityDashboardPalette.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          const Spacer(),
                        _OpportunitySaveButton(
                          isBusy: isBusy,
                          isSaved: isSaved,
                          onPressed: onToggleSaved,
                          boxSize: 24,
                          iconSize: 18,
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
    );
  }
}

class _TrendingIdentityCircle extends StatelessWidget {
  final String companyName;
  final String logoUrl;
  final IconData fallbackIcon;

  const _TrendingIdentityCircle({
    required this.companyName,
    required this.logoUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _OpportunityCompanyAvatar(
          companyName: companyName,
          logoUrl: logoUrl,
          size: 44,
        ),
        if (!hasLogo)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Icon(
                  fallbackIcon,
                  size: 15,
                  color: OpportunityDashboardPalette.primary.withValues(
                    alpha: 0.86,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class OpportunityListTile extends StatelessWidget {
  final OpportunityModel opportunity;
  final String companyLocationText;
  final List<String> statusItems;
  final String? badgeText;
  final Color? badgeColor;
  final Color? statusColor;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onToggleSaved;

  const OpportunityListTile({
    super.key,
    required this.opportunity,
    required this.companyLocationText,
    required this.statusItems,
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
    this.onToggleSaved,
    this.badgeText,
    this.badgeColor,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeColor =
        badgeColor ?? OpportunityDashboardPalette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: OpportunityDashboardPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OpportunityCompanyAvatar(
                companyName: opportunity.companyName,
                logoUrl: opportunity.companyLogo,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      companyLocationText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: OpportunityDashboardPalette.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (statusItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        statusItems.join('  |  '),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color:
                              statusColor ??
                              OpportunityDashboardPalette.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _OpportunitySaveButton(
                    isBusy: isBusy,
                    isSaved: isSaved,
                    onPressed: onToggleSaved,
                  ),
                  if (badgeText != null && badgeText!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText!,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: effectiveBadgeColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: OpportunityDashboardPalette.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OpportunityDashboardLoadingSkeleton extends StatelessWidget {
  const OpportunityDashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: const [
        _SkeletonLine(widthFactor: 0.44, height: 28),
        SizedBox(height: 8),
        _SkeletonLine(widthFactor: 0.86, height: 14),
        SizedBox(height: 6),
        _SkeletonLine(widthFactor: 0.7, height: 14),
        SizedBox(height: 20),
        _SkeletonBlock(height: 56, radius: 22),
        SizedBox(height: 12),
        _SkeletonLine(widthFactor: 0.78, height: 14),
        SizedBox(height: 20),
        _SkeletonBlock(height: 228, radius: 30),
        SizedBox(height: 14),
        SizedBox(
          height: 152,
          child: Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 152, radius: 24)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBlock(height: 152, radius: 24)),
            ],
          ),
        ),
        SizedBox(height: 14),
        _SkeletonBlock(height: 82, radius: 24),
        SizedBox(height: 28),
        _SkeletonLine(widthFactor: 0.54, height: 18),
        SizedBox(height: 6),
        _SkeletonLine(widthFactor: 0.62, height: 14),
        SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 210, radius: 24)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBlock(height: 210, radius: 24)),
            ],
          ),
        ),
        SizedBox(height: 28),
        _SkeletonLine(widthFactor: 0.48, height: 18),
        SizedBox(height: 14),
        _SkeletonBlock(height: 94, radius: 22),
        SizedBox(height: 12),
        _SkeletonBlock(height: 94, radius: 22),
      ],
    );
  }
}

class _OpportunityCompanyAvatar extends StatelessWidget {
  final String companyName;
  final String logoUrl;
  final double size;

  const _OpportunityCompanyAvatar({
    required this.companyName,
    required this.logoUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedName = companyName.trim();
    final label = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : 'A';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.trim().isEmpty
          ? Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.primary,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.primary,
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

  const _OpportunitySaveButton({
    required this.isBusy,
    required this.isSaved,
    required this.onPressed,
    this.boxSize = 28,
    this.iconSize = 20,
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
            ? OpportunityDashboardPalette.primary
            : OpportunityDashboardPalette.textSecondary,
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({required this.widthFactor, required this.height});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: _SkeletonBlock(height: height, radius: height / 2),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final double radius;

  const _SkeletonBlock({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: OpportunityDashboardPalette.border.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
