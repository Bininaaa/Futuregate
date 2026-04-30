import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/subscription_model.dart';
import '../theme/app_colors.dart';
import 'premium_badge.dart';

class SubscriptionStatusCard extends StatelessWidget {
  final SubscriptionModel? subscription;
  final bool isLoading;
  final VoidCallback? onUpgrade;
  final VoidCallback? onRenew;

  const SubscriptionStatusCard({
    super.key,
    required this.subscription,
    this.isLoading = false,
    this.onUpgrade,
    this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return _shell(
        colors,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final sub = subscription;

    if (sub == null || (!sub.isActive && !sub.isPending)) {
      return _shell(
        colors,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.premiumPassTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.premiumPassSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              child: Text(l10n.premiumPassUpgradeButton),
            ),
          ],
        ),
      );
    }

    if (sub.isPending) {
      return _shell(
        colors,
        gradient: LinearGradient(
          colors: [
            colors.warningSoft,
            colors.surface,
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty_rounded,
                color: colors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.premiumPassPendingTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.warning,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.premiumPassPendingMessage,
                    style: TextStyle(
                      fontSize: 12,
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

    // Active premium
    final expiresAt = sub.expiresAtDate;
    final expiresStr = expiresAt != null
        ? DateFormat.yMMMd().format(expiresAt)
        : '';

    return _shell(
      colors,
      gradient: LinearGradient(
        colors: [
          colors.accentSoft,
          colors.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: colors.accent.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.accent, colors.accent.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.premiumPassActiveTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const PremiumBadge(size: PremiumBadgeSize.small),
                  ],
                ),
                if (expiresStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.premiumPassExpiresLabel} $expiresStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (sub.mode == 'test') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.warningSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.paymentTestModeNotice,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.warning,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _shell(
    AppColors colors, {
    required Widget child,
    Gradient? gradient,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? colors.surface : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? colors.border,
        ),
        boxShadow: colors.softShadow(0.05),
      ),
      child: child,
    );
  }
}
