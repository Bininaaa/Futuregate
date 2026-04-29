import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'innovation_hub_theme.dart';

class IdeaMetricsRow extends StatelessWidget {
  final int interestedCount;
  final bool inverted;

  const IdeaMetricsRow({
    super.key,
    required this.interestedCount,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = inverted
        ? Colors.white.withValues(alpha: 0.88)
        : InnovationHubPalette.textSecondary;
    final pillColor = inverted
        ? Colors.white.withValues(alpha: 0.16)
        : InnovationHubPalette.cardTint;
    final iconColor = inverted ? Colors.white : InnovationHubPalette.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(
              context,
            )!.studentInterestedCountTitle(interestedCount),
            style: InnovationHubTypography.label(color: labelColor, size: 11.5),
          ),
        ],
      ),
    );
  }
}
