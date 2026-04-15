import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/opportunity_type.dart';

/// Safe card-based selector for choosing an opportunity type.
///
/// This avoids flex-in-unbounded-height layouts so it can be embedded inside
/// scroll views without blanking the whole page at runtime.
class OpportunityTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const OpportunityTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: OpportunityType.values.map((type) {
        final isSelected = selected == type;
        final typeColor = OpportunityType.color(type);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != OpportunityType.values.last ? 10 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? typeColor.withValues(alpha: 0.10)
                        : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? typeColor : colors.border,
                      width: isSelected ? 1.6 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: typeColor.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? typeColor.withValues(alpha: 0.16)
                                  : colors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              OpportunityType.icon(type),
                              color: isSelected ? typeColor : colors.textMuted,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: typeColor,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        OpportunityType.label(type),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? typeColor : colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        OpportunityType.subtitle(type),
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          height: 1.35,
                          color: isSelected
                              ? typeColor.withValues(alpha: 0.82)
                              : colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
