import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final badgeColor = OpportunityType.color(type);
    final label = OpportunityType.label(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(OpportunityType.icon(type), size: fontSize + 2, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
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
