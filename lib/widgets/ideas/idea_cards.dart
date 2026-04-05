import 'package:flutter/material.dart';

import '../../models/project_idea_model.dart';
import 'idea_metrics_row.dart';
import 'innovation_hub_theme.dart';

class IdeaCard extends StatelessWidget {
  final ProjectIdeaModel idea;
  final VoidCallback onTap;
  final bool showStatus;
  final Widget? trailingAction;

  const IdeaCard({
    super.key,
    required this.idea,
    required this.onTap,
    this.showStatus = false,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = innovationCategoryColor(idea.displayCategory);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: InnovationHubPalette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: InnovationHubPalette.border),
            boxShadow: InnovationHubPalette.softShadow(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      innovationCategoryIcon(idea.displayCategory),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (trailingAction != null) ...[
                    trailingAction!,
                    const SizedBox(width: 8),
                  ],
                  _MiniBadge(
                    label: idea.displayStage,
                    color: innovationStageColor(idea.displayStage),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                idea.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: InnovationHubTypography.section(size: 17),
              ),
              const SizedBox(height: 8),
              Text(
                idea.cardSummary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: InnovationHubTypography.body(size: 13.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagChip(label: idea.displayCategory, color: categoryColor),
                  ...idea.cardTags
                      .take(1)
                      .map(
                        (tag) => _TagChip(
                          label: tag,
                          color: InnovationHubPalette.secondary,
                        ),
                      ),
                ],
              ),
              if (showStatus) ...[
                const SizedBox(height: 10),
                _MiniBadge(
                  label: idea.statusLabel,
                  color: innovationStatusColor(idea.status),
                ),
              ],
              const SizedBox(height: 14),
              IdeaMetricsRow(
                sparksCount: idea.sparksCount,
                interestedCount: idea.interestedCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturedIdeaCard extends StatelessWidget {
  final ProjectIdeaModel idea;
  final VoidCallback onTap;
  final Widget? trailingAction;

  const FeaturedIdeaCard({
    super.key,
    required this.idea,
    required this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: InnovationHubPalette.featuredGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: InnovationHubPalette.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      innovationCategoryIcon(idea.displayCategory),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (trailingAction != null) ...[
                    trailingAction!,
                    const SizedBox(width: 8),
                  ],
                  _GlassBadge(label: 'Featured'),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GlassBadge(label: idea.displayCategory),
                  _GlassBadge(label: idea.displayStage),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                idea.title,
                style: InnovationHubTypography.title(
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                idea.featuredSummary,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: InnovationHubTypography.body(
                  color: Colors.white.withValues(alpha: 0.86),
                  size: 14.5,
                ),
              ),
              const SizedBox(height: 16),
              IdeaMetricsRow(
                sparksCount: idea.sparksCount,
                interestedCount: idea.interestedCount,
                inverted: true,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Project',
                          style: InnovationHubTypography.label(
                            color: InnovationHubPalette.primary,
                            size: 12.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: InnovationHubPalette.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IdeaWorkspaceCard extends StatelessWidget {
  final ProjectIdeaModel idea;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback onManageTeam;

  const IdeaWorkspaceCard({
    super.key,
    required this.idea,
    required this.onView,
    required this.onManageTeam,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = innovationCategoryColor(idea.displayCategory);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: InnovationHubTypography.section(size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.lastUpdatedLabel,
                      style: InnovationHubTypography.body(size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: idea.displayCategory, color: categoryColor),
              _MiniBadge(
                label: idea.displayStage,
                color: innovationStageColor(idea.displayStage),
              ),
              _MiniBadge(
                label: idea.statusLabel,
                color: innovationStatusColor(idea.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            idea.cardSummary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: InnovationHubTypography.body(),
          ),
          const SizedBox(height: 14),
          IdeaMetricsRow(
            sparksCount: idea.sparksCount,
            interestedCount: idea.interestedCount,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionChipButton(
                  label: 'View',
                  onTap: onView,
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChipButton(label: 'Edit', onTap: onEdit),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChipButton(
                  label: 'Manage Team',
                  onTap: onManageTeam,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionChipButton({
    required this.label,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled
        ? InnovationHubPalette.primary
        : InnovationHubPalette.cardTint;
    final foregroundColor = filled
        ? Colors.white
        : InnovationHubPalette.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: onTap == null
                ? backgroundColor.withValues(alpha: 0.5)
                : backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: InnovationHubPalette.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: InnovationHubTypography.label(
              color: onTap == null
                  ? foregroundColor.withValues(alpha: 0.5)
                  : foregroundColor,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(color: color, size: 11.5),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(color: color, size: 11),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String label;

  const _GlassBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(color: Colors.white, size: 11.5),
      ),
    );
  }
}
