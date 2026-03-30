import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/opportunity_type.dart';

/// A polished selector with icon-based cards for choosing an opportunity type.
/// Each option shows an icon, label, and short subtitle.
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
    return Row(
      children: OpportunityType.values.map((type) {
        final isSelected = selected == type;
        final typeColor = OpportunityType.color(type);

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: type != OpportunityType.values.last ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.10)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? typeColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? typeColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      OpportunityType.icon(type),
                      color: isSelected ? typeColor : Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    OpportunityType.label(type),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? typeColor : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    OpportunityType.subtitle(type),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: isSelected
                          ? typeColor.withValues(alpha: 0.7)
                          : Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
