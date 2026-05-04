import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import '../utils/application_status.dart';

class ApplicationStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool pendingPremium;

  const ApplicationStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.pendingPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPendingPremium =
        pendingPremium &&
        ApplicationStatus.parse(status) == ApplicationStatus.pending;
    final badgeColor = isPendingPremium
        ? AppColors.of(context).activity
        : ApplicationStatus.color(status);
    final label = isPendingPremium
        ? '${ApplicationStatus.label(status, l10n)} ${l10n.premiumBadgeLabel}'
        : ApplicationStatus.label(status, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.product(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}
