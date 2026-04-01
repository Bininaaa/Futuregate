import 'package:flutter/material.dart';

import 'innovation_hub_theme.dart';

class IdeaMetricsRow extends StatelessWidget {
  final int sparksCount;
  final int interestedCount;
  final bool inverted;

  const IdeaMetricsRow({
    super.key,
    required this.sparksCount,
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricPill(
          icon: Icons.flash_on_rounded,
          label: '$sparksCount Sparks',
          iconColor: iconColor,
          textColor: labelColor,
          backgroundColor: pillColor,
        ),
        _MetricPill(
          icon: Icons.groups_rounded,
          label: '$interestedCount Interested',
          iconColor: inverted ? Colors.white : InnovationHubPalette.secondary,
          textColor: labelColor,
          backgroundColor: pillColor,
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: InnovationHubTypography.label(color: textColor, size: 11.5),
          ),
        ],
      ),
    );
  }
}
