import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/admin_application_item_model.dart';
import '../../models/cv_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/project_idea_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../models/training_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../services/company_service.dart';
import '../../services/document_access_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/application_status.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import 'admin_student_profile_sheet.dart';
import 'admin_library_screen.dart';
import 'admin_opportunity_editor_screen.dart';
import '../student/create_idea_screen.dart';
import 'admin_scholarship_editor_screen.dart';

class AdminContentCenterScreen extends StatefulWidget {
  static const int projectIdeasTab = 0;
  static const int opportunitiesTab = 1;
  static const int scholarshipsTab = 2;
  static const int libraryTab = 3;

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
  static Color get _primaryColor => AdminPalette.textPrimary;
  static Color get _accentColor => AdminPalette.primary;
  static Color get _ideaAccentColor => AdminPalette.secondary;
  static Color get _scholarshipAccentColor => AdminPalette.activity;
  static Color get _libraryAccentColor => AdminPalette.secondary;
  static const String _ideaFilterAll = 'all';
  static const String _ideaFilterPending = 'pending';
  static const String _ideaFilterApproved = 'approved';
  static const String _ideaFilterRejected = 'rejected';
  static const String _ideaFilterHidden = 'hidden';
  static const String _opportunityFilterAll = 'all';
  static const String _opportunityFilterLatest = 'latest';
  static const String _opportunityFilterAdmin = 'admin';
  static const String _opportunityFilterPendingApps = 'pending_apps';
  static const String _opportunityFilterClosed = 'closed';
  static const String _opportunityFilterFeatured = 'featured';
  static const String _opportunityFilterHidden = 'hidden';
  static const String _scholarshipFilterAll = 'all';
  static const String _scholarshipFilterFeatured = 'featured';
  static const String _scholarshipFilterHidden = 'hidden';

  final AdminService _adminService = AdminService();
  final CompanyService _companyService = CompanyService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _ideaStatusFilter = _ideaFilterAll;
  String _opportunityFilter = _opportunityFilterAll;
  String _scholarshipFilter = _scholarshipFilterAll;
  bool _openedInitialTarget = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(
        0,
        AdminContentCenterScreen.libraryTab,
      ),
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

