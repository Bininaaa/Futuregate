import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/opportunity_model.dart';
import '../utils/opportunity_dashboard_palette.dart';

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
                      width: 10,
                      height: 10,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: OpportunityDashboardPalette.textSecondary,
                  height: 1.45,
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
              textStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(actionLabel!),
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
        borderRadius: BorderRadius.circular(28),
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
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: OpportunityDashboardPalette.primary.withValues(
                  alpha: 0.24,
                ),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -28,
                right: -18,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -22,
                right: 44,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 112, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Featured pathway',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          supportingLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                            size: 18,
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
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
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
              const SizedBox(height: 10),
              Text(
                caption,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
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
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: OpportunityDashboardPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: OpportunityDashboardPalette.secondary.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cast_for_education_outlined,
                  color: OpportunityDashboardPalette.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeLabel != null && badgeLabel!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: OpportunityDashboardPalette.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
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
  final String primaryMeta;
  final String secondaryMeta;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onToggleSaved;

  const TrendingOpportunityCard({
    super.key,
    required this.opportunity,
    required this.badgeLabel,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
    this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          width: 276,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: OpportunityDashboardPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OpportunityDashboardPalette.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isBusy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (onToggleSaved != null)
                    IconButton(
                      onPressed: onToggleSaved,
                      splashRadius: 20,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: isSaved
                            ? OpportunityDashboardPalette.primary
                            : OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _OpportunityCompanyAvatar(
                companyName: opportunity.companyName,
                logoUrl: opportunity.companyLogo,
              ),
              const SizedBox(height: 14),
              Text(
                opportunity.title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.textPrimary,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                primaryMeta,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: OpportunityDashboardPalette.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OpportunityDashboardPalette.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        secondaryMeta,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class OpportunityListTile extends StatelessWidget {
  final OpportunityModel opportunity;
  final String metaText;
  final String supportingText;
  final String? badgeText;
  final Color? badgeColor;
  final bool compact;
  final VoidCallback onTap;

  const OpportunityListTile({
    super.key,
    required this.opportunity,
    required this.metaText,
    required this.supportingText,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBackground = (badgeColor ?? OpportunityDashboardPalette.primary)
        .withValues(alpha: 0.12);
    final effectiveBadgeColor =
        badgeColor ?? OpportunityDashboardPalette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(compact ? 14 : 16),
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
            children: [
              _OpportunityCompanyAvatar(
                companyName: opportunity.companyName,
                logoUrl: opportunity.companyLogo,
                size: compact ? 44 : 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opportunity.companyName.isNotEmpty
                          ? opportunity.companyName
                          : 'Opportunity',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            metaText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: OpportunityDashboardPalette.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: OpportunityDashboardPalette.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            supportingText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: OpportunityDashboardPalette.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (badgeText != null && badgeText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: effectiveBadgeColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: OpportunityDashboardPalette.textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
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
        _SkeletonLine(widthFactor: 0.34, height: 14),
        SizedBox(height: 14),
        _SkeletonLine(widthFactor: 0.62, height: 34),
        SizedBox(height: 10),
        _SkeletonLine(widthFactor: 0.95, height: 14),
        SizedBox(height: 6),
        _SkeletonLine(widthFactor: 0.8, height: 14),
        SizedBox(height: 20),
        _SkeletonBlock(height: 58, radius: 22),
        SizedBox(height: 20),
        _SkeletonBlock(height: 220, radius: 28),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _SkeletonBlock(height: 160, radius: 24)),
            SizedBox(width: 14),
            Expanded(child: _SkeletonBlock(height: 160, radius: 24)),
          ],
        ),
        SizedBox(height: 16),
        _SkeletonBlock(height: 90, radius: 24),
        SizedBox(height: 28),
        _SkeletonLine(widthFactor: 0.48, height: 20),
        SizedBox(height: 6),
        _SkeletonLine(widthFactor: 0.64, height: 14),
        SizedBox(height: 14),
        SizedBox(
          height: 224,
          child: Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 224, radius: 26)),
              SizedBox(width: 14),
              Expanded(child: _SkeletonBlock(height: 224, radius: 26)),
            ],
          ),
        ),
        SizedBox(height: 28),
        _SkeletonLine(widthFactor: 0.42, height: 20),
        SizedBox(height: 14),
        _SkeletonBlock(height: 88, radius: 22),
        SizedBox(height: 12),
        _SkeletonBlock(height: 88, radius: 22),
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
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final label = companyName.trim().isNotEmpty
        ? companyName.trim()[0].toUpperCase()
        : 'A';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.trim().isEmpty
          ? Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.36,
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
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.primary,
                  ),
                ),
              ),
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: size * 0.34,
                  height: size * 0.34,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
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
