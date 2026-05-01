import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/premium_config_model.dart';
import '../providers/premium_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';

Future<bool> showSavedLimitUpgradeModal(
  BuildContext context, {
  required int limit,
  int? currentCount,
  bool justReached = false,
  VoidCallback? onUpgrade,
}) async {
  final safeLimit = limit < 1
      ? PremiumConfigModel.normalStudentSavedLimit
      : limit;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SavedLimitUpgradeSheet(
      limit: safeLimit,
      currentCount: (currentCount ?? safeLimit).clamp(0, safeLimit).toInt(),
      justReached: justReached,
      onUpgrade: onUpgrade,
    ),
  );
  return result == true;
}

Future<bool> showSavedLimitReachedAfterSave(
  BuildContext context, {
  required int currentCount,
  int limit = PremiumConfigModel.normalStudentSavedLimit,
  VoidCallback? onUpgrade,
}) async {
  final effectiveLimit = _effectiveFreeSavedLimit(context, limit);
  if (_hasActivePremium(context) || currentCount < effectiveLimit) {
    return false;
  }

  await showSavedLimitUpgradeModal(
    context,
    limit: effectiveLimit,
    currentCount: currentCount,
    justReached: true,
    onUpgrade: onUpgrade,
  );
  return true;
}

int _effectiveFreeSavedLimit(BuildContext context, int fallback) {
  try {
    return context.read<PremiumProvider>().config.effectiveFreeSavedLimit;
  } catch (_) {
    return fallback;
  }
}

bool _hasActivePremium(BuildContext context) {
  try {
    return context.read<SubscriptionProvider>().hasActivePremium;
  } catch (_) {
    return false;
  }
}

class _SavedLimitUpgradeSheet extends StatelessWidget {
  final int limit;
  final int currentCount;
  final bool justReached;
  final VoidCallback? onUpgrade;

  const _SavedLimitUpgradeSheet({
    required this.limit,
    required this.currentCount,
    required this.justReached,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final progress = (currentCount / limit).clamp(0.0, 1.0);
    final body = justReached
        ? l10n.savedLimitReachedFullMessage(currentCount, limit)
        : l10n.savedLimitBlockedMessage(limit);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
          boxShadow: colors.softShadow(0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderStrong.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.accent, colors.warning],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.savedLimitReachedTitle,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1.14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.savedLimitUpgradeSheetSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.accentSoft.withValues(
                    alpha: colors.isDarkMode ? 0.28 : 0.86,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_rounded,
                          size: 18,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.savedLimitProgressLabel(currentCount, limit),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          l10n.premiumBadgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colors.surface.withValues(alpha: 0.88),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SavedLimitBenefit(
                    icon: Icons.all_inclusive_rounded,
                    label: l10n.premiumFeatureSaved,
                    color: colors.accent,
                    colors: colors,
                  ),
                  _SavedLimitBenefit(
                    icon: Icons.bolt_rounded,
                    label: l10n.premiumFeatureEarlyAccess,
                    color: colors.primary,
                    colors: colors,
                  ),
                  _SavedLimitBenefit(
                    icon: Icons.trending_up_rounded,
                    label: l10n.premiumFeaturePriority,
                    color: colors.secondary,
                    colors: colors,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onUpgrade?.call();
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: Text(l10n.premiumPassUpgradeButton),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancelLabel,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedLimitBenefit extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppColors colors;

  const _SavedLimitBenefit({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isDarkMode ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
