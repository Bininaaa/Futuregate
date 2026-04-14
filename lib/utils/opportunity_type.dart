import 'package:flutter/material.dart';

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

  // Display labels
  static String label(String type) {
    switch (parse(type)) {
      case internship:
        return 'Internship';
      case sponsoring:
        return 'Sponsored';
      case job:
      default:
        return 'Job';
    }
  }

  static String lowercaseLabel(String type) {
    switch (parse(type)) {
      case internship:
        return 'internship';
      case sponsoring:
        return 'sponsored';
      case job:
      default:
        return 'job';
    }
  }

  static String headline(String type) {
    switch (parse(type)) {
      case internship:
        return 'Bring in future talent';
      case sponsoring:
        return 'Support students with a premium sponsored program';
      case job:
      default:
        return 'Hire for a real role';
    }
  }

  // Short helper text used in selectors.
  static String subtitle(String type) {
    switch (parse(type)) {
      case internship:
        return 'Learning & work experience';
      case sponsoring:
        return 'Premium funded & partner programs';
      case job:
      default:
        return 'Full-time & part-time work';
    }
  }

  static String descriptionLabel(String type) {
    switch (parse(type)) {
      case sponsoring:
        return 'Program description';
      case internship:
      case job:
      default:
        return 'Role description';
    }
  }

  static String descriptionHint(String type) {
    switch (parse(type)) {
      case sponsoring:
        return 'Describe the sponsoring program, support offered, and who it is for...';
      case internship:
        return 'Describe the internship scope, learning goals, and responsibilities...';
      case job:
      default:
        return 'Describe the role, team, and responsibilities...';
    }
  }

  static String requirementsLabel(String type) {
    switch (parse(type)) {
      case sponsoring:
        return 'Eligibility';
      case internship:
      case job:
      default:
        return 'Requirements';
    }
  }

  static String requirementsHint(String type) {
    switch (parse(type)) {
      case sponsoring:
        return 'Share eligibility criteria, documents, or expectations...';
      case internship:
        return 'Share preferred skills, academic background, or tools...';
      case job:
      default:
        return 'Share the skills and qualifications needed...';
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
