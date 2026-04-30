import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

enum PremiumBadgeSize { small, medium, large }

class PremiumBadge extends StatelessWidget {
  final PremiumBadgeSize size;
  final bool showLabel;

  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.small,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (iconSize, fontSize, padding) = switch (size) {
      PremiumBadgeSize.small => (10.0, 9.0, const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
      PremiumBadgeSize.medium => (12.0, 10.0, const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
      PremiumBadgeSize.large => (14.0, 12.0, const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent,
            colors.accent.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: iconSize, color: Colors.white),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              l10n.premiumBadgeLabel,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
