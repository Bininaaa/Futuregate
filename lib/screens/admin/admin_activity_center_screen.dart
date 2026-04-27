import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
import '../../widgets/admin/admin_activity_preview_sheet.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/shared/app_loading.dart';
import 'admin_content_center_screen.dart';

class AdminActivityCenterScreen extends StatefulWidget {
  final bool embedded;
  final void Function(int tab, {String targetId})? onOpenContent;

  const AdminActivityCenterScreen({
    super.key,
    this.embedded = false,
    this.onOpenContent,
  });

  @override
  State<AdminActivityCenterScreen> createState() =>
      _AdminActivityCenterScreenState();
}

class _AdminActivityCenterScreenState extends State<AdminActivityCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ActivitySectionFilter _sectionFilter = _ActivitySectionFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadActivityFeed(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim();
    final activities = provider.recentActivity
        .where((activity) => activity.matchesQuery(query))
        .where(_matchesSectionFilter)
        .toList();

    final content = provider.activityLoading && provider.recentActivity.isEmpty
        ? const AppLoadingView(density: AppLoadingDensity.compact)
        : provider.activityError != null && provider.recentActivity.isEmpty
        ? AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: l10n.uiActivityFeedUnavailable,
            message: provider.activityError!,
            action: FilledButton(
              onPressed: () => provider.loadActivityFeed(reset: true),
              child: Text(l10n.retryLabel),
            ),
          )
        : RefreshIndicator(
            color: AdminPalette.primary,
            onRefresh: () => provider.loadActivityFeed(reset: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminSectionHeader(
                            eyebrow: l10n.uiLiveFeed,
                            title: l10n.uiRecentPlatformActivity,
                            subtitle: l10n
                                .uiReviewTheLatestModerationUpdatesPublishingChangesAndSubmissionsFrom,
                            trailing: IconButton(
                              tooltip: l10n.uiRefreshActivityFeed,
                              onPressed: provider.activityLoading
                                  ? null
                                  : () =>
                                        provider.loadActivityFeed(reset: true),
                              style: IconButton.styleFrom(
                                foregroundColor: AdminPalette.primary,
                                backgroundColor: AdminPalette.primarySoft,
                                disabledForegroundColor: AdminPalette.textMuted,
                                disabledBackgroundColor:
                                    AdminPalette.surfaceMuted,
                              ),
                              icon: provider.activityLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AdminSearchField(
                      controller: _searchController,
                      hintText: l10n.uiSearchByTypeTitleActorOrStatus,
                      onChanged: (_) => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _ActivitySectionChips(
                      selected: _sectionFilter,
                      activities: provider.recentActivity,
                      onChanged: (filter) =>
                          setState(() => _sectionFilter = filter),
                    ),
                  ),
                ),
                if (activities.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AdminPalette.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.timeline_rounded,
                              size: 16,
                              color: AdminPalette.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            query.isEmpty
                                ? l10n.uiRecentActivitiesCount(
                                    activities.length,
                                  )
                                : l10n.uiMatchingActivitiesCount(
                                    activities.length,
                                  ),
                            style: AppTypography.product(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            l10n.uiNewestFirst,
                            style: AppTypography.product(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AdminPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (activities.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AdminEmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: l10n.uiNoActivityMatchesThisSearch,
                      message: l10n.uiTryABroaderQueryOrRefreshToLoadTheLatest,
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final activity = activities[index];
                        return _ActivityTile(
                          activity: activity,
                          onOpen: () => _openActivity(activity),
                        );
                      }, childCount: activities.length),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                      child: _ActivityFeedFooter(provider: provider),
                    ),
                  ),
                ],
              ],
            ),
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.uiRecentActivity),
        backgroundColor: AdminPalette.surface,
        foregroundColor: AdminPalette.textPrimary,
      ),
      body: AdminShellBackground(child: SafeArea(top: false, child: content)),
    );
  }

  bool _matchesSectionFilter(AdminActivityModel activity) {
    switch (_sectionFilter) {
      case _ActivitySectionFilter.all:
        return true;
      case _ActivitySectionFilter.reviews:
        return activity.type == 'application' ||
            activity.status.trim().toLowerCase() == 'pending';
      case _ActivitySectionFilter.content:
        return activity.type == 'opportunity' ||
            activity.type == 'scholarship' ||
            activity.type == 'project_idea';
      case _ActivitySectionFilter.library:
        return activity.type == 'training';
      case _ActivitySectionFilter.pending:
        return activity.status.trim().toLowerCase() == 'pending';
    }
  }

  Future<void> _openActivity(AdminActivityModel activity) {
    final target = switch (activity.type) {
      'application' => AdminContentCenterScreen.opportunitiesTab,
      'opportunity' => AdminContentCenterScreen.opportunitiesTab,
      'scholarship' => AdminContentCenterScreen.scholarshipsTab,
      'training' => AdminContentCenterScreen.libraryTab,
      _ => AdminContentCenterScreen.projectIdeasTab,
    };

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AdminActivityPreviewSheet(
        activity: activity,
        manageLabel: _manageLabelForActivity(activity),
        onManage: () => _openContent(target, targetId: activity.relatedId),
      ),
    );
  }

  void _openContent(int tab, {String targetId = ''}) {
    if (widget.onOpenContent != null) {
      widget.onOpenContent!(tab, targetId: targetId);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminContentCenterScreen(
          initialTab: tab,
          initialTargetId: targetId,
        ),
      ),
    );
  }

  String _manageLabelForActivity(AdminActivityModel activity) {
    final l10n = AppLocalizations.of(context)!;
    return switch (activity.type) {
      'application' => l10n.uiManageApplication,
      'opportunity' => l10n.uiManageOpportunity,
      'scholarship' => l10n.uiManageScholarship,
      'training' => l10n.uiManageLibraryResource,
      _ => l10n.uiManageProjectIdea,
    };
  }
}

