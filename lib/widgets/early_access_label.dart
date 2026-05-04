import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

String formatEarlyAccessRemaining(BuildContext context, Duration? remaining) {
  final l10n = AppLocalizations.of(context)!;
  if (remaining == null || remaining <= Duration.zero) {
    return l10n.earlyAccessTimeHours(1);
  }

  if (remaining.inHours >= 24) {
    final days = (remaining.inHours / 24).ceil();
    return l10n.earlyAccessTimeDays(days);
  }

  final hours = remaining.inMinutes <= 60
      ? 1
      : (remaining.inMinutes / 60).ceil();
  return l10n.earlyAccessTimeHours(hours);
}

class EarlyAccessLabel extends StatelessWidget {
  final String status; // none, pending, approved, rejected, expired
  final bool compact;

  const EarlyAccessLabel({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (label, bg, fg, icon) = switch (status) {
      'pending' => (
        l10n.earlyAccessPendingStatus,
        colors.warningSoft,
        colors.warning,
        Icons.hourglass_empty_rounded,
      ),
      'approved' => (
        l10n.earlyAccessApprovedStatus,
        colors.accent.withValues(alpha: 0.15),
        colors.accent,
        Icons.bolt_rounded,
      ),
      'rejected' => (
        l10n.earlyAccessRejectedStatus,
        colors.dangerSoft,
        colors.danger,
        Icons.block_rounded,
      ),
      'expired' => (
        l10n.earlyAccessExpiredStatus,
        colors.surfaceMuted,
        colors.textMuted,
        Icons.timer_off_rounded,
      ),
      _ => (
        l10n.earlyAccessNoneStatus,
        colors.surfaceMuted,
        colors.textMuted,
        Icons.article_outlined,
      ),
    };

    return _AccessPill(
      label: label,
      icon: icon,
      foregroundColor: fg,
      backgroundColor: bg,
      compact: compact,
      elevated: status == 'approved',
    );
  }
}

class EarlyAccessStatusChip extends StatelessWidget {
  final bool unlocked;
  final bool compact;

  const EarlyAccessStatusChip({
    super.key,
    required this.unlocked,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final foreground = unlocked ? colors.accent : colors.primary;
    final background = unlocked
        ? colors.accentSoft
        : colors.primarySoft.withValues(alpha: AppColors.isDark ? 0.86 : 1);

    return _AccessPill(
      label: unlocked
          ? l10n.premiumEarlyAccessUnlockedChip
          : l10n.premiumEarlyAccessLockedChip,
      icon: unlocked ? Icons.flash_on_rounded : Icons.workspace_premium_rounded,
      foregroundColor: foreground,
      backgroundColor: background,
      compact: compact,
      elevated: unlocked,
    );
  }
}

class EarlyAccessTopBadge extends StatelessWidget {
  final bool unlocked;
  final bool compact;
  final bool onDarkSurface;
  final bool fullLabel;
  final bool showLabel;

