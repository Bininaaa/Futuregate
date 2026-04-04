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
        final tone = iconColor ?? AdminPalette.accent;
        final surfaceBase = backgroundColor ?? AdminPalette.surface;
        final cardPadding = isVeryCompact ? 10.0 : (isCompact ? 11.0 : 12.0);
        final iconPadding = isVeryCompact ? 6.0 : (isCompact ? 7.0 : 8.0);
        final iconSize = isVeryCompact ? 15.0 : (isCompact ? 16.0 : 17.0);
        final valueFontSize = isVeryCompact ? 18.0 : (isCompact ? 19.0 : 20.5);
        final titleFontSize = isVeryCompact ? 10.6 : (isCompact ? 11.3 : 12.0);
        final cardRadius = BorderRadius.circular(22);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surfaceBase,
                Color.lerp(surfaceBase, tone, isCompact ? 0.10 : 0.14)!,
              ],
            ),
            borderRadius: cardRadius,
            border: Border.all(color: tone.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -18,
                  child: IgnorePointer(
                    child: Container(
                      width: isCompact ? 64 : 74,
                      height: isCompact ? 64 : 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tone.withValues(alpha: 0.20),
                            tone.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tone.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(icon, size: iconSize, color: tone),
                      ),
                      SizedBox(width: isCompact ? 8 : 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              softWrap: true,
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                color: AdminPalette.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: isVeryCompact ? 7 : 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        value,
                                        style: GoogleFonts.poppins(
                                          fontSize: valueFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: AdminPalette.textPrimary,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isCompact ? 8 : 10),
                                Container(
                                  width: isCompact ? 22 : 26,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: [
                                        tone,
                                        tone.withValues(alpha: 0.22),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
