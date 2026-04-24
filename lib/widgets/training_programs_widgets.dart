import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_typography.dart';

import '../utils/opportunity_dashboard_palette.dart';
import 'shared/app_feedback.dart';
import 'shared/app_loading.dart';
import 'student/student_search_field.dart';

class TrainingCourseBadgeData {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const TrainingCourseBadgeData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class TrainingCourseCardData {
  final String id;
  final String title;
  final String providerName;
  final String providerLogoUrl;
  final String imageUrl;
  final String trainingType;
  final String durationLabel;
  final String levelLabel;
  final String? ratingLabel;
  final String categoryLabel;
  final Color accentColor;
  final Color secondaryAccentColor;
  final IconData fallbackIcon;
  final List<TrainingCourseBadgeData> badges;

  const TrainingCourseCardData({
    required this.id,
    required this.title,
    required this.providerName,
    required this.providerLogoUrl,
    required this.imageUrl,
    required this.trainingType,
    required this.durationLabel,
    required this.levelLabel,
    required this.ratingLabel,
    required this.categoryLabel,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.fallbackIcon,
    required this.badges,
  });
}

class TrainingHeaderBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;

  const TrainingHeaderBar({
    super.key,
    required this.onMenuTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.menu_rounded,
          tooltip: AppLocalizations.of(context)!.uiTrainingMenu,
          onTap: onMenuTap,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.uiTrainingPrograms,
            style: AppTypography.product(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.primary,
            ),
          ),
        ),
        _HeaderIconButton(
          icon: Icons.search_rounded,
          tooltip: AppLocalizations.of(context)!.uiFocusSearch,
          onTap: onSearchTap,
        ),
      ],
    );
  }
}

class TrainingHeroIntro extends StatelessWidget {
  const TrainingHeroIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.uiBuildYourNextSkill,
          style: AppTypography.product(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(
            context,
          )!.uiCoursesBooksAndCertificationsThatSharpenYourJourney,
          style: AppTypography.product(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: OpportunityDashboardPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class TrainingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const TrainingSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return StudentSearchField(
      controller: controller,
      focusNode: focusNode,
      hintText: AppLocalizations.of(context)!.uiSearchCourses,
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}

class TrainingSectionTitle extends StatelessWidget {
  final String title;

  const TrainingSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.product(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: OpportunityDashboardPalette.textPrimary,
      ),
    );
  }
}

class TrainingInfoBanner extends StatelessWidget {
  final String message;

  const TrainingInfoBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AppInlineMessage(
      type: AppFeedbackType.info,
      message: message,
      icon: Icons.info_outline_rounded,
      accentColor: OpportunityDashboardPalette.primary,
    );
  }
}

class TrainingCourseCard extends StatelessWidget {
  final TrainingCourseCardData data;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final bool isSaved;
  final bool isSaveBusy;
  final VoidCallback? onToggleSaved;

