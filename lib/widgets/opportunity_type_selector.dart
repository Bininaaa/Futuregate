import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Column(
      children: [
        _buildTypeCard(
          context: context,
          l10n: l10n,
          colors: colors,
          type: OpportunityType.job,
          wide: true,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTypeCard(
                context: context,
                l10n: l10n,
                colors: colors,
                type: OpportunityType.internship,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTypeCard(
                context: context,
                l10n: l10n,
                colors: colors,
                type: OpportunityType.sponsoring,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required AppColors colors,
    required String type,
    bool wide = false,
  }) {
    final isSelected = selected == type;
    final typeColor = OpportunityType.color(type);
    const cardRadius = 18.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: BoxConstraints(minHeight: wide ? 92 : 132),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? typeColor.withValues(alpha: 0.10)
                : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: isSelected ? typeColor : colors.border,
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: typeColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: wide
              ? _buildWideContent(l10n, colors, type, typeColor, isSelected)
              : _buildCompactContent(l10n, colors, type, typeColor, isSelected),
        ),
      ),
    );
  }

  Widget _buildWideContent(
    AppLocalizations l10n,
    AppColors colors,
    String type,
    Color typeColor,
    bool isSelected,
  ) {
    return Row(
      children: [
        _buildIcon(type, colors, typeColor, isSelected),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextBlock(l10n, colors, type, typeColor, isSelected),
        ),
        if (isSelected) ...[const SizedBox(width: 10), _buildCheck(typeColor)],
      ],
    );
  }

  Widget _buildCompactContent(
    AppLocalizations l10n,
    AppColors colors,
    String type,
    Color typeColor,
    bool isSelected,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildIcon(type, colors, typeColor, isSelected),
            const Spacer(),
            if (isSelected) _buildCheck(typeColor),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextBlock(
          l10n,
          colors,
          type,
          typeColor,
          isSelected,
          centered: true,
        ),
      ],
    );
  }

  Widget _buildTextBlock(
    AppLocalizations l10n,
    AppColors colors,
    String type,
    Color typeColor,
    bool isSelected, {
    bool centered = false,
  }) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          OpportunityType.label(type, l10n),
          style: GoogleFonts.poppins(
            fontSize: 12.6,
            fontWeight: FontWeight.w700,
            color: isSelected ? typeColor : colors.textSecondary,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          OpportunityType.subtitle(type, l10n),
          style: GoogleFonts.poppins(
            fontSize: 10.4,
            height: 1.35,
            color: isSelected
                ? typeColor.withValues(alpha: 0.82)
                : colors.textMuted,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildIcon(
    String type,
    AppColors colors,
    Color typeColor,
    bool isSelected,
  ) {
    return Container(
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
    );
  }

  Widget _buildCheck(Color typeColor) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }
}
