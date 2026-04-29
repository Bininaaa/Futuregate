import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';

abstract final class LocalizedDisplay {
  static const List<String> _arabicMonths = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static bool isArabic(BuildContext context) {
    return _localeName(context).startsWith('ar');
  }

  static bool isFrench(BuildContext context) {
    return _localeName(context).startsWith('fr');
  }

  static String shortDate(
    BuildContext context,
    DateTime value, {
    bool includeYear = false,
  }) {
    final date = value.toLocal();
    final localeName = _localeName(context);

    if (localeName.startsWith('ar')) {
      final month = _arabicMonths[date.month - 1];
      return includeYear
          ? '${date.day} $month ${date.year}'
          : '${date.day} $month';
    }

    final formatter = includeYear
        ? DateFormat.yMMMd(localeName)
        : DateFormat.MMMd(localeName);
    return formatter.format(date);
  }

  static String longMonthDay(BuildContext context, DateTime value) {
    final date = value.toLocal();
    final localeName = _localeName(context);

    if (localeName.startsWith('ar')) {
      return '${date.day} ${_arabicMonths[date.month - 1]}';
    }

    return DateFormat.MMMMd(localeName).format(date);
  }

  static String dateText(
    BuildContext context,
    String raw, {
    bool includeYear = true,
  }) {
    final value = raw.trim();
    if (value.isEmpty) {
      return value;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return shortDate(context, parsed, includeYear: includeYear);
    }

    return value;
  }

  static String metadataLabel(BuildContext context, String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return '';
    }

    final durationLabel = duration(context, value);
    if (durationLabel != value) {
      return durationLabel;
    }

    final l10n = AppLocalizations.of(context)!;
    final normalized = _normalize(value);

    switch (normalized) {
      case 'full time':
      case 'fulltime':
        return l10n.employmentTypeFullTime;
      case 'part time':
      case 'parttime':
        return l10n.employmentTypePartTime;
      case 'internship':
        return l10n.employmentTypeInternship;
      case 'contract':
        return l10n.employmentTypeContract;
      case 'temporary':
        return l10n.employmentTypeTemporary;
      case 'freelance':
        return l10n.employmentTypeFreelance;
      case 'on site':
      case 'onsite':
        return l10n.workModeOnsite;
      case 'remote':
        return l10n.workModeRemote;
      case 'hybrid':
        return l10n.workModeHybrid;
      case 'paid':
        return l10n.paidLabel;
      case 'unpaid':
        return l10n.unpaidLabel;
      case 'fully funded':
      case 'full funded':
      case 'full funding':
        return l10n.uiFullyFunded;
      case 'partial':
      case 'partial funding':
      case 'partially funded':
        return l10n.studentPartiallyFunded;
      case 'merit':
      case 'merit based':
        return l10n.studentMeritBased;
      case 'master':
      case 'masters':
        return l10n.academicLevelMaster;
      case 'phd':
      case 'doctorate':
      case 'doctoral':
        return l10n.uiDoctorate;
      case 'open':
        return _byLocale(context, ar: 'مفتوحة', fr: 'Ouvert', en: 'Open');
      case 'machine learning':
        return _byLocale(
          context,
          ar: 'تعلم الآلة',
          fr: 'Apprentissage automatique',
          en: value,
        );
      case 'artificial intelligence':
      case 'intelligence artificielle':
      case "l'intelligence artificielle":
        return _byLocale(
          context,
          ar: 'الذكاء الاصطناعي',
          fr: 'Intelligence artificielle',
          en: value,
        );
      case 'europe':
        return _byLocale(context, ar: 'أوروبا', fr: 'Europe', en: value);
      case 'asia':
        return _byLocale(context, ar: 'آسيا', fr: 'Asie', en: value);
      case 'france':
        return _byLocale(context, ar: 'فرنسا', fr: 'France', en: value);
      case 'paris':
        return _byLocale(context, ar: 'باريس', fr: 'Paris', en: value);
      case 'paris france':
        return _byLocale(
          context,
          ar: 'باريس، فرنسا',
          fr: 'Paris, France',
          en: value,
        );
      case 'algeria':
      case 'algerie':
      case 'algérie':
        return _byLocale(context, ar: 'الجزائر', fr: 'Algérie', en: 'Algeria');
      case 'general':
        return l10n.trainingGeneralDomainLabel;
      case 'design':
        return _byLocale(context, ar: 'تصميم', fr: 'Design', en: 'Design');
      case 'marketing':
        return _byLocale(context, ar: 'تسويق', fr: 'Marketing', en: 'Marketing');
      case 'strategy':
        return _byLocale(
          context,
          ar: 'استراتيجية',
          fr: 'Stratégie',
          en: 'Strategy',
        );
      case 'engineering':
        return _byLocale(
          context,
          ar: 'هندسة',
          fr: 'Ingénierie',
          en: 'Engineering',
        );
      case 'finance':
        return _byLocale(context, ar: 'مالية', fr: 'Finance', en: 'Finance');
      case 'research':
        return _byLocale(context, ar: 'بحث', fr: 'Recherche', en: 'Research');
      case 'business':
        return _byLocale(
          context,
          ar: 'أعمال',
          fr: 'Affaires',
          en: 'Business',
        );
      case 'technology':
      case 'tech':
        return _byLocale(
          context,
          ar: 'تكنولوجيا',
          fr: 'Technologie',
          en: 'Technology',
        );
      case 'entry level':
      case 'entry':
        return _byLocale(
          context,
          ar: 'مستوى مبتدئ',
          fr: 'Débutant',
          en: 'Entry level',
        );
      case 'junior':
        return _byLocale(context, ar: 'مبتدئ', fr: 'Junior', en: 'Junior');
      case 'mid level':
      case 'mid':
        return _byLocale(
          context,
          ar: 'مستوى متوسط',
          fr: 'Intermédiaire',
          en: 'Mid-level',
        );
      case 'senior':
        return _byLocale(context, ar: 'متقدم', fr: 'Senior', en: 'Senior');
      case 'graduate':
      case 'grad':
        return _byLocale(context, ar: 'خريج', fr: 'Diplômé', en: 'Graduate');
      case 'student':
        return _byLocale(context, ar: 'طالب', fr: 'Étudiant', en: 'Student');
    }

