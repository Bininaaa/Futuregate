import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

Future<bool> showPremiumUpgradeModal(
  BuildContext context, {
  required String title,
  required String body,
  String? highlightText,
  VoidCallback? onUpgrade,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PremiumUpgradeSheet(
      title: title,
      body: body,
      highlightText: highlightText,
      onUpgrade: onUpgrade,
    ),
  );
  return result == true;
}

class _PremiumUpgradeSheet extends StatelessWidget {
  final String title;
  final String body;
  final String? highlightText;
  final VoidCallback? onUpgrade;

  const _PremiumUpgradeSheet({
    required this.title,
    required this.body,
    this.highlightText,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: colors.softShadow(0.12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crown icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.accent, colors.accent.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            if (highlightText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlightText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
    );
  }
}
