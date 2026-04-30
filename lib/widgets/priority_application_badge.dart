import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

class PriorityApplicationBadge extends StatelessWidget {
  final bool compact;

  const PriorityApplicationBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final iconSize = compact ? 10.0 : 12.0;
    final fontSize = compact ? 9.0 : 10.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 3);

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
            const SizedBox(width: 3),
            Text(
              l10n.priorityApplicationLabel,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
