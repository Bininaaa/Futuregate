import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_typography.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';

class OpportunityVisualTheme {
  final String type;
  final List<Color> heroGradient;
  final Color pageBackground;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color accentDeepColor;
  final Color accentSoftColor;
  final Color accentMutedColor;
  final Color accentBarColor;
  final Color heroChipBackgroundColor;
  final Color heroChipTextColor;
  final Color heroBadgeBackgroundColor;
  final Color heroBadgeTextColor;
  final Color outlineColor;
  final Color shareSurfaceColor;
  final Color shareIconColor;
  final Color shadowColor;
  final double heroBottomRadius;
  final double heroBottomPadding;
  final double cardRadius;
  final double shadowBlur;
  final bool emphasizeCompensation;
  final bool beginnerFriendly;
  final String? highlightBadge;

  const OpportunityVisualTheme({
    required this.type,
    required this.heroGradient,
    required this.pageBackground,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.accentDeepColor,
    required this.accentSoftColor,
    required this.accentMutedColor,
    required this.accentBarColor,
    required this.heroChipBackgroundColor,
    required this.heroChipTextColor,
    required this.heroBadgeBackgroundColor,
    required this.heroBadgeTextColor,
    required this.outlineColor,
    required this.shareSurfaceColor,
    required this.shareIconColor,
    required this.shadowColor,
    required this.heroBottomRadius,
    required this.heroBottomPadding,
    required this.cardRadius,
    required this.shadowBlur,
    required this.emphasizeCompensation,
    required this.beginnerFriendly,
    required this.highlightBadge,
  });

  factory OpportunityVisualTheme.fromType(String rawType) {
    switch (OpportunityType.parse(rawType)) {
      case OpportunityType.internship:
        return const OpportunityVisualTheme(
          type: OpportunityType.internship,
          heroGradient: [Color(0xFF14B8A6), Color(0xFF4F46E5)],
          pageBackground: Color(0xFFF3FBFC),
          surfaceColor: Colors.white,
          primaryTextColor: Color(0xFF0F172A),
          secondaryTextColor: Color(0xFF475569),
          accentColor: Color(0xFF14B8A6),
          accentDeepColor: Color(0xFF4338CA),
          accentSoftColor: Color(0xFFDDF8F6),
          accentMutedColor: Color(0xFFE7E8FF),
          accentBarColor: Color(0xFF14B8A6),
          heroChipBackgroundColor: Color(0x26FFFFFF),
          heroChipTextColor: Colors.white,
          heroBadgeBackgroundColor: Color(0xFFFFF7ED),
          heroBadgeTextColor: Color(0xFF0F766E),
          outlineColor: Color(0xFFE2E8F0),
          shareSurfaceColor: Color(0xFFE7F8F6),
          shareIconColor: Color(0xFF0F766E),
          shadowColor: Color(0x1014B8A6),
          heroBottomRadius: 28,
          heroBottomPadding: 26,
          cardRadius: 20,
          shadowBlur: 18,
          emphasizeCompensation: false,
          beginnerFriendly: true,
          highlightBadge: 'Beginner Friendly',
        );
      case OpportunityType.sponsoring:
        return const OpportunityVisualTheme(
          type: OpportunityType.sponsoring,
          heroGradient: [Color(0xFF1E40AF), Color(0xFFF97316)],
          pageBackground: Color(0xFFFFFBF5),
          surfaceColor: Colors.white,
          primaryTextColor: Color(0xFF111827),
          secondaryTextColor: Color(0xFF4B5563),
          accentColor: Color(0xFFF97316),
          accentDeepColor: Color(0xFF1E40AF),
          accentSoftColor: Color(0xFFFFEDD5),
          accentMutedColor: Color(0xFFDBEAFE),
          accentBarColor: Color(0xFFF97316),
          heroChipBackgroundColor: Color(0x21FFFFFF),
          heroChipTextColor: Colors.white,
          heroBadgeBackgroundColor: Color(0xFFFFF7ED),
          heroBadgeTextColor: Color(0xFF9A3412),
          outlineColor: Color(0xFFF1E2CC),
          shareSurfaceColor: Color(0xFFFFEDD5),
          shareIconColor: Color(0xFFC2410C),
          shadowColor: Color(0x12F97316),
          heroBottomRadius: 32,
          heroBottomPadding: 30,
          cardRadius: 22,
          shadowBlur: 20,
          emphasizeCompensation: true,
          beginnerFriendly: false,
          highlightBadge: 'FEATURED',
        );
      case OpportunityType.job:
      default:
        return const OpportunityVisualTheme(
          type: OpportunityType.job,
          heroGradient: [Color(0xFF3B22F6), Color(0xFF1E40AF)],
          pageBackground: Color(0xFFF5F7FF),
          surfaceColor: Colors.white,
          primaryTextColor: Color(0xFF111827),
          secondaryTextColor: Color(0xFF475569),
          accentColor: Color(0xFF3B22F6),
          accentDeepColor: Color(0xFF1E40AF),
          accentSoftColor: Color(0xFFE8E9FF),
          accentMutedColor: Color(0xFFDBEAFE),
          accentBarColor: Color(0xFF3B22F6),
          heroChipBackgroundColor: Color(0x24FFFFFF),
          heroChipTextColor: Colors.white,
          heroBadgeBackgroundColor: Color(0xFFFFFFFF),
          heroBadgeTextColor: Color(0xFF1E40AF),
          outlineColor: Color(0xFFE2E8F0),
          shareSurfaceColor: Color(0xFFEAEFFF),
          shareIconColor: Color(0xFF1E40AF),
          shadowColor: Color(0x103B22F6),
          heroBottomRadius: 26,
          heroBottomPadding: 24,
          cardRadius: 20,
          shadowBlur: 16,
          emphasizeCompensation: false,
          beginnerFriendly: false,
          highlightBadge: null,
        );
    }
  }
}

