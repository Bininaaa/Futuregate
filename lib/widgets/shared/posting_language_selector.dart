import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../utils/content_language.dart';

class PostingLanguageSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final Color activeColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final double labelFontSize;
  final double optionFontSize;

  const PostingLanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    this.labelFontSize = 12.5,
    this.optionFontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedValue = ContentLanguage.normalizeCode(
      value,
      fallback: ContentLanguage.english,
    );
    final selectedCode =
        ContentLanguage.supportedCodes.contains(normalizedValue)
        ? normalizedValue
        : ContentLanguage.supportedCodes.first;
    final remainingCodes = ContentLanguage.supportedCodes
        .where((code) => code != selectedCode)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.translate_rounded, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.postingLanguageLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildLanguageChip(context, l10n, selectedCode),
          ],
        ),
        if (remainingCodes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: remainingCodes
                .map((code) => _buildLanguageChip(context, l10n, code))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageChip(
    BuildContext context,
    AppLocalizations l10n,
    String code,
  ) {
    final selected = ContentLanguage.normalizeCode(value) == code;
    final label = ContentLanguage.label(code, l10n);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(code),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 46, minWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? activeColor : borderColor,
                width: selected ? 1.3 : 1,
              ),
            ),
            child: Text(
              '${ContentLanguage.flag(code)} $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: optionFontSize,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
