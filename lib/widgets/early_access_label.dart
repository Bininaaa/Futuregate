import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

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
          Icons.workspace_premium_rounded,
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

    final fontSize = compact ? 9.0 : 10.0;
    final iconSize = compact ? 10.0 : 11.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
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
      label = '${remaining.inMinutes}m';
    } else if (remaining.inHours < 24) {
      label = '${remaining.inHours}h';
    } else {
      label = '${remaining.inDays}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_rounded, size: 11, color: colors.accent),
          const SizedBox(width: 4),
          Text(
            '${l10n.earlyAccessRemainingLabel} $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
