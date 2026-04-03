import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/admin_application_item_model.dart';
import '../../models/cv_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/project_idea_model.dart';
import '../../providers/auth_provider.dart';
import '../../models/training_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/company_service.dart';
import '../../services/document_access_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/profile_avatar.dart';
import 'admin_opportunity_editor_screen.dart';
import 'admin_project_idea_editor_screen.dart';
import 'admin_scholarship_editor_screen.dart';

class AdminContentCenterScreen extends StatefulWidget {
  static const int projectIdeasTab = 0;
  static const int opportunitiesTab = 1;
  static const int scholarshipsTab = 2;
  static const int trainingsTab = 3;

  final int initialTab;
  final String initialTargetId;
  final bool embedded;

  const AdminContentCenterScreen({
    super.key,
    this.initialTab = projectIdeasTab,
    this.initialTargetId = '',
    this.embedded = false,
  });

  @override
  State<AdminContentCenterScreen> createState() =>
      _AdminContentCenterScreenState();
}

class _AdminContentCenterScreenState extends State<AdminContentCenterScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = AdminPalette.textPrimary;
  static const Color _accentColor = AdminPalette.primary;

  final CompanyService _companyService = CompanyService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  bool _showPendingOnly = true;
  bool _openedInitialTarget = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadModerationData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final pendingIdeas = provider.allProjectIdeas
        .where((idea) => idea.status == 'pending')
        .length;

    if (!provider.moderationLoading &&
        !_openedInitialTarget &&
        widget.initialTargetId.trim().isNotEmpty) {
      _openedInitialTarget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openInitialTarget(provider, widget.initialTargetId.trim());
      });
    }

    final content = provider.moderationLoading
        ? const Center(child: CircularProgressIndicator(color: _accentColor))
        : provider.moderationError != null &&
              provider.allProjectIdeas.isEmpty &&
              provider.allApplications.isEmpty &&
              provider.allOpportunities.isEmpty &&
              provider.allScholarships.isEmpty &&
              provider.allTrainings.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load admin content',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: provider.loadModerationData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: AdminSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSectionHeader(
                          eyebrow: 'Moderation',
                          title: 'Content Workspace',
                          subtitle:
                              'Review submissions, monitor queues, and move between content types without losing context.',
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            AdminPill(
                              label: '$pendingIdeas pending ideas',
                              color: AdminPalette.warning,
                              icon: Icons.hourglass_top_rounded,
                            ),
                            AdminPill(
                              label:
                                  '${provider.allApplications.length} applications',
                              color: AdminPalette.activity,
                              icon: Icons.assignment_outlined,
                            ),
                            AdminPill(
                              label:
                                  '${provider.allOpportunities.length} opportunities',
                              color: AdminPalette.accent,
                              icon: Icons.work_outline_rounded,
                            ),
                            AdminPill(
                              label:
                                  '${provider.allTrainings.length} trainings',
                              color: AdminPalette.secondary,
                              icon: Icons.cast_for_education_outlined,
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
                    hintText: _searchHintForCurrentTab(),
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _AdminTabBarHeaderDelegate(
                  child: Container(
                    color: AdminPalette.background,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AdminPalette.border),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: _primaryColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicator: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tabs: [
                          _buildTab(
                            icon: Icons.lightbulb,
                            label: 'Ideas',
                            badgeCount: pendingIdeas,
                          ),
                          _buildTab(
                            icon: Icons.work_outline,
                            label: 'Opportunities',
                          ),
                          _buildTab(
                            icon: Icons.card_giftcard,
                            label: 'Scholarships',
                          ),
                          _buildTab(
                            icon: Icons.cast_for_education_outlined,
                            label: 'Trainings',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectIdeasTab(provider),
                _buildOpportunitiesTab(provider),
                _buildScholarshipsTab(provider),
                _buildTrainingsTab(provider),
              ],
            ),
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: AppBar(
        title: const Text('Admin Content Center'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
      ),
      body: SafeArea(child: content),
    );
  }

  Tab _buildTab({
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
          if (badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
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
    );
  }

  Widget _buildProjectIdeasTab(AdminProvider provider) {
    final adminId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    final allIdeas = provider.allProjectIdeas
        .where(_matchesIdeaSearch)
        .toList();
    final ideas = _showPendingOnly
        ? allIdeas.where((idea) => idea.status == 'pending').toList()
        : allIdeas;

    if (provider.allProjectIdeas.isEmpty) {
      return AdminEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No project ideas yet',
        message:
            'Create the first admin idea to seed the innovation feed and make the space feel alive immediately.',
        action: FilledButton.icon(
          onPressed: () => _openIdeaEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Post Admin Idea'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (ideas.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        _showPendingOnly
            ? 'No pending ideas match your search'
            : 'No ideas match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ideas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _showPendingOnly
                        ? 'Pending Ideas (${ideas.length})'
                        : 'All Ideas (${ideas.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  AdminFilterChip(
                    label: _showPendingOnly ? 'Show All' : 'Pending Only',
                    selected: false,
                    icon: Icons.swap_horiz_rounded,
                    onTap: () => setState(() {
                      _showPendingOnly = !_showPendingOnly;
                    }),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openIdeaEditor(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Post Admin Idea'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final idea = ideas[index - 1];
          final isIdeaBusy = provider.busyIdeaIds.contains(idea.id);
          final canEditIdea = adminId.isNotEmpty && idea.submittedBy == adminId;
          final submitterLabel = idea.submittedByName.trim().isNotEmpty
              ? idea.submittedByName
              : idea.submittedBy;

          return _buildContentCard(
            id: idea.id,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.amber.shade800,
              ),
            ),
            title: idea.title,
            subtitle: 'Submitted by $submitterLabel',
            description: idea.description,
            badges: [
              _BadgeData(idea.status, _statusColor(idea.status)),
              _BadgeData(idea.domain, Colors.blue),
              _BadgeData(idea.level, Colors.purple),
              if (idea.tools.isNotEmpty) _BadgeData(idea.tools, Colors.teal),
            ],
            metaText: idea.createdAt == null
                ? null
                : _formatTimestamp(idea.createdAt),
            onTap: () => _showProjectIdeaDetails(idea),
            action: _buildCardActionRow([
              if (canEditIdea)
                _buildCompactCardAction(
                  icon: Icons.edit_outlined,
                  color: AdminPalette.primary,
                  onTap: () => _openIdeaEditor(idea: idea),
                ),
              _buildCompactCardAction(
                icon: Icons.delete_outline_rounded,
                color: AdminPalette.danger,
                onTap: () => _showDeleteDialog(
                  'Delete Project Idea',
                  'Are you sure you want to delete "${idea.title}"?',
                  () async {
                    final error = await provider.deleteProjectIdea(idea.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                ),
              ),
            ]),
            footer: idea.status == 'pending'
                ? _buildResponsiveActionGroup([
                    FilledButton.icon(
                      onPressed: isIdeaBusy
                          ? null
                          : () async {
                              final error = await provider
                                  .updateProjectIdeaStatus(idea.id, 'approved');
                              if (error != null && context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              }
                            },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(isIdeaBusy ? 'Working...' : 'Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminPalette.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: isIdeaBusy
                          ? null
                          : () async {
                              final error = await provider
                                  .updateProjectIdeaStatus(idea.id, 'rejected');
                              if (error != null && context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              }
                            },
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(isIdeaBusy ? 'Working...' : 'Reject'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminPalette.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ])
                : null,
          );
        },
      ),
    );
  }

  List<AdminApplicationItemModel> _applicationsForOpportunity(
    AdminProvider provider,
    String opportunityId,
  ) {
    final matches = provider.allApplications
        .where((application) => application.opportunityId == opportunityId)
        .toList();

    matches.sort((a, b) {
      final aTime = a.appliedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.appliedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return matches;
  }

  void _showOpportunityApplications(
    Map<String, dynamic> opportunity,
    List<AdminApplicationItemModel> applications,
  ) {
    final opportunityTitle = (opportunity['title'] ?? 'Opportunity').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            AdminSurface(
              radius: 24,
              gradient: AdminPalette.heroGradient(AdminPalette.activity),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Applications for $opportunityTitle',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${applications.length} application${applications.length == 1 ? '' : 's'} linked to this opportunity.',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (applications.isEmpty)
              const AdminEmptyState(
                icon: Icons.assignment_late_outlined,
                title: 'No applications yet',
                message:
                    'This opportunity does not have any submitted applications right now.',
              )
            else
              ...applications.map((item) {
                final statusColor = _statusColor(item.status);
                return _buildContentCard(
                  id: item.id,
                  leading: ProfileAvatar(
                    radius: 18,
                    userId: item.application.studentId,
                    fallbackName: item.studentName,
                    role: 'student',
                  ),
                  title: item.studentName,
                  subtitle: item.companyName.isNotEmpty
                      ? item.companyName
                      : 'Application',
                  badges: [
                    _BadgeData(item.status, statusColor),
                    if (item.appliedAt != null)
                      _BadgeData(
                        DateFormat('MMM d').format(item.appliedAt!.toDate()),
                        AdminPalette.info,
                      ),
                  ],
                  metaText: _formatTimestamp(item.appliedAt),
                  onTap: () {
                    Navigator.pop(context);
                    _showApplicationDetails(item);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportunitiesTab(AdminProvider provider) {
    final adminId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    final opportunities = provider.allOpportunities
        .where(_matchesOpportunitySearch)
        .toList();

    if (provider.allOpportunities.isEmpty) {
      return AdminEmptyState(
        icon: Icons.work_outline,
        title: 'No opportunities yet',
        message:
            'Publish the first admin opportunity so students have something to discover right away.',
        action: FilledButton.icon(
          onPressed: () => _openOpportunityEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Post Opportunity'),
        ),
      );
    }

    if (opportunities.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No opportunities match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: opportunities.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'All Opportunities (${opportunities.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openOpportunityEditor(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Post Opportunity'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final opportunity = opportunities[index - 1];
          final opportunityId = opportunity['id'].toString();
          final isOwnedByAdmin =
              adminId.isNotEmpty &&
              (opportunity['companyId'] ?? '').toString().trim() == adminId;
          final applications = _applicationsForOpportunity(
            provider,
            opportunityId,
          );
          final opportunityModel = OpportunityModel.fromMap(opportunity);
          final metadata = OpportunityMetadata.buildMetadataItems(
            type: opportunityModel.type,
            salaryMin: opportunityModel.salaryMin,
            salaryMax: opportunityModel.salaryMax,
            salaryCurrency: opportunityModel.salaryCurrency,
            salaryPeriod: opportunityModel.salaryPeriod,
            compensationText: opportunityModel.compensationText,
            isPaid: opportunityModel.isPaid,
            employmentType: opportunityModel.employmentType,
            workMode: opportunityModel.workMode,
            duration: opportunityModel.duration,
            maxItems: 2,
          );
          final opportunityType = OpportunityType.parse(
            (opportunity['type'] ?? '').toString(),
          );
          return _buildMapListTile(
            id: opportunityId,
            icon: Icons.work,
            iconColor: _accentColor,
            title: (opportunity['title'] ?? 'No title').toString(),
            subtitle: (opportunity['companyName'] ?? 'Unknown company')
                .toString(),
            badges: [
              if (isOwnedByAdmin)
                _BadgeData('Admin post', AdminPalette.primary),
              _BadgeData(
                '${applications.length} app${applications.length == 1 ? '' : 's'}',
                AdminPalette.activity,
              ),
              _BadgeData(
                OpportunityType.label(opportunityType),
                OpportunityType.color(opportunityType),
              ),
              _BadgeData(
                (opportunity['status'] ?? '').toString(),
                (opportunity['status'] ?? '') == 'open'
                    ? Colors.green
                    : Colors.grey,
              ),
              ...metadata.map((item) => _BadgeData(item, Colors.indigo)),
            ],
            onTap: () => _showOpportunityDetails(opportunity),
            footer: OutlinedButton.icon(
              onPressed: () =>
                  _showOpportunityApplications(opportunity, applications),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: Text(
                applications.isEmpty
                    ? 'No Applications Yet'
                    : 'View Applications (${applications.length})',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminPalette.activity,
                side: BorderSide(
                  color: AdminPalette.activity.withValues(alpha: 0.24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            trailing: _buildCardActionRow([
              if (isOwnedByAdmin)
                _buildCompactCardAction(
                  icon: Icons.edit_outlined,
                  color: AdminPalette.primary,
                  onTap: () => _openOpportunityEditor(opportunity: opportunity),
                ),
              _buildCompactCardAction(
                icon: Icons.delete_outline_rounded,
                color: AdminPalette.danger,
                onTap: () => _showDeleteDialog(
                  'Delete Opportunity',
                  'Are you sure you want to delete "${opportunity['title']}"?',
                  () async {
                    final error = await provider.deleteOpportunity(
                      opportunityId,
                    );
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildScholarshipsTab(AdminProvider provider) {
    final scholarships = provider.allScholarships
        .where(_matchesScholarshipSearch)
        .toList();

    if (provider.allScholarships.isEmpty) {
      return AdminEmptyState(
        icon: Icons.card_giftcard,
        title: 'No scholarships yet',
        message:
            'Publish the first scholarship and start shaping the student discovery catalog from the admin side.',
        action: FilledButton.icon(
          onPressed: () => _openScholarshipEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Post Scholarship'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (scholarships.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No scholarships match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: scholarships.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'All Scholarships (${scholarships.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openScholarshipEditor(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Post Scholarship'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final scholarship = scholarships[index - 1];
          return _buildMapListTile(
            id: scholarship['id'].toString(),
            icon: Icons.card_giftcard,
            iconColor: Colors.pink,
            title: (scholarship['title'] ?? 'No title').toString(),
            subtitle: (scholarship['provider'] ?? 'Unknown provider')
                .toString(),
            badges: [
              if (scholarship['amount'] != null)
                _BadgeData('${scholarship['amount']} DA', Colors.green),
              if ((scholarship['deadline'] ?? '').toString().isNotEmpty)
                _BadgeData('Due: ${scholarship['deadline']}', Colors.orange),
            ],
            onTap: () => _showScholarshipDetails(scholarship),
            trailing: _buildCardActionRow([
              _buildCompactCardAction(
                icon: Icons.edit_outlined,
                color: AdminPalette.primary,
                onTap: () => _openScholarshipEditor(scholarship: scholarship),
              ),
              _buildCompactCardAction(
                icon: Icons.delete_outline_rounded,
                color: AdminPalette.danger,
                onTap: () => _showDeleteDialog(
                  'Delete Scholarship',
                  'Are you sure you want to delete "${scholarship['title']}"?',
                  () async {
                    final error = await provider.deleteScholarship(
                      scholarship['id'].toString(),
                    );
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildTrainingsTab(AdminProvider provider) {
    final trainings = provider.allTrainings
        .where(_matchesTrainingSearch)
        .toList();

    if (provider.allTrainings.isEmpty) {
      return _buildEmptyState(
        Icons.cast_for_education_outlined,
        'No trainings yet',
      );
    }

    if (trainings.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No trainings match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final training = trainings[index];
          return _buildTrainingListTile(training);
        },
      ),
    );
  }

  String _searchHintForCurrentTab() {
    switch (_tabController.index) {
      case AdminContentCenterScreen.projectIdeasTab:
        return 'Search ideas by title, domain, submitter, or status...';
      case AdminContentCenterScreen.opportunitiesTab:
        return 'Search opportunities by title, company, location, status, or compensation...';
      case AdminContentCenterScreen.scholarshipsTab:
        return 'Search scholarships by title, provider, or deadline...';
      case AdminContentCenterScreen.trainingsTab:
        return 'Search trainings by title, provider, domain, or level...';
      default:
        return 'Search...';
    }
  }

  bool _matchesIdeaSearch(ProjectIdeaModel idea) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return idea.title.toLowerCase().contains(query) ||
        idea.description.toLowerCase().contains(query) ||
        idea.domain.toLowerCase().contains(query) ||
        idea.level.toLowerCase().contains(query) ||
        idea.tools.toLowerCase().contains(query) ||
        idea.status.toLowerCase().contains(query) ||
        idea.submittedBy.toLowerCase().contains(query) ||
        idea.submittedByName.toLowerCase().contains(query);
  }

  bool _matchesOpportunitySearch(Map<String, dynamic> opportunity) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final opportunityModel = OpportunityModel.fromMap(opportunity);
    final metadataText = OpportunityMetadata.buildMetadataItems(
      type: opportunityModel.type,
      salaryMin: opportunityModel.salaryMin,
      salaryMax: opportunityModel.salaryMax,
      salaryCurrency: opportunityModel.salaryCurrency,
      salaryPeriod: opportunityModel.salaryPeriod,
      compensationText: opportunityModel.compensationText,
      isPaid: opportunityModel.isPaid,
      employmentType: opportunityModel.employmentType,
      workMode: opportunityModel.workMode,
      duration: opportunityModel.duration,
      maxItems: 3,
    ).join(' ').toLowerCase();

    return (opportunity['title'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (opportunity['companyName'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (opportunity['location'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (opportunity['type'] ?? '').toString().toLowerCase().contains(query) ||
        (opportunity['status'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        metadataText.contains(query);
  }

  bool _matchesScholarshipSearch(Map<String, dynamic> scholarship) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return (scholarship['title'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (scholarship['provider'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (scholarship['eligibility'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (scholarship['deadline'] ?? '').toString().toLowerCase().contains(
          query,
        );
  }

  bool _matchesTrainingSearch(TrainingModel training) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return training.title.toLowerCase().contains(query) ||
        training.provider.toLowerCase().contains(query) ||
        training.domain.toLowerCase().contains(query) ||
        training.level.toLowerCase().contains(query) ||
        training.source.toLowerCase().contains(query) ||
        training.type.toLowerCase().contains(query);
  }

  void _openInitialTarget(AdminProvider provider, String targetId) {
    switch (widget.initialTab) {
      case AdminContentCenterScreen.projectIdeasTab:
        final matches = provider.allProjectIdeas
            .where((item) => item.id == targetId)
            .toList();
        final idea = matches.isEmpty ? null : matches.first;
        if (idea != null) {
          _showProjectIdeaDetails(idea);
        }
        break;
      case AdminContentCenterScreen.opportunitiesTab:
        final matches = provider.allOpportunities
            .where((item) => item['id'] == targetId)
            .toList();
        final opportunity = matches.isEmpty ? null : matches.first;
        if (opportunity != null) {
          _showOpportunityDetails(opportunity);
          break;
        }

        final matchingApplications = provider.allApplications
            .where((item) => item.id == targetId)
            .toList();
        final application = matchingApplications.isEmpty
            ? null
            : matchingApplications.first;
        if (application != null) {
          _showApplicationDetails(application);
        }
        break;
      case AdminContentCenterScreen.scholarshipsTab:
        final matches = provider.allScholarships
            .where((item) => item['id'] == targetId)
            .toList();
        final scholarship = matches.isEmpty ? null : matches.first;
        if (scholarship != null) {
          _showScholarshipDetails(scholarship);
        }
        break;
      case AdminContentCenterScreen.trainingsTab:
        final matches = provider.allTrainings
            .where((item) => item.id == targetId)
            .toList();
        final training = matches.isEmpty ? null : matches.first;
        if (training != null) {
          _showTrainingDetails(training);
        }
        break;
    }
  }

  Future<void> _openIdeaEditor({ProjectIdeaModel? idea}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminProjectIdeaEditorScreen(initialIdea: idea),
      ),
    );
  }

  Future<void> _openOpportunityEditor({
    Map<String, dynamic>? opportunity,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminOpportunityEditorScreen(initialOpportunity: opportunity),
      ),
    );
  }

  Future<void> _openScholarshipEditor({
    Map<String, dynamic>? scholarship,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminScholarshipEditorScreen(initialScholarship: scholarship),
      ),
    );
  }

  Widget _buildCardActionRow(List<Widget> actions) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          actions[index],
          if (index < actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildCompactCardAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String id,
    required Widget leading,
    required String title,
    required String subtitle,
    required List<_BadgeData> badges,
    required VoidCallback onTap,
    String? description,
    String? metaText,
    Widget? action,
    Widget? footer,
  }) {
    final borderColor = id == widget.initialTargetId
        ? _accentColor
        : AdminPalette.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AdminSurface(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            radius: 20,
            border: Border.all(
              color: borderColor,
              width: id == widget.initialTargetId ? 1.4 : 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
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
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AdminPalette.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    action ??
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AdminPalette.textMuted,
                        ),
                  ],
                ),
                if ((description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AdminPalette.textSecondary,
                    ),
                  ),
                ],
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges
                        .map((badge) => _statusBadge(badge.label, badge.color))
                        .toList(),
                  ),
                ],
                if ((metaText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    metaText!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AdminPalette.textMuted,
                    ),
                  ),
                ],
                if (footer != null) ...[const SizedBox(height: 12), footer],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveActionGroup(List<Widget> buttons) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (buttons.isEmpty) {
          return const SizedBox.shrink();
        }

        if (buttons.length == 1) {
          return SizedBox(width: double.infinity, child: buttons.first);
        }

        if (constraints.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                buttons[index],
                if (index < buttons.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < buttons.length; index++) ...[
              Expanded(child: buttons[index]),
              if (index < buttons.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildMapListTile({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<_BadgeData> badges,
    required VoidCallback onTap,
    Widget? trailing,
    Widget? footer,
  }) {
    return _buildContentCard(
      id: id,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: title,
      subtitle: subtitle,
      badges: badges,
      onTap: onTap,
      action: trailing,
      footer: footer,
    );
  }

  Widget _buildTrainingListTile(TrainingModel training) {
    return _buildMapListTile(
      id: training.id,
      icon: Icons.cast_for_education_outlined,
      iconColor: Colors.cyan,
      title: training.title,
      subtitle: training.provider.isNotEmpty
          ? training.provider
          : 'Unknown provider',
      badges: [
        if (training.domain.isNotEmpty)
          _BadgeData(training.domain, Colors.cyan),
        if (training.level.isNotEmpty)
          _BadgeData(training.level, Colors.indigo),
        _BadgeData(training.type, Colors.teal),
        if (training.isFeatured) _BadgeData('featured', _accentColor),
      ],
      onTap: () => _showTrainingDetails(training),
    );
  }

  void _showProjectIdeaDetails(ProjectIdeaModel idea) {
    final submitterLabel = idea.submittedByName.trim().isNotEmpty
        ? idea.submittedByName
        : idea.submittedBy;

    _showContentDetailsSheet(
      title: idea.title,
      subtitle: 'Submitted by $submitterLabel',
      description: idea.description,
      detailLines: [
        _SheetDetailLine('Domain', idea.domain),
        _SheetDetailLine('Level', idea.level),
        _SheetDetailLine('Tools', idea.tools),
        _SheetDetailLine('Status', idea.status),
        _SheetDetailLine('Submitted', _formatTimestamp(idea.createdAt)),
      ],
    );
  }

  void _showApplicationDetails(AdminApplicationItemModel item) {
    _showContentDetailsSheet(
      title: item.studentName,
      subtitle: item.companyName.isNotEmpty ? item.companyName : 'Application',
      description: item.opportunityTitle.isNotEmpty
          ? 'Applied to ${item.opportunityTitle}.'
          : 'Application details',
      detailLines: [
        _SheetDetailLine('Opportunity', item.opportunityTitle),
        _SheetDetailLine('Company', item.companyName),
        _SheetDetailLine('Status', item.status),
        _SheetDetailLine('Applied', _formatTimestamp(item.appliedAt)),
      ],
      actionLabel: 'View CV',
      onAction: () {
        Navigator.pop(context);
        _showApplicationCv(item.application.id);
      },
    );
  }

  Future<void> _showApplicationCv(String applicationId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<CvModel?>(
          future: _companyService.getApplicationCv(applicationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _documentErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final cv = snapshot.data;
            if (cv == null) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Text('No CV available for this application'),
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              minChildSize: 0.3,
              expand: false,
              builder: (_, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      cv.fullName.isNotEmpty ? cv.fullName : 'Applicant',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (cv.email.isNotEmpty)
                      Text(
                        cv.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    if (cv.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cv.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildApplicationDocumentCard(
                      title: 'Primary CV PDF',
                      subtitle: cv.hasUploadedCv
                          ? 'File: ${cv.uploadedCvDisplayName}\nUploaded: ${_formatDocumentDate(cv.uploadedCvUploadedAt)}'
                          : 'No CV uploaded',
                      accentColor: _accentColor,
                      warningText: cv.hasUploadedCv && !cv.isUploadedCvPdf
                          ? 'This uploaded file is not a valid PDF. Ask the user to replace it with a PDF version.'
                          : null,
                      onView: cv.hasUploadedCv && cv.isUploadedCvPdf
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'primary',
                              requirePdf: true,
                            )
                          : null,
                      onDownload: cv.hasUploadedCv
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'primary',
                              download: true,
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildApplicationDocumentCard(
                      title: 'Built CV',
                      subtitle: cv.hasExportedPdf
                          ? 'Built CV PDF is ready for review.'
                          : cv.hasBuilderContent
                          ? 'Built CV information is available, but no PDF has been exported yet.'
                          : 'No built CV information available.',
                      accentColor: _primaryColor,
                      onView: cv.hasExportedPdf
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'built',
                              requirePdf: true,
                            )
                          : null,
                      onDownload: cv.hasExportedPdf
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'built',
                              download: true,
                            )
                          : null,
                    ),
                    if (cv.summary.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildCvSection('Summary', [cv.summary]),
                    ],
                    if (cv.education.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildCvSection(
                        'Education',
                        cv.education
                            .map(
                              (item) =>
                                  '${item['degree'] ?? ''} - ${item['institution'] ?? ''} (${item['year'] ?? ''})',
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.experience.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildCvSection(
                        'Experience',
                        cv.experience
                            .map(
                              (item) =>
                                  '${item['position'] ?? item['title'] ?? ''} at ${item['company'] ?? ''} (${item['duration'] ?? ''})',
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.skills.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildTagSection('Skills', cv.skills, _accentColor),
                    ],
                    if (cv.languages.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildTagSection(
                        'Languages',
                        cv.languages,
                        _primaryColor,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openApplicationDocument(
    String applicationId, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getApplicationCvDocument(
        applicationId: applicationId,
        variant: variant,
      );

      if (requirePdf && !document.isPdf) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('This document is not a valid PDF file.'),
          ),
        );
        return;
      }

      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  Widget _buildApplicationDocumentCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onView,
    VoidCallback? onDownload,
    String? warningText,
  }) {
    final hasActions = onView != null || onDownload != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 10),
            Text(
              warningText,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasActions) ...[
            const SizedBox(height: 12),
            _buildResponsiveActionGroup([
              if (onView != null)
                FilledButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View CV'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              if (onDownload != null)
                OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download CV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
            ]),
          ],
        ],
      ),
    );
  }

  String _formatDocumentDate(Timestamp? value) {
    if (value == null) {
      return 'Not available';
    }

    return DateFormat('MMM d, yyyy').format(value.toDate());
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }

    return 'Could not open the document right now.';
  }

  void _showOpportunityDetails(Map<String, dynamic> opportunity) {
    final provider = context.read<AdminProvider>();
    final opportunityId = (opportunity['id'] ?? '').toString();
    final applications = _applicationsForOpportunity(provider, opportunityId);
    final opportunityModel = OpportunityModel.fromMap(opportunity);
    final compensationLabel = OpportunityMetadata.buildCompensationLabel(
      salaryMin: opportunityModel.salaryMin,
      salaryMax: opportunityModel.salaryMax,
      salaryCurrency: opportunityModel.salaryCurrency,
      salaryPeriod: opportunityModel.salaryPeriod,
      compensationText: opportunityModel.compensationText,
      isPaid: opportunityModel.isPaid,
      preferCompensationText: true,
    );
    _showContentDetailsSheet(
      title: (opportunity['title'] ?? 'Opportunity').toString(),
      subtitle: (opportunity['companyName'] ?? 'Unknown company').toString(),
      description: (opportunity['description'] ?? '').toString(),
      detailLines: [
        _SheetDetailLine(
          'Type',
          OpportunityType.label(
            OpportunityType.parse((opportunity['type'] ?? '').toString()),
          ),
        ),
        _SheetDetailLine('Status', (opportunity['status'] ?? '').toString()),
        _SheetDetailLine(
          'Location',
          (opportunity['location'] ?? '').toString(),
        ),
        _SheetDetailLine('Deadline', opportunityModel.deadlineLabel),
        _SheetDetailLine('Compensation', compensationLabel ?? ''),
        _SheetDetailLine(
          'Employment type',
          OpportunityMetadata.formatEmploymentType(
                opportunityModel.employmentType,
              ) ??
              '',
        ),
        _SheetDetailLine(
          'Work mode',
          OpportunityMetadata.formatWorkMode(opportunityModel.workMode) ?? '',
        ),
        _SheetDetailLine(
          'Paid status',
          OpportunityMetadata.formatPaidLabel(opportunityModel.isPaid) ?? '',
        ),
        _SheetDetailLine('Duration', opportunityModel.duration ?? ''),
        _SheetDetailLine(
          'Requirements',
          (opportunity['requirements'] ?? '').toString(),
        ),
        _SheetDetailLine(
          'Applications',
          '${applications.length} application${applications.length == 1 ? '' : 's'}',
        ),
      ].where((line) => line.value.trim().isNotEmpty).toList(),
      actionLabel: applications.isEmpty
          ? null
          : 'View Applications (${applications.length})',
      onAction: applications.isEmpty
          ? null
          : () {
              Navigator.pop(context);
              _showOpportunityApplications(opportunity, applications);
            },
    );
  }

  void _showScholarshipDetails(Map<String, dynamic> scholarship) {
    _showContentDetailsSheet(
      title: (scholarship['title'] ?? 'Scholarship').toString(),
      subtitle: (scholarship['provider'] ?? 'Unknown provider').toString(),
      description: (scholarship['description'] ?? '').toString(),
      detailLines: [
        _SheetDetailLine(
          'Eligibility',
          (scholarship['eligibility'] ?? '').toString(),
        ),
        _SheetDetailLine('Amount', '${scholarship['amount'] ?? 0} DA'),
        _SheetDetailLine(
          'Deadline',
          (scholarship['deadline'] ?? '').toString(),
        ),
      ],
      actionLabel: (scholarship['link'] ?? '').toString().trim().isEmpty
          ? null
          : 'Open Link',
      onAction: () => _openExternalLink((scholarship['link'] ?? '').toString()),
    );
  }

  void _showTrainingDetails(TrainingModel training) {
    _showContentDetailsSheet(
      title: training.title,
      subtitle: training.provider.isNotEmpty ? training.provider : 'Training',
      description: training.description,
      detailLines: [
        _SheetDetailLine('Type', training.type),
        _SheetDetailLine('Source', training.source),
        _SheetDetailLine('Domain', training.domain),
        _SheetDetailLine('Level', training.level),
        _SheetDetailLine('Duration', training.duration),
      ],
      actionLabel: training.displayLink.trim().isEmpty ? null : 'Open Resource',
      onAction: () => _openExternalLink(training.displayLink),
    );
  }

  void _showContentDetailsSheet({
    required String title,
    required String subtitle,
    required String description,
    required List<_SheetDetailLine> detailLines,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final visibleDetails = detailLines
        .where((line) => line.value.trim().isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            AdminSurface(
              radius: 24,
              gradient: AdminPalette.heroGradient(_accentColor),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_mosaic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              AdminSurface(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (visibleDetails.isNotEmpty) ...[
              const SizedBox(height: 14),
              const AdminSectionHeader(
                eyebrow: 'Details',
                title: 'Item Metadata',
                subtitle:
                    'Important fields are grouped here in a more readable admin detail layout.',
              ),
              const SizedBox(height: 12),
              ...visibleDetails.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDetailLine(line.label, line.value),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildCvSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return AdminSurface(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.trim().isEmpty ? 'Not available' : value,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AdminPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return AdminEmptyState(
      icon: icon,
      title: 'Nothing to show here',
      message: message,
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) {
      return 'Unknown time';
    }

    final dateTime = value is DateTime
        ? value
        : value is Timestamp
        ? value.toDate()
        : null;
    if (dateTime == null) {
      return 'Unknown time';
    }

    return DateFormat('MMM d, yyyy - HH:mm').format(dateTime);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'accepted':
      case 'open':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'featured':
        return _accentColor;
      default:
        return Colors.orange;
    }
  }
}

class _BadgeData {
  final String label;
  final Color color;

  const _BadgeData(this.label, this.color);
}

class _SheetDetailLine {
  final String label;
  final String value;

  const _SheetDetailLine(this.label, this.value);
}

class _AdminTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _AdminTabBarHeaderDelegate({required this.child});

  @override
  double get minExtent => 68;

  @override
  double get maxExtent => 68;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _AdminTabBarHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
