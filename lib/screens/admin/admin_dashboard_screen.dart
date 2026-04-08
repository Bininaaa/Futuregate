import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/admin/admin_activity_preview_sheet.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/admin_charts.dart';
import '../../widgets/opportunity_type_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/stat_card.dart';
import '../notifications_screen.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import 'admin_library_screen.dart';
import 'users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenUsers;
  final void Function(int tab, {String targetId})? onOpenContent;
  final VoidCallback? onOpenActivity;
  final VoidCallback? onOpenLibrary;

  const AdminDashboardScreen({
    super.key,
    this.onOpenUsers,
    this.onOpenContent,
    this.onOpenActivity,
    this.onOpenLibrary,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminPalette.primary),
      );
    }

    if (provider.dashboardError != null) {
      return AdminEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Dashboard unavailable',
        message: 'We could not load admin analytics right now.',
        action: FilledButton(
          onPressed: provider.loadDashboardData,
          child: const Text('Retry'),
        ),
      );
    }

    final stats = provider.stats;
    final monthlyRegistrations =
        (stats['monthlyRegistrations'] as List<dynamic>?) ?? [];
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return RefreshIndicator(
      color: AdminPalette.primary,
      onRefresh: provider.loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminHeroCard(
              title: 'Admin Control Room',
              subtitle:
                  'Review companies, content, and platform activity from one focused workspace.',
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AdminPalette.secondary,
              actions: [
                AdminActionChip(
                  label: 'Review Companies',
                  icon: Icons.verified_user_outlined,
                  onTap: _openUsers,
                ),
                AdminActionChip(
                  label: 'Review Content',
                  icon: Icons.auto_awesome_mosaic_rounded,
                  filled: true,
                  onTap: () =>
                      _openContent(AdminContentCenterScreen.projectIdeasTab),
                ),
                AdminActionChip(
                  label: 'Open Activity',
                  icon: Icons.timeline_rounded,
                  onTap: _openActivityCenter,
                ),
                AdminActionChip(
                  label: 'Library',
                  icon: Icons.menu_book_rounded,
                  onTap: _openLibrary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AdminSectionHeader(
              eyebrow: 'Snapshot',
              title: 'Platform Overview',
              subtitle:
                  'The high-level user and account picture admins usually need first.',
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(
              items: [
                _DashboardMetric(
                  title: 'Total Users',
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.people_alt_outlined,
                  color: AdminPalette.primary,
                ),
                _DashboardMetric(
                  title: 'Active Users',
                  value: '${stats['activeUsers'] ?? 0}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AdminPalette.success,
                ),
                _DashboardMetric(
                  title: 'Students',
                  value: '${stats['students'] ?? 0}',
                  icon: Icons.school_outlined,
                  color: AdminPalette.info,
                ),
                _DashboardMetric(
                  title: 'Companies',
                  value: '${stats['companies'] ?? 0}',
                  icon: Icons.business_center_outlined,
                  color: AdminPalette.secondary,
                ),
                _DashboardMetric(
                  title: 'Pending Reviews',
                  value: '${stats['pendingCompanies'] ?? 0}',
                  icon: Icons.pending_actions_rounded,
                  color: AdminPalette.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AdminSectionHeader(
              eyebrow: 'Students',
              title: 'Academic Breakdown',
              subtitle:
                  'See how the student population is distributed by level before diving into the charts.',
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(
              items: [
                _DashboardMetric(
                  title: 'Bac',
                  value: '${stats['bac'] ?? 0}',
                  icon: Icons.menu_book_outlined,
                  color: AdminPalette.accent,
                ),
                _DashboardMetric(
                  title: 'Licence',
                  value: '${stats['licence'] ?? 0}',
                  icon: Icons.import_contacts_outlined,
                  color: Colors.indigo,
                ),
                _DashboardMetric(
                  title: 'Master',
                  value: '${stats['master'] ?? 0}',
                  icon: Icons.workspace_premium_outlined,
                  color: Colors.deepPurple,
                ),
                _DashboardMetric(
                  title: 'Doctorat',
                  value: '${stats['doctorat'] ?? 0}',
                  icon: Icons.science_outlined,
                  color: AdminPalette.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            UsersByLevelBarChart(
              bacCount: (stats['bac'] ?? 0) as int,
              licenceCount: (stats['licence'] ?? 0) as int,
              masterCount: (stats['master'] ?? 0) as int,
              doctoratCount: (stats['doctorat'] ?? 0) as int,
            ),
            const SizedBox(height: 16),
            UsersRolePieChart(
              students: (stats['students'] ?? 0) as int,
              companies: (stats['companies'] ?? 0) as int,
              admins: (stats['admins'] ?? 0) as int,
            ),
            const SizedBox(height: 16),
            MonthlyRegistrationsLineChart(monthlyData: monthlyRegistrations),
            const SizedBox(height: 24),
            const AdminSectionHeader(
              eyebrow: 'Content',
              title: 'Managed Inventory',
              subtitle:
                  'A quick count of the content types handled inside the admin workspace.',
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(
              items: [
                _DashboardMetric(
                  title: 'Opportunities',
                  value: '${stats['opportunities'] ?? 0}',
                  icon: Icons.work_outline_rounded,
                  color: AdminPalette.accent,
                ),
                _DashboardMetric(
                  title: 'Applications',
                  value: '${stats['applications'] ?? 0}',
                  icon: Icons.assignment_outlined,
                  color: AdminPalette.activity,
                ),
                _DashboardMetric(
                  title: 'Scholarships',
                  value: '${stats['scholarships'] ?? 0}',
                  icon: Icons.card_giftcard_outlined,
                  color: Colors.pink,
                ),
                _DashboardMetric(
                  title: 'Trainings',
                  value: '${stats['trainings'] ?? 0}',
                  icon: Icons.cast_for_education_outlined,
                  color: AdminPalette.secondary,
                ),
                _DashboardMetric(
                  title: 'Project Ideas',
                  value: '${stats['projectIdeas'] ?? 0}',
                  icon: Icons.lightbulb_outline_rounded,
                  color: Colors.amber.shade700,
                ),
                _DashboardMetric(
                  title: 'Conversations',
                  value: '${stats['conversations'] ?? 0}',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AdminPalette.success,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AdminSectionHeader(
              eyebrow: 'Performance',
              title: 'Engagement Analytics',
              subtitle:
                  'These ratios help admins see whether users are engaging deeply or only browsing.',
            ),
            const SizedBox(height: 12),
            _InsightTile(
              icon: Icons.percent_rounded,
              iconColor: AdminPalette.info,
              title: 'Application Rate',
              value:
                  '${((stats['applicationRate'] ?? 0.0) as double).toStringAsFixed(1)} apps per opportunity',
            ),
            const SizedBox(height: 10),
            _InsightTile(
              icon: Icons.description_outlined,
              iconColor: AdminPalette.success,
              title: 'CV Completion Rate',
              value:
                  '${((stats['cvCompletionRate'] ?? 0.0) as double).toStringAsFixed(0)}% (${stats['totalCvs'] ?? 0} of ${stats['students'] ?? 0} students)',
            ),
            const SizedBox(height: 10),
            _InsightTile(
              icon: Icons.pending_actions_outlined,
              iconColor: AdminPalette.warning,
              title: 'Pending Project Ideas',
              value:
                  '${stats['pendingIdeas'] ?? 0} pending and ${stats['approvedIdeas'] ?? 0} approved',
            ),
            const SizedBox(height: 24),
            _RankedListCard(
              title: 'Most Applied Opportunities',
              icon: Icons.trending_up_rounded,
              color: AdminPalette.activity,
              items: (stats['topApplied'] as List<dynamic>?) ?? [],
              suffixLabel: 'applications',
            ),
            const SizedBox(height: 16),
            _RankedListCard(
              title: 'Most Saved Opportunities',
              icon: Icons.bookmark_outline_rounded,
              color: AdminPalette.accent,
              items: (stats['topSaved'] as List<dynamic>?) ?? [],
              suffixLabel: 'saves',
            ),
            const SizedBox(height: 24),
            const AdminSectionHeader(
              eyebrow: 'Actions',
              title: 'Quick Access',
              subtitle:
                  'Jump straight into the admin areas you open most often.',
            ),
            const SizedBox(height: 12),
            _QuickAccessGrid(
              unreadCount: unreadCount,
              onOpenContent: _openContent,
              onOpenActivity: _openActivityCenter,
              onOpenLibrary: _openLibrary,
            ),
            const SizedBox(height: 24),
            const AdminSectionHeader(
              eyebrow: 'Feed',
              title: 'Recent Activity',
              subtitle:
                  'Use the live feed to jump directly into the right moderation target.',
            ),
            const SizedBox(height: 12),
            _RecentActivityCard(
              activities: provider.recentActivity.take(6).toList(),
              onOpenActivity: _openActivityItem,
            ),
            const SizedBox(height: 16),
            _RecentUsersCard(users: provider.recentUsers.take(6).toList()),
            const SizedBox(height: 16),
            _RecentOpportunitiesCard(
              opportunities: provider.recentOpportunities.take(6).toList(),
            ),
          ],
        ),
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

  void _openActivityCenter() {
    if (widget.onOpenActivity != null) {
      widget.onOpenActivity!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminActivityCenterScreen()),
    );
  }

  void _openLibrary() {
    if (widget.onOpenLibrary != null) {
      widget.onOpenLibrary!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AdminPalette.background,
          appBar: AppBar(
            title: const Text('Resource Library'),
            backgroundColor: Colors.white,
            foregroundColor: AdminPalette.textPrimary,
          ),
          body: const SafeArea(child: AdminLibraryScreen()),
        ),
      ),
    );
  }

  void _openUsers() {
    if (widget.onOpenUsers != null) {
      widget.onOpenUsers!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AdminPalette.background,
          appBar: AppBar(
            title: const Text('User Management'),
            backgroundColor: Colors.white,
            foregroundColor: AdminPalette.textPrimary,
          ),
          body: const SafeArea(child: UsersScreen()),
        ),
      ),
    );
  }

  void _openActivityItem(AdminActivityModel activity) {
    final targetTab = switch (activity.type) {
      'application' => AdminContentCenterScreen.opportunitiesTab,
      'opportunity' => AdminContentCenterScreen.opportunitiesTab,
      'scholarship' => AdminContentCenterScreen.scholarshipsTab,
      'training' => AdminContentCenterScreen.trainingsTab,
      _ => AdminContentCenterScreen.projectIdeasTab,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AdminActivityPreviewSheet(
        activity: activity,
        manageLabel: _manageLabelForActivity(activity),
        onManage: () => _openContent(targetTab, targetId: activity.relatedId),
      ),
    );
  }

  String _manageLabelForActivity(AdminActivityModel activity) {
    return switch (activity.type) {
      'application' => 'Manage Application',
      'opportunity' => 'Manage Opportunity',
      'scholarship' => 'Manage Scholarship',
      'training' => 'Manage Training',
      _ => 'Manage Project Idea',
    };
  }
}

class _DashboardMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _DashboardMetricGrid extends StatelessWidget {
  final List<_DashboardMetric> items;

  const _DashboardMetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : constraints.maxWidth < 260
            ? 1
            : 2;
        final childAspectRatio = switch (crossAxisCount) {
          1 => 2.7,
          2 =>
            constraints.maxWidth < 360
                ? 1.72
                : constraints.maxWidth < 420
                ? 1.58
                : 1.42,
          3 => 1.28,
          _ => 1.32,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return StatCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              iconColor: item.color,
            );
          },
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 22 : 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminPalette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: isCompact ? 15 : 16,
                        fontWeight: FontWeight.bold,
                        color: AdminPalette.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RankedListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;
  final String suffixLabel;

  const _RankedListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.suffixLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'No highlights available yet',
              style: TextStyle(color: AdminPalette.textMuted),
            ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final normalizedTitle = (item['title'] ?? '')
                      .toString()
                      .trim();
                  if (normalizedTitle.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final countLabel = DisplayText.capitalizeLeadingLabel(
                    '${item['count']} $suffixLabel',
                  );
                  final badge = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      countLabel,
                      style: TextStyle(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                  final typeBadge = OpportunityTypeBadge(
                    type: (item['type'] ?? '').toString(),
                    fontSize: 10.4,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              normalizedTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [typeBadge, badge],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final int unreadCount;
  final void Function(int tab, {String targetId}) onOpenContent;
  final VoidCallback onOpenActivity;
  final VoidCallback onOpenLibrary;

  const _QuickAccessGrid({
    required this.unreadCount,
    required this.onOpenContent,
    required this.onOpenActivity,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(
        title: 'Applications',
        subtitle: 'Review offer submissions',
        icon: Icons.assignment_outlined,
        color: AdminPalette.activity,
        onTap: () => onOpenContent(AdminContentCenterScreen.opportunitiesTab),
      ),
      _QuickAccessItem(
        title: 'Opportunities',
        subtitle: 'Manage live offers',
        icon: Icons.work_outline_rounded,
        color: AdminPalette.accent,
        onTap: () => onOpenContent(AdminContentCenterScreen.opportunitiesTab),
      ),
      _QuickAccessItem(
        title: 'Scholarships',
        subtitle: 'Review funding queue',
        icon: Icons.card_giftcard_outlined,
        color: Colors.pink,
        onTap: () => onOpenContent(AdminContentCenterScreen.scholarshipsTab),
      ),
      _QuickAccessItem(
        title: 'Trainings',
        subtitle: 'Browse learning hub',
        icon: Icons.cast_for_education_outlined,
        color: AdminPalette.secondary,
        onTap: () => onOpenContent(AdminContentCenterScreen.trainingsTab),
      ),
      _QuickAccessItem(
        title: 'Project Ideas',
        subtitle: 'Moderate idea queue',
        icon: Icons.lightbulb_outline_rounded,
        color: Colors.amber.shade700,
        onTap: () => onOpenContent(AdminContentCenterScreen.projectIdeasTab),
      ),
      _QuickAccessItem(
        title: 'Activity',
        subtitle: 'Track latest events',
        icon: Icons.timeline_rounded,
        color: AdminPalette.info,
        onTap: onOpenActivity,
      ),
      _QuickAccessItem(
        title: 'Notifications',
        subtitle: unreadCount > 0
            ? '$unreadCount unread alerts'
            : 'Open alert center',
        icon: Icons.notifications_outlined,
        color: AdminPalette.primary,
        badgeCount: unreadCount,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Library',
        subtitle: 'Curate resource hub',
        icon: Icons.menu_book_rounded,
        color: AdminPalette.secondary,
        onTap: onOpenLibrary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : constraints.maxWidth < 250
            ? 1
            : 2;
        final childAspectRatio = switch (crossAxisCount) {
          1 => 2.6,
          2 => constraints.maxWidth < 420 ? 1.22 : 1.26,
          3 => 1.18,
          _ => 1.22,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(24),
                child: AdminSurface(
                  radius: 22,
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
                  child: LayoutBuilder(
                    builder: (context, itemConstraints) {
                      final isCompact = itemConstraints.maxWidth < 172;

                      return Padding(
                        padding: const EdgeInsets.all(1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isCompact ? 8 : 9),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: isCompact ? 16.5 : 18.5,
                                  ),
                                ),
                                const Spacer(),
                                if (item.badgeCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminPalette.accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item.badgeCount > 9
                                          ? '9+'
                                          : '${item.badgeCount}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AdminPalette.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 13 : 15),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 13.2 : 14.0,
                                fontWeight: FontWeight.w700,
                                color: AdminPalette.textPrimary,
                                height: 1.14,
                              ),
                            ),
                            SizedBox(height: isCompact ? 4 : 5),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 10.9 : 11.2,
                                color: AdminPalette.textSecondary,
                                height: 1.26,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAccessItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });
}

class _RecentActivityCard extends StatelessWidget {
  final List<AdminActivityModel> activities;
  final ValueChanged<AdminActivityModel> onOpenActivity;

  const _RecentActivityCard({
    required this.activities,
    required this.onOpenActivity,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: activities.isEmpty
          ? const Text(
              'No recent activity yet',
              style: TextStyle(color: AdminPalette.textMuted),
            )
          : Column(
              children: activities.asMap().entries.map((entry) {
                final activity = entry.value;
                final color = _activityColor(activity.type);
                final title = DisplayText.capitalizeLeadingLabel(
                  activity.title,
                );
                final description = DisplayText.capitalizeLeadingLabel(
                  activity.description,
                );
                final actorName = activity.actorName.trim();
                final status = DisplayText.capitalizeLeadingLabel(
                  activity.status,
                );
                final dateLabel = _formatActivityDate(activity.createdAt);

                return Column(
                  children: [
                    if (entry.key > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AdminPalette.border.withValues(alpha: 0.72),
                        ),
                      ),
                    InkWell(
                      onTap: () => onOpenActivity(activity),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Icon(
                                _activityIcon(activity.type),
                                size: 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.6,
                                      fontWeight: FontWeight.w700,
                                      color: AdminPalette.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AdminPalette.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (actorName.isNotEmpty)
                                        _ActivityMetaChip(
                                          label: actorName,
                                          color: AdminPalette.primary,
                                          icon: Icons.person_outline_rounded,
                                        ),
                                      if (status.isNotEmpty)
                                        _ActivityMetaChip(
                                          label: status,
                                          color: _activityStatusColor(
                                            activity.status,
                                          ),
                                        ),
                                      Text(
                                        dateLabel,
                                        style: const TextStyle(
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w500,
                                          color: AdminPalette.textMuted,
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
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  String _formatActivityDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown time';
    }

    final date = timestamp.toDate();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ActivityMetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _ActivityMetaChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersCard extends StatelessWidget {
  final List<dynamic> users;

  const _RecentUsersCard({required this.users});

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AdminPalette.primary),
              SizedBox(width: 8),
              Text(
                'Recent Users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            const Text(
              'No recent users yet',
              style: TextStyle(color: AdminPalette.textMuted),
            ),
          ...users.asMap().entries.map((entry) {
            final user = entry.value;
            final roleColor = _roleColor(user.role);
            final roleLabel = DisplayText.capitalizeLeadingLabel(user.role);
            final email = (user.email).toString().trim();
            final roleIcon = user.role == 'company'
                ? Icons.business_outlined
                : user.role == 'student'
                ? Icons.school_outlined
                : Icons.shield_outlined;

            return Column(
              children: [
                if (entry.key > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AdminPalette.border.withValues(alpha: 0.72),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: roleColor.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ProfileAvatar(user: user, radius: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          user.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14.2,
                                            fontWeight: FontWeight.w700,
                                            color: AdminPalette.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 6 : 8),
                                    _ActivityMetaChip(
                                      label: roleLabel,
                                      color: roleColor,
                                      icon: roleIcon,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.8,
                                    color: AdminPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RecentOpportunitiesCard extends StatelessWidget {
  final List<Map<String, dynamic>> opportunities;

  const _RecentOpportunitiesCard({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work_outline_rounded, color: AdminPalette.accent),
              SizedBox(width: 8),
              Text(
                'Recent Opportunities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (opportunities.isEmpty)
            const Text(
              'No opportunities published yet',
              style: TextStyle(color: AdminPalette.textMuted),
            ),
          ...opportunities.asMap().entries.map((entry) {
            final offer = entry.value;
            final type = (offer['type'] ?? '').toString();
            final title = (offer['title'] ?? '').toString().trim();
            final companyName = (offer['companyName'] ?? '').toString().trim();

            return Column(
              children: [
                if (entry.key > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AdminPalette.border.withValues(alpha: 0.72),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: OpportunityType.color(
                            type,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OpportunityType.color(
                              type,
                            ).withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(
                          OpportunityType.icon(type),
                          size: 18,
                          color: OpportunityType.color(type),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      title.isNotEmpty
                                          ? title
                                          : 'Untitled opportunity',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14.2,
                                        fontWeight: FontWeight.w700,
                                        color: AdminPalette.textPrimary,
                                        height: 1.18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OpportunityTypeBadge(
                                  type: type,
                                  fontSize: 10.2,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              companyName.isNotEmpty
                                  ? companyName
                                  : 'Company name not added',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.8,
                                color: AdminPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'student':
      return AdminPalette.info;
    case 'company':
      return AdminPalette.secondary;
    case 'admin':
      return AdminPalette.accent;
    default:
      return AdminPalette.textMuted;
  }
}

IconData _activityIcon(String type) {
  switch (type) {
    case 'application':
      return Icons.assignment_outlined;
    case 'opportunity':
      return Icons.work_outline;
    case 'scholarship':
      return Icons.card_giftcard_outlined;
    case 'training':
      return Icons.cast_for_education_outlined;
    default:
      return Icons.lightbulb_outline_rounded;
  }
}

Color _activityColor(String type) {
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

Color _activityStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'approved':
    case 'accepted':
    case 'featured':
      return AdminPalette.success;
    case 'pending':
      return AdminPalette.warning;
    case 'rejected':
      return AdminPalette.danger;
    default:
      return AdminPalette.primary;
  }
}
