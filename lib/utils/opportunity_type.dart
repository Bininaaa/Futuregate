import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// Centralized definitions for opportunity types used across the app.
///
/// Backward compatibility: older Firestore documents without a `type` field
/// (or with an unrecognized value) fall back to [OpportunityType.job].
class OpportunityType {
  OpportunityType._();

  // Type keys stored in Firestore.
  static const String job = 'job';
  static const String internship = 'internship';
  static const String sponsoring = 'sponsoring';

  /// All valid type keys, in display order.
  static const List<String> values = [job, internship, sponsoring];

  // Colors
  static Color get jobColor => AppColors.current.primary;
  static Color get internshipColor => AppColors.current.secondary;
  static Color get sponsoringColor => AppColors.current.accent;

  static Color color(String type) {
    switch (parse(type)) {
      case internship:
        return internshipColor;
      case sponsoring:
        return sponsoringColor;
      case job:
      default:
        return jobColor;
    }
  }

  static Color softBackground(String type) {
    switch (parse(type)) {
      case internship:
        return AppColors.current.secondarySoft;
      case sponsoring:
        return AppColors.current.accentSoft;
      case job:
      default:
        return AppColors.current.primarySoft;
    }
  }

  static Color softAccent(String type, {double opacity = 0.14}) {
    return color(type).withValues(alpha: opacity);
  }

  static Color softBorder(String type, {double opacity = 0.22}) {
    return color(type).withValues(alpha: opacity);
  }

  // Icons
  static IconData icon(String type) {
    switch (parse(type)) {
      case internship:
        return Icons.school_outlined;
      case sponsoring:
        return Icons.workspace_premium_outlined;
      case job:
      default:
        return Icons.work_outline;
    }
  }

  // ── Localized display labels (require AppLocalizations) ─────────────────

  static String label(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case internship:
        return l10n.opportunityTypeInternship;
      case sponsoring:
        return l10n.opportunityTypeSponsored;
      case job:
      default:
        return l10n.opportunityTypeJob;
    }
  }

  static String lowercaseLabel(String type, AppLocalizations l10n) =>
      label(type, l10n).toLowerCase();

  static String headline(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case internship:
        return l10n.opportunityHeadlineInternship;
      case sponsoring:
        return l10n.opportunityHeadlineSponsoring;
      case job:
      default:
        return l10n.opportunityHeadlineJob;
    }
  }

  static String subtitle(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case internship:
        return l10n.opportunitySubtitleInternship;
      case sponsoring:
        return l10n.opportunitySubtitleSponsoring;
      case job:
      default:
        return l10n.opportunitySubtitleJob;
    }
  }

  static String descriptionLabel(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case sponsoring:
        return l10n.opportunityDescriptionLabelSponsoring;
      case internship:
      case job:
      default:
        return l10n.roleDescriptionLabel;
    }
  }

  static String descriptionHint(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case sponsoring:
        return l10n.opportunityDescriptionHintSponsoring;
      case internship:
        return l10n.opportunityDescriptionHintInternship;
      case job:
      default:
        return l10n.opportunityDescriptionHintJob;
    }
  }

  static String requirementsLabel(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case sponsoring:
        return l10n.opportunityRequirementsLabelSponsoring;
      case internship:
      case job:
      default:
        return l10n.opportunityRequirementsLabelJob;
    }
  }

  static String requirementsHint(String type, AppLocalizations l10n) {
    switch (parse(type)) {
      case sponsoring:
        return l10n.opportunityRequirementsHintSponsoring;
      case internship:
        return l10n.opportunityRequirementsHintInternship;
      case job:
      default:
        return l10n.opportunityRequirementsHintJob;
    }
  }

  static bool isSponsoring(String? raw) => parse(raw) == sponsoring;

  static bool supportsStudentPostNotification(String? raw) => isSponsoring(raw);

  /// Safely parse a Firestore value to a known type key.
  /// Returns [job] for null, empty, or unrecognized values.
  static String parse(String? raw) {
    if (raw == null || raw.isEmpty) return job;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'sponsored' || normalized == 'sponsorship') {
      return sponsoring;
    }
    if (values.contains(normalized)) return normalized;
    return job;
  }
}
