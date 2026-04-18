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

    return Row(
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
        const SizedBox(width: 10),
        ...ContentLanguage.supportedCodes.map((code) {
          final selected = value == code;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? activeColor : borderColor,
                  ),
                ),
                child: Text(
                  '${ContentLanguage.flag(code)} ${ContentLanguage.label(code, l10n)}',
                  style: TextStyle(
                    fontSize: optionFontSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? activeColor : textColor,
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
