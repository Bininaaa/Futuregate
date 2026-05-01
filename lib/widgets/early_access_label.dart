import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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

    final fontSize = compact ? 9.0 : 10.5;
    final iconSize = compact ? 10.0 : 12.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 5);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
        boxShadow: status == 'approved'
            ? [
                BoxShadow(
                  color: fg.withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.product(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class EarlyAccessCountdownChip extends StatelessWidget {
  final DateTime publicVisibleAt;

  const EarlyAccessCountdownChip({super.key, required this.publicVisibleAt});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final remaining = publicVisibleAt.difference(DateTime.now());

    String label;
    if (remaining.isNegative) {
      label = l10n.earlyAccessOpensSoonLabel;
    } else if (remaining.inHours < 1) {
      label = '${remaining.inMinutes}m left';
    } else if (remaining.inHours < 24) {
      label = '${remaining.inHours}h left';
    } else {
      label = '${remaining.inDays}d left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.22),
            colors.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accent.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_rounded, size: 12, color: colors.accent),
          const SizedBox(width: 5),
          Text(
            '${l10n.earlyAccessRemainingLabel} $label',
            style: AppTypography.product(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full early access banner shown at the top of opportunity detail.
class EarlyAccessDetailBanner extends StatelessWidget {
  final DateTime? publicVisibleAt;

  const EarlyAccessDetailBanner({super.key, this.publicVisibleAt});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final remaining = publicVisibleAt?.difference(DateTime.now());

    String countdownText = '';
    if (remaining != null && !remaining.isNegative) {
      if (remaining.inHours < 1) {
        countdownText = '${remaining.inMinutes} minutes';
      } else if (remaining.inHours < 24) {
        countdownText = '${remaining.inHours} hours';
      } else {
        countdownText = '${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'}';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withValues(alpha: 0.20),
            colors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.accent, colors.accent.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Early Access — Premium Only',
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  countdownText.isNotEmpty
                      ? 'Opens to everyone in $countdownText. You\'re ahead of the crowd.'
                      : 'You have exclusive access before this goes public.',
                  style: AppTypography.product(
                    fontSize: 11.5,
                    height: 1.45,
                    color: colors.textSecondary,
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