enum _ActivitySectionFilter { all, reviews, content, library, pending }

class _ActivitySectionChips extends StatelessWidget {
  final _ActivitySectionFilter selected;
  final List<AdminActivityModel> activities;
  final ValueChanged<_ActivitySectionFilter> onChanged;

  const _ActivitySectionChips({
    required this.selected,
    required this.activities,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = _ActivitySectionFilter.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            AdminFilterChip(
              label: _label(filter),
              selected: selected == filter,
              icon: _icon(filter),
              badgeCount: _count(filter),
              onTap: () => onChanged(filter),
              compact: true,
            ),
            if (filter != filters.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  int _count(_ActivitySectionFilter filter) {
    return activities.where((activity) {
      switch (filter) {
        case _ActivitySectionFilter.all:
          return true;
        case _ActivitySectionFilter.reviews:
          return activity.type == 'application' ||
              activity.status.trim().toLowerCase() == 'pending';
        case _ActivitySectionFilter.content:
          return activity.type == 'opportunity' ||
              activity.type == 'scholarship' ||
              activity.type == 'project_idea';
        case _ActivitySectionFilter.library:
          return activity.type == 'training';
        case _ActivitySectionFilter.pending:
          return activity.status.trim().toLowerCase() == 'pending';
      }
    }).length;
  }

  IconData _icon(_ActivitySectionFilter filter) {
    return switch (filter) {
      _ActivitySectionFilter.all => Icons.timeline_rounded,
      _ActivitySectionFilter.reviews => Icons.rate_review_outlined,
      _ActivitySectionFilter.content => Icons.auto_awesome_mosaic_outlined,
      _ActivitySectionFilter.library => Icons.menu_book_outlined,
      _ActivitySectionFilter.pending => Icons.pending_actions_rounded,
    };
  }

  String _label(_ActivitySectionFilter filter) {
    return switch (filter) {
      _ActivitySectionFilter.all => 'All',
      _ActivitySectionFilter.reviews => 'Reviews',
      _ActivitySectionFilter.content => 'Content',
      _ActivitySectionFilter.library => 'Library',
      _ActivitySectionFilter.pending => 'Pending',
    };
  }
}

class _ActivityTile extends StatelessWidget {
  final AdminActivityModel activity;
  final VoidCallback onOpen;

  const _ActivityTile({required this.activity, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = _colorForType(activity.type);
    final typeLabel = DisplayText.capitalizeLeadingLabel(
      activity.type.replaceAll('_', ' '),
    );
    final title = DisplayText.capitalizeLeadingLabel(activity.title);
    final description = DisplayText.capitalizeLeadingLabel(
      activity.description,
    );
    final actorName = DisplayText.capitalizeLeadingLabel(
      activity.actorName.trim(),
    );
    final status = DisplayText.capitalizeLeadingLabel(activity.status.trim());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminSurface(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _iconForType(activity.type),
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ActivityHeaderLine(
                            typeLabel: typeLabel,
                            actorName: actorName,
                            color: accentColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.3,
                              color: AdminPalette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 12.5,
                                color: AdminPalette.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 10),
                      _ActivityOpenButton(
                        color: accentColor,
                        onPressed: onOpen,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (status.isNotEmpty)
                            _ActivityStatusBadge(
                              label: status,
                              color: _statusColor(activity.status),
                            ),
                          _ActivityInlineInfo(
                            icon: Icons.schedule_rounded,
                            label: _formatTimestamp(activity.createdAt, l10n),
                          ),
                        ],
                      ),
                    ),
                    if (isCompact) ...[
                      const SizedBox(width: 10),
                      _ActivityOpenButton(
                        color: accentColor,
                        onPressed: onOpen,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatTimestamp(Timestamp? createdAt, AppLocalizations l10n) {
    if (createdAt == null) {
      return l10n.uiUnknownTime;
    }

    final date = createdAt.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return l10n.uiJustNow;
    }
    if (difference.inHours < 1) {
      return l10n.uiMinutesAgoShort(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return l10n.uiHoursAgoShort(difference.inHours);
    }
    if (difference.inDays < 7) {
      return l10n.uiDaysAgoShort(difference.inDays);
    }

    return DateFormat.yMMMd(l10n.localeName).format(date);
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'application':
        return Icons.assignment_outlined;
      case 'opportunity':
        return Icons.work_outline_rounded;
      case 'scholarship':
        return Icons.card_giftcard_rounded;
      case 'training':
        return Icons.cast_for_education_outlined;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'application':
        return AdminPalette.activity;
      case 'opportunity':
        return AdminPalette.accent;
      case 'scholarship':
        return Colors.pink;
      case 'training':
        return AdminPalette.secondary;
      default:
        return Colors.amber.shade700;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'open':
      case 'featured':
        return AdminPalette.success;
      case 'rejected':
        return AdminPalette.danger;
      default:
        return AdminPalette.warning;
    }
  }
}

class _ActivityInlineInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActivityInlineInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AdminPalette.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.product(
            fontSize: 11.4,
            fontWeight: FontWeight.w600,
            color: AdminPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ActivityHeaderLine extends StatelessWidget {
  final String typeLabel;
  final String actorName;
  final Color color;

  const _ActivityHeaderLine({
    required this.typeLabel,
    required this.actorName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              typeLabel.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: 10.2,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.45,
                color: color,
              ),
            ),
          ),
        ),
        if (actorName.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              actorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: 11.3,
                fontWeight: FontWeight.w600,
                color: AdminPalette.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActivityStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ActivityStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 10.8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ActivityOpenButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  const _ActivityOpenButton({
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.uiOpenActivity,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.10),
        minimumSize: Size(compact ? 36 : 40, compact ? 36 : 40),
        padding: EdgeInsets.all(compact ? 8 : 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.arrow_outward_rounded, size: 18),
    );
  }
}

class _ActivityFeedFooter extends StatelessWidget {
  final AdminProvider provider;

  const _ActivityFeedFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!provider.activityHasMore && provider.activityError == null) {
      return Padding(
        padding: EdgeInsets.only(top: 6, bottom: 6),
        child: Center(
          child: Text(
            l10n.uiEndOfActivityFeed,
            style: AppTypography.product(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminPalette.textMuted,
            ),
          ),
        ),
      );
    }

    final isRetryState = provider.activityError != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        final button = FilledButton.tonalIcon(
          onPressed: provider.activityLoadingMore
              ? null
              : provider.loadMoreActivityFeed,
          icon: provider.activityLoadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isRetryState
                      ? Icons.refresh_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
          label: Text(
            provider.activityLoadingMore
                ? l10n.uiLoading
                : isRetryState
                ? l10n.retryLabel
                : l10n.uiOlderActivity,
          ),
          style: FilledButton.styleFrom(
            foregroundColor: AdminPalette.primary,
            backgroundColor: AdminPalette.primarySoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRetryState
                  ? l10n.uiOlderActivityUnavailable
                  : l10n.uiNeedMoreActivity,
              style: AppTypography.product(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isRetryState
                  ? provider.activityError!
                  : provider.activityLoadingMore
                  ? l10n.uiFetchingOlderUpdates
                  : l10n.uiLoadOlderUpdates,
              style: AppTypography.product(
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
                color: isRetryState
                    ? AdminPalette.danger
                    : AdminPalette.textMuted,
                height: 1.35,
              ),
            ),
          ],
        );

        return AdminSurface(
          radius: 18,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          color: AdminPalette.surfaceMuted,
          border: Border.all(color: AdminPalette.border.withValues(alpha: 0.9)),
          boxShadow: const [],
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: button),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 12),
                    button,
                  ],
                ),
        );
      },
    );
  }
}
