import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../utils/localized_display.dart';

class ChatFormatters {
  static final DateFormat _fallbackClockFormat = DateFormat('h:mma');
  static final DateFormat _monthShortFormat = DateFormat('MMM d');
  static final DateFormat _monthDayFormat = DateFormat('MMMM d');
  static final DateFormat _metaDateFormat = DateFormat('MMM d');

  static String inboxTimestamp(Timestamp? timestamp, {BuildContext? context}) {
    if (timestamp == null) {
      return '';
    }

    final now = DateTime.now();
    final date = timestamp.toDate();
    final l10n = context == null ? null : AppLocalizations.of(context);

    if (_isSameDay(now, date)) {
      return _clockLabel(context, date);
    }

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (_isSameDay(yesterday, date)) {
      return _caseLabel(context, l10n?.uiYesterday ?? 'YESTERDAY');
    }

    if (context != null) {
      return LocalizedDisplay.shortDate(
        context,
        date,
        includeYear: now.year != date.year,
      );
    }

    return now.year == date.year
        ? _monthShortFormat.format(date).toUpperCase()
        : _metaDateFormat.format(date).toUpperCase();
  }

  static String messageTime(Timestamp? timestamp, {BuildContext? context}) {
    if (timestamp == null) {
      return '';
    }

    return _clockLabel(context, timestamp.toDate());
  }

  static String dayDividerLabel(DateTime date, {BuildContext? context}) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final l10n = context == null ? null : AppLocalizations.of(context);

    if (_isSameDay(now, date)) {
      final label = l10n?.uiToday ?? 'TODAY';
      final dateLabel = context == null
          ? _monthDayFormat.format(date).toUpperCase()
          : LocalizedDisplay.longMonthDay(context, date);
      return '${_caseLabel(context, label)}, $dateLabel';
    }

    if (_isSameDay(yesterday, date)) {
      final label = l10n?.uiYesterday ?? 'YESTERDAY';
      final dateLabel = context == null
          ? _monthDayFormat.format(date).toUpperCase()
          : LocalizedDisplay.longMonthDay(context, date);
      return '${_caseLabel(context, label)}, $dateLabel';
    }

    return context == null
        ? _monthDayFormat.format(date).toUpperCase()
        : LocalizedDisplay.longMonthDay(context, date);
  }

  static String presenceLabel(
    Timestamp? lastSeenAt, {
    required bool isOnline,
    BuildContext? context,
  }) {
    if (isOnline) {
      return _caseLabel(
        context,
        _byLocale(context, ar: 'متصل', fr: 'En ligne', en: 'ONLINE'),
      );
    }

    if (lastSeenAt == null) {
      return _caseLabel(
        context,
        _byLocale(context, ar: 'غير متصل', fr: 'Hors ligne', en: 'OFFLINE'),
      );
    }

    final seenDate = lastSeenAt.toDate();
    final now = DateTime.now();
    final difference = now.difference(seenDate);
    final l10n = context == null ? null : AppLocalizations.of(context);

    if (difference.inMinutes < 1) {
      return _caseLabel(
        context,
        _byLocale(
          context,
          ar: 'نشط الآن',
          fr: 'Actif maintenant',
          en: 'ACTIVE NOW',
        ),
      );
    }
    if (difference.inMinutes < 60) {
      if (l10n != null) {
        return _lastSeen(
          context,
          l10n.studentMinutesAgoCompact(difference.inMinutes),
        );
      }
      return 'LAST SEEN ${difference.inMinutes}M AGO';
    }
    if (difference.inHours < 24) {
      if (l10n != null) {
        return _lastSeen(
          context,
          l10n.studentHoursAgoCompact(difference.inHours),
        );
      }
      return 'LAST SEEN ${difference.inHours}H AGO';
    }

    if (context != null) {
      return _lastSeen(context, LocalizedDisplay.shortDate(context, seenDate));
    }
    return 'LAST SEEN ${_metaDateFormat.format(seenDate).toUpperCase()}';
  }

  static String fileSizeLabel(int bytes) {
    if (bytes <= 0) {
      return '';
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }

    final decimals = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  static bool isSameMessageDay(Timestamp? left, Timestamp? right) {
    if (left == null || right == null) {
      return false;
    }

    return _isSameDay(left.toDate(), right.toDate());
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _clockLabel(BuildContext? context, DateTime date) {
    final localeName = context == null
        ? null
        : AppLocalizations.of(context)?.localeName;
    final formatter = localeName == null
        ? _fallbackClockFormat
        : DateFormat('h:mma', localeName);
    return formatter.format(date).replaceAll(' ', '').toUpperCase();
  }

  static String _lastSeen(BuildContext? context, String value) {
    return _byLocale(
      context,
      ar: 'آخر ظهور $value',
      fr: 'Vu $value',
      en: 'LAST SEEN ${value.toUpperCase()}',
    );
  }

  static String _caseLabel(BuildContext? context, String value) {
    if (context != null && LocalizedDisplay.isArabic(context)) {
      return value;
    }
    return value.toUpperCase();
  }

  static String _byLocale(
    BuildContext? context, {
    required String ar,
    required String fr,
    required String en,
  }) {
    if (context != null && LocalizedDisplay.isArabic(context)) {
      return ar;
    }
    if (context != null && LocalizedDisplay.isFrench(context)) {
      return fr;
    }
    return en;
  }
}
