import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/generated/app_localizations.dart';
import '../utils/application_status.dart';

class ApplicationStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const ApplicationStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badgeColor = ApplicationStatus.color(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        ApplicationStatus.label(status, l10n),
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}