  const EarlyAccessTopBadge({
    super.key,
    required this.unlocked,
    this.compact = true,
    this.onDarkSurface = false,
    this.fullLabel = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = unlocked ? colors.accent : colors.primary;
    final foreground = onDarkSurface ? Colors.white : accent;
    final background = onDarkSurface
        ? Colors.white.withValues(alpha: 0.14)
        : (unlocked ? colors.accentSoft : colors.primarySoft).withValues(
            alpha: AppColors.isDark ? 0.76 : 0.96,
          );
    final border = onDarkSurface
        ? Colors.white.withValues(alpha: 0.20)
        : accent.withValues(alpha: 0.24);
    final label = fullLabel
        ? (unlocked
              ? l10n.earlyAccessUnlockedBadgeLabel
              : l10n.premiumEarlyAccessBadgeLabel)
        : l10n.premiumBadgeLabel;

    return Tooltip(
      message: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: showLabel ? (fullLabel ? 176 : 104) : 30,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? (compact ? 8 : 10) : (compact ? 6 : 7),
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                unlocked
                    ? Icons.flash_on_rounded
                    : Icons.workspace_premium_rounded,
                size: compact ? 12 : 13,
                color: foreground,
              ),
              if (showLabel) ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.product(
                      fontSize: compact ? 9.4 : 10.6,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EarlyAccessCountdownChip extends StatelessWidget {
  final DateTime publicVisibleAt;
  final bool compact;

  const EarlyAccessCountdownChip({
    super.key,
    required this.publicVisibleAt,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = publicVisibleAt.difference(DateTime.now());
    return EarlyAccessCountdownText(
      remaining: remaining.isNegative ? Duration.zero : remaining,
      compact: compact,
    );
  }
}

class EarlyAccessCountdownText extends StatelessWidget {
  final Duration? remaining;
  final bool compact;

  const EarlyAccessCountdownText({
    super.key,
    required this.remaining,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final time = formatEarlyAccessRemaining(context, remaining);

    return _AccessPill(
      label: l10n.earlyAccessApplicationsOpenForYouIn(time),
      icon: Icons.lock_clock_rounded,
      foregroundColor: colors.primary,
      backgroundColor: colors.primarySoft.withValues(
        alpha: AppColors.isDark ? 0.72 : 0.92,
      ),
      compact: compact,
      elevated: false,
    );
  }
}

class PremiumAccessBanner extends StatelessWidget {
  final bool unlocked;
  final Duration? remaining;
  final bool compact;

  const PremiumAccessBanner({
    super.key,
    required this.unlocked,
    this.remaining,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = unlocked ? colors.accent : colors.primary;
    final soft = unlocked ? colors.accentSoft : colors.primarySoft;
    final title = unlocked
        ? l10n.premiumEarlyAccessUnlockedChip
        : l10n.premiumEarlyAccessLockedChip;
    final body = unlocked
        ? l10n.earlyAccessPremiumUnlockedBody
        : l10n.earlyAccessFreeLockedBody(
            formatEarlyAccessRemaining(context, remaining),
          );
    final footer = unlocked
        ? l10n.earlyAccessPriorityVisibilityBody
        : l10n.earlyAccessPremiumCanApplyImmediately;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            soft.withValues(alpha: AppColors.isDark ? 0.52 : 0.82),
            colors.surface.withValues(alpha: AppColors.isDark ? 0.82 : 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  Color.alphaBlend(
                    colors.secondary.withValues(alpha: 0.28),
                    accent,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              unlocked ? Icons.flash_on_rounded : Icons.lock_rounded,
              color: Colors.white,
              size: compact ? 19 : 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.product(
                    fontSize: compact ? 12.5 : 13.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: AppTypography.product(
                    fontSize: compact ? 11.5 : 12.4,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  footer,
                  style: AppTypography.product(
                    fontSize: compact ? 11.3 : 12.2,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
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

class LockedApplyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isBusy;

  const LockedApplyButton({super.key, this.onPressed, this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _AccessButton(
      label: l10n.upgradeToApplyNow,
      icon: Icons.workspace_premium_rounded,
      foregroundColor: Colors.white,
      gradientColors: [colors.primaryDeep, colors.primary],
      isBusy: isBusy,
      onPressed: onPressed,
    );
  }
}

class PremiumApplyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isBusy;

  const PremiumApplyButton({super.key, this.onPressed, this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _AccessButton(
      label: l10n.applyWithPriority,
      icon: Icons.flash_on_rounded,
      foregroundColor: Colors.white,
      gradientColors: [colors.accent, colors.primary],
      isBusy: isBusy,
      onPressed: onPressed,
    );
  }
}

class AppliedStatusBanner extends StatelessWidget {
  final bool priority;
  final bool compact;

  const AppliedStatusBanner({
    super.key,
    this.priority = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _StatusBanner(
      icon: priority ? Icons.star_rounded : Icons.check_circle_rounded,
      title: l10n.applicationSentLabel,
      subtitle: priority ? l10n.sentWithPriorityLabel : null,
      accentColor: priority ? colors.accent : colors.success,
      backgroundColor: priority ? colors.accentSoft : colors.successSoft,
      compact: compact,
    );
  }
}

class ClosedStatusBanner extends StatelessWidget {
  final bool compact;

  const ClosedStatusBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _StatusBanner(
      icon: Icons.lock_outline_rounded,
      title: l10n.closedLabel,
      subtitle: l10n.studentOpportunityClosedMessage,
      accentColor: colors.textMuted,
      backgroundColor: colors.surfaceMuted,
      compact: compact,
    );
  }
}

class EarlyAccessDetailBanner extends StatelessWidget {
  final DateTime? publicVisibleAt;

  const EarlyAccessDetailBanner({super.key, this.publicVisibleAt});

  @override
  Widget build(BuildContext context) {
    final remaining = publicVisibleAt?.difference(DateTime.now());
    return PremiumAccessBanner(
      unlocked: true,
      remaining: remaining != null && remaining.isNegative
          ? Duration.zero
          : remaining,
    );
  }
}

class _AccessPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool compact;
  final bool elevated;

  const _AccessPill({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.compact,
    required this.elevated,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 9.4 : 10.8;
    final iconSize = compact ? 11.0 : 13.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.28)),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: foregroundColor.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 190 : 280),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final List<Color> gradientColors;
  final bool isBusy;
  final VoidCallback? onPressed;

  const _AccessButton({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.gradientColors,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: isBusy ? null : onPressed,
          icon: isBusy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: foregroundColor,
                  ),
                )
              : Icon(icon, size: 18),
          label: Text(
            label,
            style: AppTypography.product(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final Color backgroundColor;
  final bool compact;

  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: AppColors.isDark ? 0.72 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: compact ? 18 : 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.product(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.product(
                      fontSize: compact ? 11 : 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
