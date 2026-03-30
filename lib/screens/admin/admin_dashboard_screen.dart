import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifications_screen.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import '../../widgets/admin_charts.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/stat_card.dart';

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
        child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
      );
    }

    if (provider.dashboardError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load the admin dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D1B4E),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: provider.loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = provider.stats;
    final monthlyRegistrations =
        (stats['monthlyRegistrations'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      color: const Color(0xFFFF8C00),
      onRefresh: provider.loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Overview'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Users',
                    value: '${stats['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    iconColor: const Color(0xFF2D1B4E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Active Users',
                    value: '${stats['activeUsers'] ?? 0}',
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Students',
                    value: '${stats['students'] ?? 0}',
                    icon: Icons.school,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Companies',
                    value: '${stats['companies'] ?? 0}',
                    icon: Icons.business,
                    iconColor: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Students by Level'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Bac',
                    value: '${stats['bac'] ?? 0}',
                    icon: Icons.menu_book,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Licence',
                    value: '${stats['licence'] ?? 0}',
                    icon: Icons.book,
                    iconColor: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Master',
                    value: '${stats['master'] ?? 0}',
                    icon: Icons.workspace_premium,
                    iconColor: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Doctorat',
                    value: '${stats['doctorat'] ?? 0}',
                    icon: Icons.science,
                    iconColor: Colors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
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
            _buildSectionTitle('Content'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Opportunities',
                    value: '${stats['opportunities'] ?? 0}',
                    icon: Icons.work,
                    iconColor: const Color(0xFFFF8C00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Applications',
                    value: '${stats['applications'] ?? 0}',
                    icon: Icons.assignment,
                    iconColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Scholarships',
                    value: '${stats['scholarships'] ?? 0}',
                    icon: Icons.card_giftcard,
                    iconColor: Colors.pink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Trainings',
                    value: '${stats['trainings'] ?? 0}',
                    icon: Icons.cast_for_education,
                    iconColor: Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Project Ideas',
                    value: '${stats['projectIdeas'] ?? 0}',
                    icon: Icons.lightbulb,
                    iconColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Conversations',
                    value: '${stats['conversations'] ?? 0}',
                    icon: Icons.chat,
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Engagement Analytics'),
            const SizedBox(height: 12),
            _buildEngagementCard(
              icon: Icons.percent,
              iconColor: Colors.blue,
              title: 'Application Rate',
              value:
                  '${((stats['applicationRate'] ?? 0.0) as double).toStringAsFixed(1)} apps/opportunity',
            ),
            const SizedBox(height: 10),
            _buildEngagementCard(
              icon: Icons.description,
              iconColor: Colors.green,
              title: 'CV Completion Rate',
              value:
                  '${((stats['cvCompletionRate'] ?? 0.0) as double).toStringAsFixed(0)}% (${stats['totalCvs'] ?? 0} of ${stats['students'] ?? 0} students)',
            ),
            const SizedBox(height: 10),
            _buildEngagementCard(
              icon: Icons.pending_actions,
              iconColor: Colors.orange,
              title: 'Pending Project Ideas',
              value:
                  '${stats['pendingIdeas'] ?? 0} pending, ${stats['approvedIdeas'] ?? 0} approved',
            ),
            const SizedBox(height: 24),
            _buildTopListSection(
              'Most Applied Opportunities',
              Icons.trending_up,
              Colors.deepPurple,
              (stats['topApplied'] as List<dynamic>?) ?? [],
              'applications',
            ),
            const SizedBox(height: 16),
            _buildTopListSection(
              'Most Saved Opportunities',
              Icons.bookmark,
              const Color(0xFFFF8C00),
              (stats['topSaved'] as List<dynamic>?) ?? [],
              'saves',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Quick Access'),
            const SizedBox(height: 12),
            _buildQuickAccess(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Recent Activity'),
            const SizedBox(height: 12),
            _buildActivityFeed(
              context,
              provider.recentActivity.take(8).toList(),
            ),
            const SizedBox(height: 16),
            _buildRecentUsersSection(provider),
            const SizedBox(height: 16),
            _buildRecentOffersSection(provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D1B4E),
      ),
    );
  }

  Widget _buildEngagementCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B4E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopListSection(
    String title,
    IconData icon,
    Color color,
    List<dynamic> items,
    String countLabel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No data yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['title'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item['count']} $countLabel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildQuickAccess(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final items = [
      _QuickAccessItem(
        title: 'Applications',
        subtitle: 'Review all submissions',
        icon: Icons.assignment_outlined,
        color: Colors.deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminContentCenterScreen(
              initialTab: AdminContentCenterScreen.applicationsTab,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Opportunities',
        subtitle: 'Manage published offers',
        icon: Icons.work_outline,
        color: const Color(0xFFFF8C00),
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
        subtitle: 'Open scholarship list',
        icon: Icons.card_giftcard,
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
        subtitle: 'Browse training resources',
        icon: Icons.cast_for_education_outlined,
        color: Colors.cyan,
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
        subtitle: 'Moderate submissions',
        icon: Icons.lightbulb_outline,
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
        title: 'Recent Activity',
        subtitle: 'See the latest events',
        icon: Icons.timeline,
        color: const Color(0xFF3A6EA5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminActivityCenterScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Notifications',
        subtitle: unreadCount > 0
            ? '$unreadCount unread notifications'
            : 'Open notification center',
        icon: Icons.notifications_outlined,
        color: const Color(0xFF2D1B4E),
        badgeCount: unreadCount,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.38,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                            color: const Color(
                              0xFFFF8C00,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF8C00),
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
                      color: Color(0xFF2D1B4E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityFeed(
    BuildContext context,
    List<AdminActivityModel> activities,
  ) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'No recent activity',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: activities.map((activity) {
          final activityColor = _activityColor(activity.type);
          final activityIcon = _activityIcon(activity.type);
          final timeStr = activity.createdAt == null
              ? 'Unknown time'
              : '${activity.createdAt!.toDate().day}/${activity.createdAt!.toDate().month}/${activity.createdAt!.toDate().year}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                final targetTab = switch (activity.type) {
                  'application' => AdminContentCenterScreen.applicationsTab,
                  'opportunity' => AdminContentCenterScreen.opportunitiesTab,
                  'scholarship' => AdminContentCenterScreen.scholarshipsTab,
                  'training' => AdminContentCenterScreen.trainingsTab,
                  _ => AdminContentCenterScreen.projectIdeasTab,
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminContentCenterScreen(
                      initialTab: targetTab,
                      initialTargetId: activity.relatedId,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(activityIcon, size: 18, color: activityColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D1B4E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (activity.actorName.trim().isNotEmpty ||
                              activity.status.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [
                                  if (activity.actorName.trim().isNotEmpty)
                                    activity.actorName,
                                  if (activity.status.trim().isNotEmpty)
                                    activity.status,
                                ].join(' • '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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

  Widget _buildRecentUsersSection(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF2D1B4E), size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.recentUsers.isEmpty)
            Text('No recent users', style: TextStyle(color: Colors.grey[500])),
          ...provider.recentUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _roleColor(user.role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _roleColor(user.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOffersSection(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work, color: Color(0xFFFF8C00), size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Opportunities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.recentOpportunities.isEmpty)
            Text(
              'No opportunities yet',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ...provider.recentOpportunities.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      size: 18,
                      color: Color(0xFFFF8C00),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          offer['companyName'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (offer['type'] == 'job' ? Colors.blue : Colors.green)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer['type'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: offer['type'] == 'job'
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'student':
        return Colors.blue;
      case 'company':
        return Colors.teal;
      case 'admin':
        return const Color(0xFFFF8C00);
      default:
        return Colors.grey;
    }
  }

  IconData _activityIcon(String type) {
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

  Color _activityColor(String type) {
    switch (type) {
      case 'application':
        return Colors.deepPurple;
      case 'opportunity':
        return const Color(0xFFFF8C00);
      case 'scholarship':
        return Colors.pink;
      case 'training':
        return Colors.cyan;
      default:
        return Colors.amber.shade700;
    }
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
