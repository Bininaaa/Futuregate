import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
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
  static const String withdrawn = 'withdrawn';

  static const List<String> values = [pending, accepted, rejected, withdrawn];

  static String parse(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    switch (normalized) {
      case accepted:
      case 'approved':
        return accepted;
      case rejected:
        return rejected;
      case withdrawn:
        return withdrawn;
      case pending:
      default:
        return pending;
    }
  }

  static String label(String? raw, AppLocalizations l10n) {
    switch (parse(raw)) {
      case accepted:
        return l10n.uiApproved;
      case rejected:
        return l10n.uiRejected;
      case withdrawn:
        return 'Withdrawn';
      case pending:
      default:
        return l10n.uiPending;
    }
  }

  static String sentenceLabel(String? raw, AppLocalizations l10n) {
    switch (parse(raw)) {
      case accepted:
        return l10n.applicationStatusApprovedSentence;
      case rejected:
        return l10n.applicationStatusRejectedSentence;
      case withdrawn:
        return 'You withdrew this application.';
      case pending:
      default:
        return l10n.applicationStatusPendingSentence;
    }
  }

  static Color color(String? raw) {
    switch (parse(raw)) {
      case accepted:
        return AppColors.current.success;
      case rejected:
        return AppColors.current.danger;
      case withdrawn:
        return const Color(0xFF64748B);
      case pending:
      default:
        return AppColors.current.warning;
    }
  }

  static bool isNotifiable(String? raw) {
    final s = parse(raw);
    return s != pending && s != withdrawn;
  }

  static bool shouldNotifyTransition(String? previous, String? next) {
    final normalizedPrevious = parse(previous);
    final normalizedNext = parse(next);

    return normalizedPrevious != normalizedNext && isNotifiable(normalizedNext);
  }
}
