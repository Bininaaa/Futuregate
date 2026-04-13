import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/shared/app_feedback.dart';

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
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF2D1B4E),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: const Color(0xFFFF8C00),
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
                          color: Colors.red,
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
                )
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
      color: const Color(0xFFFF8C00),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D1B4E),
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
                        color: const Color(0xFF2D1B4E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _showPendingOnly ? 'Show All' : 'Pending Only',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D1B4E),
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
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.pending;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1B4E),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildChip(idea.domain, Colors.blue),
                      _buildChip(idea.level, Colors.purple),
                      if (idea.tools.isNotEmpty)
                        _buildChip(idea.tools, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submitted by: ${idea.submittedBy}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                              backgroundColor: Colors.green,
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
                              backgroundColor: Colors.red,
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
      color: const Color(0xFFFF8C00),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.work,
                  color: Color(0xFFFF8C00),
                  size: 22,
                ),
              ),
              title: Text(
                opp['title'] ?? 'Untitled opportunity',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2D1B4E),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opp['companyName'] ?? 'Unknown company',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                                      ? Colors.blue
                                      : Colors.green)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          opp['type'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: opp['type'] == 'job'
                                ? Colors.blue
                                : Colors.green,
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
                                      ? Colors.green
                                      : Colors.grey)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          effectiveStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: effectiveStatus == 'open'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
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
      color: const Color(0xFFFF8C00),
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: scholarships.length,
        itemBuilder: (context, index) {
          final sch = scholarships[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.pink,
                  size: 22,
                ),
              ),
              title: Text(
                sch['title'] ?? 'Untitled scholarship',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2D1B4E),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sch['provider'] ?? 'Unknown provider',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sch['amount']} DA',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
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
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Due: ${sch['deadline']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
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
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Text(content),
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
