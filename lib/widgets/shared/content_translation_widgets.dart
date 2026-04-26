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
