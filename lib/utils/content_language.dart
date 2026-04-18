import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

class ContentLanguage {
  const ContentLanguage._();

  static const String english = 'en';
  static const String french = 'fr';
  static const String arabic = 'ar';

  static const List<String> supportedCodes = <String>[
    english,
    french,
    arabic,
  ];

  static String normalizeCode(String? value, {String fallback = ''}) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return fallback;
    }

    if (normalized.startsWith('ar')) {
      return arabic;
    }
    if (normalized.startsWith('fr')) {
      return french;
    }
    if (normalized.startsWith('en')) {
      return english;
    }

    if (supportedCodes.contains(normalized)) {
      return normalized;
    }

    return fallback;
  }

  static bool isSupported(String? value) => supportedCodes.contains(
    normalizeCode(value),
  );

  static bool isArabicCode(String? value) => normalizeCode(value) == arabic;

  static String englishName(String? value) {
    return switch (normalizeCode(value, fallback: english)) {
      french => 'French',
      arabic => 'Arabic',
      _ => 'English',
    };
  }

  static String localizedName(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    return switch (normalizeCode(value, fallback: english)) {
      french => l10n.languageFrench,
      arabic => l10n.languageArabic,
      _ => l10n.languageEnglish,
    };
  }

  static String flag(String? value) {
    return switch (normalizeCode(value, fallback: english)) {
      french => 'FR',
      arabic => 'AR',
      _ => 'EN',
    };
  }

  static String label(String? value, AppLocalizations l10n) {
    return switch (normalizeCode(value, fallback: english)) {
      french => l10n.languageFrench,
      arabic => l10n.languageArabic,
      _ => l10n.languageEnglish,
    };
  }

  static Locale localeFor(String? value) {
    return Locale(normalizeCode(value, fallback: english));
  }
}
