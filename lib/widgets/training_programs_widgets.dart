import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/opportunity_dashboard_palette.dart';

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
  final bool isPlaceholder;

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
    required this.isPlaceholder,
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
          tooltip: 'Training menu',
          onTap: onMenuTap,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Training Programs',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.primary,
            ),
          ),
        ),
        _HeaderIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Focus search',
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
          'Training Programs',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Build skills and grow your career with curated learning paths.',
          style: GoogleFonts.poppins(
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
  final VoidCallback? onClear;

  const TrainingSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: OpportunityDashboardPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search for courses...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: OpportunityDashboardPalette.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: OpportunityDashboardPalette.textSecondary,
          size: 20,
        ),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: OpportunityDashboardPalette.textSecondary,
                  size: 18,
                ),
              ),
        filled: true,
        fillColor: OpportunityDashboardPalette.primary.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: OpportunityDashboardPalette.primary.withValues(alpha: 0.18),
          ),
        ),
      ),
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
      style: GoogleFonts.poppins(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OpportunityDashboardPalette.warning.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: OpportunityDashboardPalette.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: OpportunityDashboardPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingCourseCard extends StatelessWidget {
  final TrainingCourseCardData data;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const TrainingCourseCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onStart,
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
                                          style: GoogleFonts.poppins(
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
                              style: GoogleFonts.poppins(
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
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: OpportunityDashboardPalette
                                              .warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            data.ratingLabel!,
                                            style: GoogleFonts.poppins(
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

  const TrainingCourseListCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onStart,
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
                                  style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
                                const Icon(
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
                                    style: GoogleFonts.poppins(
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

class BrowseMoreTopicsCard extends StatelessWidget {
  const BrowseMoreTopicsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: OpportunityDashboardPalette.border,
        radius: 26,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Text(
              'Browse More Topics',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: OpportunityDashboardPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore 500+ other professional certifications',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.55,
                color: OpportunityDashboardPalette.textSecondary,
              ),
            ),
          ],
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
  final ValueChanged<String> onSelected;

  const TrainingCatalogueSelector({
    super.key,
    required this.domains,
    required this.selectedDomain,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catalogue',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your domain',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: OpportunityDashboardPalette.textSecondary,
          ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: OpportunityDashboardPalette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: OpportunityDashboardPalette.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.55,
              color: OpportunityDashboardPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingProgramsLoadingView extends StatelessWidget {
  const TrainingProgramsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: const [
        SizedBox(height: 8),
        _HeaderSkeleton(),
        SizedBox(height: 22),
        _SkeletonLine(widthFactor: 0.62, height: 24),
        SizedBox(height: 8),
        _SkeletonLine(widthFactor: 0.88, height: 14),
        SizedBox(height: 6),
        _SkeletonLine(widthFactor: 0.7, height: 14),
        SizedBox(height: 18),
        _SkeletonBlock(height: 48, radius: 20),
        SizedBox(height: 22),
        _SkeletonLine(widthFactor: 0.46, height: 18),
        SizedBox(height: 14),
        _TrainingCardSkeleton(),
        SizedBox(height: 14),
        _TrainingCardSkeleton(),
        SizedBox(height: 18),
        _SkeletonBlock(height: 242, radius: 26),
      ],
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
                style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(
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

  _TrainingStickerData _stickerData() {
    switch (data.trainingType.trim().toLowerCase()) {
      case 'video':
        return const _TrainingStickerData(
          label: 'VIDEO',
          icon: Icons.play_circle_fill_rounded,
        );
      case 'book':
        return const _TrainingStickerData(
          label: 'BOOK',
          icon: Icons.auto_stories_rounded,
        );
      case 'file':
        return const _TrainingStickerData(
          label: 'GUIDE',
          icon: Icons.description_rounded,
        );
      case 'course':
        return const _TrainingStickerData(
          label: 'COURSE',
          icon: Icons.cast_for_education_rounded,
        );
      default:
        return const _TrainingStickerData(
          label: 'TRAIN',
          icon: Icons.school_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sticker = _stickerData();

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
              style: GoogleFonts.poppins(
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
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
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
          style: GoogleFonts.poppins(
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
            'Start',
            style: GoogleFonts.poppins(
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

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(paint.strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 8, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SkeletonBlock(width: 42, height: 42, radius: 16),
        SizedBox(width: 12),
        Expanded(child: _SkeletonLine(widthFactor: 1, height: 20)),
        SizedBox(width: 12),
        _SkeletonBlock(width: 42, height: 42, radius: 16),
      ],
    );
  }
}

class _TrainingCardSkeleton extends StatelessWidget {
  const _TrainingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return _SkeletonBlock(height: 314, radius: 24);
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({required this.widthFactor, required this.height});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: _SkeletonBlock(height: height, radius: height / 2),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
    );
  }
}

class _TrainingStickerData {
  final String label;
  final IconData icon;

  const _TrainingStickerData({required this.label, required this.icon});
}
