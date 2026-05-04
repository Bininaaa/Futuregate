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

    final (iconSize, fontSize, padding, minHeight, gap) = switch (size) {
      PremiumBadgeSize.small => (
        13.0,
        11.0,
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        25.0,
        5.0,
      ),
      PremiumBadgeSize.medium => (
        14.0,
        11.5,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        32.0,
        8.0,
      ),
      PremiumBadgeSize.large => (
        16.0,
        13.0,
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        40.0,
        8.0,
      ),
    };

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accent, colors.accent.withValues(alpha: 0.75)],
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
          Icon(
            Icons.workspace_premium_rounded,
            size: iconSize,
            color: Colors.white,
          ),
          if (showLabel) ...[
            SizedBox(width: gap),
            Text(
              l10n.premiumBadgeLabel,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
