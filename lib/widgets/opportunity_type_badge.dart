import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_typography.dart';
import '../utils/opportunity_type.dart';

/// A compact, pill-shaped badge that displays an opportunity type
/// with its associated color and icon.
class OpportunityTypeBadge extends StatelessWidget {
  final String type;
  final bool showIcon;
  final double fontSize;

  const OpportunityTypeBadge({
    super.key,
    required this.type,
    this.showIcon = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedType = OpportunityType.parse(type);
    final badgeColor = OpportunityType.color(normalizedType);
    final l10n = AppLocalizations.of(context)!;
    final label = OpportunityType.label(normalizedType, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              OpportunityType.icon(normalizedType),
              size: fontSize + 2,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.product(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
