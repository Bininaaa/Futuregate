import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';

class ModerateScreen extends StatefulWidget {
  const ModerateScreen({super.key});

  @override
  State<ModerateScreen> createState() => _ModerateScreenState();
}

class _ModerateScreenState extends State<ModerateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadModerationData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AdminPalette.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminPalette.border),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: AdminPalette.textPrimary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: AdminPalette.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb, size: 14),
                    const SizedBox(width: 3),
                    const Text('Ideas', style: TextStyle(fontSize: 11)),
                    if (provider.allProjectIdeas
                        .where((i) => i.status == 'pending')
                        .isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AdminPalette.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.allProjectIdeas.where((i) => i.status == 'pending').length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work, size: 14),
                    SizedBox(width: 3),
                    Text('Offers', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard, size: 14),
                    SizedBox(width: 3),
                    Text('Scholarships', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.moderationLoading
              ? const AppLoadingView(density: AppLoadingDensity.compact)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProjectIdeasTab(provider),
                    _buildOpportunitiesTab(provider),
                    _buildScholarshipsTab(provider),
                  ],
                ),
        ),
      ],
    );
  }

  bool _showPendingOnly = true;

  Widget _buildProjectIdeasTab(AdminProvider provider) {
    final allIdeas = provider.allProjectIdeas;
    final ideas = _showPendingOnly
        ? allIdeas.where((i) => i.status == 'pending').toList()
        : allIdeas;

    if (allIdeas.isEmpty) {
      return _buildEmptyState(
        Icons.lightbulb_outline,
        'No project ideas to review yet',
      );
    }

    return RefreshIndicator(
      color: AdminPalette.accent,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ideas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showPendingOnly
                        ? 'Pending Ideas (${ideas.length})'
                        : 'All Ideas (${ideas.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showPendingOnly = !_showPendingOnly;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AdminPalette.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _showPendingOnly ? 'Show All' : 'Pending Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AdminPalette.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (ideas.isEmpty) {
            return _buildEmptyState(
              Icons.check_circle,
              'No pending ideas to review',
            );
          }
          final idea = ideas[index - 1];
          final isIdeaBusy = provider.busyIdeaIds.contains(idea.id);
          Color statusColor;
          IconData statusIcon;
          switch (idea.status) {
            case 'approved':
              statusColor = AdminPalette.success;
              statusIcon = Icons.check_circle;
              break;
            case 'rejected':
              statusColor = AdminPalette.danger;
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = AdminPalette.warning;
              statusIcon = Icons.pending;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AdminPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminPalette.border),
              boxShadow: AdminPalette.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          idea.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AdminPalette.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              idea.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    idea.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AdminPalette.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildChip(idea.domain, AdminPalette.info),
                      _buildChip(idea.level, AdminPalette.activity),
                      if (idea.tools.isNotEmpty)
                        _buildChip(idea.tools, AdminPalette.secondary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submitted by: ${idea.submittedBy}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AdminPalette.textMuted,
                    ),
                  ),
                  if (idea.status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isIdeaBusy
                                ? null
                                : () async {
                                    final error = await provider
                                        .updateProjectIdeaStatus(
                                          idea.id,
                                          'approved',
                                        );
                                    if (error != null && context.mounted) {
                                      context.showAppSnackBar(
                                        error,
                                        title: 'Update unavailable',
                                        type: AppFeedbackType.error,
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(isIdeaBusy ? 'Working...' : 'Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminPalette.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isIdeaBusy
                                ? null
                                : () async {
                                    final error = await provider
                                        .updateProjectIdeaStatus(
                                          idea.id,
                                          'rejected',
                                        );
                                    if (error != null && context.mounted) {
                                      context.showAppSnackBar(
                                        error,
                                        title: 'Update unavailable',
                                        type: AppFeedbackType.error,
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(isIdeaBusy ? 'Working...' : 'Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminPalette.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunitiesTab(AdminProvider provider) {
    final opportunities = provider.allOpportunities;

    if (opportunities.isEmpty) {
      return _buildEmptyState(
        Icons.work_outline,
        'No opportunities published yet',
      );
    }

    return RefreshIndicator(
      color: AdminPalette.accent,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: opportunities.length,
        itemBuilder: (context, index) {
          final opp = opportunities[index];
          final effectiveStatus = OpportunityModel.fromMap(
            Map<String, dynamic>.from(opp),
          ).effectiveStatus();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AdminPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminPalette.border),
              boxShadow: AdminPalette.softShadow,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminPalette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.work, color: AdminPalette.accent, size: 22),
              ),
              title: Text(
                opp['title'] ?? 'Untitled opportunity',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AdminPalette.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opp['companyName'] ?? 'Unknown company',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (opp['type'] == 'job'
                                      ? AdminPalette.info
                                      : AdminPalette.secondary)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          opp['type'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: opp['type'] == 'job'
                                ? AdminPalette.info
                                : AdminPalette.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (effectiveStatus == 'open'
                                      ? AdminPalette.success
                                      : AdminPalette.textMuted)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          effectiveStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: effectiveStatus == 'open'
                                ? AdminPalette.success
                                : AdminPalette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AdminPalette.danger,
                  size: 22,
                ),
                onPressed: () => _showDeleteDialog(
                  'Delete Opportunity',
                  'Are you sure you want to delete "${opp['title']}"?',
                  () async {
                    final error = await provider.deleteOpportunity(opp['id']);
                    if (error != null && context.mounted) {
                      context.showAppSnackBar(
                        error,
                        title: 'Delete unavailable',
                        type: AppFeedbackType.error,
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScholarshipsTab(AdminProvider provider) {
    final scholarships = provider.allScholarships;

    if (scholarships.isEmpty) {
      return _buildEmptyState(
        Icons.card_giftcard,
        'No scholarships published yet',
      );
    }

    return RefreshIndicator(
      color: AdminPalette.accent,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: scholarships.length,
        itemBuilder: (context, index) {
          final sch = scholarships[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AdminPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminPalette.border),
              boxShadow: AdminPalette.softShadow,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminPalette.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: AdminPalette.danger,
                  size: 22,
                ),
              ),
              title: Text(
                sch['title'] ?? 'Untitled scholarship',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AdminPalette.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sch['provider'] ?? 'Unknown provider',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (sch['amount'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AdminPalette.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sch['amount']} DA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdminPalette.success,
                            ),
                          ),
                        ),
                      if (sch['deadline'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AdminPalette.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Due: ${sch['deadline']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdminPalette.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AdminPalette.danger,
                  size: 22,
                ),
                onPressed: () => _showDeleteDialog(
                  'Delete Scholarship',
                  'Are you sure you want to delete "${sch['title']}"?',
                  () async {
                    final error = await provider.deleteScholarship(sch['id']);
                    if (error != null && context.mounted) {
                      context.showAppSnackBar(
                        error,
                        title: 'Delete unavailable',
                        type: AppFeedbackType.error,
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AdminPalette.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AdminPalette.textMuted),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title, style: TextStyle(color: AdminPalette.textPrimary)),
        content: Text(
          content,
          style: TextStyle(color: AdminPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: AdminPalette.danger),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
