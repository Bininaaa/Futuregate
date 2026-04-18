import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../utils/content_language.dart';

class ContentTranslationBadge extends StatelessWidget {
  final bool showingTranslated;
  final String originalLanguage;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;

  const ContentTranslationBadge({
    super.key,
    required this.showingTranslated,
    required this.originalLanguage,
    required this.foregroundColor,
    required this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedLanguage = ContentLanguage.normalizeCode(originalLanguage);
    if (normalizedLanguage.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final languageLabel = ContentLanguage.localizedName(context, normalizedLanguage);
    final label = showingTranslated
        ? '${l10n.translatedFromLabel} $languageLabel'
        : '${l10n.originalLanguageLabel}: $languageLabel';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10.6,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class ContentTranslationBanner extends StatelessWidget {
  final bool isTranslating;
  final bool hasTranslation;
  final bool showingTranslated;
  final String originalLanguage;
  final VoidCallback onToggle;
  final Color accentColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;

  const ContentTranslationBanner({
    super.key,
    required this.isTranslating,
    required this.hasTranslation,
    required this.showingTranslated,
    required this.originalLanguage,
    required this.onToggle,
    required this.accentColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedLanguage = ContentLanguage.normalizeCode(originalLanguage);
    final languageLabel = normalizedLanguage.isEmpty
        ? ''
        : ContentLanguage.localizedName(context, normalizedLanguage);

    final title = isTranslating
        ? l10n.translatingLabel
        : showingTranslated
        ? '${l10n.translatedFromLabel} $languageLabel'
        : '${l10n.originalLanguageLabel}: $languageLabel';
    final subtitle = isTranslating
        ? l10n.translationNote
        : showingTranslated
        ? l10n.viewingTranslatedVersionLabel
        : l10n.viewingOriginalVersionLabel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.translate_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (hasTranslation && !isTranslating)
            TextButton(
              onPressed: onToggle,
              child: Text(
                showingTranslated
                    ? l10n.showOriginalLabel
                    : l10n.showTranslatedLabel,
              ),
            ),
        ],
      ),
    );
  }
}
