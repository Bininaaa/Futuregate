import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatFormatters {
  static final DateFormat _clockFormat = DateFormat('h:mma');
  static final DateFormat _monthShortFormat = DateFormat('MMM d');
  static final DateFormat _monthDayFormat = DateFormat('MMMM d');
  static final DateFormat _metaDateFormat = DateFormat('MMM d');

  static String inboxTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final now = DateTime.now();
    final date = timestamp.toDate();

    if (_isSameDay(now, date)) {
      return _clockFormat.format(date).replaceAll(' ', '').toUpperCase();
    }

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (_isSameDay(yesterday, date)) {
      return 'YESTERDAY';
    }

    if (now.year == date.year) {
      return _monthShortFormat.format(date).toUpperCase();
    }

    return _metaDateFormat.format(date).toUpperCase();
  }

  static String messageTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    return _clockFormat
        .format(timestamp.toDate())
        .replaceAll(' ', '')
        .toUpperCase();
  }

  static String dayDividerLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(now, date)) {
      return 'TODAY, ${_monthDayFormat.format(date).toUpperCase()}';
    }

    if (_isSameDay(yesterday, date)) {
      return 'YESTERDAY, ${_monthDayFormat.format(date).toUpperCase()}';
    }

    return _monthDayFormat.format(date).toUpperCase();
  }

  static String presenceLabel(Timestamp? lastSeenAt, {required bool isOnline}) {
    if (isOnline) {
      return 'ONLINE';
    }

    if (lastSeenAt == null) {
      return 'OFFLINE';
    }

    final seenDate = lastSeenAt.toDate();
    final now = DateTime.now();
    final difference = now.difference(seenDate);

    if (difference.inMinutes < 1) {
      return 'ACTIVE NOW';
    }
    if (difference.inMinutes < 60) {
      return 'LAST SEEN ${difference.inMinutes}M AGO';
    }
    if (difference.inHours < 24) {
      return 'LAST SEEN ${difference.inHours}H AGO';
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
}
