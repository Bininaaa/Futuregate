import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/admin_charts.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/stat_card.dart';
import '../notifications_screen.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import 'admin_library_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

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
              title: 'Command Center for Platform Operations',
              subtitle:
                  'Keep moderation, growth, activity, and curation in one focused admin workspace with faster paths into the queues that need attention.',
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AdminPalette.secondary,
              stats: [
                AdminHeroStat(
                  label: 'Users',
                  value: '${stats['totalUsers'] ?? 0}',
                ),
                AdminHeroStat(
                  label: 'Active',
                  value: '${stats['activeUsers'] ?? 0}',
                ),
                AdminHeroStat(
                  label: 'Pending Ideas',
                  value: '${stats['pendingIdeas'] ?? 0}',
                ),
                AdminHeroStat(label: 'Unread', value: '$unreadCount'),
              ],
              actions: [
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
            const SizedBox(height: 22),
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
                  'The most common admin destinations are one tap away from here.',
            ),
            const SizedBox(height: 12),
            _QuickAccessGrid(
              unreadCount: unreadCount,
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
              activities: provider.recentActivity.take(8).toList(),
              onOpenActivity: _openActivityItem,
            ),
            const SizedBox(height: 16),
            _RecentUsersCard(users: provider.recentUsers),
            const SizedBox(height: 16),
            _RecentOpportunitiesCard(
              opportunities: provider.recentOpportunities,
            ),
          ],
        ),
      ),
    );
  }

  void _openContent(int tab, {String targetId = ''}) {
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminActivityCenterScreen()),
    );
  }

  void _openLibrary() {
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

  void _openActivityItem(AdminActivityModel activity) {
    final targetTab = switch (activity.type) {
      'application' => AdminContentCenterScreen.opportunitiesTab,
      'opportunity' => AdminContentCenterScreen.opportunitiesTab,
      'scholarship' => AdminContentCenterScreen.scholarshipsTab,
      'training' => AdminContentCenterScreen.trainingsTab,
      _ => AdminContentCenterScreen.projectIdeasTab,
    };

    _openContent(targetTab, targetId: activity.relatedId);
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
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.28,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'No data yet',
              style: TextStyle(color: AdminPalette.textMuted),
            ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
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
                    child: Text(
                      item['title'] ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${item['count']} $suffixLabel',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
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
  final VoidCallback onOpenActivity;
  final VoidCallback onOpenLibrary;

  const _QuickAccessGrid({
    required this.unreadCount,
    required this.onOpenActivity,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(
        title: 'Opportunity Apps',
        subtitle: 'Review submissions inside offers',
        icon: Icons.assignment_outlined,
        color: AdminPalette.activity,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminContentCenterScreen(
              initialTab: AdminContentCenterScreen.opportunitiesTab,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Opportunities',
        subtitle: 'Manage published offers',
        icon: Icons.work_outline_rounded,
        color: AdminPalette.accent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminContentCenterScreen(
              initialTab: AdminContentCenterScreen.opportunitiesTab,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Scholarships',
        subtitle: 'Open scholarship queue',
        icon: Icons.card_giftcard_outlined,
        color: Colors.pink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminContentCenterScreen(
              initialTab: AdminContentCenterScreen.scholarshipsTab,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Trainings',
        subtitle: 'Browse learning content',
        icon: Icons.cast_for_education_outlined,
        color: AdminPalette.secondary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminContentCenterScreen(
              initialTab: AdminContentCenterScreen.trainingsTab,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Project Ideas',
        subtitle: 'Moderate pending ideas',
        icon: Icons.lightbulb_outline_rounded,
        color: Colors.amber.shade700,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminContentCenterScreen(
              initialTab: AdminContentCenterScreen.projectIdeasTab,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Activity',
        subtitle: 'See latest events',
        icon: Icons.timeline_rounded,
        color: AdminPalette.info,
        onTap: onOpenActivity,
      ),
      _QuickAccessItem(
        title: 'Notifications',
        subtitle: unreadCount > 0
            ? '$unreadCount unread notifications'
            : 'Open notification center',
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
        subtitle: 'Curate imported resources',
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
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.26,
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
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.color),
                            ),
                            const Spacer(),
                            if (item.badgeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AdminPalette.accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
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
              'No recent activity',
              style: TextStyle(color: AdminPalette.textMuted),
            )
          : Column(
              children: activities.map((activity) {
                final color = _activityColor(activity.type);
                final dateLabel = activity.createdAt == null
                    ? 'Unknown time'
                    : '${activity.createdAt!.toDate().day}/${activity.createdAt!.toDate().month}/${activity.createdAt!.toDate().year}';
                final actorAndStatus = [
                  if (activity.actorName.trim().isNotEmpty) activity.actorName,
                  if (activity.status.trim().isNotEmpty) activity.status,
                ].join(' - ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => onOpenActivity(activity),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _activityIcon(activity.type),
                              size: 18,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AdminPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activity.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AdminPalette.textSecondary,
                                  ),
                                ),
                                if (actorAndStatus.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    actorAndStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AdminPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AdminPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
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
              'No recent users',
              style: TextStyle(color: AdminPalette.textMuted),
            ),
          ...users.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ProfileAvatar(user: user, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AdminPalette.textPrimary,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminPill(label: user.role, color: _roleColor(user.role)),
                ],
              ),
            ),
          ),
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
              'No opportunities yet',
              style: TextStyle(color: AdminPalette.textMuted),
            ),
          ...opportunities.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminPalette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      size: 18,
                      color: AdminPalette.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer['title'] ?? 'No title',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AdminPalette.textPrimary,
                          ),
                        ),
                        Text(
                          offer['companyName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminPill(
                    label: offer['type'] ?? '',
                    color: offer['type'] == 'job'
                        ? AdminPalette.info
                        : AdminPalette.success,
                  ),
                ],
              ),
            ),
          ),
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
