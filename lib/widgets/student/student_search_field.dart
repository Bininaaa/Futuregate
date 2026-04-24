import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/opportunity_dashboard_palette.dart';

class StudentSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final IconData prefixIcon;

  const StudentSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.prefixIcon = Icons.search_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasValue = controller.text.trim().isNotEmpty;
    final clearAction =
        onClear ??
        () {
          controller.clear();
          onChanged?.call('');
        };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.product(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: OpportunityDashboardPalette.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: false,
          hintText: hintText,
          hintStyle: AppTypography.product(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: OpportunityDashboardPalette.textSecondary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 46,
            minHeight: 48,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: OpportunityDashboardPalette.textSecondary,
            size: 20,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 46,
            minHeight: 48,
          ),
          suffixIcon: hasValue
              ? IconButton(
                  tooltip: AppLocalizations.of(context)!.uiClearSearch,
                  onPressed: clearAction,
                  icon: Icon(
                    Icons.close_rounded,
                    color: OpportunityDashboardPalette.textSecondary,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: colors.isDarkMode
              ? colors.surfaceElevated.withValues(alpha: 0.94)
              : colors.surface.withValues(alpha: 0.96),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.95),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.95),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: OpportunityDashboardPalette.primary.withValues(
                alpha: 0.32,
              ),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
