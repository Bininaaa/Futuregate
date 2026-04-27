import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';

class ReviewerCvHeader extends StatelessWidget {
  final String name;
  final List<String> details;
  final Color accentColor;
  final IconData icon;

  const ReviewerCvHeader({
    super.key,
    required this.name,
    required this.details,
    required this.accentColor,
    this.icon = Icons.description_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final visibleDetails = details
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? 'Applicant' : name.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.16,
                  ),
                ),
                if (visibleDetails.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleDetails
                        .map(
                          (detail) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 11.6,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewerCvDocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final String viewLabel;
  final String downloadLabel;
  final String? warningText;

  const ReviewerCvDocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.viewLabel,
    required this.downloadLabel,
    this.onView,
    this.onDownload,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = onView != null || onDownload != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 19,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.product(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: AppTypography.product(
                        fontSize: 12.2,
                        height: 1.48,
                        color: AdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warningText != null && warningText!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: AdminPalette.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AdminPalette.warning.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                warningText!,
                style: AppTypography.product(
                  fontSize: 11.8,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AdminPalette.warning,
                ),
              ),
            ),
          ],
          if (hasActions) ...[
            const SizedBox(height: 12),
            _ReviewerActionGroup(
              children: [
                if (onView != null)
                  FilledButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(viewLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                if (onDownload != null)
                  OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(downloadLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(
                        color: accentColor.withValues(alpha: 0.24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewerActionGroup extends StatelessWidget {
  final List<Widget> children;

  const _ReviewerActionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}
