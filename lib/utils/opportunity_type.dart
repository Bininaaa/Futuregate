import 'package:flutter/material.dart';

/// Centralized definitions for opportunity types used across the app.
///
/// Backward compatibility: older Firestore documents without a `type` field
/// (or with an unrecognized value) fall back to [OpportunityType.job].
class OpportunityType {
  OpportunityType._();

  // ── Type keys (stored in Firestore) ──
  static const String job = 'job';
  static const String internship = 'internship';
  static const String sponsoring = 'sponsoring';

  /// All valid type keys, in display order.
  static const List<String> values = [job, internship, sponsoring];

  // ── Colors ──
  static const Color jobColor = Color(0xFF6C63FF);
  static const Color internshipColor = Color(0xFF4DA0FF);
  static const Color sponsoringColor = Color(0xFFFF9F43);

  static Color color(String type) {
    switch (type) {
      case internship:
        return internshipColor;
      case sponsoring:
        return sponsoringColor;
      case job:
      default:
        return jobColor;
    }
  }

  // ── Icons ──
  static IconData icon(String type) {
    switch (type) {
      case internship:
        return Icons.school_outlined;
      case sponsoring:
        return Icons.campaign_outlined;
      case job:
      default:
        return Icons.work_outline;
    }
  }

  // ── Display labels ──
  static String label(String type) {
    switch (type) {
      case internship:
        return 'Internship';
      case sponsoring:
        return 'Sponsoring';
      case job:
      default:
        return 'Job';
    }
  }

  // ── Short helper text (used in selectors) ──
  static String subtitle(String type) {
    switch (type) {
      case internship:
        return 'Learning & work experience';
      case sponsoring:
        return 'Sponsored support programs';
      case job:
      default:
        return 'Full-time & part-time work';
    }
  }

  /// Safely parse a Firestore value to a known type key.
  /// Returns [job] for null, empty, or unrecognized values.
  static String parse(String? raw) {
    if (raw == null || raw.isEmpty) return job;
    final normalized = raw.trim().toLowerCase();
    if (values.contains(normalized)) return normalized;
    return job;
  }
}