    return value;
  }

  static String employmentType(BuildContext context, String? raw) {
    return metadataLabel(context, raw);
  }

  static String workMode(BuildContext context, String? raw) {
    return metadataLabel(context, raw);
  }

  static String duration(BuildContext context, String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return '';
    }

    final leading = RegExp(
      r'^(\d+)\s*(?:months?|mois)$',
      caseSensitive: false,
    ).firstMatch(value);
    final trailing = RegExp(
      r'^(?:months?|mois)\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(value);
    final match = leading ?? trailing;
    if (match == null) {
      return value;
    }

    final count = int.tryParse(match.group(1) ?? '');
    if (count == null) {
      return value;
    }

    return monthCount(context, count);
  }

  static String monthCount(BuildContext context, int count) {
    if (isArabic(context)) {
      if (count == 1) {
        return 'شهر واحد';
      }
      if (count == 2) {
        return 'شهران';
      }
      if (count >= 3 && count <= 10) {
        return '$count أشهر';
      }
      return '$count شهرًا';
    }

    if (isFrench(context)) {
      return '$count mois';
    }

    return count == 1 ? '1 month' : '$count months';
  }

  static String compensation(BuildContext context, String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return value;
    }

    if (isArabic(context)) {
      return value
          .replaceAll(RegExp(r'/\s*months?', caseSensitive: false), '/ شهر')
          .replaceAll(RegExp(r'\bmonths?\b', caseSensitive: false), 'شهر');
    }

    if (isFrench(context)) {
      return value
          .replaceAll(RegExp(r'/\s*months?', caseSensitive: false), '/ mois')
          .replaceAll(RegExp(r'\bmonths?\b', caseSensitive: false), 'mois');
    }

    return value;
  }

  static String _localeName(BuildContext context) {
    return AppLocalizations.of(context)?.localeName ??
        Localizations.localeOf(context).toLanguageTag();
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[_\-/]+'), ' ')
        .replaceAll(RegExp(r'[,\u060C]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _byLocale(
    BuildContext context, {
    required String ar,
    required String fr,
    required String en,
  }) {
    if (isArabic(context)) {
      return ar;
    }
    if (isFrench(context)) {
      return fr;
    }
    return en;
  }
}
