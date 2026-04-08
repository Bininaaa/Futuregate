import 'package:flutter/material.dart';

import '../../models/project_idea_model.dart';
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: InnovationHubPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: InnovationHubPalette.border),
            boxShadow: InnovationHubPalette.softShadow(0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      innovationCategoryIcon(idea.displayCategory),
                      color: categoryColor,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  ?trailingAction,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                idea.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: InnovationHubTypography.section(size: 14),
              ),
              const SizedBox(height: 4),
              Text(
                idea.cardSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: InnovationHubTypography.body(size: 12),
              ),
              const SizedBox(height: 10),
              _MiniBadge(
                label: idea.displayStage,
                color: innovationStageColor(idea.displayStage),
              ),
              if (showStatus) ...[
                const SizedBox(height: 6),
                _MiniBadge(
                  label: idea.statusLabel,
                  color: innovationStatusColor(idea.status),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 14,
                    color: InnovationHubPalette.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${idea.interestedCount}',
                    style: InnovationHubTypography.label(
                      color: InnovationHubPalette.textSecondary,
                      size: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IdeaListCard extends StatelessWidget {
  final ProjectIdeaModel idea;
  final VoidCallback onTap;
  final Widget? trailingAction;

  const IdeaListCard({
    super.key,
    required this.idea,
    required this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = innovationCategoryColor(idea.displayCategory);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: InnovationHubPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: InnovationHubPalette.border),
            boxShadow: InnovationHubPalette.softShadow(0.04),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InnovationHubTypography.section(size: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.cardSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: InnovationHubTypography.body(size: 12.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniBadge(
                          label: idea.displayStage,
                          color: innovationStageColor(idea.displayStage),
                        ),
                        const SizedBox(width: 6),
                        _MiniBadge(
                          label: idea.statusLabel,
                          color: innovationStatusColor(idea.status),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: InnovationHubPalette.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.interestedCount}',
                          style: InnovationHubTypography.label(
                            color: InnovationHubPalette.textSecondary,
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 8),
                trailingAction!,
              ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InnovationHubTypography.section(size: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      idea.lastUpdatedLabel,
                      style: InnovationHubTypography.body(size: 12),
                    ),
                  ],
                ),
              ),
              _MiniBadge(
                label: idea.statusLabel,
                color: innovationStatusColor(idea.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            idea.cardSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: InnovationHubTypography.body(size: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniBadge(
                label: idea.displayStage,
                color: innovationStageColor(idea.displayStage),
              ),
              const SizedBox(width: 6),
              _MiniBadge(label: idea.displayCategory, color: categoryColor),
              const Spacer(),
              Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: InnovationHubPalette.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${idea.interestedCount}',
                style: InnovationHubTypography.label(
                  color: InnovationHubPalette.textSecondary,
                  size: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionChipButton(
                  label: 'View',
                  onTap: onView,
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChipButton(label: 'Edit', onTap: onEdit),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChipButton(label: 'Team', onTap: onManageTeam),
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: onTap == null
                ? backgroundColor.withValues(alpha: 0.5)
                : backgroundColor,
            borderRadius: BorderRadius.circular(12),
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

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(color: color, size: 10.5),
      ),
    );
  }
}