  ThemeData _buildScopedTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(theme.primaryTextTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scopedTheme = _buildScopedTheme(context);
    final provider = context.watch<AdminProvider>();
    final l10n = AppLocalizations.of(context)!;
    final adminId = context.watch<AuthProvider>().userModel?.uid.trim() ?? '';
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
    final pendingApplications = provider.allApplications
        .where(
          (a) =>
              a.canBeManagedByAdmin(adminId) &&
              ApplicationStatus.parse(a.status) == ApplicationStatus.pending,
        )
        .length;
    final isLibraryTab =
        _tabController.index == AdminContentCenterScreen.libraryTab;

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
        ? const AppLoadingView(density: AppLoadingDensity.compact)
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
                Text(
                  'Failed to load admin content',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: provider.loadModerationData,
                  child: Text(AppLocalizations.of(context)!.retryLabel),
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
                          AdminSectionHeader(
                            eyebrow: 'Moderation',
                            title: l10n.uiContentWorkspace,
                            subtitle: l10n
                                .uiReviewSubmissionsMonitorQueuesAndMoveBetweenContentTypesWithout,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              AdminPill(
                                label:
                                    '${provider.allProjectIdeas.length} ideas',
                                color: _ideaAccentColor,
                                icon: Icons.lightbulb_outline_rounded,
                              ),
                              if (pendingIdeas > 0)
                                AdminPill(
                                  label: '$pendingIdeas pending ideas',
                                  color: _ideaAccentColor,
                                  icon: Icons.hourglass_top_rounded,
                                ),
                              if (pendingApplications > 0)
                                AdminPill(
                                  label: '$pendingApplications pending apps',
                                  color: AdminPalette.danger,
                                  icon: Icons.assignment_late_outlined,
                                ),
                              AdminPill(
                                label:
                                    '${provider.allOpportunities.length} opportunities',
                                color: AdminPalette.primary,
                                icon: Icons.work_outline_rounded,
                              ),
                              AdminPill(
                                label:
                                    '${provider.allScholarships.length} scholarships',
                                color: _scholarshipAccentColor,
                                icon: Icons.card_giftcard_rounded,
                              ),
                              AdminPill(
                                label:
                                    '${provider.allTrainings.length} resources',
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
              if (!isLibraryTab)
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
                  extent: 68,
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
                        color: AdminPalette.surface.withValues(alpha: 0.96),
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
                            label: l10n.uiProjectIdeas,
                            badgeCount: pendingIdeas,
                          ),
                          _buildTab(
                            icon: Icons.work_outline,
                            label: l10n.uiOpportunities,
                          ),
                          _buildTab(
                            icon: Icons.card_giftcard,
                            label: l10n.uiScholarships,
                          ),
                          _buildTab(
                            icon: Icons.menu_book_rounded,
                            label: l10n.uiLibrary,
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
                const AdminLibraryScreen(embedded: true),
              ],
            ),
          );

    if (widget.embedded) {
      return Theme(data: scopedTheme, child: content);
    }

    return Theme(
      data: scopedTheme,
      child: Scaffold(
        backgroundColor: AdminPalette.background,
        appBar: AppBar(
          title: Text(l10n.uiAdminContentCenter),
          backgroundColor: AdminPalette.surface,
          foregroundColor: _primaryColor,
        ),
        body: AdminShellBackground(child: SafeArea(top: false, child: content)),
      ),
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
    final l10n = AppLocalizations.of(context)!;
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
    final hiddenIdeasCount = allIdeas.where((idea) => idea.isHidden).length;
    final ideas = allIdeas
        .where((idea) => _matchesIdeaStatusFilter(idea, _ideaStatusFilter))
        .toList();
    if (provider.allProjectIdeas.isEmpty) {
      return AdminEmptyState(
        icon: Icons.lightbulb_outline,
        title: l10n.uiNoProjectIdeasToReviewYet,
        message: l10n.uiCreateTheFirstProjectIdeaToStartShapingTheInnovation,
        action: FilledButton.icon(
          onPressed: () => _openIdeaEditor(),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.uiPostAdminIdea),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                        _buildFilterChipRow([
                          AdminFilterChip(
                            label: 'All Ideas',
                            selected: _ideaStatusFilter == _ideaFilterAll,
                            icon: Icons.grid_view_rounded,
                            badgeCount: allIdeas.length,
                            onTap: () => setState(() {
                              _ideaStatusFilter = _ideaFilterAll;
                            }),
                          ),
                          AdminFilterChip(
                            label: 'Pending',
                            selected: _ideaStatusFilter == _ideaFilterPending,
                            icon: Icons.hourglass_top_rounded,
                            badgeCount: pendingIdeasCount,
                            onTap: () => setState(() {
                              _ideaStatusFilter = _toggleFilterValue(
                                _ideaStatusFilter,
                                _ideaFilterPending,
                                allValue: _ideaFilterAll,
                              );
                            }),
                          ),
                        ]),
                        if (_ideaStatusFilter != _ideaFilterPending) ...[
                          const SizedBox(height: 8),
                          _buildFilterChipRow([
                            AdminFilterChip(
                              label: 'Approved',
                              selected:
                                  _ideaStatusFilter == _ideaFilterApproved,
                              icon: Icons.check_circle_outline_rounded,
                              badgeCount: approvedIdeasCount,
                              onTap: () => setState(() {
                                _ideaStatusFilter = _toggleFilterValue(
                                  _ideaStatusFilter,
                                  _ideaFilterApproved,
                                  allValue: _ideaFilterAll,
                                );
                              }),
                            ),
                            AdminFilterChip(
                              label: 'Rejected',
                              selected:
                                  _ideaStatusFilter == _ideaFilterRejected,
                              icon: Icons.cancel_outlined,
                              badgeCount: rejectedIdeasCount,
                              onTap: () => setState(() {
                                _ideaStatusFilter = _toggleFilterValue(
                                  _ideaStatusFilter,
                                  _ideaFilterRejected,
                                  allValue: _ideaFilterAll,
                                );
                              }),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          _buildFilterChipRow([
                            AdminFilterChip(
                              label: 'Hidden',
                              selected: _ideaStatusFilter == _ideaFilterHidden,
                              icon: Icons.visibility_off_outlined,
                              badgeCount: hiddenIdeasCount,
                              onTap: () => setState(() {
                                _ideaStatusFilter = _toggleFilterValue(
                                  _ideaStatusFilter,
                                  _ideaFilterHidden,
                                  allValue: _ideaFilterAll,
                                );
                              }),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () => _openIdeaEditor(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!.uiPostAdminIdea,
                            ),
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
          final isIdeaVisibilityBusy = provider.busyContentKeys.contains(
            'idea:${idea.id}',
          );
          final canEditIdea = adminId.isNotEmpty && idea.submittedBy == adminId;
          final submitterLabel = idea.submittedByName.trim().isNotEmpty
              ? idea.submittedByName
              : idea.submittedBy;

          final isPending =
              _normalizedIdeaStatus(idea.status) == _ideaFilterPending;
          final ideaFooterButtons = <Widget>[
            OutlinedButton.icon(
              onPressed: () => _showProjectIdeaDetails(idea),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(AppLocalizations.of(context)!.uiDetails),
              style: _compactOutlinedFooterStyle(_ideaAccentColor),
            ),
            if (isPending)
              FilledButton.icon(
                onPressed: isIdeaBusy
                    ? null
                    : () async {
                        final error = await provider.updateProjectIdeaStatus(
                          idea.id,
                          'approved',
                        );
                        if (error != null && context.mounted) {
                          context.showAppSnackBar(
                            error,
                            title: l10n.updateUnavailableTitle,
                            type: AppFeedbackType.error,
                          );
                        }
                      },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(isIdeaBusy ? 'Working...' : 'Approve'),
                style: _compactFilledFooterStyle(AdminPalette.success),
              ),
            if (isPending)
              FilledButton.icon(
                onPressed: isIdeaBusy
                    ? null
                    : () async {
                        final error = await provider.updateProjectIdeaStatus(
                          idea.id,
                          'rejected',
                        );
                        if (error != null && context.mounted) {
                          context.showAppSnackBar(
                            error,
                            title: l10n.updateUnavailableTitle,
                            type: AppFeedbackType.error,
                          );
                        }
                      },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(isIdeaBusy ? 'Working...' : 'Reject'),
                style: _compactFilledFooterStyle(AdminPalette.danger),
              ),
            if (idea.isHidden)
              _buildUnhideFooterButton(
                onPressed: isIdeaVisibilityBusy
                    ? null
                    : () => _toggleItemVisibility(
                        itemType: 'Idea',
                        itemTitle: idea.title,
                        isHidden: idea.isHidden,
                        onToggle: (nextHidden) =>
                            provider.setProjectIdeaHidden(idea.id, nextHidden),
                      ),
              ),
          ];

          return _buildContentCard(
            id: idea.id,
            leading: _buildIdeaLeading(idea),
            title: _formatIdeaTitle(idea.title),
            subtitle:
                'By ${DisplayText.capitalizeLeadingLabel(submitterLabel)}',
            description: _formatIdeaDescription(idea.cardSummary),
            badges: [
              if (idea.isHidden) _BadgeData('Hidden', Colors.blueGrey),
              _BadgeData(
                _formatIdeaBadgeValue(idea.status),
                _statusColor(idea.status),
              ),
              if (idea.displayCategory.trim().isNotEmpty)
                _BadgeData(
                  _formatIdeaBadgeValue(idea.displayCategory),
                  AdminPalette.textSecondary,
                ),
              if (canEditIdea) _BadgeData('Your Post', _ideaAccentColor),
            ],
            metaText: idea.lastUpdatedLabel,
            onTap: () => _showProjectIdeaDetails(idea),
            accentColor: _ideaAccentColor,
            action: _buildCardActionRow([
              if (canEditIdea)
                _buildCompactCardAction(
                  icon: Icons.edit_outlined,
                  color: _ideaAccentColor,
                  onTap: () => _openIdeaEditor(idea: idea),
                ),
              _buildCompactCardAction(
                icon: idea.isHidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_outlined,
                color: idea.isHidden
                    ? AdminPalette.success
                    : AdminPalette.textSecondary,
                onTap: isIdeaVisibilityBusy
                    ? null
                    : () => _toggleItemVisibility(
                        itemType: 'Idea',
                        itemTitle: idea.title,
                        isHidden: idea.isHidden,
                        onToggle: (nextHidden) =>
                            provider.setProjectIdeaHidden(idea.id, nextHidden),
                      ),
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
                      context.showAppSnackBar(
                        error,
                        title: l10n.uiDeleteUnavailable,
                        type: AppFeedbackType.error,
                      );
                    }
                  },
                ),
              ),
            ]),
            footer: _buildResponsiveActionGroup(ideaFooterButtons),
          );
        },
      ),
    );
  }

  Widget _buildPendingIdeasWarning(int pendingCount) {
    return AdminSurface(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      color: AdminPalette.secondarySoft,
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
              Icons.hourglass_top_rounded,
              color: _ideaAccentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                  style: TextStyle(
                    fontSize: 12.2,
                    height: 1.4,
                    color: AdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _ideaStatusFilter == _ideaFilterPending
                ? null
                : () => setState(() {
                    _ideaStatusFilter = _ideaFilterPending;
                  }),
            child: Text(AppLocalizations.of(context)!.uiOpen),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaLeading(ProjectIdeaModel idea) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _ideaAccentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.lightbulb_outline_rounded,
        color: _ideaAccentColor,
        size: 19,
      ),
    );
  }

  Widget _buildUnhideFooterButton({required VoidCallback? onPressed}) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_rounded, size: 16),
      label: Text(onPressed == null ? 'Working...' : 'Unhide'),
      style: _compactFilledFooterStyle(AdminPalette.success),
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
    final l10n = AppLocalizations.of(context)!;
    final opportunityTitle = (opportunity['title'] ?? 'Opportunity').toString();
    final opportunityId = (opportunity['id'] ?? '').toString().trim();
    final adminId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    final opportunityModel = OpportunityModel.fromMap(opportunity);
    final canManageApplications =
        adminId.isNotEmpty &&
        opportunityModel.isAdminPosted &&
        opportunityModel.companyId.trim() == adminId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final liveApplications = opportunityId.isEmpty
              ? applications
              : _applicationsForOpportunity(provider, opportunityId);

          return DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.4,
            maxChildSize: 0.94,
            expand: false,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 12),
                AdminSurface(
                  radius: 20,
                  gradient: AdminPalette.heroGradient(AdminPalette.activity),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.uiApplicationsForOpportunitytitle(
                          opportunityTitle,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${liveApplications.length} application${liveApplications.length == 1 ? '' : 's'} linked to this opportunity.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (liveApplications.isEmpty)
                  AdminEmptyState(
                    icon: Icons.assignment_late_outlined,
                    title: l10n.uiNoApplicationsToReviewYet,
                    message: l10n
                        .uiThereAreNoSubmittedApplicationsForThisOpportunityRightNow,
                  )
                else
                  ...liveApplications.map((item) {
                    final statusColor = _statusColor(item.status);
                    final canReview =
                        canManageApplications &&
                        item.canBeManagedByAdmin(adminId) &&
                        ApplicationStatus.parse(item.status) ==
                            ApplicationStatus.pending;
                    final isBusy = provider.busyContentKeys.contains(
                      'application:${item.id}',
                    );

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
                        _BadgeData(
                          ApplicationStatus.label(item.status, l10n),
                          statusColor,
                        ),
                        if (item.appliedAt != null)
                          _BadgeData(
                            DateFormat(
                              'MMM d',
                            ).format(item.appliedAt!.toDate()),
                            AdminPalette.info,
                          ),
                      ],
                      accentColor: statusColor,
                      metaText: _formatTimestamp(item.appliedAt),
                      footer: canReview
                          ? _buildResponsiveActionGroup(
                              _buildAdminApplicationDecisionButtons(
                                item,
                                isBusy: isBusy,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _showApplicantQuickActions(item);
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunitiesTab(AdminProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final adminId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    final searchQuery = _searchController.text.trim();
    final allOpportunities =
        provider.allOpportunities.where(_matchesOpportunitySearch).toList()
          ..sort((first, second) {
            final firstModel = OpportunityModel.fromMap(first);
            final secondModel = OpportunityModel.fromMap(second);
            final firstIsOpen = firstModel.effectiveStatus() == 'open';
            final secondIsOpen = secondModel.effectiveStatus() == 'open';
            if (firstIsOpen != secondIsOpen) {
              return firstIsOpen ? -1 : 1;
            }

            if (firstModel.isHidden != secondModel.isHidden) {
              return firstModel.isHidden ? 1 : -1;
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
    final latestCount = allOpportunities.where((item) {
      final ts = OpportunityModel.fromMap(item).createdAt;
      if (ts == null) return false;
      return DateTime.now().difference(ts.toDate()).inDays <= 7;
    }).length;
    final adminCount = allOpportunities
        .where((item) => OpportunityModel.fromMap(item).isAdminPosted)
        .length;
    final pendingAppsCount = allOpportunities.where((item) {
      final m = OpportunityModel.fromMap(item);
      if (!m.isAdminPosted || adminId.isEmpty) return false;
      if (m.companyId.trim() != adminId) return false;
      return _applicationsForOpportunity(provider, m.id).any(
        (a) => ApplicationStatus.parse(a.status) == ApplicationStatus.pending,
      );
    }).length;
    final closedCount = allOpportunities
        .where(
          (item) =>
              OpportunityModel.fromMap(item).effectiveStatus() == 'closed',
        )
        .length;
    final featuredCount = allOpportunities
        .where((item) => OpportunityModel.fromMap(item).isFeatured)
        .length;
    final hiddenCount = allOpportunities
        .where((item) => OpportunityModel.fromMap(item).isHidden)
        .length;
    final opportunities = allOpportunities
        .where(
          (item) => _matchesOpportunityFilter(
            item,
            _opportunityFilter,
            provider,
            adminId,
          ),
        )
        .toList();

    if (provider.allOpportunities.isEmpty) {
      return AdminEmptyState(
        icon: Icons.work_outline,
        title: l10n.uiNoOpportunitiesPublishedYet,
        message: l10n
            .uiPublishTheFirstOpportunityToStartPopulatingTheStudentDiscovery,
        action: FilledButton.icon(
          onPressed: () => _openOpportunityEditor(),
          icon: const Icon(Icons.add_rounded),
          label: Text(AppLocalizations.of(context)!.uiPostOpportunity),
        ),
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: opportunities.isEmpty ? 2 : opportunities.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCollectionWorkspaceHeader(
                eyebrow: 'Opportunities',
                title:
                    '${_opportunityFilterTitle(_opportunityFilter)} (${opportunities.length})',
                subtitle: searchQuery.isEmpty
                    ? 'Review jobs, internships, and sponsored posts. Filter by source, status, or pending reviews.'
                    : 'Showing filtered results for "$searchQuery".',
                primaryFilters: [
                  _CollectionHeaderFilter(
                    label: 'All',
                    selected: _opportunityFilter == _opportunityFilterAll,
                    icon: Icons.grid_view_rounded,
                    badgeCount: allOpportunities.length,
                    onTap: () => setState(
                      () => _opportunityFilter = _opportunityFilterAll,
                    ),
                  ),
                  _CollectionHeaderFilter(
                    label: 'Latest',
                    selected: _opportunityFilter == _opportunityFilterLatest,
                    icon: Icons.schedule_rounded,
                    badgeCount: latestCount,
                    onTap: () => setState(() {
                      _opportunityFilter = _toggleFilterValue(
                        _opportunityFilter,
                        _opportunityFilterLatest,
                        allValue: _opportunityFilterAll,
                      );
                    }),
                  ),
                  _CollectionHeaderFilter(
                    label: 'Admin Posts',
                    selected: _opportunityFilter == _opportunityFilterAdmin,
                    icon: Icons.admin_panel_settings_outlined,
                    badgeCount: adminCount,
                    onTap: () => setState(() {
                      _opportunityFilter = _toggleFilterValue(
                        _opportunityFilter,
                        _opportunityFilterAdmin,
                        allValue: _opportunityFilterAll,
                      );
                    }),
                  ),
                ],
                secondaryFilters: [
                  if (pendingAppsCount > 0)
                    _CollectionHeaderFilter(
                      label: 'Pending Apps',
                      selected:
                          _opportunityFilter == _opportunityFilterPendingApps,
                      icon: Icons.hourglass_top_rounded,
                      badgeCount: pendingAppsCount,
                      onTap: () => setState(() {
                        _opportunityFilter = _toggleFilterValue(
                          _opportunityFilter,
                          _opportunityFilterPendingApps,
                          allValue: _opportunityFilterAll,
                        );
                      }),
                    ),
                  _CollectionHeaderFilter(
                    label: 'Featured',
                    selected: _opportunityFilter == _opportunityFilterFeatured,
                    icon: Icons.workspace_premium_outlined,
                    badgeCount: featuredCount,
                    onTap: () => setState(() {
                      _opportunityFilter = _toggleFilterValue(
                        _opportunityFilter,
                        _opportunityFilterFeatured,
                        allValue: _opportunityFilterAll,
                      );
                    }),
                  ),
                  _CollectionHeaderFilter(
                    label: 'Closed',
                    selected: _opportunityFilter == _opportunityFilterClosed,
                    icon: Icons.pause_circle_outline_rounded,
                    badgeCount: closedCount,
                    onTap: () => setState(() {
                      _opportunityFilter = _toggleFilterValue(
                        _opportunityFilter,
                        _opportunityFilterClosed,
                        allValue: _opportunityFilterAll,
                      );
                    }),
                  ),
                  _CollectionHeaderFilter(
                    label: 'Hidden',
                    selected: _opportunityFilter == _opportunityFilterHidden,
                    icon: Icons.visibility_off_outlined,
                    badgeCount: hiddenCount,
                    onTap: () => setState(() {
                      _opportunityFilter = _toggleFilterValue(
                        _opportunityFilter,
                        _opportunityFilterHidden,
                        allValue: _opportunityFilterAll,
                      );
                    }),
                  ),
                ],
                action: FilledButton.icon(
                  onPressed: () => _openOpportunityEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.uiPostOpportunity),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                searchQuery: searchQuery,
              ),
            );
          }

          if (opportunities.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildEmptyState(
                Icons.search_off_outlined,
                _opportunityEmptyMessage(_opportunityFilter),
              ),
            );
          }

          final opportunity = opportunities[index - 1];
          final opportunityId = opportunity['id'].toString();
          final isOpportunityVisibilityBusy = provider.busyContentKeys.contains(
            'opportunity:$opportunityId',
          );
          final isOwnedByAdmin =
              adminId.isNotEmpty &&
              (opportunity['companyId'] ?? '').toString().trim() == adminId;
          final applications = _applicationsForOpportunity(
            provider,
            opportunityId,
          );
          final pendingAppCount = applications
              .where(
                (a) =>
                    ApplicationStatus.parse(a.status) ==
                    ApplicationStatus.pending,
              )
              .length;
          final opportunityModel = OpportunityModel.fromMap(opportunity);
          final effectiveStatus = opportunityModel.effectiveStatus();
          final opportunityType = OpportunityType.parse(
            (opportunity['type'] ?? '').toString(),
          );
          final opportunityTypeColor = OpportunityType.color(opportunityType);
          final isOpen = effectiveStatus == 'open';
          final compensationLabel =
              opportunityType == OpportunityType.sponsoring
              ? opportunityModel.fundingLabel(preferFundingNote: true)
              : OpportunityMetadata.buildCompensationLabel(
                  salaryMin: opportunityModel.salaryMin,
                  salaryMax: opportunityModel.salaryMax,
                  salaryCurrency: opportunityModel.salaryCurrency,
                  salaryPeriod: opportunityModel.salaryPeriod,
                  compensationText: opportunityModel.compensationText,
                  isPaid: opportunityModel.isPaid,
                  preferCompensationText: true,
                );
          final workModeLabel =
              OpportunityMetadata.formatWorkMode(opportunityModel.workMode) ??
              '';
          final footerButtons = <Widget>[
            OutlinedButton.icon(
              onPressed: () => _showOpportunityDetails(opportunity),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(AppLocalizations.of(context)!.uiDetails),
              style: _compactOutlinedFooterStyle(AdminPalette.primary),
            ),
            if (applications.isNotEmpty)
              FilledButton.icon(
                onPressed: () =>
                    _showOpportunityApplications(opportunity, applications),
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: Text('${applications.length} Apps'),
                style: _compactFilledFooterStyle(AdminPalette.primary),
              ),
          ];
          if (opportunityModel.isHidden) {
            footerButtons.add(
              _buildUnhideFooterButton(
                onPressed: isOpportunityVisibilityBusy
                    ? null
                    : () => _toggleItemVisibility(
                        itemType: 'Opportunity',
                        itemTitle: (opportunity['title'] ?? 'Opportunity')
                            .toString(),
                        isHidden: opportunityModel.isHidden,
                        onToggle: (nextHidden) => provider.setOpportunityHidden(
                          opportunityId,
                          nextHidden,
                        ),
                      ),
              ),
            );
          }
          final subtitle = _joinCardSubtitleParts([
            DisplayText.capitalizeLeadingLabel(
              opportunityModel.companyName.isNotEmpty
                  ? opportunityModel.companyName
                  : 'Unknown company',
            ),
            if (opportunityModel.location.trim().isNotEmpty)
              DisplayText.capitalizeLeadingLabel(opportunityModel.location),
          ]);
          final deadlineLabel = _formatDateBadgeLabel(
            opportunityModel.applicationDeadline ?? opportunityModel.deadline,
            prefix: 'Due',
          );
          return _buildMapListTile(
            id: opportunityId,
            icon: OpportunityType.icon(opportunityType),
            iconColor: opportunityTypeColor,
            title: DisplayText.capitalizeWords(
              (opportunity['title'] ?? 'Untitled opportunity').toString(),
            ),
            subtitle: subtitle,
            description: _cleanCardDescription(
              opportunityModel.description.isNotEmpty
                  ? opportunityModel.description
                  : opportunityModel.requirements,
              fallback:
                  'Open this post to review the full role and requirements.',
            ),
            badges: _buildOpportunityBadges(
              isHidden: opportunityModel.isHidden,
              isOpen: isOpen,
              typeLabel: OpportunityType.label(opportunityType, l10n),
              typeColor: opportunityTypeColor,
              isOwnedByAdmin: isOwnedByAdmin,
              workModeLabel: workModeLabel,
              deadlineLabel: deadlineLabel,
              compensationLabel: compensationLabel,
            ),
            onTap: () => _showOpportunityDetails(opportunity),
            metaText: _joinCardSubtitleParts([
              _buildDateMetaLabel(
                'Updated',
                opportunityModel.updatedAt ?? opportunityModel.createdAt,
              ),
              if (applications.isNotEmpty)
                '${applications.length} app${applications.length == 1 ? '' : 's'}',
              if (pendingAppCount > 0) '$pendingAppCount pending',
            ]),
            footer: _buildResponsiveActionGroup(footerButtons),
            trailing: _buildCardActionRow([
              if (isOwnedByAdmin)
                _buildCompactCardAction(
                  icon: Icons.edit_outlined,
                  color: AdminPalette.primary,
                  onTap: () => _openOpportunityEditor(opportunity: opportunity),
                ),
              _buildCompactCardAction(
                icon: opportunityModel.isHidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_outlined,
                color: opportunityModel.isHidden
                    ? AdminPalette.success
                    : AdminPalette.textSecondary,
                onTap: isOpportunityVisibilityBusy
                    ? null
                    : () => _toggleItemVisibility(
                        itemType: 'Opportunity',
                        itemTitle: (opportunity['title'] ?? 'Opportunity')
                            .toString(),
                        isHidden: opportunityModel.isHidden,
                        onToggle: (nextHidden) => provider.setOpportunityHidden(
                          opportunityId,
                          nextHidden,
                        ),
                      ),
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
                      context.showAppSnackBar(
                        error,
                        title: l10n.uiDeleteUnavailable,
                        type: AppFeedbackType.error,
                      );
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
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = _searchController.text.trim();
    final allScholarships =
        provider.allScholarships.where(_matchesScholarshipSearch).toList()
          ..sort((first, second) {
            final firstModel = ScholarshipModel.fromMap(first);
            final secondModel = ScholarshipModel.fromMap(second);
            if (firstModel.isHidden != secondModel.isHidden) {
              return firstModel.isHidden ? 1 : -1;
            }
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
    final featuredCount = allScholarships
        .where((item) => ScholarshipModel.fromMap(item).isFeatured)
        .length;
    final hiddenCount = allScholarships
        .where((item) => ScholarshipModel.fromMap(item).isHidden)
        .length;
    final scholarships = allScholarships
        .where((item) => _matchesScholarshipFilter(item, _scholarshipFilter))
        .toList();

    if (provider.allScholarships.isEmpty) {
      return AdminEmptyState(
        icon: Icons.card_giftcard,
        title: l10n.uiNoScholarshipsPublishedYet,
        message:
            l10n.uiPublishTheFirstScholarshipToStartShapingTheStudentDiscovery,
        action: FilledButton.icon(
          onPressed: () => _openScholarshipEditor(),
          icon: const Icon(Icons.add_rounded),
          label: Text(AppLocalizations.of(context)!.uiPostScholarship),
          style: FilledButton.styleFrom(
            backgroundColor: _scholarshipAccentColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: scholarships.isEmpty ? 2 : scholarships.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCollectionWorkspaceHeader(
                eyebrow: 'Scholarships',
                title:
                    '${_scholarshipFilterTitle(_scholarshipFilter)} (${scholarships.length})',
                subtitle: searchQuery.isEmpty
                    ? 'Keep funding calls clear, trustworthy, and easy to scan before students open the full details.'
                    : 'Showing filtered results for "$searchQuery".',
                primaryFilters: [
                  _CollectionHeaderFilter(
                    label: 'All',
                    selected: _scholarshipFilter == _scholarshipFilterAll,
                    icon: Icons.grid_view_rounded,
                    badgeCount: allScholarships.length,
                    onTap: () => setState(
                      () => _scholarshipFilter = _scholarshipFilterAll,
                    ),
                  ),
                ],
                secondaryFilters: [
                  _CollectionHeaderFilter(
                    label: 'Featured',
                    selected: _scholarshipFilter == _scholarshipFilterFeatured,
                    icon: Icons.workspace_premium_outlined,
                    badgeCount: featuredCount,
                    onTap: () => setState(() {
                      _scholarshipFilter = _toggleFilterValue(
                        _scholarshipFilter,
                        _scholarshipFilterFeatured,
                        allValue: _scholarshipFilterAll,
                      );
                    }),
                  ),
                  _CollectionHeaderFilter(
                    label: 'Hidden',
                    selected: _scholarshipFilter == _scholarshipFilterHidden,
                    icon: Icons.visibility_off_outlined,
                    badgeCount: hiddenCount,
                    onTap: () => setState(() {
                      _scholarshipFilter = _toggleFilterValue(
                        _scholarshipFilter,
                        _scholarshipFilterHidden,
                        allValue: _scholarshipFilterAll,
                      );
                    }),
                  ),
                ],
                action: FilledButton.icon(
                  onPressed: () => _openScholarshipEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.uiPostScholarship),
                  style: FilledButton.styleFrom(
                    backgroundColor: _scholarshipAccentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                searchQuery: searchQuery,
              ),
            );
          }

          if (scholarships.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildEmptyState(
                Icons.search_off_outlined,
                _scholarshipEmptyMessage(_scholarshipFilter),
              ),
            );
          }

          final scholarship = scholarships[index - 1];
          final scholarshipModel = ScholarshipModel.fromMap(scholarship);
          final isScholarshipVisibilityBusy = provider.busyContentKeys.contains(
            'scholarship:${scholarshipModel.id}',
          );
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
          final scholarshipFooterButtons = <Widget>[
            OutlinedButton.icon(
              onPressed: () => _showScholarshipDetails(scholarship),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(AppLocalizations.of(context)!.uiDetails),
              style: _compactOutlinedFooterStyle(_scholarshipAccentColor),
            ),
            if (scholarshipModel.link.trim().isNotEmpty)
              FilledButton.icon(
                onPressed: () => _openExternalLink(scholarshipModel.link),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.uiApplyLink),
                style: _compactFilledFooterStyle(_scholarshipAccentColor),
              ),
            if (scholarshipModel.isHidden)
              _buildUnhideFooterButton(
                onPressed: isScholarshipVisibilityBusy
                    ? null
                    : () => _toggleItemVisibility(
                        itemType: 'Scholarship',
                        itemTitle: scholarshipModel.title,
                        isHidden: scholarshipModel.isHidden,
                        onToggle: (nextHidden) => provider.setScholarshipHidden(
                          scholarshipModel.id,
                          nextHidden,
                        ),
                      ),
              ),
          ];
          final deadlineBadge = _formatDateBadgeLabel(
            scholarshipModel.deadline,
            prefix: 'Due',
          );
          final fundingLabel = (scholarshipModel.fundingType ?? '').trim();
          return _buildMapListTile(
            id: scholarshipModel.id,
            icon: Icons.card_giftcard_rounded,
            iconColor: _scholarshipAccentColor,
            title: DisplayText.capitalizeWords(
              scholarshipModel.title.isNotEmpty
                  ? scholarshipModel.title
                  : 'Untitled scholarship',
            ),
            subtitle: _joinCardSubtitleParts([
              DisplayText.capitalizeLeadingLabel(
                scholarshipModel.provider.isNotEmpty
                    ? scholarshipModel.provider
                    : 'Unknown provider',
              ),
              if (locationText.isNotEmpty)
                DisplayText.capitalizeLeadingLabel(locationText),
            ]),
            description: _cleanCardDescription(
              scholarshipModel.description.isNotEmpty
                  ? scholarshipModel.description
                  : scholarshipModel.eligibility,
              fallback:
                  'Open this scholarship to review eligibility and access details.',
            ),
            badges: [
              if (scholarshipModel.isHidden)
                _BadgeData('Hidden', Colors.blueGrey),
              if (amountText.isNotEmpty)
                _BadgeData(amountText, AdminPalette.success),
              if (fundingLabel.isNotEmpty && amountText.isEmpty)
                _BadgeData(
                  DisplayText.capitalizeWords(fundingLabel),
                  _scholarshipAccentColor,
                ),
              if ((scholarshipModel.level ?? '').trim().isNotEmpty)
                _BadgeData(
                  DisplayText.capitalizeWords(scholarshipModel.level!),
                  AdminPalette.info,
                ),
              if (deadlineBadge != null)
                _BadgeData(deadlineBadge, _deadlineBadgeColor(deadlineBadge)),
              if (scholarshipModel.isFeatured)
                _BadgeData('Featured', _accentColor),
            ],
            onTap: () => _showScholarshipDetails(scholarship),
            metaText: _buildDateMetaLabel('Added', scholarshipModel.createdAt),
            footer: _buildResponsiveActionGroup(scholarshipFooterButtons),
            trailing: _buildCardActionRow([
              _buildCompactCardAction(
                icon: Icons.edit_outlined,
                color: AdminPalette.primary,
                onTap: () => _openScholarshipEditor(scholarship: scholarship),
              ),
              _buildCompactCardAction(
                icon: scholarshipModel.isHidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_outlined,
                color: scholarshipModel.isHidden
                    ? AdminPalette.success
                    : AdminPalette.textSecondary,
                onTap: isScholarshipVisibilityBusy
                    ? null
                    : () => _toggleItemVisibility(
                        itemType: 'Scholarship',
                        itemTitle: scholarshipModel.title,
                        isHidden: scholarshipModel.isHidden,
                        onToggle: (nextHidden) => provider.setScholarshipHidden(
                          scholarshipModel.id,
                          nextHidden,
                        ),
                      ),
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
                      context.showAppSnackBar(
                        error,
                        title: l10n.uiDeleteUnavailable,
                        type: AppFeedbackType.error,
                      );
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

  String _searchHintForCurrentTab() {
    switch (_tabController.index) {
      case AdminContentCenterScreen.projectIdeasTab:
        return 'Search ideas by title, domain, submitter, or status...';
      case AdminContentCenterScreen.opportunitiesTab:
        return 'Search opportunities by title, company, location, status, or compensation...';
      case AdminContentCenterScreen.scholarshipsTab:
        return 'Search scholarships by title, provider, or deadline...';
      case AdminContentCenterScreen.libraryTab:
        return 'Search library resources...';
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

    if (filter == _ideaFilterHidden) {
      return idea.isHidden;
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
      case _ideaFilterHidden:
        return 'Hidden Ideas';
      default:
        return 'All Ideas';
    }
  }

  String _ideaEmptyMessage(String filter) {
    switch (filter) {
      case _ideaFilterPending:
        return 'No pending ideas match this search';
      case _ideaFilterApproved:
        return 'No approved ideas match this search';
      case _ideaFilterRejected:
        return 'No rejected ideas match this search';
      case _ideaFilterHidden:
        return 'No hidden ideas match this search';
      default:
        return 'No ideas match this search';
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

    if (a.isHidden != b.isHidden) {
      return a.isHidden ? 1 : -1;
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
    _opportunityFilter = _opportunityFilterAll;
    _scholarshipFilter = _scholarshipFilterAll;
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
      fundingAmount: opportunityModel.fundingAmount,
      fundingCurrency: opportunityModel.fundingCurrency,
      fundingNote: opportunityModel.fundingNote,
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
        opportunityModel.effectiveStatus().contains(query) ||
        (opportunity['status'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        metadataText.contains(query);
  }

  bool _matchesOpportunityFilter(
    Map<String, dynamic> opportunity,
    String filter,
    AdminProvider provider,
    String adminId,
  ) {
    final opportunityModel = OpportunityModel.fromMap(opportunity);
    switch (filter) {
      case _opportunityFilterLatest:
        final ts = opportunityModel.createdAt;
        if (ts == null) return false;
        final age = DateTime.now().difference(ts.toDate());
        return age.inDays <= 7;
      case _opportunityFilterAdmin:
        return opportunityModel.isAdminPosted;
      case _opportunityFilterPendingApps:
        if (!opportunityModel.isAdminPosted) return false;
        if (adminId.isEmpty) return false;
        if (opportunityModel.companyId.trim() != adminId) return false;
        final apps = _applicationsForOpportunity(provider, opportunityModel.id);
        return apps.any(
          (a) => ApplicationStatus.parse(a.status) == ApplicationStatus.pending,
        );
      case _opportunityFilterClosed:
        return opportunityModel.effectiveStatus() == 'closed';
      case _opportunityFilterFeatured:
        return opportunityModel.isFeatured;
      case _opportunityFilterHidden:
        return opportunityModel.isHidden;
      default:
        return true;
    }
  }

  String _opportunityFilterTitle(String filter) {
    switch (filter) {
      case _opportunityFilterLatest:
        return 'Latest Opportunities';
      case _opportunityFilterAdmin:
        return 'Admin Opportunities';
      case _opportunityFilterPendingApps:
        return 'Pending Applications';
      case _opportunityFilterClosed:
        return 'Closed Opportunities';
      case _opportunityFilterFeatured:
        return 'Featured Opportunities';
      case _opportunityFilterHidden:
        return 'Hidden Opportunities';
      default:
        return 'Opportunity Queue';
    }
  }

  String _opportunityEmptyMessage(String filter) {
    switch (filter) {
      case _opportunityFilterLatest:
        return 'No opportunities added in the last 7 days';
      case _opportunityFilterAdmin:
        return 'No admin-posted opportunities match this search';
      case _opportunityFilterPendingApps:
        return 'No opportunities with pending applications right now';
      case _opportunityFilterClosed:
        return 'No closed opportunities match this search';
      case _opportunityFilterFeatured:
        return 'No featured opportunities match this search';
      case _opportunityFilterHidden:
        return 'No hidden opportunities match this search';
      default:
        return 'No opportunities match this search';
    }
  }

  List<_BadgeData> _buildOpportunityBadges({
    required bool isHidden,
    required bool isOpen,
    required String typeLabel,
    required Color typeColor,
    required bool isOwnedByAdmin,
    required String workModeLabel,
    required String? deadlineLabel,
    required String? compensationLabel,
  }) {
    final badges = <_BadgeData>[
      _BadgeData(
        isHidden
            ? 'Hidden'
            : isOpen
            ? 'Open'
            : 'Closed',
        isHidden
            ? Colors.blueGrey
            : isOpen
            ? AdminPalette.textSecondary
            : AdminPalette.textMuted,
      ),
      _BadgeData(typeLabel, typeColor),
    ];

    final supportingLabel = workModeLabel.trim().isNotEmpty
        ? workModeLabel
        : (deadlineLabel?.trim().isNotEmpty ?? false)
        ? deadlineLabel!.trim()
        : (compensationLabel?.trim().isNotEmpty ?? false)
        ? compensationLabel!.trim()
        : isOwnedByAdmin
        ? 'Admin'
        : '';

    if (supportingLabel.isNotEmpty) {
      badges.add(_BadgeData(supportingLabel, AdminPalette.textSecondary));
    }

    return badges.take(3).toList();
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

  bool _matchesScholarshipFilter(
    Map<String, dynamic> scholarship,
    String filter,
  ) {
    final scholarshipModel = ScholarshipModel.fromMap(scholarship);
    switch (filter) {
      case _scholarshipFilterFeatured:
        return scholarshipModel.isFeatured;
      case _scholarshipFilterHidden:
        return scholarshipModel.isHidden;
      default:
        return true;
    }
  }

  String _scholarshipFilterTitle(String filter) {
    switch (filter) {
      case _scholarshipFilterFeatured:
        return 'Featured Scholarships';
      case _scholarshipFilterHidden:
        return 'Hidden Scholarships';
      default:
        return 'Scholarship Listings';
    }
  }

  String _scholarshipEmptyMessage(String filter) {
    switch (filter) {
      case _scholarshipFilterFeatured:
        return 'No featured scholarships match this search';
      case _scholarshipFilterHidden:
        return 'No hidden scholarships match this search';
      default:
        return 'No scholarships match this search';
    }
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
          _showApplicantQuickActions(application);
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
      case AdminContentCenterScreen.libraryTab:
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
        builder: (_) => CreateIdeaScreen(
          idea: idea,
          isEditMode: idea != null,
          isAdmin: true,
        ),
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
          if (index < actions.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _buildCompactCardAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final effectiveColor = onTap == null ? AdminPalette.textMuted : color;

    return Material(
      color: effectiveColor.withValues(alpha: onTap == null ? 0.05 : 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16.5, color: effectiveColor),
        ),
      ),
    );
  }

  String _toggleFilterValue(
    String current,
    String next, {
    required String allValue,
  }) {
    return current == next ? allValue : next;
  }

  Future<void> _toggleItemVisibility({
    required String itemType,
    required String itemTitle,
    required bool isHidden,
    required Future<String?> Function(bool nextHidden) onToggle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final nextHidden = !isHidden;
    final error = await onToggle(nextHidden);
    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: l10n.updateUnavailableTitle,
        type: AppFeedbackType.error,
      );
      return;
    }

    final normalizedTitle = itemTitle.trim().isEmpty ? itemType : itemTitle;
    final message = nextHidden
        ? '$itemType "$normalizedTitle" hidden. You can restore it later.'
        : '$itemType "$normalizedTitle" is visible again.';
    context.showAppSnackBar(
      message,
      title: nextHidden ? '$itemType hidden' : '$itemType visible',
      type: AppFeedbackType.success,
    );
  }

  Widget _buildContentCard({
    required String id,
    required Widget leading,
    required String title,
    required String subtitle,
    required List<_BadgeData> badges,
    required VoidCallback onTap,
    Color? accentColor,
    String? description,
    String? metaText,
    Widget? action,
    Widget? footer,
  }) {
    final isTarget = id == widget.initialTargetId;
    final resolvedAccentColor = accentColor ?? AdminPalette.primary;
    final highlightColor = isTarget ? _accentColor : resolvedAccentColor;
    final borderColor = isTarget
        ? _accentColor.withValues(alpha: 0.42)
        : AdminPalette.border.withValues(alpha: 0.88);
    final normalizedMetaText = (metaText ?? '').trim();
    final resolvedAction =
        action ??
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: highlightColor.withValues(alpha: 0.78),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isTarget
            ? highlightColor.withValues(alpha: 0.035)
            : AdminPalette.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: isTarget ? 1.2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCardTitleBlock(
                          title: title,
                          subtitle: subtitle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      resolvedAction,
                    ],
                  ),
                  if (badges.isNotEmpty || normalizedMetaText.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isTarget) _statusBadge('Focused', highlightColor),
                        ...badges.map(
                          (badge) => _statusBadge(badge.label, badge.color),
                        ),
                        if (normalizedMetaText.isNotEmpty)
                          _cardMetaBadge(normalizedMetaText, highlightColor),
                      ],
                    ),
                  ],
                  if (footer != null) ...[const SizedBox(height: 8), footer],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardTitleBlock({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.6,
            color: AdminPalette.textPrimary,
            height: 1.2,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.4,
              fontWeight: FontWeight.w600,
              color: AdminPalette.textMuted,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResponsiveActionGroup(List<Widget> buttons) {
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    if (buttons.length == 1) {
      return Align(alignment: Alignment.centerLeft, child: buttons.first);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                buttons[index],
                if (index < buttons.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Wrap(spacing: 8, runSpacing: 8, children: buttons);
      },
    );
  }

  ButtonStyle _compactOutlinedFooterStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  ButtonStyle _compactFilledFooterStyle(Color color) {
    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: title,
      subtitle: subtitle,
      description: description,
      badges: badges,
      onTap: onTap,
      accentColor: iconColor,
      metaText: metaText,
      action: trailing,
      footer: footer,
    );
  }

  Widget _buildCollectionWorkspaceHeader({
    required String eyebrow,
    required String title,
    required String subtitle,
    required List<_CollectionHeaderFilter> primaryFilters,
    List<_CollectionHeaderFilter> secondaryFilters = const [],
    Widget? action,
    String searchQuery = '',
  }) {
    return AdminSurface(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
          ),
          if (primaryFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildFilterChipRow(
              primaryFilters
                  .map(
                    (filter) => AdminFilterChip(
                      label: filter.label,
                      selected: filter.selected,
                      icon: filter.icon,
                      badgeCount: filter.badgeCount,
                      onTap: filter.onTap,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (secondaryFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildFilterChipRow(
              secondaryFilters
                  .map(
                    (filter) => AdminFilterChip(
                      label: filter.label,
                      selected: filter.selected,
                      icon: filter.icon,
                      badgeCount: filter.badgeCount,
                      onTap: filter.onTap,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: action),
          ],
          if (searchQuery.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            AdminPill(
              label: 'Search: $searchQuery',
              color: AdminPalette.textSecondary,
              icon: Icons.search_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChipRow(List<Widget> chips) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < chips.length; index++) ...[
            chips[index],
            if (index < chips.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _joinCardSubtitleParts(Iterable<String?> parts) {
    final visibleParts = parts
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return visibleParts.join(' | ');
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

    String fallback = '';
    Object? rawValue = value;
    if (value is Timestamp) {
      rawValue = value.toDate();
    } else if (value is DateTime) {
      rawValue = value;
    } else {
      fallback = value.toString().trim();
      rawValue = fallback;
    }

    final dateTime = OpportunityMetadata.normalizeDeadline(rawValue);
    if (dateTime != null) {
      final resolvedPrefix = OpportunityMetadata.isDeadlineExpired(dateTime)
          ? 'Expired'
          : prefix;
      return '$resolvedPrefix ${DateFormat('MMM d').format(dateTime)}';
    }

    if (fallback.isEmpty) {
      return null;
    }

    return '$prefix ${DisplayText.capitalizeLeadingLabel(fallback)}';
  }

  Color _deadlineBadgeColor(String label) {
    return label.trim().toLowerCase().startsWith('expired')
        ? AdminPalette.danger
        : AdminPalette.info;
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

  Color _trainingAccentColor(String type) {
    switch (type.trim().toLowerCase()) {
      case 'book':
        return const Color(0xFF0F766E);
      case 'video':
        return const Color(0xFFDC2626);
      case 'file':
        return const Color(0xFF475569);
      case 'course':
        return const Color(0xFF0284C7);
      default:
        return _libraryAccentColor;
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
            const SizedBox(height: 10),
            _buildIdeaHighlightsSection(idea, statusColor: statusColor),
            if (summary.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSurface(
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 12.8,
                        height: 1.5,
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
              const SizedBox(height: 10),
              Text(
                'Problem, Solution & Impact',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (problemText.trim().isNotEmpty) ...[
                _buildIdeaNarrativeCard(
                  title: AppLocalizations.of(context)!.uiProblemStatement,
                  value: problemText,
                  icon: Icons.report_problem_outlined,
                  color: AdminPalette.danger,
                ),
                const SizedBox(height: 8),
              ],
              if (solutionText.trim().isNotEmpty) ...[
                _buildIdeaNarrativeCard(
                  title: AppLocalizations.of(context)!.uiProposedSolution,
                  value: solutionText,
                  icon: Icons.auto_fix_high_outlined,
                  color: _ideaAccentColor,
                ),
                const SizedBox(height: 8),
              ],
              if (benefitsText.trim().isNotEmpty)
                _buildIdeaNarrativeCard(
                  title: AppLocalizations.of(context)!.uiExpectedBenefits,
                  value: benefitsText,
                  icon: Icons.trending_up_rounded,
                  color: AdminPalette.success,
                ),
            ],
            const SizedBox(height: 10),
            Text(
              'Audience & Metadata',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildIdeaMetadataGrid(<_IdeaDetailItem>[
              _IdeaDetailItem(
                'Level',
                _formatIdeaBadgeValue(idea.level),
                icon: Icons.school_outlined,
                color: AdminPalette.primary,
              ),
              if (targetAudience.trim().isNotEmpty)
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
            ]),
            if (skills.isNotEmpty ||
                teamNeeded.isNotEmpty ||
                tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSurface(
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team & Skill Signals',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildTagSection(
                        'Skills Needed',
                        skills,
                        _ideaAccentColor,
                      ),
                    ],
                    if (teamNeeded.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildTagSection(
                        'Team Needed',
                        teamNeeded,
                        AdminPalette.info,
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildTagSection('Tags', tags, AdminPalette.activity),
                    ],
                  ],
                ),
              ),
            ],
            if (canEditIdea) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openIdeaEditor(idea: idea);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(AppLocalizations.of(context)!.uiEditIdea),
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
        icon: Icons.groups_rounded,
        label: 'Interested',
        value: '${idea.interestedCount}',
        color: AdminPalette.info,
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
            style: TextStyle(
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
                style: TextStyle(
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
                  style: TextStyle(
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
            style: TextStyle(
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    if ((subtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
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
                      style: TextStyle(
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
      border: Border.all(color: item.resolvedColor.withValues(alpha: 0.12)),
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
                  color: item.resolvedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: item.resolvedColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                style: TextStyle(
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

  List<Widget> _buildAdminApplicationDecisionButtons(
    AdminApplicationItemModel item, {
    required bool isBusy,
  }) {
    return [
      FilledButton.icon(
        onPressed: isBusy
            ? null
            : () {
                Navigator.pop(context);
                _updateAdminApplicationStatus(item, ApplicationStatus.accepted);
              },
        icon: const Icon(Icons.verified_outlined, size: 18),
        label: Text(isBusy ? 'Working...' : 'Approve'),
        style: FilledButton.styleFrom(
          backgroundColor: AdminPalette.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      OutlinedButton.icon(
        onPressed: isBusy
            ? null
            : () {
                Navigator.pop(context);
                _updateAdminApplicationStatus(item, ApplicationStatus.rejected);
              },
        icon: const Icon(Icons.block_outlined, size: 18),
        label: Text(AppLocalizations.of(context)!.uiReject),
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminPalette.danger,
          side: BorderSide(color: AdminPalette.danger.withValues(alpha: 0.34)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];
  }

  Future<void> _updateAdminApplicationStatus(
    AdminApplicationItemModel item,
    String status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final adminId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    if (!item.canBeManagedByAdmin(adminId)) {
      context.showAppSnackBar(
        l10n.uiYouCanOnlyUpdateApplicationsForOpportunitiesYouPostedAs,
        title: l10n.uiApplicationUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final error = await context.read<AdminProvider>().updateApplicationStatus(
      appId: item.id,
      status: status,
      adminId: adminId,
    );

    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      error ??
          l10n.uiApplicationStatusValue(
            ApplicationStatus.sentenceLabel(status, l10n),
          ),
      title: error == null
          ? l10n.uiApplicationUpdated
          : l10n.updateUnavailableTitle,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  void _showApplicantQuickActions(AdminApplicationItemModel item) {
    final applicantFuture = _adminService.getUserById(
      item.application.studentId,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<UserModel?>(
          future: applicantFuture,
          builder: (context, snapshot) {
            final applicant = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final university = (applicant?.university ?? '').trim();
            final academicLevel = (applicant?.academicLevel ?? '').trim();
            final location = (applicant?.location ?? '').trim();
            final subtitle = university.isNotEmpty
                ? university
                : location.isNotEmpty
                ? location
                : 'Student profile and submitted documents.';

            return DraggableScrollableSheet(
              initialChildSize: 0.58,
              minChildSize: 0.34,
              maxChildSize: 0.84,
              expand: false,
              builder: (context, scrollController) => ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Material(
                  color: AdminPalette.background,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                    children: [
                      _buildSheetHandle(),
                      const SizedBox(height: 16),
                      AdminSurface(
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        gradient: AdminPalette.heroGradient(AdminPalette.info),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: Column(
                          children: [
                            ProfileAvatar(
                              user: applicant,
                              userId: item.application.studentId,
                              fallbackName: item.studentName,
                              role: 'student',
                              radius: 34,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.studentName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white70,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                const AdminPill(
                                  label: 'Student',
                                  color: Colors.white,
                                  icon: Icons.school_outlined,
                                ),
                                if (academicLevel.isNotEmpty)
                                  AdminPill(
                                    label: DisplayText.capitalizeLeadingLabel(
                                      academicLevel,
                                    ),
                                    color: Colors.white,
                                    icon: Icons.workspace_premium_outlined,
                                  ),
                                if ((applicant?.isActive ?? true) == false)
                                  const AdminPill(
                                    label: 'Blocked',
                                    color: Colors.white,
                                    icon: Icons.block_outlined,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: LinearProgressIndicator(),
                        )
                      else if (applicant == null)
                        AdminSurface(
                          radius: 18,
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'We could not load the full student profile right now. You can still open the application CV and the visible submitted applications.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: AdminPalette.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildResponsiveActionGroup([
                        FilledButton.icon(
                          onPressed: applicant == null
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!mounted) {
                                      return;
                                    }
                                    showAdminStudentProfileSheet(
                                      this.context,
                                      user: applicant,
                                    );
                                  });
                                },
                          icon: const Icon(Icons.person_outline_rounded),
                          label: Text(
                            AppLocalizations.of(context)!.uiViewProfile,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminPalette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) {
                                return;
                              }
                              _showApplicationCv(item.application.id);
                            });
                          },
                          icon: const Icon(Icons.description_outlined),
                          label: Text(AppLocalizations.of(context)!.uiViewCv),
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminPalette.activity,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) {
                                return;
                              }
                              showAdminStudentApplicationsSheet(
                                this.context,
                                studentId: item.application.studentId,
                                studentName: item.studentName,
                              );
                            });
                          },
                          icon: const Icon(Icons.assignment_outlined),
                          label: Text(
                            AppLocalizations.of(context)!.uiViewAllApps,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminPalette.info,
                            side: BorderSide(
                              color: AdminPalette.info.withValues(alpha: 0.26),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showApplicationCv(String applicationId) async {
    final l10n = AppLocalizations.of(context)!;
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
              return SizedBox(
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
                  child: Text(
                    'CV details are not available for this application',
                  ),
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (cv.email.isNotEmpty)
                      Text(
                        cv.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminPalette.textMuted,
                        ),
                      ),
                    if (cv.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cv.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminPalette.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildApplicationDocumentCard(
                      title: l10n.uiPrimaryCvPdf,
                      subtitle: cv.hasUploadedCv
                          ? 'File: ${cv.uploadedCvDisplayName}\nUploaded: ${_formatDocumentDate(cv.uploadedCvUploadedAt)}'
                          : l10n.uiNoUploadedCv,
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
                    const SizedBox(height: 10),
                    _buildApplicationDocumentCard(
                      title: l10n.uiBuiltCv,
                      subtitle: cv.hasExportedPdf
                          ? l10n.uiBuiltCvPdfReadyForReview
                          : cv.hasBuilderContent
                          ? l10n.uiBuiltCvDetailsAvailableNoPdfYet
                          : l10n.uiNoBuiltCvDetailsAvailable,
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final document = await _documentAccessService.getApplicationCvDocument(
        applicationId: applicationId,
        variant: variant,
      );
      if (!mounted) return;

      if (requirePdf && !document.isPdf) {
        context.showAppSnackBar(
          l10n.uiThisDocumentIsNotAValidPdfFile,
          title: l10n.uiPreviewUnavailable,
          type: AppFeedbackType.warning,
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
      if (!mounted) return;
      if (!launched) {
        context.showAppSnackBar(
          l10n.uiCouldNotOpenTheDocumentRightNow,
          title: l10n.uiDocumentUnavailable,
          type: AppFeedbackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        _documentErrorMessage(e),
        title: l10n.uiDocumentUnavailable,
        type: AppFeedbackType.error,
      );
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
            style: TextStyle(
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
              color: AdminPalette.textSecondary,
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 10),
            Text(
              warningText,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AdminPalette.activity,
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
                  label: Text(AppLocalizations.of(context)!.uiViewCv),
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
                  label: Text(AppLocalizations.of(context)!.uiDownloadCv),
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

    return 'We couldn\'t open the document right now.';
  }

  void _showOpportunityDetails(Map<String, dynamic> opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<AdminProvider>();
    final opportunityId = (opportunity['id'] ?? '').toString();
    final applications = _applicationsForOpportunity(provider, opportunityId);
    final opportunityModel = OpportunityModel.fromMap(opportunity);
    final opportunityType = OpportunityType.parse(
      (opportunity['type'] ?? '').toString(),
    );
    final typeLabel = OpportunityType.label(opportunityType, l10n);
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
      opportunityModel.effectiveStatus(),
    );
    final compensationLabel =
        OpportunityType.parse(opportunityModel.type) ==
            OpportunityType.sponsoring
        ? opportunityModel.fundingLabel(preferFundingNote: true)
        : OpportunityMetadata.buildCompensationLabel(
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
                  icon: _ideaStatusIcon(opportunityModel.effectiveStatus()),
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
            const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              _buildIdeaNarrativeCard(
                title: AppLocalizations.of(context)!.uiRoleOverview,
                value: description,
                icon: Icons.description_outlined,
                color: typeColor,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Location & Logistics',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
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
              if (employmentLabel.isNotEmpty)
                _IdeaDetailItem(
                  'Employment',
                  employmentLabel,
                  icon: Icons.badge_outlined,
                  color: AdminPalette.primary,
                ),
              if (paidLabel.isNotEmpty)
                _IdeaDetailItem(
                  'Paid Status',
                  paidLabel,
                  icon: Icons.account_balance_wallet_outlined,
                  color: AdminPalette.success,
                ),
              if ((opportunityModel.duration ?? '').trim().isNotEmpty)
                _IdeaDetailItem(
                  'Duration',
                  opportunityModel.duration!,
                  icon: Icons.schedule_outlined,
                  color: AdminPalette.textMuted,
                ),
            ]),
            if (requirements.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailListCard(
                title: AppLocalizations.of(context)!.requirementsLabel,
                items: requirements,
                icon: Icons.checklist_rounded,
                color: typeColor,
              ),
            ],
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailListCard(
                title: AppLocalizations.of(context)!.uiBenefits,
                items: benefits,
                icon: Icons.star_outline_rounded,
                color: AdminPalette.success,
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSurface(
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTagSection('Opportunity Tags', tags, typeColor),
                  ],
                ),
              ),
            ],
            if (applications.isNotEmpty) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showOpportunityApplications(opportunity, applications);
                },
                icon: const Icon(Icons.assignment_outlined),
                label: Text(
                  AppLocalizations.of(
                    context,
                  )!.uiViewApplicationsCount(applications.length),
                ),
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
              accentColor: _scholarshipAccentColor,
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
            const SizedBox(height: 10),
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
                  color: _scholarshipAccentColor,
                ),
              _IdeaHighlightItem(
                icon: Icons.business_outlined,
                label: 'Provider',
                value: providerName,
                color: _scholarshipAccentColor,
              ),
              _IdeaHighlightItem(
                icon: link.isNotEmpty
                    ? Icons.link_rounded
                    : Icons.link_off_rounded,
                label: 'Access',
                value: link.isNotEmpty
                    ? 'Application Link Ready'
                    : 'Link not added',
                color: link.isNotEmpty
                    ? AdminPalette.info
                    : AdminPalette.textMuted,
              ),
            ]),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildIdeaNarrativeCard(
                title: AppLocalizations.of(context)!.uiScholarshipOverview,
                value: description,
                icon: Icons.description_outlined,
                color: _scholarshipAccentColor,
              ),
            ],
            if (eligibility.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildIdeaNarrativeCard(
                title: AppLocalizations.of(context)!.eligibilityLabel,
                value: eligibility,
                icon: Icons.verified_user_outlined,
                color: AdminPalette.activity,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Positioning & Access',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildIdeaMetadataGrid([
              if (categoryText.trim().isNotEmpty)
                _IdeaDetailItem(
                  'Category',
                  DisplayText.capitalizeWords(categoryText),
                  icon: Icons.category_outlined,
                  color: AdminPalette.info,
                ),
              if (levelText.trim().isNotEmpty)
                _IdeaDetailItem(
                  'Level',
                  DisplayText.capitalizeWords(levelText),
                  icon: Icons.school_outlined,
                  color: AdminPalette.primary,
                ),
              if (locationText.trim().isNotEmpty)
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
                    : 'Link unavailable',
                icon: link.isNotEmpty
                    ? Icons.open_in_new_rounded
                    : Icons.link_off_rounded,
                color: link.isNotEmpty
                    ? AdminPalette.info
                    : AdminPalette.textMuted,
              ),
            ]),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSurface(
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: _buildTagSection(
                  'Scholarship Tags',
                  tags,
                  _scholarshipAccentColor,
                ),
              ),
            ],
            if (link.isNotEmpty) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => _openExternalLink(link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  AppLocalizations.of(context)!.uiOpenScholarshipLink,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _scholarshipAccentColor,
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
    final trainingAccentColor = _trainingAccentColor(training.type);
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
        : 'Certificate not included';
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 12),
            _buildDetailHeroCard(
              title: training.title,
              subtitle: providerName,
              icon: _trainingIcon(training.type),
              accentColor: trainingAccentColor,
              chips: [
                AdminActionChip(
                  label: typeLabel,
                  icon: _trainingIcon(training.type),
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
            const SizedBox(height: 10),
            _buildDetailHighlightsGrid([
              if (training.duration.trim().isNotEmpty)
                _IdeaHighlightItem(
                  icon: Icons.schedule_outlined,
                  label: 'Duration',
                  value: training.duration,
                  color: trainingAccentColor,
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
              const SizedBox(height: 10),
              _buildIdeaNarrativeCard(
                title: AppLocalizations.of(context)!.uiTrainingOverview,
                value: description,
                icon: Icons.description_outlined,
                color: trainingAccentColor,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Delivery & Access',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildIdeaMetadataGrid([
              if (sourceLabel.isNotEmpty)
                _IdeaDetailItem(
                  'Source',
                  sourceLabel,
                  icon: Icons.cloud_outlined,
                  color: AdminPalette.secondary,
                ),
              if (training.language.trim().isNotEmpty)
                _IdeaDetailItem(
                  'Language',
                  DisplayText.capitalizeWords(training.language),
                  icon: Icons.translate_rounded,
                  color: AdminPalette.activity,
                ),
              if (accessLabel.isNotEmpty)
                _IdeaDetailItem(
                  'Access',
                  accessLabel,
                  icon: Icons.payments_outlined,
                  color: training.isFree == true
                      ? AdminPalette.success
                      : _ideaAccentColor,
                ),
              if (certificateLabel.isNotEmpty)
                _IdeaDetailItem(
                  'Certificate',
                  certificateLabel,
                  icon: Icons.verified_outlined,
                  color: AdminPalette.success,
                ),
            ]),
            if (authors.isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSurface(
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: _buildTagSection(
                  'Authors',
                  authors,
                  trainingAccentColor,
                ),
              ),
            ],
            if (link.isNotEmpty) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => _openExternalLink(link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(AppLocalizations.of(context)!.uiOpenResource),
                style: FilledButton.styleFrom(
                  backgroundColor: trainingAccentColor,
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
          style: TextStyle(
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
              style: TextStyle(fontSize: 13, color: AdminPalette.textSecondary),
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
          style: TextStyle(
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

  Widget _cardMetaBadge(String label, Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.05),
            AdminPalette.surfaceMuted,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 11.5,
              color: color.withValues(alpha: 0.84),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.2,
                  fontWeight: FontWeight.w600,
                  color: AdminPalette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.2,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return AdminEmptyState(
      icon: icon,
      title: AppLocalizations.of(context)!.uiNoResultsInThisView,
      message: message,
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    if (isCompact) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.34),
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: _buildDeleteConfirmationSurface(
            title: title,
            content: content,
            showHandle: true,
            onCancel: () => Navigator.pop(ctx),
            onConfirm: () {
              Navigator.pop(ctx);
              onConfirm();
            },
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _buildDeleteConfirmationSurface(
            title: title,
            content: content,
            onCancel: () => Navigator.pop(ctx),
            onConfirm: () {
              Navigator.pop(ctx);
              onConfirm();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmationSurface({
    required String title,
    required String content,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    bool showHandle = false,
  }) {
    return AdminSurface(
      radius: showHandle ? 28 : 26,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      border: Border.all(color: AdminPalette.danger.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: AdminPalette.danger.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHandle) ...[
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AdminPalette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminPalette.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AdminPalette.danger,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 13.2,
                        height: 1.5,
                        color: AdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminPalette.textSecondary,
                    side: BorderSide(
                      color: AdminPalette.border.withValues(alpha: 0.9),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.uiDelete),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminPalette.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
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
    if (ApplicationStatus.parse(status) == ApplicationStatus.withdrawn) {
      return AdminPalette.textMuted;
    }

    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'open':
        return AdminPalette.success;
      case 'rejected':
        return AdminPalette.danger;
      case 'featured':
        return _accentColor;
      default:
        return _ideaAccentColor;
    }
  }
}

class _BadgeData {
  final String label;
  final Color color;

  const _BadgeData(this.label, this.color);
}

class _CollectionHeaderFilter {
  final String label;
  final bool selected;
  final IconData icon;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _CollectionHeaderFilter({
    required this.label,
    required this.selected,
    required this.icon,
    this.badgeCount,
    this.onTap,
  });
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
  final Color? color;

  const _IdeaDetailItem(
    this.label,
    this.value, {
    this.icon = Icons.info_outline_rounded,
    this.color,
  });

  Color get resolvedColor => color ?? AdminPalette.textMuted;
}

class _AdminTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  const _AdminTabBarHeaderDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

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
    return child != oldDelegate.child || extent != oldDelegate.extent;
  }
}
