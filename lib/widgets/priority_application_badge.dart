import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

class PriorityApplicationBadge extends StatelessWidget {
  final bool compact;
  final bool fullLabel;
  final bool showLabel;

  const PriorityApplicationBadge({
    super.key,
    this.compact = false,
    this.fullLabel = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final iconSize = compact ? 10.0 : 12.0;
    final fontSize = compact ? 9.0 : 10.0;
    final padding = showLabel
        ? (compact
              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 7, vertical: 3))
        : (compact
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 5)
              : const EdgeInsets.symmetric(horizontal: 7, vertical: 6));

    return Tooltip(
      message: l10n.priorityApplicationTooltip,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.activity, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: iconSize, color: Colors.white),
            if (showLabel) ...[
              const SizedBox(width: 3),
              Text(
                fullLabel
                    ? l10n.priorityApplicationFullLabel
                    : l10n.priorityApplicationLabel,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
