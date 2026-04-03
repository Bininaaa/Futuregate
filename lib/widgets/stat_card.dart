import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/admin_palette.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final isVeryCompact = constraints.maxWidth < 150;
        final cardPadding = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
        final iconPadding = isVeryCompact ? 7.0 : (isCompact ? 8.0 : 9.0);
        final iconSize = isVeryCompact ? 16.0 : 18.0;
        final valueFontSize = isVeryCompact ? 16.0 : (isCompact ? 18.0 : 20.0);
        final titleFontSize = isVeryCompact ? 10.0 : 11.0;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AdminPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AdminPalette.border.withValues(alpha: 0.92),
            ),
            boxShadow: AdminPalette.softShadow,
          ),
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: (iconColor ?? AdminPalette.accent).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? AdminPalette.accent,
                ),
              ),
              SizedBox(height: isCompact ? 8 : 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  color: AdminPalette.textMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
