import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import 'admin_content_center_screen.dart';

class AdminActivityCenterScreen extends StatefulWidget {
  final bool embedded;

  const AdminActivityCenterScreen({super.key, this.embedded = false});

  @override
  State<AdminActivityCenterScreen> createState() =>
      _AdminActivityCenterScreenState();
}

class _AdminActivityCenterScreenState extends State<AdminActivityCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

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
    final activities = provider.recentActivity
        .where((activity) => activity.matchesQuery(_searchController.text))
        .toList();

    final pendingCount = activities
        .where((activity) => activity.status == 'pending')
        .length;
    final applicationCount = activities
        .where((activity) => activity.type == 'application')
        .length;
    final opportunityCount = activities
        .where((activity) => activity.type == 'opportunity')
        .length;

    final content = provider.activityLoading && provider.recentActivity.isEmpty
        ? const Center(
            child: CircularProgressIndicator(color: AdminPalette.primary),
          )
        : provider.activityError != null && provider.recentActivity.isEmpty
        ? AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Activity could not be loaded',
            message: provider.activityError!,
            action: FilledButton(
              onPressed: () => provider.loadActivityFeed(reset: true),
              child: const Text('Retry'),
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
                          const AdminSectionHeader(
                            eyebrow: 'Live Feed',
                            title: 'Recent Platform Activity',
                            subtitle:
                                'Browse the latest moderation and publishing events, then jump straight into the matching admin queue.',
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              AdminPill(
                                label: '${activities.length} visible events',
                                color: AdminPalette.primary,
                                icon: Icons.bolt_rounded,
                              ),
                              AdminPill(
                                label: '$pendingCount pending',
                                color: AdminPalette.warning,
                                icon: Icons.hourglass_top_rounded,
                              ),
                              AdminPill(
                                label: '$applicationCount applications',
                                color: AdminPalette.activity,
                                icon: Icons.assignment_outlined,
                              ),
                              AdminPill(
                                label: '$opportunityCount opportunities',
                                color: AdminPalette.accent,
                                icon: Icons.work_outline_rounded,
                              ),
                            ],
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
                      hintText: 'Search by type, title, actor, or status...',
                      onChanged: (_) => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),
                if (activities.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AdminEmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'No activity matches this search',
                      message:
                          'Try a broader query or refresh to load the latest events.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == activities.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: OutlinedButton(
                              onPressed: provider.activityLoadingMore
                                  ? null
                                  : provider.loadMoreActivityFeed,
                              child: Text(
                                provider.activityLoadingMore
                                    ? 'Loading...'
                                    : 'Load More',
                              ),
                            ),
                          );
                        }

                        final activity = activities[index];
                        return _ActivityTile(
                          activity: activity,
                          onOpen: () => _openActivity(activity),
                        );
                      }, childCount: activities.length + 1),
                    ),
                  ),
              ],
            ),
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: AppBar(
        title: const Text('Recent Activity'),
        backgroundColor: Colors.white,
        foregroundColor: AdminPalette.textPrimary,
      ),
      body: SafeArea(child: content),
    );
  }

  Future<void> _openActivity(AdminActivityModel activity) {
    final target = switch (activity.type) {
      'application' => AdminContentCenterScreen.opportunitiesTab,
      'opportunity' => AdminContentCenterScreen.opportunitiesTab,
      'scholarship' => AdminContentCenterScreen.scholarshipsTab,
      'training' => AdminContentCenterScreen.trainingsTab,
      _ => AdminContentCenterScreen.projectIdeasTab,
    };

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminContentCenterScreen(
          initialTab: target,
          initialTargetId: activity.relatedId,
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AdminActivityModel activity;
  final VoidCallback onOpen;

  const _ActivityTile({required this.activity, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final accentColor = _colorForType(activity.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminSurface(
        radius: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconForType(activity.type), color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AdminPalette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metaChip(
                        activity.type.replaceAll('_', ' '),
                        accentColor,
                      ),
                      if (activity.actorName.trim().isNotEmpty)
                        _metaChip(activity.actorName, AdminPalette.info),
                      if (activity.status.trim().isNotEmpty)
                        _metaChip(
                          activity.status,
                          _statusColor(activity.status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activity.createdAt == null
                        ? 'Unknown time'
                        : DateFormat(
                            'MMM d, yyyy - HH:mm',
                          ).format(activity.createdAt!.toDate()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open'),
              style: FilledButton.styleFrom(
                foregroundColor: AdminPalette.primary,
                backgroundColor: AdminPalette.primarySoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _metaChip(String label, Color color) {
    return AdminPill(label: label, color: color);
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'application':
        return Icons.assignment_outlined;
      case 'opportunity':
        return Icons.work_outline;
      case 'scholarship':
        return Icons.card_giftcard;
      case 'training':
        return Icons.cast_for_education_outlined;
      default:
        return Icons.lightbulb_outline;
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
    switch (status) {
      case 'approved':
      case 'accepted':
      case 'open':
        return AdminPalette.success;
      case 'rejected':
        return AdminPalette.danger;
      default:
        return AdminPalette.warning;
    }
  }
}
