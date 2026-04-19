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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              l10n.postingLanguageLabel,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        ...ContentLanguage.supportedCodes.map((code) {
          final selected = value == code;
          final label = ContentLanguage.label(code, l10n);
          return Semantics(
            button: true,
            selected: selected,
            label: label,
            child: GestureDetector(
              onTap: () => onChanged(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? activeColor : borderColor,
                  ),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    '${ContentLanguage.flag(code)} $label',
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
        }),
      ],
    );
  }
}
