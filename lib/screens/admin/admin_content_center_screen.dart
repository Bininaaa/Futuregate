import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/admin_application_item_model.dart';
import '../../models/cv_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/project_idea_model.dart';
import '../../models/scholarship_model.dart';
import '../../providers/auth_provider.dart';
import '../../models/training_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/company_service.dart';
import '../../services/document_access_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
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
  final int resetToken;

  const AdminContentCenterScreen({
    super.key,
    this.initialTab = projectIdeasTab,
    this.initialTargetId = '',
    this.embedded = false,
    this.resetToken = 0,
  });

  @override
  State<AdminContentCenterScreen> createState() =>
      _AdminContentCenterScreenState();
}

class _AdminContentCenterScreenState extends State<AdminContentCenterScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = AdminPalette.textPrimary;
  static const Color _accentColor = AdminPalette.primary;
  static const Color _ideaAccentColor = AdminPalette.warning;
  static const String _ideaFilterAll = 'all';
  static const String _ideaFilterPending = 'pending';
  static const String _ideaFilterApproved = 'approved';
  static const String _ideaFilterRejected = 'rejected';

  final CompanyService _companyService = CompanyService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _ideaStatusFilter = _ideaFilterAll;
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
      final provider = context.read<AdminProvider>();
      if (!provider.moderationInitialized || provider.moderationError != null) {
        provider.loadModerationData();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdminContentCenterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.embedded && widget.resetToken != oldWidget.resetToken) {
      _resetEmbeddedView();
    }
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
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hasModerationData =
        provider.allProjectIdeas.isNotEmpty ||
        provider.allApplications.isNotEmpty ||
        provider.allOpportunities.isNotEmpty ||
        provider.allScholarships.isNotEmpty ||
        provider.allTrainings.isNotEmpty;
    final waitingForInitialModerationLoad =
        !provider.moderationInitialized && !hasModerationData;
    final pendingIdeas = provider.allProjectIdeas
        .where(
          (idea) => _normalizedIdeaStatus(idea.status) == _ideaFilterPending,
        )
        .length;

    if (!provider.moderationLoading &&
        provider.moderationInitialized &&
        !_openedInitialTarget &&
        widget.initialTargetId.trim().isNotEmpty) {
      _openedInitialTarget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openInitialTarget(provider, widget.initialTargetId.trim());
      });
    }

    final content =
        provider.moderationLoading || waitingForInitialModerationLoad
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
              if (!keyboardVisible)
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    keyboardVisible ? 8 : 12,
                    16,
                    0,
                  ),
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      keyboardVisible ? 8 : 12,
                      16,
                      keyboardVisible ? 2 : 6,
                    ),
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
    final allIdeas = provider.allProjectIdeas.where(_matchesIdeaSearch).toList()
      ..sort(_compareIdeasForAdmin);
    final searchQuery = _searchController.text.trim();
    final totalPendingIdeasCount = provider.allProjectIdeas
        .where(
          (idea) => _normalizedIdeaStatus(idea.status) == _ideaFilterPending,
        )
        .length;
    final pendingIdeasCount = allIdeas
        .where(
          (idea) => _normalizedIdeaStatus(idea.status) == _ideaFilterPending,
        )
        .length;
    final approvedIdeasCount = allIdeas
        .where(
          (idea) => _normalizedIdeaStatus(idea.status) == _ideaFilterApproved,
        )
        .length;
    final rejectedIdeasCount = allIdeas
        .where(
          (idea) => _normalizedIdeaStatus(idea.status) == _ideaFilterRejected,
        )
        .length;
    final ideas = allIdeas
        .where((idea) => _matchesIdeaStatusFilter(idea, _ideaStatusFilter))
        .toList();
    final showResolvedFilters =
        _ideaStatusFilter == _ideaFilterAll ||
        _ideaStatusFilter == _ideaFilterApproved ||
        _ideaStatusFilter == _ideaFilterRejected;

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
            backgroundColor: _ideaAccentColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ideas.isEmpty ? 2 : ideas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  if (totalPendingIdeasCount > 0) ...[
                    _buildPendingIdeasWarning(totalPendingIdeasCount),
                    const SizedBox(height: 12),
                  ],
                  AdminSurface(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminSectionHeader(
                          eyebrow: 'Ideas',
                          title:
                              '${_ideaFilterTitle(_ideaStatusFilter)} (${ideas.length})',
                          subtitle: searchQuery.isEmpty
                              ? 'Review submitted ideas, keep the pending queue moving, and open details when you need the full picture.'
                              : 'Showing filtered results for "$searchQuery".',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AdminFilterChip(
                              label: 'All Ideas',
                              selected: _ideaStatusFilter == _ideaFilterAll,
                              icon: Icons.grid_view_rounded,
                              badgeCount: allIdeas.length,
                              onTap: _ideaStatusFilter != _ideaFilterAll
                                  ? () => setState(() {
                                      _ideaStatusFilter = _ideaFilterAll;
                                    })
                                  : null,
                            ),
                            AdminFilterChip(
                              label: 'Pending',
                              selected: _ideaStatusFilter == _ideaFilterPending,
                              icon: Icons.hourglass_top_rounded,
                              badgeCount: pendingIdeasCount,
                              onTap: _ideaStatusFilter != _ideaFilterPending
                                  ? () => setState(() {
                                      _ideaStatusFilter = _ideaFilterPending;
                                    })
                                  : null,
                            ),
                          ],
                        ),
                        if (showResolvedFilters) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AdminFilterChip(
                                label: 'Approved',
                                selected:
                                    _ideaStatusFilter == _ideaFilterApproved,
                                icon: Icons.check_circle_outline_rounded,
                                badgeCount: approvedIdeasCount,
                                onTap: _ideaStatusFilter != _ideaFilterApproved
                                    ? () => setState(() {
                                        _ideaStatusFilter = _ideaFilterApproved;
                                      })
                                    : null,
                              ),
                              AdminFilterChip(
                                label: 'Rejected',
                                selected:
                                    _ideaStatusFilter == _ideaFilterRejected,
                                icon: Icons.cancel_outlined,
                                badgeCount: rejectedIdeasCount,
                                onTap: _ideaStatusFilter != _ideaFilterRejected
                                    ? () => setState(() {
                                        _ideaStatusFilter = _ideaFilterRejected;
                                      })
                                    : null,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () => _openIdeaEditor(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Post Admin Idea'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _ideaAccentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          AdminPill(
                            label: 'Search: $searchQuery',
                            color: AdminPalette.textSecondary,
                            icon: Icons.search_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (ideas.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildEmptyState(
                Icons.search_off_outlined,
                _ideaEmptyMessage(_ideaStatusFilter),
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
            leading: _buildIdeaLeading(idea),
            title: _formatIdeaTitle(idea.title),
            subtitle:
                'By ${DisplayText.capitalizeLeadingLabel(submitterLabel)}',
            description: _formatIdeaDescription(idea.cardSummary),
            badges: [
              _BadgeData(
                _formatIdeaBadgeValue(idea.status),
                _statusColor(idea.status),
              ),
              _BadgeData(
                _formatIdeaBadgeValue(idea.displayCategory),
                AdminPalette.textSecondary,
              ),
            ],
            metaText: idea.lastUpdatedLabel,
            onTap: () => _showProjectIdeaDetails(idea),
            action: _buildCardActionRow([
              if (canEditIdea)
                _buildCompactCardAction(
                  icon: Icons.edit_outlined,
                  color: _ideaAccentColor,
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
            footer: _buildIdeaCardFooter(
              isIdeaBusy: isIdeaBusy,
              onViewDetails: () => _showProjectIdeaDetails(idea),
              onApprove:
                  _normalizedIdeaStatus(idea.status) == _ideaFilterPending
                  ? () async {
                      final error = await provider.updateProjectIdeaStatus(
                        idea.id,
                        'approved',
                      );
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    }
                  : null,
              onReject: _normalizedIdeaStatus(idea.status) == _ideaFilterPending
                  ? () async {
                      final error = await provider.updateProjectIdeaStatus(
                        idea.id,
                        'rejected',
                      );
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingIdeasWarning(int pendingCount) {
    return AdminSurface(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      color: const Color(0xFFFFF7E8),
      border: Border.all(color: _ideaAccentColor.withValues(alpha: 0.22)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _ideaAccentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: _ideaAccentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending ideas need review',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingCount idea${pendingCount == 1 ? '' : 's'} still waiting for approval or rejection.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _ideaStatusFilter == _ideaFilterPending
                ? null
                : () => setState(() {
                    _ideaStatusFilter = _ideaFilterPending;
                  }),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaLeading(ProjectIdeaModel idea) {
    final statusColor = _statusColor(idea.status);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _ideaAccentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.14)),
      ),
      child: Icon(Icons.lightbulb_outline_rounded, color: _ideaAccentColor),
    );
  }

  Widget _buildIdeaCardFooter({
    required bool isIdeaBusy,
    required VoidCallback onViewDetails,
    Future<void> Function()? onApprove,
    Future<void> Function()? onReject,
  }) {
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: onViewDetails,
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('Details'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ideaAccentColor,
          side: BorderSide(color: _ideaAccentColor.withValues(alpha: 0.28)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];

    if (onApprove != null) {
      actions.add(
        FilledButton.icon(
          onPressed: isIdeaBusy ? null : () => onApprove(),
          icon: const Icon(Icons.check, size: 18),
          label: Text(isIdeaBusy ? 'Working...' : 'Approve'),
          style: FilledButton.styleFrom(
            backgroundColor: AdminPalette.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (onReject != null) {
      actions.add(
        FilledButton.icon(
          onPressed: isIdeaBusy ? null : () => onReject(),
          icon: const Icon(Icons.close, size: 18),
          label: Text(isIdeaBusy ? 'Working...' : 'Reject'),
          style: FilledButton.styleFrom(
            backgroundColor: AdminPalette.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return _buildResponsiveActionGroup(actions);
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
    final opportunities =
        provider.allOpportunities.where(_matchesOpportunitySearch).toList()
          ..sort((first, second) {
            final firstModel = OpportunityModel.fromMap(first);
            final secondModel = OpportunityModel.fromMap(second);
            final firstIsOpen =
                firstModel.status.trim().toLowerCase() == 'open';
            final secondIsOpen =
                secondModel.status.trim().toLowerCase() == 'open';
            if (firstIsOpen != secondIsOpen) {
              return firstIsOpen ? -1 : 1;
            }

            if (firstModel.isFeatured != secondModel.isFeatured) {
              return firstModel.isFeatured ? -1 : 1;
            }

            final firstDeadline =
                firstModel.applicationDeadline ??
                OpportunityMetadata.parseDateTimeLike(firstModel.deadlineLabel);
            final secondDeadline =
                secondModel.applicationDeadline ??
                OpportunityMetadata.parseDateTimeLike(
                  secondModel.deadlineLabel,
                );
            if (firstDeadline != null && secondDeadline != null) {
              final comparison = firstDeadline.compareTo(secondDeadline);
              if (comparison != 0) {
                return comparison;
              }
            } else if (firstDeadline != null || secondDeadline != null) {
              return firstDeadline != null ? -1 : 1;
            }

            final firstTime =
                (firstModel.updatedAt ?? firstModel.createdAt)
                    ?.millisecondsSinceEpoch ??
                0;
            final secondTime =
                (secondModel.updatedAt ?? secondModel.createdAt)
                    ?.millisecondsSinceEpoch ??
                0;
            return secondTime.compareTo(firstTime);
          });

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
            final openCount = opportunities
                .where(
                  (item) =>
                      OpportunityModel.fromMap(
                        item,
                      ).status.trim().toLowerCase() ==
                      'open',
                )
                .length;
            final internshipCount = opportunities
                .where(
                  (item) =>
                      OpportunityType.parse((item['type'] ?? '').toString()) ==
                      OpportunityType.internship,
                )
                .length;
            final sponsoredCount = opportunities
                .where(
                  (item) =>
                      OpportunityType.parse((item['type'] ?? '').toString()) ==
                      OpportunityType.sponsoring,
                )
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCollectionOverviewCard(
                icon: Icons.work_outline_rounded,
                accentColor: AdminPalette.primary,
                title: 'Opportunity Queue',
                subtitle:
                    'Review jobs, internships, and sponsored posts with faster access to applications and edits.',
                highlights: [
                  _BadgeData(
                    '${opportunities.length} Visible',
                    AdminPalette.textSecondary,
                  ),
                  if (openCount > 0)
                    _BadgeData('$openCount Open', AdminPalette.success),
                  if (internshipCount > 0)
                    _BadgeData(
                      '$internshipCount Internships',
                      OpportunityType.color(OpportunityType.internship),
                    ),
                  if (sponsoredCount > 0)
                    _BadgeData(
                      '$sponsoredCount Sponsored',
                      OpportunityType.color(OpportunityType.sponsoring),
                    ),
                ],
                action: FilledButton.icon(
                  onPressed: () => _openOpportunityEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Post Opportunity'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
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
          final opportunityTypeColor = OpportunityType.color(opportunityType);
          final subtitle = _joinCardSubtitleParts([
            DisplayText.capitalizeLeadingLabel(
              opportunityModel.companyName.isNotEmpty
                  ? opportunityModel.companyName
                  : 'Unknown company',
            ),
            DisplayText.capitalizeLeadingLabel(opportunityModel.location),
          ]);
          final deadlineLabel = _formatDateBadgeLabel(
            opportunityModel.applicationDeadline ?? opportunityModel.deadline,
            prefix: 'Deadline',
          );
          return _buildMapListTile(
            id: opportunityId,
            icon: OpportunityType.icon(opportunityType),
            iconColor: opportunityTypeColor,
            title: DisplayText.capitalizeWords(
              (opportunity['title'] ?? 'No title').toString(),
            ),
            subtitle: subtitle,
            description: _cleanCardDescription(
              opportunityModel.description.isNotEmpty
                  ? opportunityModel.description
                  : opportunityModel.requirements,
              fallback:
                  'Open this post to review the full role, requirements, and moderation context.',
            ),
            badges: [
              if (isOwnedByAdmin)
                _BadgeData('Admin Post', AdminPalette.primary),
              _BadgeData(
                OpportunityType.label(opportunityType),
                opportunityTypeColor,
              ),
              _BadgeData(
                '${applications.length} Application${applications.length == 1 ? '' : 's'}',
                AdminPalette.activity,
              ),
              _BadgeData(
                DisplayText.capitalizeWords(
                  (opportunity['status'] ?? '').toString(),
                ),
                (opportunity['status'] ?? '') == 'open'
                    ? Colors.green
                    : Colors.grey,
              ),
              if (deadlineLabel != null)
                _BadgeData(deadlineLabel, AdminPalette.warning),
              ...metadata.map((item) => _BadgeData(item, AdminPalette.info)),
            ],
            onTap: () => _showOpportunityDetails(opportunity),
            metaText: _joinCardSubtitleParts([
              _buildDateMetaLabel(
                'Updated',
                opportunityModel.updatedAt ?? opportunityModel.createdAt,
              ),
              if (applications.isNotEmpty) '${applications.length} in review',
            ]),
            footer: _buildResponsiveActionGroup([
              OutlinedButton.icon(
                onPressed: () => _showOpportunityDetails(opportunity),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: opportunityTypeColor,
                  side: BorderSide(
                    color: opportunityTypeColor.withValues(alpha: 0.28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    _showOpportunityApplications(opportunity, applications),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: Text(
                  applications.isEmpty
                      ? 'Applications (0)'
                      : 'Applications (${applications.length})',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminPalette.activity,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ]),
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
    final scholarships =
        provider.allScholarships.where(_matchesScholarshipSearch).toList()
          ..sort((first, second) {
            final firstModel = ScholarshipModel.fromMap(first);
            final secondModel = ScholarshipModel.fromMap(second);
            if (firstModel.isFeatured != secondModel.isFeatured) {
              return firstModel.isFeatured ? -1 : 1;
            }

            final firstDeadline = OpportunityMetadata.parseDateTimeLike(
              firstModel.deadline,
            );
            final secondDeadline = OpportunityMetadata.parseDateTimeLike(
              secondModel.deadline,
            );
            if (firstDeadline != null && secondDeadline != null) {
              final comparison = firstDeadline.compareTo(secondDeadline);
              if (comparison != 0) {
                return comparison;
              }
            } else if (firstDeadline != null || secondDeadline != null) {
              return firstDeadline != null ? -1 : 1;
            }

            final firstTime = firstModel.createdAt?.millisecondsSinceEpoch ?? 0;
            final secondTime =
                secondModel.createdAt?.millisecondsSinceEpoch ?? 0;
            return secondTime.compareTo(firstTime);
          });

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
            final featuredCount = scholarships
                .where((item) => ScholarshipModel.fromMap(item).isFeatured)
                .length;
            final withDeadlineCount = scholarships
                .where(
                  (item) =>
                      OpportunityMetadata.parseDateTimeLike(
                        (item['deadline'] ?? '').toString(),
                      ) !=
                      null,
                )
                .length;
            final withFundingCount = scholarships
                .where(
                  (item) =>
                      ScholarshipModel.fromMap(item).amount > 0 ||
                      ScholarshipModel.fromMap(item).fundingType != null,
                )
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCollectionOverviewCard(
                icon: Icons.card_giftcard_rounded,
                accentColor: Colors.pink,
                title: 'Scholarship Listings',
                subtitle:
                    'Keep funding calls clear, trustworthy, and easy to scan before students open the full details.',
                highlights: [
                  _BadgeData(
                    '${scholarships.length} Visible',
                    AdminPalette.textSecondary,
                  ),
                  if (featuredCount > 0)
                    _BadgeData('$featuredCount Featured', _accentColor),
                  if (withDeadlineCount > 0)
                    _BadgeData(
                      '$withDeadlineCount With Deadline',
                      AdminPalette.warning,
                    ),
                  if (withFundingCount > 0)
                    _BadgeData('$withFundingCount With Funding', Colors.green),
                ],
                action: FilledButton.icon(
                  onPressed: () => _openScholarshipEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Post Scholarship'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            );
          }

          final scholarship = scholarships[index - 1];
          final scholarshipModel = ScholarshipModel.fromMap(scholarship);
          final amountText = _formatScholarshipAmount(
            scholarshipModel.amount,
            fallback: scholarshipModel.fundingType,
          );
          final locationText =
              scholarshipModel.location?.trim().isNotEmpty == true
              ? scholarshipModel.location!.trim()
              : _joinCardSubtitleParts([
                  scholarshipModel.city,
                  scholarshipModel.country,
                ]);
          final footerButtons = <Widget>[
            OutlinedButton.icon(
              onPressed: () => _showScholarshipDetails(scholarship),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.pink,
                side: BorderSide(color: Colors.pink.withValues(alpha: 0.28)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ];
          if (scholarshipModel.link.trim().isNotEmpty) {
            footerButtons.add(
              FilledButton.icon(
                onPressed: () => _openExternalLink(scholarshipModel.link),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open Link'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            );
          }
          return _buildMapListTile(
            id: scholarshipModel.id,
            icon: Icons.card_giftcard_rounded,
            iconColor: Colors.pink,
            title: DisplayText.capitalizeWords(
              scholarshipModel.title.isNotEmpty
                  ? scholarshipModel.title
                  : 'No title',
            ),
            subtitle: _joinCardSubtitleParts([
              DisplayText.capitalizeLeadingLabel(
                scholarshipModel.provider.isNotEmpty
                    ? scholarshipModel.provider
                    : 'Unknown provider',
              ),
              DisplayText.capitalizeLeadingLabel(locationText),
            ]),
            description: _cleanCardDescription(
              scholarshipModel.description.isNotEmpty
                  ? scholarshipModel.description
                  : scholarshipModel.eligibility,
              fallback:
                  'Open this scholarship to review the provider, eligibility, and access details.',
            ),
            badges: [
              if (amountText.isNotEmpty) _BadgeData(amountText, Colors.green),
              if ((scholarshipModel.fundingType ?? '').trim().isNotEmpty)
                _BadgeData(
                  DisplayText.capitalizeWords(scholarshipModel.fundingType!),
                  Colors.pink,
                ),
              if ((scholarshipModel.level ?? '').trim().isNotEmpty)
                _BadgeData(
                  DisplayText.capitalizeWords(scholarshipModel.level!),
                  AdminPalette.info,
                ),
              if (_formatDateBadgeLabel(
                    scholarshipModel.deadline,
                    prefix: 'Due',
                  ) !=
                  null)
                _BadgeData(
                  _formatDateBadgeLabel(
                    scholarshipModel.deadline,
                    prefix: 'Due',
                  )!,
                  AdminPalette.warning,
                ),
              if (scholarshipModel.isFeatured)
                _BadgeData('Featured', _accentColor),
            ],
            onTap: () => _showScholarshipDetails(scholarship),
            metaText: _joinCardSubtitleParts([
              _buildDateMetaLabel('Added', scholarshipModel.createdAt),
              if ((scholarshipModel.category ?? '').trim().isNotEmpty)
                DisplayText.capitalizeWords(scholarshipModel.category!),
            ]),
            footer: _buildResponsiveActionGroup(footerButtons),
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
    final trainings =
        provider.allTrainings.where(_matchesTrainingSearch).toList()
          ..sort((first, second) {
            if (first.isApproved != second.isApproved) {
              return first.isApproved ? 1 : -1;
            }
            if (first.isFeatured != second.isFeatured) {
              return first.isFeatured ? -1 : 1;
            }
            final firstTime = first.createdAt?.millisecondsSinceEpoch ?? 0;
            final secondTime = second.createdAt?.millisecondsSinceEpoch ?? 0;
            return secondTime.compareTo(firstTime);
          });

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
        itemCount: trainings.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final pendingCount = trainings
                .where((training) => !training.isApproved)
                .length;
            final featuredCount = trainings
                .where((training) => training.isFeatured)
                .length;
            final freeCount = trainings
                .where((training) => training.isFree == true)
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCollectionOverviewCard(
                icon: Icons.cast_for_education_outlined,
                accentColor: Colors.cyan,
                title: 'Training Library',
                subtitle:
                    'Review learning resources, spot pending items quickly, and open the right material without leaving the queue.',
                highlights: [
                  _BadgeData(
                    '${trainings.length} Visible',
                    AdminPalette.textSecondary,
                  ),
                  if (pendingCount > 0)
                    _BadgeData(
                      '$pendingCount Pending Review',
                      AdminPalette.warning,
                    ),
                  if (featuredCount > 0)
                    _BadgeData('$featuredCount Featured', _accentColor),
                  if (freeCount > 0)
                    _BadgeData('$freeCount Free', AdminPalette.success),
                ],
              ),
            );
          }
          final training = trainings[index - 1];
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

  bool _matchesIdeaStatusFilter(ProjectIdeaModel idea, String filter) {
    if (filter == _ideaFilterAll) {
      return true;
    }

    return _normalizedIdeaStatus(idea.status) == filter;
  }

  String _normalizedIdeaStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case _ideaFilterPending:
        return _ideaFilterPending;
      case _ideaFilterApproved:
        return _ideaFilterApproved;
      case _ideaFilterRejected:
        return _ideaFilterRejected;
      default:
        return _ideaFilterAll;
    }
  }

  String _ideaFilterTitle(String filter) {
    switch (filter) {
      case _ideaFilterPending:
        return 'Pending Ideas';
      case _ideaFilterApproved:
        return 'Approved Ideas';
      case _ideaFilterRejected:
        return 'Rejected Ideas';
      default:
        return 'All Ideas';
    }
  }

  String _ideaEmptyMessage(String filter) {
    switch (filter) {
      case _ideaFilterPending:
        return 'No pending ideas match your search';
      case _ideaFilterApproved:
        return 'No approved ideas match your search';
      case _ideaFilterRejected:
        return 'No rejected ideas match your search';
      default:
        return 'No ideas match your search';
    }
  }

  String _formatIdeaTitle(String text) {
    return DisplayText.capitalizeWords(text);
  }

  String _formatIdeaDescription(String text) {
    return DisplayText.capitalizeLeadingLabel(text);
  }

  String _formatIdeaBadgeValue(String text) {
    return DisplayText.capitalizeWords(text);
  }

  int _compareIdeasForAdmin(ProjectIdeaModel a, ProjectIdeaModel b) {
    final statusComparison = _ideaStatusRank(
      a.status,
    ).compareTo(_ideaStatusRank(b.status));
    if (statusComparison != 0) {
      return statusComparison;
    }

    final aTime = (a.updatedAt ?? a.createdAt)?.millisecondsSinceEpoch ?? 0;
    final bTime = (b.updatedAt ?? b.createdAt)?.millisecondsSinceEpoch ?? 0;

    return bTime.compareTo(aTime);
  }

  int _ideaStatusRank(String status) {
    switch (_normalizedIdeaStatus(status)) {
      case _ideaFilterPending:
        return 0;
      case _ideaFilterApproved:
        return 1;
      case _ideaFilterRejected:
        return 2;
      default:
        return 3;
    }
  }

  void _resetEmbeddedView() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _ideaStatusFilter = _ideaFilterAll;
    _openedInitialTarget = false;
    if (_tabController.index != AdminContentCenterScreen.projectIdeasTab) {
      _tabController.index = AdminContentCenterScreen.projectIdeasTab;
    }
    if (mounted) {
      setState(() {});
    }
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
            padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
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
                              fontSize: 14.5,
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
                                fontSize: 11.8,
                                fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 10),
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
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AdminPalette.border.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  footer,
                ],
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
    String? description,
    String? metaText,
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
          border: Border.all(color: iconColor.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: title,
      subtitle: subtitle,
      description: description,
      badges: badges,
      onTap: onTap,
      metaText: metaText,
      action: trailing,
      footer: footer,
    );
  }

  Widget _buildTrainingListTile(TrainingModel training) {
    final statusColor = training.isApproved
        ? AdminPalette.success
        : AdminPalette.warning;
    final statusLabel = training.isApproved ? 'Approved' : 'Pending Review';
    final levelLabel = DisplayText.capitalizeWords(training.level);
    final providerLabel = DisplayText.capitalizeLeadingLabel(
      training.provider.isNotEmpty ? training.provider : 'Unknown provider',
    );
    final domainLabel = DisplayText.capitalizeLeadingLabel(training.domain);
    final footerButtons = <Widget>[
      OutlinedButton.icon(
        onPressed: () => _showTrainingDetails(training),
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('Details'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.cyan,
          side: BorderSide(color: Colors.cyan.withValues(alpha: 0.28)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];
    if (training.displayLink.trim().isNotEmpty) {
      footerButtons.add(
        FilledButton.icon(
          onPressed: () => _openExternalLink(training.displayLink),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Open Resource'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return _buildMapListTile(
      id: training.id,
      icon: _trainingIcon(training.type),
      iconColor: Colors.cyan,
      title: DisplayText.capitalizeWords(training.title),
      subtitle: _joinCardSubtitleParts([providerLabel, domainLabel]),
      description: _cleanCardDescription(
        training.description,
        fallback:
            'Open this resource to review the learning summary, metadata, and delivery details.',
      ),
      badges: [
        _BadgeData(statusLabel, statusColor),
        _BadgeData(DisplayText.capitalizeWords(training.type), Colors.teal),
        if (levelLabel.trim().isNotEmpty)
          _BadgeData(levelLabel, AdminPalette.info),
        if (training.isFree == true) _BadgeData('Free', AdminPalette.success),
        if (training.hasCertificate == true)
          _BadgeData('Certificate', AdminPalette.activity),
        if (training.isFeatured) _BadgeData('Featured', _accentColor),
      ],
      onTap: () => _showTrainingDetails(training),
      metaText: _joinCardSubtitleParts([
        _buildDateMetaLabel('Added', training.createdAt),
        if (training.learnerCountLabel.trim().isNotEmpty)
          '${training.learnerCountLabel.trim()} learners',
      ]),
      footer: _buildResponsiveActionGroup(footerButtons),
    );
  }

  Widget _buildCollectionOverviewCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required List<_BadgeData> highlights,
    Widget? action,
  }) {
    return AdminSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
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
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: highlights
                  .map((badge) => _statusBadge(badge.label, badge.color))
                  .toList(),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }

  String _joinCardSubtitleParts(Iterable<String?> parts) {
    final visibleParts = parts
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return visibleParts.join(' • ');
  }

  String _cleanCardDescription(String text, {required String fallback}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return fallback;
    }
    return DisplayText.capitalizeLeadingLabel(normalized);
  }

  String _buildDateMetaLabel(String prefix, dynamic value) {
    final dateLabel = _formatShortDate(value);
    if (dateLabel.isEmpty) {
      return '';
    }
    return '$prefix $dateLabel';
  }

  String _formatShortDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final dateTime = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    if (dateTime == null) {
      return '';
    }

    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  String? _formatDateBadgeLabel(dynamic value, {String prefix = 'Due'}) {
    if (value == null) {
      return null;
    }

    DateTime? dateTime;
    String fallback = '';
    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    } else {
      fallback = value.toString().trim();
      dateTime = OpportunityMetadata.parseDateTimeLike(fallback);
    }

    if (dateTime != null) {
      return '$prefix ${DateFormat('MMM d').format(dateTime)}';
    }

    if (fallback.isEmpty) {
      return null;
    }

    return '$prefix ${DisplayText.capitalizeLeadingLabel(fallback)}';
  }

  String _formatScholarshipAmount(num amount, {String? fallback}) {
    if (amount <= 0) {
      return fallback?.trim() ?? '';
    }

    final isWholeNumber = amount is int || amount == amount.roundToDouble();
    final formatter = NumberFormat(isWholeNumber ? '#,##0' : '#,##0.##');
    return '${formatter.format(amount)} DA';
  }

  IconData _trainingIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'video':
        return Icons.ondemand_video_outlined;
      case 'file':
        return Icons.description_outlined;
      case 'course':
        return Icons.school_outlined;
      default:
        return Icons.cast_for_education_outlined;
    }
  }

  void _showProjectIdeaDetails(ProjectIdeaModel idea) {
    final submitterLabel = idea.submittedByName.trim().isNotEmpty
        ? idea.submittedByName
        : idea.submittedBy;
    final title = _formatIdeaTitle(idea.title);
    final subtitle =
        'Submitted By ${DisplayText.capitalizeLeadingLabel(submitterLabel)}';
    final summary = _formatIdeaDescription(idea.featuredSummary);
    final tagline = _formatIdeaDescription(idea.tagline);
    final targetAudience = _formatIdeaDescription(idea.targetAudience);
    final problemText = _formatIdeaDescription(idea.problemText);
    final solutionText = _formatIdeaDescription(idea.solutionText);
    final benefitsText = _formatIdeaDescription(idea.impactText);
    final statusColor = _statusColor(idea.status);
    final skills = idea.displaySkills
        .map(_formatIdeaBadgeValue)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final teamNeeded = idea.displayTeamNeeded
        .map(_formatIdeaBadgeValue)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final tags = idea.tags
        .map(_formatIdeaBadgeValue)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final canEditIdea =
        (context.read<AuthProvider>().userModel?.uid.trim() ?? '') ==
        idea.submittedBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            AdminSurface(
              radius: 24,
              gradient: AdminPalette.heroGradient(_ideaAccentColor),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.white,
                    size: 30,
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
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AdminActionChip(
                        label: _formatIdeaBadgeValue(idea.status),
                        icon: _ideaStatusIcon(idea.status),
                        color: Colors.white,
                      ),
                      AdminActionChip(
                        label: _formatIdeaBadgeValue(idea.displayCategory),
                        icon: Icons.category_outlined,
                        color: Colors.white,
                      ),
                      AdminActionChip(
                        label: _formatIdeaBadgeValue(idea.displayStage),
                        icon: Icons.timeline_outlined,
                        color: Colors.white,
                      ),
                      AdminActionChip(
                        label: idea.isPublic ? 'Public' : 'Private',
                        icon: idea.isPublic
                            ? Icons.public_rounded
                            : Icons.lock_outline_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildIdeaHighlightsSection(idea, statusColor: statusColor),
            if (summary.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              AdminSurface(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 13.2,
                        height: 1.6,
                        color: AdminPalette.textSecondary,
                      ),
                    ),
                    if (tagline.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _ideaAccentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tagline,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: _ideaAccentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (problemText.trim().isNotEmpty ||
                solutionText.trim().isNotEmpty ||
                benefitsText.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              const AdminSectionHeader(
                eyebrow: 'Build Story',
                title: 'Problem, Solution, And Impact',
                subtitle:
                    'This section shows what the idea is solving, how it works, and the value it aims to create.',
              ),
              const SizedBox(height: 12),
              if (problemText.trim().isNotEmpty) ...[
                _buildIdeaNarrativeCard(
                  title: 'Problem Statement',
                  value: problemText,
                  icon: Icons.report_problem_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 10),
              ],
              if (solutionText.trim().isNotEmpty) ...[
                _buildIdeaNarrativeCard(
                  title: 'Proposed Solution',
                  value: solutionText,
                  icon: Icons.auto_fix_high_outlined,
                  color: _ideaAccentColor,
                ),
                const SizedBox(height: 10),
              ],
              if (benefitsText.trim().isNotEmpty)
                _buildIdeaNarrativeCard(
                  title: 'Expected Benefits',
                  value: benefitsText,
                  icon: Icons.trending_up_rounded,
                  color: AdminPalette.success,
                ),
            ],
            const SizedBox(height: 14),
            const AdminSectionHeader(
              eyebrow: 'Positioning',
              title: 'Audience And Metadata',
              subtitle:
                  'These fields help you judge where the idea fits and how ready it is for review.',
            ),
            const SizedBox(height: 12),
            _buildIdeaMetadataGrid(<_IdeaDetailItem>[
              _IdeaDetailItem(
                'Category',
                _formatIdeaBadgeValue(idea.displayCategory),
                icon: Icons.category_outlined,
                color: AdminPalette.info,
              ),
              _IdeaDetailItem(
                'Stage',
                _formatIdeaBadgeValue(idea.displayStage),
                icon: Icons.timeline_outlined,
                color: AdminPalette.activity,
              ),
              _IdeaDetailItem(
                'Level',
                _formatIdeaBadgeValue(idea.level),
                icon: Icons.school_outlined,
                color: AdminPalette.primary,
              ),
              _IdeaDetailItem(
                'Status',
                _formatIdeaBadgeValue(idea.status),
                icon: _ideaStatusIcon(idea.status),
                color: statusColor,
              ),
              _IdeaDetailItem(
                'Audience',
                targetAudience,
                icon: Icons.groups_2_outlined,
                color: AdminPalette.secondary,
              ),
              _IdeaDetailItem(
                'Visibility',
                idea.isPublic ? 'Public Idea' : 'Private Idea',
                icon: idea.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_outline_rounded,
                color: idea.isPublic
                    ? AdminPalette.success
                    : AdminPalette.textMuted,
              ),
              _IdeaDetailItem(
                'Submitted',
                _formatTimestamp(idea.createdAt),
                icon: Icons.event_outlined,
                color: AdminPalette.textMuted,
              ),
              _IdeaDetailItem(
                'Last Updated',
                idea.lastUpdatedLabel,
                icon: Icons.update_rounded,
                color: _ideaAccentColor,
              ),
            ]),
            if (skills.isNotEmpty ||
                teamNeeded.isNotEmpty ||
                tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              AdminSurface(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionHeader(
                      eyebrow: 'Collaboration',
                      title: 'Team And Skill Signals',
                      subtitle:
                          'Use these tags to understand what support the idea needs next.',
                    ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTagSection(
                        'Skills Needed',
                        skills,
                        _ideaAccentColor,
                      ),
                    ],
                    if (teamNeeded.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTagSection(
                        'Team Needed',
                        teamNeeded,
                        AdminPalette.info,
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTagSection('Tags', tags, AdminPalette.activity),
                    ],
                  ],
                ),
              ),
            ],
            if (canEditIdea) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openIdeaEditor(idea: idea);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Idea'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ideaAccentColor,
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

  Widget _buildIdeaHighlightsSection(
    ProjectIdeaModel idea, {
    required Color statusColor,
  }) {
    final highlightItems = <_IdeaHighlightItem>[
      _IdeaHighlightItem(
        icon: _ideaStatusIcon(idea.status),
        label: 'Status',
        value: _formatIdeaBadgeValue(idea.status),
        color: statusColor,
      ),
      _IdeaHighlightItem(
        icon: Icons.bolt_rounded,
        label: 'Sparks',
        value: '${idea.sparksCount}',
        color: _ideaAccentColor,
      ),
      _IdeaHighlightItem(
        icon: Icons.groups_rounded,
        label: 'Interested',
        value: '${idea.interestedCount}',
        color: AdminPalette.info,
      ),
      _IdeaHighlightItem(
        icon: Icons.remove_red_eye_outlined,
        label: 'Views',
        value: '${idea.viewsCount}',
        color: AdminPalette.activity,
      ),
    ];

    return _buildDetailHighlightsGrid(highlightItems);
  }

  Widget _buildDetailHighlightsGrid(List<_IdeaHighlightItem> highlightItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 320 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: highlightItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) {
            final item = highlightItems[index];
            return _buildIdeaHighlightCard(item);
          },
        );
      },
    );
  }

  Widget _buildIdeaHighlightCard(_IdeaHighlightItem item) {
    return AdminSurface(
      radius: 18,
      color: AdminPalette.surfaceMuted,
      boxShadow: const [],
      border: Border.all(color: item.color.withValues(alpha: 0.14)),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaNarrativeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AdminSurface(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.2,
              height: 1.6,
              color: AdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final visibleItems = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdminSurface(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    if ((subtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminPalette.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...visibleItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visibleItems.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13.2,
                        height: 1.55,
                        color: AdminPalette.textSecondary,
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

  Widget _buildDetailHeroCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    List<Widget> chips = const [],
  }) {
    return AdminSurface(
      radius: 24,
      gradient: AdminPalette.heroGradient(accentColor),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
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
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }

  Widget _buildIdeaMetadataGrid(List<_IdeaDetailItem> items) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 320 ? 1 : 2;
        final mainAxisExtent = crossAxisCount == 1 ? 104.0 : 120.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return _buildIdeaMetadataCard(item);
          },
        );
      },
    );
  }

  Widget _buildIdeaMetadataCard(_IdeaDetailItem item) {
    return AdminSurface(
      radius: 18,
      color: AdminPalette.surfaceMuted,
      boxShadow: const [],
      border: Border.all(color: item.color.withValues(alpha: 0.12)),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                item.value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.4,
                  height: 1.45,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _ideaStatusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'open':
        return Icons.lock_open_rounded;
      case 'featured':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
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
    final opportunityType = OpportunityType.parse(
      (opportunity['type'] ?? '').toString(),
    );
    final typeLabel = OpportunityType.label(opportunityType);
    final typeColor = OpportunityType.color(opportunityType);
    final description = DisplayText.capitalizeLeadingLabel(
      opportunityModel.description,
    );
    final workModeLabel =
        OpportunityMetadata.formatWorkMode(opportunityModel.workMode) ?? '';
    final employmentLabel =
        OpportunityMetadata.formatEmploymentType(
          opportunityModel.employmentType,
        ) ??
        '';
    final paidLabel =
        OpportunityMetadata.formatPaidLabel(opportunityModel.isPaid) ?? '';
    final statusLabel = DisplayText.capitalizeLeadingLabel(
      opportunityModel.status,
    );
    final compensationLabel = OpportunityMetadata.buildCompensationLabel(
      salaryMin: opportunityModel.salaryMin,
      salaryMax: opportunityModel.salaryMax,
      salaryCurrency: opportunityModel.salaryCurrency,
      salaryPeriod: opportunityModel.salaryPeriod,
      compensationText: opportunityModel.compensationText,
      isPaid: opportunityModel.isPaid,
      preferCompensationText: true,
    );
    final requirements =
        (opportunityModel.requirementItems.isNotEmpty
                ? opportunityModel.requirementItems
                : <String>[opportunityModel.requirements])
            .map(DisplayText.capitalizeLeadingLabel)
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
    final benefits = opportunityModel.benefits
        .map(DisplayText.capitalizeLeadingLabel)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final tags = opportunityModel.tags
        .map(DisplayText.capitalizeWords)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            _buildDetailHeroCard(
              title: (opportunity['title'] ?? 'Opportunity').toString(),
              subtitle: (opportunity['companyName'] ?? 'Unknown company')
                  .toString(),
              icon: Icons.work_outline_rounded,
              accentColor: typeColor,
              chips: [
                AdminActionChip(
                  label: typeLabel,
                  icon: Icons.work_history_outlined,
                  color: Colors.white,
                ),
                AdminActionChip(
                  label: statusLabel,
                  icon: _ideaStatusIcon(opportunityModel.status),
                  color: Colors.white,
                ),
                if (workModeLabel.isNotEmpty)
                  AdminActionChip(
                    label: workModeLabel,
                    icon: Icons.lan_outlined,
                    color: Colors.white,
                  ),
                if (opportunityModel.isFeatured)
                  const AdminActionChip(
                    label: 'Featured',
                    icon: Icons.workspace_premium_outlined,
                    color: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailHighlightsGrid([
              _IdeaHighlightItem(
                icon: Icons.assignment_outlined,
                label: 'Applications',
                value: '${applications.length}',
                color: AdminPalette.activity,
              ),
              if (opportunityModel.deadlineLabel.trim().isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.event_outlined,
                  label: 'Deadline',
                  value: opportunityModel.deadlineLabel,
                  color: _accentColor,
                ),
              if ((compensationLabel ?? '').trim().isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.payments_outlined,
                  label: 'Compensation',
                  value: compensationLabel!,
                  color: AdminPalette.success,
                ),
              _IdeaHighlightItem(
                icon: Icons.badge_outlined,
                label: 'Work Setup',
                value: workModeLabel.isNotEmpty
                    ? workModeLabel
                    : employmentLabel.isNotEmpty
                    ? employmentLabel
                    : typeLabel,
                color: typeColor,
              ),
            ]),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildIdeaNarrativeCard(
                title: 'Role Overview',
                value: description,
                icon: Icons.description_outlined,
                color: typeColor,
              ),
            ],
            const SizedBox(height: 14),
            const AdminSectionHeader(
              eyebrow: 'Role Setup',
              title: 'Location And Logistics',
              subtitle:
                  'These details help you evaluate how the opportunity is positioned for applicants.',
            ),
            const SizedBox(height: 12),
            _buildIdeaMetadataGrid([
              _IdeaDetailItem(
                'Company',
                opportunityModel.companyName,
                icon: Icons.business_outlined,
                color: typeColor,
              ),
              _IdeaDetailItem(
                'Location',
                opportunityModel.location,
                icon: Icons.location_on_outlined,
                color: AdminPalette.info,
              ),
              _IdeaDetailItem(
                'Type',
                typeLabel,
                icon: Icons.work_outline_rounded,
                color: typeColor,
              ),
              _IdeaDetailItem(
                'Status',
                statusLabel,
                icon: _ideaStatusIcon(opportunityModel.status),
                color: _statusColor(opportunityModel.status),
              ),
              _IdeaDetailItem(
                'Employment',
                employmentLabel,
                icon: Icons.badge_outlined,
                color: AdminPalette.primary,
              ),
              _IdeaDetailItem(
                'Work Mode',
                workModeLabel,
                icon: Icons.lan_outlined,
                color: AdminPalette.secondary,
              ),
              _IdeaDetailItem(
                'Paid Status',
                paidLabel,
                icon: Icons.account_balance_wallet_outlined,
                color: AdminPalette.success,
              ),
              _IdeaDetailItem(
                'Duration',
                opportunityModel.duration ?? '',
                icon: Icons.schedule_outlined,
                color: AdminPalette.textMuted,
              ),
              _IdeaDetailItem(
                'Deadline',
                opportunityModel.deadlineLabel,
                icon: Icons.event_outlined,
                color: _accentColor,
              ),
              _IdeaDetailItem(
                'Compensation',
                compensationLabel ?? '',
                icon: Icons.payments_outlined,
                color: AdminPalette.success,
              ),
            ]),
            if (requirements.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildDetailListCard(
                title: 'Requirements',
                subtitle:
                    'These are the main qualifications or expectations shown to applicants.',
                items: requirements,
                icon: Icons.checklist_rounded,
                color: typeColor,
              ),
            ],
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildDetailListCard(
                title: 'Benefits',
                subtitle:
                    'This gives the admin view of what makes the role attractive.',
                items: benefits,
                icon: Icons.star_outline_rounded,
                color: AdminPalette.success,
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              AdminSurface(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTagSection('Opportunity Tags', tags, typeColor),
                  ],
                ),
              ),
            ],
            if (applications.isNotEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showOpportunityApplications(opportunity, applications);
                },
                icon: const Icon(Icons.assignment_outlined),
                label: Text('View Applications (${applications.length})'),
                style: FilledButton.styleFrom(
                  backgroundColor: typeColor,
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

  void _showScholarshipDetails(Map<String, dynamic> scholarship) {
    final title = (scholarship['title'] ?? 'Scholarship').toString();
    final providerName = (scholarship['provider'] ?? 'Unknown provider')
        .toString();
    final description = DisplayText.capitalizeLeadingLabel(
      (scholarship['description'] ?? '').toString(),
    );
    final eligibility = DisplayText.capitalizeLeadingLabel(
      (scholarship['eligibility'] ?? '').toString(),
    );
    final amountText = scholarship['amount'] == null
        ? ''
        : '${scholarship['amount']} DA';
    final deadlineText = (scholarship['deadline'] ?? '').toString();
    final categoryText =
        (scholarship['category'] ??
                scholarship['domain'] ??
                scholarship['field'] ??
                '')
            .toString();
    final levelText =
        (scholarship['level'] ??
                scholarship['academicLevel'] ??
                scholarship['studyLevel'] ??
                '')
            .toString();
    final locationText =
        (scholarship['location'] ??
                scholarship['country'] ??
                scholarship['destination'] ??
                '')
            .toString();
    final link = (scholarship['link'] ?? '').toString().trim();
    final tags = OpportunityMetadata.stringListFromValue(
      scholarship['tags'] ??
          scholarship['domains'] ??
          scholarship['categories'] ??
          scholarship['fields'],
      maxItems: 6,
    ).map(DisplayText.capitalizeWords).toList(growable: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            _buildDetailHeroCard(
              title: title,
              subtitle: providerName,
              icon: Icons.card_giftcard_rounded,
              accentColor: Colors.pink,
              chips: [
                if (amountText.isNotEmpty)
                  const AdminActionChip(
                    label: 'Funding',
                    icon: Icons.savings_outlined,
                    color: Colors.white,
                  ),
                if (deadlineText.trim().isNotEmpty)
                  const AdminActionChip(
                    label: 'Deadline Set',
                    icon: Icons.event_outlined,
                    color: Colors.white,
                  ),
                if (link.isNotEmpty)
                  const AdminActionChip(
                    label: 'External Link',
                    icon: Icons.open_in_new_rounded,
                    color: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailHighlightsGrid([
              if (amountText.isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.payments_outlined,
                  label: 'Amount',
                  value: amountText,
                  color: AdminPalette.success,
                ),
              if (deadlineText.trim().isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.event_outlined,
                  label: 'Deadline',
                  value: deadlineText,
                  color: Colors.pink,
                ),
              _IdeaHighlightItem(
                icon: Icons.business_outlined,
                label: 'Provider',
                value: providerName,
                color: Colors.pink,
              ),
              _IdeaHighlightItem(
                icon: link.isNotEmpty
                    ? Icons.link_rounded
                    : Icons.link_off_rounded,
                label: 'Access',
                value: link.isNotEmpty
                    ? 'Application Link Ready'
                    : 'No Link Yet',
                color: link.isNotEmpty
                    ? AdminPalette.info
                    : AdminPalette.textMuted,
              ),
            ]),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildIdeaNarrativeCard(
                title: 'Scholarship Overview',
                value: description,
                icon: Icons.description_outlined,
                color: Colors.pink,
              ),
            ],
            if (eligibility.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildIdeaNarrativeCard(
                title: 'Eligibility',
                value: eligibility,
                icon: Icons.verified_user_outlined,
                color: Colors.orange,
              ),
            ],
            const SizedBox(height: 14),
            const AdminSectionHeader(
              eyebrow: 'Scholarship Details',
              title: 'Provider And Access',
              subtitle:
                  'These details help you review where the scholarship fits and how students will reach it.',
            ),
            const SizedBox(height: 12),
            _buildIdeaMetadataGrid([
              _IdeaDetailItem(
                'Provider',
                providerName,
                icon: Icons.business_outlined,
                color: Colors.pink,
              ),
              _IdeaDetailItem(
                'Amount',
                amountText,
                icon: Icons.payments_outlined,
                color: AdminPalette.success,
              ),
              _IdeaDetailItem(
                'Deadline',
                deadlineText,
                icon: Icons.event_outlined,
                color: Colors.pink,
              ),
              _IdeaDetailItem(
                'Category',
                DisplayText.capitalizeWords(categoryText),
                icon: Icons.category_outlined,
                color: AdminPalette.info,
              ),
              _IdeaDetailItem(
                'Level',
                DisplayText.capitalizeWords(levelText),
                icon: Icons.school_outlined,
                color: AdminPalette.primary,
              ),
              _IdeaDetailItem(
                'Location',
                DisplayText.capitalizeLeadingLabel(locationText),
                icon: Icons.public_rounded,
                color: AdminPalette.secondary,
              ),
              _IdeaDetailItem(
                'Access',
                link.isNotEmpty
                    ? 'External Link Available'
                    : 'No Link Available',
                icon: link.isNotEmpty
                    ? Icons.open_in_new_rounded
                    : Icons.link_off_rounded,
                color: link.isNotEmpty
                    ? AdminPalette.info
                    : AdminPalette.textMuted,
              ),
            ]),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              AdminSurface(
                radius: 20,
                child: _buildTagSection('Scholarship Tags', tags, Colors.pink),
              ),
            ],
            if (link.isNotEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _openExternalLink(link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Scholarship Link'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pink,
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

  void _showTrainingDetails(TrainingModel training) {
    final description = DisplayText.capitalizeLeadingLabel(
      training.description,
    );
    final providerName = training.provider.isNotEmpty
        ? training.provider
        : 'Training';
    final typeLabel = DisplayText.capitalizeWords(training.type);
    final domainLabel = DisplayText.capitalizeWords(training.domain);
    final levelLabel = DisplayText.capitalizeWords(training.level);
    final sourceLabel = DisplayText.capitalizeWords(training.source);
    final accessLabel = training.isFree == null
        ? ''
        : training.isFree!
        ? 'Free'
        : 'Paid';
    final certificateLabel = training.hasCertificate == null
        ? ''
        : training.hasCertificate!
        ? 'Certificate Available'
        : 'No Certificate';
    final learnerLabel = training.learnerCountLabel.trim().isNotEmpty
        ? training.learnerCountLabel.trim()
        : training.learnerCount?.toString() ?? '';
    final ratingLabel = training.rating == null
        ? ''
        : training.rating!.toStringAsFixed(1);
    final authors = training.authors
        .map(DisplayText.capitalizeLeadingLabel)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final link = training.displayLink.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            _buildDetailHeroCard(
              title: training.title,
              subtitle: providerName,
              icon: Icons.cast_for_education_outlined,
              accentColor: Colors.cyan,
              chips: [
                AdminActionChip(
                  label: typeLabel,
                  icon: Icons.school_outlined,
                  color: Colors.white,
                ),
                if (domainLabel.isNotEmpty)
                  AdminActionChip(
                    label: domainLabel,
                    icon: Icons.category_outlined,
                    color: Colors.white,
                  ),
                if (levelLabel.isNotEmpty)
                  AdminActionChip(
                    label: levelLabel,
                    icon: Icons.timeline_outlined,
                    color: Colors.white,
                  ),
                if (training.isFeatured)
                  const AdminActionChip(
                    label: 'Featured',
                    icon: Icons.workspace_premium_outlined,
                    color: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailHighlightsGrid([
              if (training.duration.trim().isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.schedule_outlined,
                  label: 'Duration',
                  value: training.duration,
                  color: Colors.cyan,
                ),
              if (learnerLabel.isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.groups_rounded,
                  label: 'Learners',
                  value: learnerLabel,
                  color: AdminPalette.info,
                ),
              if (ratingLabel.isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.star_outline_rounded,
                  label: 'Rating',
                  value: ratingLabel,
                  color: _accentColor,
                ),
              _IdeaHighlightItem(
                icon: training.isApproved
                    ? Icons.check_circle_outline_rounded
                    : Icons.hourglass_top_rounded,
                label: 'Status',
                value: training.isApproved ? 'Approved' : 'Pending Review',
                color: training.isApproved
                    ? AdminPalette.success
                    : _ideaAccentColor,
              ),
            ]),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildIdeaNarrativeCard(
                title: 'Training Overview',
                value: description,
                icon: Icons.description_outlined,
                color: Colors.cyan,
              ),
            ],
            const SizedBox(height: 14),
            const AdminSectionHeader(
              eyebrow: 'Resource Details',
              title: 'Provider And Delivery Setup',
              subtitle:
                  'This section helps you review how the training is packaged and presented to users.',
            ),
            const SizedBox(height: 12),
            _buildIdeaMetadataGrid([
              _IdeaDetailItem(
                'Provider',
                providerName,
                icon: Icons.business_outlined,
                color: Colors.cyan,
              ),
              _IdeaDetailItem(
                'Type',
                typeLabel,
                icon: Icons.school_outlined,
                color: Colors.cyan,
              ),
              _IdeaDetailItem(
                'Source',
                sourceLabel,
                icon: Icons.cloud_outlined,
                color: AdminPalette.secondary,
              ),
              _IdeaDetailItem(
                'Domain',
                domainLabel,
                icon: Icons.category_outlined,
                color: AdminPalette.info,
              ),
              _IdeaDetailItem(
                'Level',
                levelLabel,
                icon: Icons.timeline_outlined,
                color: AdminPalette.primary,
              ),
              _IdeaDetailItem(
                'Language',
                DisplayText.capitalizeWords(training.language),
                icon: Icons.translate_rounded,
                color: AdminPalette.activity,
              ),
              _IdeaDetailItem(
                'Access',
                accessLabel,
                icon: Icons.payments_outlined,
                color: training.isFree == true
                    ? AdminPalette.success
                    : _ideaAccentColor,
              ),
              _IdeaDetailItem(
                'Certificate',
                certificateLabel,
                icon: Icons.verified_outlined,
                color: AdminPalette.success,
              ),
            ]),
            if (authors.isNotEmpty) ...[
              const SizedBox(height: 14),
              AdminSurface(
                radius: 20,
                child: _buildTagSection('Authors', authors, Colors.cyan),
              ),
            ],
            if (link.isNotEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _openExternalLink(link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Resource'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.cyan,
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

  void _showContentDetailsSheet({
    required String title,
    required String subtitle,
    required String description,
    required List<_SheetDetailLine> detailLines,
    String? actionLabel,
    VoidCallback? onAction,
    Color? accentColor,
    IconData heroIcon = Icons.auto_awesome_mosaic_rounded,
    String detailsEyebrow = 'Details',
    String detailsTitle = 'Item Metadata',
    String detailsSubtitle =
        'Important fields are grouped here in a more readable admin detail layout.',
  }) {
    final visibleDetails = detailLines
        .where((line) => line.value.trim().isNotEmpty)
        .toList();
    final resolvedAccentColor = accentColor ?? _accentColor;

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
              gradient: AdminPalette.heroGradient(resolvedAccentColor),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(heroIcon, color: Colors.white, size: 28),
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
              AdminSectionHeader(
                eyebrow: detailsEyebrow,
                title: detailsTitle,
                subtitle: detailsSubtitle,
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
                  backgroundColor: resolvedAccentColor,
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

class _IdeaHighlightItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IdeaHighlightItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _IdeaDetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _IdeaDetailItem(
    this.label,
    this.value, {
    this.icon = Icons.info_outline_rounded,
    this.color = AdminPalette.textMuted,
  });
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
