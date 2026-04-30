import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'premium_upgrade_modal.dart';

Future<bool> showSavedLimitUpgradeModal(
  BuildContext context, {
  required int limit,
  VoidCallback? onUpgrade,
}) async {
  final l10n = AppLocalizations.of(context)!;
  return showPremiumUpgradeModal(
    context,
    title: l10n.savedLimitReachedTitle,
    body: l10n.savedLimitReachedMessage,
    highlightText: l10n.savedLimitUpgradeMessage,
    onUpgrade: onUpgrade,
  );
}

class SavedLimitUpgradeBanner extends StatelessWidget {
  final int limit;
  final int currentCount;
  final VoidCallback? onUpgrade;

  const SavedLimitUpgradeBanner({
    super.key,
    required this.limit,
    required this.currentCount,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedLimitReachedTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.savedLimitUpgradeMessage,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onUpgrade,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              l10n.premiumPassUpgradeButton,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
