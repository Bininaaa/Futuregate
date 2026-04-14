import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centralized application status helpers.
///
/// Storage stays backward compatible with the existing Firestore values:
/// `pending`, `accepted`, and `rejected`.
/// The UI intentionally presents `accepted` as "Approved".
class ApplicationStatus {
  ApplicationStatus._();

  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';

  static const List<String> values = [pending, accepted, rejected];

  static String parse(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    switch (normalized) {
      case accepted:
      case 'approved':
        return accepted;
      case rejected:
        return rejected;
      case pending:
      default:
        return pending;
    }
  }

  static String label(String? raw) {
    switch (parse(raw)) {
      case accepted:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case pending:
      default:
        return 'Pending';
    }
  }

  static String sentenceLabel(String? raw) {
    switch (parse(raw)) {
      case accepted:
        return 'approved';
      case rejected:
        return 'rejected';
      case pending:
      default:
        return 'pending';
    }
  }

  static Color color(String? raw) {
    switch (parse(raw)) {
      case accepted:
        return AppColors.current.success;
      case rejected:
        return AppColors.current.danger;
      case pending:
      default:
        return AppColors.current.warning;
    }
  }

  static bool isNotifiable(String? raw) => parse(raw) != pending;

  static bool shouldNotifyTransition(String? previous, String? next) {
    final normalizedPrevious = parse(previous);
    final normalizedNext = parse(next);

    return normalizedPrevious != normalizedNext && isNotifiable(normalizedNext);
  }
}