class OpportunityHeader extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final List<String> tags;
  final String title;
  final String company;
  final String? highlightBadge;
  final String companyInitial;

  const OpportunityHeader({
    super.key,
    required this.theme,
    required this.tags,
    required this.title,
    required this.company,
    required this.highlightBadge,
    required this.companyInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        theme.type == OpportunityType.sponsoring ? 22 : 18,
        18,
        theme.heroBottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(theme.heroBottomRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.72),
            blurRadius: theme.shadowBlur,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty || highlightBadge != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tags
                        .map(
                          (tag) => OpportunityTag(
                            theme: theme,
                            label: OpportunityMetadata.localizeTag(
                              tag,
                              AppLocalizations.of(context)!,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (highlightBadge != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.heroBadgeBackgroundColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      highlightBadge!,
                      style: AppTypography.product(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: theme.heroBadgeTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          SizedBox(height: tags.isEmpty && highlightBadge == null ? 4 : 16),
          Text(
            title,
            style: AppTypography.product(
              fontSize: theme.type == OpportunityType.sponsoring ? 25 : 23,
              fontWeight: FontWeight.w700,
              height: 1.14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  companyInitial,
                  style: AppTypography.product(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  company,
                  style: AppTypography.product(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OpportunityTag extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final String label;

  const OpportunityTag({super.key, required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.heroChipBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.product(
          fontSize: 9.25,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: theme.heroChipTextColor,
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  const InfoCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isHighlighted
        ? Color.lerp(theme.accentSoftColor, Colors.white, 0.38) ?? Colors.white
        : theme.surfaceColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(
          color: isHighlighted
              ? theme.accentColor.withValues(alpha: 0.18)
              : theme.outlineColor.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(
              alpha: isHighlighted ? 0.34 : 0.2,
            ),
            blurRadius: isHighlighted ? theme.shadowBlur : theme.shadowBlur - 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isHighlighted ? theme.accentColor : theme.accentSoftColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: isHighlighted ? Colors.white : theme.accentDeepColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.product(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTypography.product(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.18,
                    color: theme.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final String title;
  final String? trailingLabel;

  const SectionTitle({
    super.key,
    required this.theme,
    required this.title,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme.accentBarColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.product(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: theme.primaryTextColor,
            ),
          ),
        ),
        if (trailingLabel != null && trailingLabel!.trim().isNotEmpty)
          Text(
            trailingLabel!,
            style: AppTypography.product(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
            ),
          ),
      ],
    );
  }
}

class RequirementItem extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final String text;
  final IconData icon;

  const RequirementItem({
    super.key,
    required this.theme,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius - 4),
        border: Border.all(color: theme.outlineColor.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.accentMutedColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: theme.accentDeepColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.product(
                fontSize: 12.5,
                height: 1.4,
                color: theme.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenefitItem extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final String text;

  const BenefitItem({super.key, required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 13,
            color: Color(0xFF15803D),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.product(
              fontSize: 12.5,
              height: 1.4,
              color: theme.primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class ApplyBar extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final VoidCallback onShare;
  final VoidCallback? onApply;
  final String applyLabel;
  final bool isBusy;
  final Color? statusColor;

  const ApplyBar({
    super.key,
    required this.theme,
    required this.onShare,
    required this.onApply,
    required this.applyLabel,
    required this.isBusy,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onApply == null || isBusy;
    final hasStatus = statusColor != null;

    List<Color> buttonGradient;
    if (hasStatus) {
      buttonGradient = [statusColor!, statusColor!.withValues(alpha: 0.82)];
    } else if (isDisabled) {
      buttonGradient = [
        theme.secondaryTextColor.withValues(alpha: 0.45),
        theme.secondaryTextColor.withValues(alpha: 0.32),
      ];
    } else {
      buttonGradient = theme.heroGradient;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: theme.outlineColor)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onShare,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.shareSurfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.ios_share_rounded,
                  color: theme.shareIconColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : onApply,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: buttonGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            applyLabel,
                            style: AppTypography.product(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