  const TrainingCourseCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onStart,
    this.isSaved = false,
    this.isSaveBusy = false,
    this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: OpportunityDashboardPalette.textPrimary.withValues(
                  alpha: 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrainingCardImage(data: data),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: data.accentColor.withValues(alpha: 0.09),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        data.accentColor.withValues(alpha: 0.04),
                        data.secondaryAccentColor.withValues(alpha: 0.07),
                      ],
                      stops: const [0.0, 0.56, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.secondaryAccentColor.withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -16,
                        right: -8,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: data.accentColor.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -12,
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: data.secondaryAccentColor.withValues(
                              alpha: 0.06,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      TrainingProviderAvatar(
                                        providerName: data.providerName,
                                        providerLogoUrl: data.providerLogoUrl,
                                        accentColor: data.accentColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          data.providerName,
                                          style: AppTypography.product(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: OpportunityDashboardPalette
                                                .textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _TrainingInfoSticker(data: data),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 14.75,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: OpportunityDashboardPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 9,
                              runSpacing: 5,
                              children: [
                                _TrainingMetaItem(
                                  icon: Icons.schedule_rounded,
                                  label: data.durationLabel,
                                ),
                                _TrainingMetaItem(
                                  icon: Icons.bar_chart_rounded,
                                  label: data.levelLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (data.ratingLabel != null &&
                                    data.ratingLabel!.trim().isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: OpportunityDashboardPalette
                                              .warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            data.ratingLabel!,
                                            style: AppTypography.product(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: OpportunityDashboardPalette
                                                  .textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Spacer(),
                                const SizedBox(width: 8),
                                if (onToggleSaved != null) ...[
                                  _SaveTrainingButton(
                                    isSaved: isSaved,
                                    isBusy: isSaveBusy,
                                    onTap: onToggleSaved,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                _StartTrainingButton(onTap: onStart),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

class TrainingCourseListCard extends StatelessWidget {
  final TrainingCourseCardData data;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final bool isSaved;
  final bool isSaveBusy;
  final VoidCallback? onToggleSaved;

  const TrainingCourseListCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onStart,
    this.isSaved = false,
    this.isSaveBusy = false,
    this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: OpportunityDashboardPalette.textPrimary.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrainingListMedia(data: data),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              TrainingProviderAvatar(
                                providerName: data.providerName,
                                providerLogoUrl: data.providerLogoUrl,
                                accentColor: data.accentColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.providerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.product(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: OpportunityDashboardPalette
                                        .textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TrainingInfoSticker(data: data),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.product(
                        fontSize: 14.25,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _TrainingMetaItem(
                          icon: Icons.schedule_rounded,
                          label: data.durationLabel,
                        ),
                        _TrainingMetaItem(
                          icon: Icons.bar_chart_rounded,
                          label: data.levelLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (data.ratingLabel != null &&
                            data.ratingLabel!.trim().isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: OpportunityDashboardPalette.warning,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    data.ratingLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.product(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: OpportunityDashboardPalette
                                          .textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 8),
                        if (onToggleSaved != null) ...[
                          _SaveTrainingButton(
                            isSaved: isSaved,
                            isBusy: isSaveBusy,
                            onTap: onToggleSaved,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _StartTrainingButton(onTap: onStart),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TrainingLayoutView { grid, list }

class TrainingLayoutToggle extends StatelessWidget {
  final TrainingLayoutView view;
  final ValueChanged<TrainingLayoutView> onChanged;

  const TrainingLayoutToggle({
    super.key,
    required this.view,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CatalogueViewToggle(
          icon: Icons.grid_view_rounded,
          isSelected: view == TrainingLayoutView.grid,
          onTap: () => onChanged(TrainingLayoutView.grid),
        ),
        const SizedBox(width: 8),
        _CatalogueViewToggle(
          icon: Icons.view_list_rounded,
          isSelected: view == TrainingLayoutView.list,
          onTap: () => onChanged(TrainingLayoutView.list),
        ),
      ],
    );
  }
}

class TrainingCatalogueSelector extends StatelessWidget {
  final List<String> domains;
  final String selectedDomain;
  final Widget? headerTrailing;
  final ValueChanged<String> onSelected;

  const TrainingCatalogueSelector({
    super.key,
    required this.domains,
    required this.selectedDomain,
    this.headerTrailing,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.uiCatalogue,
                    style: AppTypography.product(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: OpportunityDashboardPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.uiChooseYourDomain,
                    style: AppTypography.product(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (headerTrailing != null) ...[
              const SizedBox(width: 12),
              headerTrailing!,
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: domains
              .map(
                (domain) => _TrainingCatalogueChip(
                  label: domain,
                  isSelected: domain == selectedDomain,
                  onTap: () => onSelected(domain),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class TrainingProgramsEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const TrainingProgramsEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateNotice(
      type: AppFeedbackType.neutral,
      icon: Icons.search_off_rounded,
      title: title,
      message: subtitle,
      accentColor: OpportunityDashboardPalette.primary,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
    );
  }
}

class TrainingProgramsLoadingView extends StatelessWidget {
  const TrainingProgramsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          SizedBox(height: 8),
          _HeaderSkeleton(),
          SizedBox(height: 22),
          AppSkeletonLine(widthFactor: 0.62, height: 24),
          SizedBox(height: 8),
          AppSkeletonLine(widthFactor: 0.88, height: 14),
          SizedBox(height: 6),
          AppSkeletonLine(widthFactor: 0.7, height: 14),
          SizedBox(height: 18),
          AppSkeletonBlock(height: 48, radius: 20),
          SizedBox(height: 22),
          AppSkeletonLine(widthFactor: 0.46, height: 18),
          SizedBox(height: 14),
          _TrainingCardSkeleton(),
          SizedBox(height: 14),
          _TrainingCardSkeleton(),
          SizedBox(height: 18),
          AppSkeletonBlock(height: 242, radius: 26),
        ],
      ),
    );
  }
}

class TrainingProviderAvatar extends StatelessWidget {
  final String providerName;
  final String providerLogoUrl;
  final Color accentColor;

  const TrainingProviderAvatar({
    super.key,
    required this.providerName,
    required this.providerLogoUrl,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedProvider = providerName.trim();
    final initial = trimmedProvider.isEmpty ? 'T' : trimmedProvider[0];

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: providerLogoUrl.trim().isEmpty
          ? Center(
              child: Text(
                initial.toUpperCase(),
                style: AppTypography.product(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: providerLogoUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(
                child: Text(
                  initial.toUpperCase(),
                  style: AppTypography.product(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
            ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OpportunityDashboardPalette.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TrainingListMedia extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingListMedia({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data.trainingType.trim().toLowerCase();

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.accentColor.withValues(alpha: 0.92),
            data.secondaryAccentColor.withValues(alpha: 0.88),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (data.imageUrl.trim().isNotEmpty)
            CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
          if (type == 'video')
            Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            )
          else
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.fallbackIcon, color: Colors.white, size: 15),
              ),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Text(
              data.categoryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCardImage extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingCardImage({required this.data});

  @override
  Widget build(BuildContext context) {
    final trainingType = data.trainingType.trim().toLowerCase();
    final aspectRatio = switch (trainingType) {
      'video' => 2.05,
      'book' => 1.48,
      'file' => 1.72,
      _ => 1.84,
    };

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _TrainingMediaSurface(data: data),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: trainingType == 'book' ? 0.10 : 0.22,
                    ),
                  ],
                ),
              ),
            ),
            if (data.badges.isNotEmpty)
              Positioned(
                top: 9,
                left: 9,
                right: 9,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: data.badges
                      .map((badge) => _TrainingImageBadge(badge: badge))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrainingMediaSurface extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingMediaSurface({required this.data});

  @override
  Widget build(BuildContext context) {
    return switch (data.trainingType.trim().toLowerCase()) {
      'video' => _TrainingVideoVisual(data: data),
      'book' => _TrainingBookVisual(data: data),
      'file' => _TrainingFileVisual(data: data),
      _ => _TrainingCourseVisual(data: data),
    };
  }
}

class _TrainingCourseVisual extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingCourseVisual({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _GradientMediaBackground(data: data),
        if (data.imageUrl.trim().isNotEmpty)
          CachedNetworkImage(
            imageUrl: data.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        Positioned(
          top: 18,
          right: 18,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(data.fallbackIcon, color: Colors.white, size: 22),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.categoryLabel,
                style: AppTypography.product(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                data.providerName,
                style: AppTypography.product(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainingVideoVisual extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingVideoVisual({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _GradientMediaBackground(data: data),
        if (data.imageUrl.trim().isNotEmpty)
          CachedNetworkImage(
            imageUrl: data.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        Positioned(
          left: 18,
          bottom: 18,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 20,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                data.categoryLabel,
                style: AppTypography.product(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrainingBookVisual extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingBookVisual({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.accentColor.withValues(alpha: 0.18),
                data.secondaryAccentColor.withValues(alpha: 0.26),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 28,
          bottom: 18,
          child: Center(
            child: Container(
              width: 116,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: OpportunityDashboardPalette.textPrimary.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: data.imageUrl.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: data.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          _BookCoverFallback(data: data),
                    )
                  : _BookCoverFallback(data: data),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrainingFileVisual extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingFileVisual({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.accentColor.withValues(alpha: 0.92),
                data.secondaryAccentColor.withValues(alpha: 0.88),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 18,
          right: 18,
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(data.fallbackIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.categoryLabel,
                    style: AppTypography.product(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientMediaBackground extends StatelessWidget {
  final TrainingCourseCardData data;

  const _GradientMediaBackground({required this.data});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.accentColor.withValues(alpha: 0.92),
            data.secondaryAccentColor.withValues(alpha: 0.90),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -12,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -26,
            left: -16,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCoverFallback extends StatelessWidget {
  final TrainingCourseCardData data;

  const _BookCoverFallback({required this.data});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.accentColor, data.secondaryAccentColor],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.fallbackIcon, color: Colors.white, size: 24),
            const Spacer(),
            Text(
              data.categoryLabel,
              style: AppTypography.product(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              data.providerName,
              style: AppTypography.product(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingImageBadge extends StatelessWidget {
  final TrainingCourseBadgeData badge;

  const _TrainingImageBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badge.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badge.label,
        style: AppTypography.product(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: badge.foregroundColor,
        ),
      ),
    );
  }
}

class _TrainingInfoSticker extends StatelessWidget {
  final TrainingCourseCardData data;

  const _TrainingInfoSticker({required this.data});

  _TrainingStickerData _stickerData(AppLocalizations l10n) {
    switch (data.trainingType.trim().toLowerCase()) {
      case 'video':
        return _TrainingStickerData(
          label: l10n.uiVideo.toUpperCase(),
          icon: Icons.play_circle_fill_rounded,
        );
      case 'book':
        return _TrainingStickerData(
          label: l10n.uiBook.toUpperCase(),
          icon: Icons.auto_stories_rounded,
        );
      case 'file':
        return _TrainingStickerData(
          label: l10n.uiGuide.toUpperCase(),
          icon: Icons.description_rounded,
        );
      case 'course':
        return _TrainingStickerData(
          label: l10n.uiCourse.toUpperCase(),
          icon: Icons.cast_for_education_rounded,
        );
      default:
        return _TrainingStickerData(
          label: l10n.uiTrain.toUpperCase(),
          icon: Icons.school_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sticker = _stickerData(AppLocalizations.of(context)!);

    return Transform.rotate(
      angle: -0.045,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [data.accentColor, data.secondaryAccentColor],
          ),
          boxShadow: [
            BoxShadow(
              color: data.secondaryAccentColor.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sticker.icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              sticker.label,
              style: AppTypography.product(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.35,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingCatalogueChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrainingCatalogueChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizedLabel = switch (label.trim()) {
      'All' => AppLocalizations.of(context)!.uiAll,
      'General' => AppLocalizations.of(context)!.trainingGeneralDomainLabel,
      _ => label,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? OpportunityDashboardPalette.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? OpportunityDashboardPalette.primary
                  : OpportunityDashboardPalette.border,
            ),
          ),
          child: Text(
            localizedLabel,
            textAlign: TextAlign.center,
            style: AppTypography.product(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? OpportunityDashboardPalette.primary
                  : OpportunityDashboardPalette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatalogueViewToggle({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected
                ? OpportunityDashboardPalette.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? OpportunityDashboardPalette.primary
                  : OpportunityDashboardPalette.border,
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected
                ? OpportunityDashboardPalette.primary
                : OpportunityDashboardPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TrainingMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrainingMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: OpportunityDashboardPalette.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.product(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: OpportunityDashboardPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StartTrainingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartTrainingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            AppLocalizations.of(context)!.uiStart,
            style: AppTypography.product(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveTrainingButton extends StatelessWidget {
  final bool isSaved;
  final bool isBusy;
  final VoidCallback? onTap;

  const _SaveTrainingButton({
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 38,
          height: 34,
          decoration: BoxDecoration(
            color: isSaved
                ? OpportunityDashboardPalette.accent.withValues(alpha: 0.14)
                : OpportunityDashboardPalette.background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color:
                  (isSaved
                          ? OpportunityDashboardPalette.accent
                          : OpportunityDashboardPalette.border)
                      .withValues(alpha: 0.9),
            ),
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OpportunityDashboardPalette.primary,
                    ),
                  )
                : Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 18,
                    color: isSaved
                        ? OpportunityDashboardPalette.accent
                        : OpportunityDashboardPalette.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        AppSkeletonBlock(width: 42, height: 42, radius: 16),
        SizedBox(width: 12),
        Expanded(child: AppSkeletonLine(widthFactor: 1, height: 20)),
        SizedBox(width: 12),
        AppSkeletonBlock(width: 42, height: 42, radius: 16),
      ],
    );
  }
}

class _TrainingCardSkeleton extends StatelessWidget {
  const _TrainingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonBlock(height: 314, radius: 24);
  }
}

class _TrainingStickerData {
  final String label;
  final IconData icon;

  const _TrainingStickerData({required this.label, required this.icon});
}
