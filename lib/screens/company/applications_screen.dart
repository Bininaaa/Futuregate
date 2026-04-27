import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/cv_model.dart';
import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/document_access_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/application_status.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../utils/document_launch_helper.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/application_status_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import '../../widgets/shared/reviewer_cv_widgets.dart';
import '../chat/user_profile_preview_screen.dart';
import '../notifications_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final String? initialApplicationId;
  final String? initialOpportunityId;
  final String? initialOpportunityTitle;
  final bool showBackButton;
  final bool embedded;

  const ApplicationsScreen({
    super.key,
    this.initialApplicationId,
    this.initialOpportunityId,
    this.initialOpportunityTitle,
    this.showBackButton = false,
    this.embedded = false,
  });

  static Future<void> showApplicationDetailsSheet(
    BuildContext context, {
    required ApplicationModel application,
    OpportunityModel? opportunity,
    required CompanyProvider provider,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ApplicationDetailsSheetHost(
              application: application,
              opportunity: opportunity,
              provider: provider,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationDetailsSheetHost extends StatefulWidget {
  final ApplicationModel application;
  final OpportunityModel? opportunity;
  final CompanyProvider provider;

  const _ApplicationDetailsSheetHost({
    required this.application,
    required this.opportunity,
    required this.provider,
  });

  @override
  State<_ApplicationDetailsSheetHost> createState() =>
      _ApplicationDetailsSheetHostState();
}

class _ApplicationDetailsSheetHostState
    extends State<_ApplicationDetailsSheetHost> {
  final GlobalKey<_ApplicationsScreenState> _screenKey =
      GlobalKey<_ApplicationsScreenState>();
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    if (!mounted || _opened) {
      return;
    }

    _opened = true;
    final state = _screenKey.currentState;
    if (state != null) {
      await state._showApplicationDetailsSheet(
        _ApplicationListItem(
          application: widget.application,
          opportunity: widget.opportunity,
        ),
        widget.provider,
      );
    }

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(child: ApplicationsScreen(key: _screenKey, embedded: true));
  }
}

enum _ApplicationStatusFilter { all, pending, approved, rejected }

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  static const String _allOpportunityFilter = 'all';
  static const String _allTypeFilter = 'all';

  final TextEditingController _searchController = TextEditingController();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _candidateQueueKey = GlobalKey();

  _ApplicationStatusFilter _selectedStatusFilter = _ApplicationStatusFilter.all;
  String _selectedOpportunityFilter = _allOpportunityFilter;
  String _selectedTypeFilter = _allTypeFilter;
  String _searchQuery = '';
  bool _openedFocusedDetails = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String get _localeName => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    if ((widget.initialApplicationId ?? '').trim().isEmpty) {
      final initialOpportunityId = (widget.initialOpportunityId ?? '').trim();
      if (initialOpportunityId.isNotEmpty) {
        _selectedOpportunityFilter = initialOpportunityId;
      }
    }
    Future.microtask(_loadApplicationsData);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) {
      return;
    }
    setState(() => _searchQuery = nextQuery);
  }

  Future<void> _loadApplicationsData() async {
    if (!mounted) {
      return;
    }

    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      return;
    }

    final provider = context.read<CompanyProvider>();
    await Future.wait([
      provider.loadApplications(user.uid),
      provider.loadOpportunities(user.uid),
    ]);
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedStatusFilter != _ApplicationStatusFilter.all) {
      count++;
    }
    if (_selectedTypeFilter != _allTypeFilter) {
      count++;
    }
    if (_selectedOpportunityFilter != _allOpportunityFilter) {
      count++;
    }
    if (_searchQuery.isNotEmpty) {
      count++;
    }
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  String _prefilledOpportunityId() {
    if ((widget.initialApplicationId ?? '').trim().isNotEmpty) {
      return '';
    }
    return (widget.initialOpportunityId ?? '').trim();
  }

  String _prefilledOpportunityTitle(CompanyProvider provider) {
    final directTitle = (widget.initialOpportunityTitle ?? '').trim();
    if (directTitle.isNotEmpty) {
      return directTitle;
    }

    final opportunityId = _prefilledOpportunityId();
    if (opportunityId.isEmpty) {
      return '';
    }

    return provider.opportunities
            .where((item) => item.id == opportunityId)
            .firstOrNull
            ?.title
            .trim() ??
        '';
  }

  List<_ApplicationListItem> _filteredItems(CompanyProvider provider) {
    final baseItems =
        provider.applications
            .map(
              (application) => _ApplicationListItem(
                application: application,
                opportunity: provider.opportunities
                    .where((item) => item.id == application.opportunityId)
                    .firstOrNull,
              ),
            )
            .toList()
          ..sort((first, second) {
            final firstTime =
                first.application.appliedAt?.millisecondsSinceEpoch ?? 0;
            final secondTime =
                second.application.appliedAt?.millisecondsSinceEpoch ?? 0;
            return secondTime.compareTo(firstTime);
          });

    final focusedId = (widget.initialApplicationId ?? '').trim();
    if (focusedId.isNotEmpty) {
      return baseItems
          .where((item) => item.application.id == focusedId)
          .toList(growable: false);
    }

    return baseItems
        .where(_matchesStatusFilter)
        .where(_matchesTypeFilter)
        .where(_matchesOpportunityFilter)
        .where(_matchesSearchFilter)
        .toList(growable: false);
  }

  bool _matchesStatusFilter(_ApplicationListItem item) {
    final status = ApplicationStatus.parse(item.application.status);
    return switch (_selectedStatusFilter) {
      _ApplicationStatusFilter.all => true,
      _ApplicationStatusFilter.pending => status == ApplicationStatus.pending,
      _ApplicationStatusFilter.approved => status == ApplicationStatus.accepted,
      _ApplicationStatusFilter.rejected => status == ApplicationStatus.rejected,
    };
  }

  bool _matchesTypeFilter(_ApplicationListItem item) {
    final type = OpportunityType.parse(item.opportunity?.type);
    if (_selectedTypeFilter == _allTypeFilter) {
      return true;
    }
    return type == _selectedTypeFilter;
  }

  bool _matchesOpportunityFilter(_ApplicationListItem item) {
    return _selectedOpportunityFilter == _allOpportunityFilter ||
        item.application.opportunityId == _selectedOpportunityFilter;
  }

  bool _matchesSearchFilter(_ApplicationListItem item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final opportunity = item.opportunity;
    final searchText = <String>[
      item.application.studentName,
      opportunity?.title ?? '',
      opportunity?.location ?? '',
      OpportunityType.label(opportunity?.type ?? '', _l10n),
      ApplicationStatus.label(item.application.status, _l10n),
    ].join(' ').toLowerCase();

    return searchText.contains(query);
  }

  int _statusCount(CompanyProvider provider, _ApplicationStatusFilter filter) {
    return provider.applications.where((application) {
      final status = ApplicationStatus.parse(application.status);
      return switch (filter) {
        _ApplicationStatusFilter.all => true,
        _ApplicationStatusFilter.pending => status == ApplicationStatus.pending,
        _ApplicationStatusFilter.approved =>
          status == ApplicationStatus.accepted,
        _ApplicationStatusFilter.rejected =>
          status == ApplicationStatus.rejected,
      };
    }).length;
  }

  String _statusLabel(_ApplicationStatusFilter filter) {
    return switch (filter) {
      _ApplicationStatusFilter.all => _l10n.uiAll,
      _ApplicationStatusFilter.pending => _l10n.uiPending,
      _ApplicationStatusFilter.approved => _l10n.uiApproved,
      _ApplicationStatusFilter.rejected => _l10n.uiRejected,
    };
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _selectedStatusFilter = _ApplicationStatusFilter.all;
      _selectedTypeFilter = _allTypeFilter;
      _selectedOpportunityFilter = _allOpportunityFilter;
      _searchQuery = '';
    });
  }

  void _maybeOpenFocusedDetails(
    List<_ApplicationListItem> items,
    CompanyProvider provider,
  ) {
    if (_openedFocusedDetails ||
        items.length != 1 ||
        (widget.initialApplicationId ?? '').trim().isEmpty ||
        provider.applicationsLoading) {
      return;
    }

    _openedFocusedDetails = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showApplicationDetailsSheet(items.first, provider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final provider = context.watch<CompanyProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final showLocalTopBar = !widget.embedded || widget.showBackButton;

    Widget wrapScaffold(Widget body) {
      final scaffold = Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.embedded ? body : SafeArea(bottom: false, child: body),
      );
      if (widget.embedded) {
        return scaffold;
      }
      return AppShellBackground(child: scaffold);
    }

    if (user == null) {
      return wrapScaffold(
        const SafeArea(child: AppLoadingView(showBottomBar: true)),
      );
    }

    final items = _filteredItems(provider);
    final isFocusedView = (widget.initialApplicationId ?? '').trim().isNotEmpty;
    final prefilledOpportunityId = _prefilledOpportunityId();
    final isOpportunityPrefiltered =
        prefilledOpportunityId.isNotEmpty &&
        _selectedOpportunityFilter == prefilledOpportunityId;
    final prefilledOpportunityTitle = _prefilledOpportunityTitle(provider);
    final resultsCount = items.length;
    final totalApplications = provider.applications.length;
    final pendingCount = _statusCount(
      provider,
      _ApplicationStatusFilter.pending,
    );
    final reviewedCount = totalApplications - pendingCount;
    final opportunityCounts = _applicationCountsByOpportunity(provider);
    final pendingOpportunityCount = _pendingOpportunityCount(provider);

    _maybeOpenFocusedDetails(items, provider);

    return wrapScaffold(
      GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          color: _ApplicationsPalette.primary,
          onRefresh: _loadApplicationsData,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    widget.embedded ? 8 : 12,
                    16,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildApplicationsHero(
                        user: user,
                        unreadCount: unreadCount,
                        isFocusedView: isFocusedView,
                        totalApplications: totalApplications,
                        pendingCount: pendingCount,
                        reviewedCount: reviewedCount,
                        showTopBar: showLocalTopBar,
                      ),
                      if (pendingOpportunityCount > 0 && !isFocusedView) ...[
                        const SizedBox(height: 12),
                        _InlineBanner(
                          icon: Icons.warning_amber_rounded,
                          title: _l10n.uiPendingOpportunitiesNeedAttention,
                          message: pendingCount == 1
                              ? _l10n.uiPendingApplicationsNeedReview(
                                  pendingCount,
                                )
                              : _l10n
                                    .uiPendingApplicationsAcrossOpportunitiesNeedReview(
                                      pendingCount,
                                      pendingOpportunityCount,
                                    ),
                          tone: _ApplicationsPalette.accent,
                          background: _ApplicationsPalette.accentSoft,
                          actionLabel: isFocusedView
                              ? null
                              : _l10n.uiShowPending,
                          onAction: isFocusedView
                              ? null
                              : _showPendingApplications,
                        ),
                      ],
                      if (isOpportunityPrefiltered && !isFocusedView) ...[
                        const SizedBox(height: 12),
                        _InlineBanner(
                          icon: Icons.groups_rounded,
                          title: prefilledOpportunityTitle.isNotEmpty
                              ? _l10n.uiApplicationsForOpportunitytitle(
                                  prefilledOpportunityTitle,
                                )
                              : _l10n.uiApplications,
                          message: resultsCount == 0
                              ? _l10n
                                    .uiThereAreNoSubmittedApplicationsForThisOpportunityRightNow
                              : _l10n
                                    .uiShowingOnlyTheCandidatesWhoAppliedToThisRole,
                          tone: _ApplicationsPalette.primary,
                          background: _ApplicationsPalette.primarySoft,
                          actionLabel: _l10n.uiViewAllApps,
                          onAction: _clearFilters,
                        ),
                      ],
                      if ((provider.applicationsError ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InlineBanner(
                          icon: Icons.info_outline_rounded,
                          title: _l10n.uiApplicationDataIsUnavailable,
                          message: provider.applicationsError!,
                          tone: _ApplicationsPalette.error,
                          background: _ApplicationsPalette.error.withValues(
                            alpha: AppColors.isDark ? 0.14 : 0.08,
                          ),
                        ),
                      ],
                      if (isFocusedView) ...[
                        const SizedBox(height: 12),
                        _FocusedApplicationBanner(count: resultsCount),
                      ] else ...[
                        const SizedBox(height: 14),
                        _buildFiltersPanel(
                          provider,
                          resultsCount: resultsCount,
                          totalApplications: totalApplications,
                          opportunityCounts: opportunityCounts,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        key: _candidateQueueKey,
                        child: _buildQueueHeader(
                          resultsCount: resultsCount,
                          totalApplications: totalApplications,
                          isFocusedView: isFocusedView,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.applicationsLoading && provider.applications.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingState(),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyApplicationsState(
                    hasFilters: _hasActiveFilters,
                    isFocusedView: isFocusedView,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = items[index];
                      return _buildApplicationCard(item, provider);
                    }, childCount: items.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _applicationCountsByOpportunity(CompanyProvider provider) {
    final counts = <String, int>{};

    for (final application in provider.applications) {
      final opportunityId = application.opportunityId.trim();
      if (opportunityId.isEmpty) {
        continue;
      }
      counts.update(opportunityId, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  int _pendingOpportunityCount(CompanyProvider provider) {
    final ids = <String>{};

    for (final application in provider.applications) {
      if (ApplicationStatus.parse(application.status) !=
          ApplicationStatus.pending) {
        continue;
      }

      final opportunityId = application.opportunityId.trim();
      if (opportunityId.isNotEmpty) {
        ids.add(opportunityId);
      }
    }

    return ids.length;
  }

  void _showPendingApplications() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _selectedStatusFilter = _ApplicationStatusFilter.pending;
      _selectedTypeFilter = _allTypeFilter;
      _selectedOpportunityFilter = _allOpportunityFilter;
      _searchQuery = '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final queueContext = _candidateQueueKey.currentContext;
      if (queueContext != null) {
        Scrollable.ensureVisible(
          queueContext,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    });
  }

  bool _isFreshApplication(Timestamp? value) {
    if (value == null) {
      return false;
    }

    final difference = DateTime.now().difference(value.toDate());
    return !difference.isNegative && difference.inHours < 48;
  }

  String? _relativeDateLabel(Timestamp? value) {
    if (value == null) {
      return null;
    }

    final appliedAt = value.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(appliedAt.year, appliedAt.month, appliedAt.day);
    final difference = today.difference(target).inDays;

    if (difference <= 0) {
      return _l10n.uiToday;
    }
    if (difference == 1) {
      return _l10n.uiYesterday;
    }
    if (difference < 7) {
      return _l10n.uiDaysAgo(difference);
    }
    if (difference < 30) {
      final weeks = (difference / 7).ceil();
      return _l10n.uiWeeksAgo(weeks);
    }

    return DateFormat('MMM d', _localeName).format(appliedAt);
  }

  Widget _buildTopBar({
    required dynamic user,
    required int unreadCount,
    required bool isFocusedView,
  }) {
    final subtitle = isFocusedView
        ? _l10n.uiFocusedReviewMode
        : _l10n.uiReviewAndRespondToCandidates;

    return Row(
      children: [
        _HeaderIconButton(
          icon: widget.showBackButton
              ? Icons.arrow_back_rounded
              : Icons.groups_outlined,
          onTap: widget.showBackButton
              ? () => Navigator.of(context).maybePop()
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.uiApplications,
                style: AppTypography.product(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ApplicationsPalette.textPrimary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.product(
                  fontSize: 11,
                  color: _ApplicationsPalette.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!widget.showBackButton) ...[
          _NotificationIconButton(
            unreadCount: unreadCount,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _ApplicationsPalette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _ApplicationsPalette.border),
              ),
              child: ProfileAvatar(user: user, radius: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApplicationsHero({
    required dynamic user,
    required int unreadCount,
    required bool isFocusedView,
    required int totalApplications,
    required int pendingCount,
    required int reviewedCount,
    required bool showTopBar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTopBar) ...[
          _buildTopBar(
            user: user,
            unreadCount: unreadCount,
            isFocusedView: isFocusedView,
          ),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: _ApplicationsPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ApplicationsPalette.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _HeroStatTile(
                    label: _l10n.uiTotal,
                    value: '$totalApplications',
                    icon: Icons.inbox_rounded,
                    color: _ApplicationsPalette.primary,
                  ),
                ),
                const _KpiDivider(),
                Expanded(
                  child: _HeroStatTile(
                    label: _l10n.uiPending,
                    value: '$pendingCount',
                    icon: Icons.schedule_rounded,
                    color: _ApplicationsPalette.warning,
                  ),
                ),
                const _KpiDivider(),
                Expanded(
                  child: _HeroStatTile(
                    label: _l10n.uiReviewed,
                    value: '$reviewedCount',
                    icon: Icons.task_alt_rounded,
                    color: _ApplicationsPalette.success,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersPanel(
    CompanyProvider provider, {
    required int resultsCount,
    required int totalApplications,
    required Map<String, int> opportunityCounts,
  }) {
    final sectionLabelStyle = AppTypography.product(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: _ApplicationsPalette.textMuted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.uiFilters.toUpperCase(),
              style: sectionLabelStyle,
            ),
            const Spacer(),
            if (_activeFilterCount > 0)
              _CounterBadge(count: _activeFilterCount, label: _l10n.uiActive),
          ],
        ),
        const SizedBox(height: 10),
        _SearchField(
          controller: _searchController,
          hintText: _l10n.uiSearchByCandidateOpportunityLocationOrType,
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.uiStatus.toUpperCase(),
          style: sectionLabelStyle,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _ApplicationStatusFilter.values
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label: _statusLabel(filter),
                      count: _statusCount(provider, filter),
                      selected: _selectedStatusFilter == filter,
                      icon: switch (filter) {
                        _ApplicationStatusFilter.all => Icons.layers_outlined,
                        _ApplicationStatusFilter.pending =>
                          Icons.schedule_rounded,
                        _ApplicationStatusFilter.approved =>
                          Icons.check_circle_outline_rounded,
                        _ApplicationStatusFilter.rejected =>
                          Icons.cancel_outlined,
                      },
                      activeColor: switch (filter) {
                        _ApplicationStatusFilter.approved =>
                          _ApplicationsPalette.success,
                        _ApplicationStatusFilter.rejected =>
                          _ApplicationsPalette.error,
                        _ApplicationStatusFilter.pending =>
                          _ApplicationsPalette.warning,
                        _ApplicationStatusFilter.all =>
                          _ApplicationsPalette.primary,
                      },
                      onTap: () =>
                          setState(() => _selectedStatusFilter = filter),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.uiType.toUpperCase(),
          style: sectionLabelStyle,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _TypeFilterChip(
                label: _l10n.uiAll,
                icon: Icons.widgets_outlined,
                selected: _selectedTypeFilter == _allTypeFilter,
                tone: _toneForType(null),
                onTap: () =>
                    setState(() => _selectedTypeFilter = _allTypeFilter),
              ),
              const SizedBox(width: 6),
              _TypeFilterChip(
                label: _l10n.uiJobs,
                icon: OpportunityType.icon(OpportunityType.job),
                selected: _selectedTypeFilter == OpportunityType.job,
                tone: _toneForType(OpportunityType.job),
                onTap: () =>
                    setState(() => _selectedTypeFilter = OpportunityType.job),
              ),
              const SizedBox(width: 6),
              _TypeFilterChip(
                label: _l10n.uiInternships,
                icon: OpportunityType.icon(OpportunityType.internship),
                selected: _selectedTypeFilter == OpportunityType.internship,
                tone: _toneForType(OpportunityType.internship),
                onTap: () => setState(
                  () => _selectedTypeFilter = OpportunityType.internship,
                ),
              ),
              const SizedBox(width: 6),
              _TypeFilterChip(
                label: OpportunityType.label(OpportunityType.sponsoring, _l10n),
                icon: OpportunityType.icon(OpportunityType.sponsoring),
                selected: _selectedTypeFilter == OpportunityType.sponsoring,
                tone: _toneForType(OpportunityType.sponsoring),
                onTap: () => setState(
                  () => _selectedTypeFilter = OpportunityType.sponsoring,
                ),
              ),
            ],
          ),
        ),
        if (provider.opportunities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.uiRoles.toUpperCase(),
            style: sectionLabelStyle,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _OpportunityFilterChip(
                  label: _l10n.uiAllRoles,
                  count: totalApplications,
                  selected: _selectedOpportunityFilter == _allOpportunityFilter,
                  onTap: () => setState(
                    () => _selectedOpportunityFilter = _allOpportunityFilter,
                  ),
                ),
                const SizedBox(width: 6),
                ...provider.opportunities.map(
                  (opportunity) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _OpportunityFilterChip(
                      label: opportunity.title,
                      count: opportunityCounts[opportunity.id] ?? 0,
                      selected: _selectedOpportunityFilter == opportunity.id,
                      onTap: () => setState(
                        () => _selectedOpportunityFilter = opportunity.id,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _l10n.uiShowingValueOfValueApplications(
                  resultsCount,
                  totalApplications,
                ),
                style: AppTypography.product(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _ApplicationsPalette.textMuted,
                ),
              ),
            ),
            if (_hasActiveFilters)
              GestureDetector(
                onTap: _clearFilters,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _l10n.uiClearSearch,
                    style: AppTypography.product(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _ApplicationsPalette.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQueueHeader({
    required int resultsCount,
    required int totalApplications,
    required bool isFocusedView,
  }) {
    final subtitle = isFocusedView
        ? _l10n.uiDirectApplicationReviewWithAllCandidateDetailsInOnePlace
        : _hasActiveFilters
        ? _l10n.uiShowingValueOfValueApplications(
            resultsCount,
            totalApplications,
          )
        : _l10n.uiLatestCandidatesReadyForReviewMessagingAndCvChecks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFocusedView ? _l10n.uiApplicationSpotlight : _l10n.uiCandidateQueue,
          style: AppTypography.product(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ApplicationsPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.product(
            fontSize: 12,
            height: 1.45,
            color: _ApplicationsPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  _OpportunityTypeTone _toneForType(String? rawType) {
    final type = OpportunityType.parse(rawType);
    return _OpportunityTypeTone(
      background: OpportunityType.softBackground(type),
      foreground: OpportunityType.color(type),
    );
  }

  _OpportunityTypeTone _toneForOpportunity(OpportunityModel? opportunity) {
    if (opportunity == null) {
      return _OpportunityTypeTone(
        background: _ApplicationsPalette.surfaceAlt,
        foreground: _ApplicationsPalette.textSecondary,
      );
    }

    return _toneForType(opportunity.type);
  }

  String _typeLabel(String? rawType) {
    return OpportunityType.label(
      OpportunityType.parse(rawType),
      _l10n,
    ).toUpperCase();
  }

  String? _appliedDateLabel(Timestamp? value) {
    if (value == null) {
      return null;
    }
    return DateFormat.yMMMd(_localeName).format(value.toDate());
  }

  String? _opportunityTitleLabel(OpportunityModel? opportunity) {
    return OpportunityMetadata.sanitizeText(opportunity?.title);
  }

  Widget _buildApplicationCard(
    _ApplicationListItem item,
    CompanyProvider provider,
  ) {
    final application = item.application;
    final opportunity = item.opportunity;
    final typeTone = _toneForOpportunity(opportunity);
    final relativeAppliedLabel = _relativeDateLabel(application.appliedAt);
    final isFresh = _isFreshApplication(application.appliedAt);
    final titleLabel = _opportunityTitleLabel(opportunity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showApplicationDetailsSheet(item, provider),
          child: Container(
            decoration: BoxDecoration(
              color: _ApplicationsPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _ApplicationsPalette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: typeTone.foreground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfileAvatar(
                            radius: 22,
                            userId: application.studentId,
                            fallbackName: application.studentName,
                            role: 'student',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        application.studentName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.product(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              _ApplicationsPalette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isFresh) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _ApplicationsPalette.accentSoft,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          _l10n.uiNew,
                                          style: AppTypography.product(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _ApplicationsPalette.accent,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (titleLabel != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    titleLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.product(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _ApplicationsPalette.textSecondary,
                                    ),
                                  ),
                                ],
                                if (relativeAppliedLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _l10n.uiAppliedAppliedtext(
                                      relativeAppliedLabel,
                                    ),
                                    style: AppTypography.product(
                                      fontSize: 11,
                                      color: _ApplicationsPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ApplicationStatusBadge(
                                status: application.status,
                                fontSize: 10,
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: _ApplicationsPalette.textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showApplicationDetailsSheet(
    _ApplicationListItem item,
    CompanyProvider provider,
  ) async {
    final application = item.application;
    final opportunity = item.opportunity;
    final tone = _toneForOpportunity(opportunity);
    final studentName = _studentNameLabel(application);
    final opportunityTitle =
        _opportunityTitleLabel(opportunity) ?? _l10n.uiOpportunityUnavailable;
    final typeLabel = opportunity == null ? null : _typeLabel(opportunity.type);
    final appliedDateLabel = _appliedDateLabel(application.appliedAt);
    final relativeAppliedLabel = _relativeDateLabel(application.appliedAt);
    final status = ApplicationStatus.parse(application.status);
    final isPending = status == ApplicationStatus.pending;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          maxChildSize: 0.88,
          minChildSize: 0.44,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _ApplicationsPalette.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                children: [
                  _SheetHeaderBar(
                    title: _l10n.uiApplicationDetails,
                    subtitle: isPending
                        ? _l10n.uiReviewTheCandidateBeforeMakingADecision
                        : _l10n.uiKeepTheCandidateContextCloseAtHand,
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 14),
                  _DetailHeroCard(
                    studentName: studentName,
                    opportunityTitle: opportunityTitle,
                    appliedLabel: appliedDateLabel,
                    relativeAppliedLabel: relativeAppliedLabel,
                    typeLabel: typeLabel,
                    typeTone: tone,
                    status: application.status,
                    studentId: application.studentId,
                    onTapProfile: () {
                      Navigator.pop(sheetContext);
                      _openStudentProfile(application);
                    },
                  ),
                  const SizedBox(height: 14),
                  _ActionRail(
                    children: [
                      _WideActionButton(
                        label: _l10n.uiProfile,
                        icon: Icons.person_outline_rounded,
                        background: _ApplicationsPalette.primarySoft,
                        foreground: _ApplicationsPalette.primary,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openStudentProfile(application);
                        },
                      ),
                      _WideActionButton(
                        label: _l10n.uiMessage,
                        icon: Icons.chat_bubble_outline_rounded,
                        background: AppColors.current.secondarySoft,
                        foreground: _ApplicationsPalette.secondaryDark,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openChatWithStudent(application);
                        },
                      ),
                      _WideActionButton(
                        label: _l10n.uiViewCv,
                        icon: Icons.description_outlined,
                        background: _ApplicationsPalette.accentSoft,
                        foreground: _ApplicationsPalette.accent,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showCvSheet(context, application, provider);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _OpportunityLinkButton(
                    title: opportunity == null
                        ? _l10n.uiOpportunityUnavailable
                        : _l10n.uiOpportunityDetails,
                    subtitle: opportunityTitle,
                    icon: OpportunityType.icon(
                      opportunity?.type ?? OpportunityType.job,
                    ),
                    tone: tone.foreground,
                    onTap: () => _openOpportunityDetailsFromSheet(
                      sheetContext,
                      opportunity,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DecisionPanel(
                    status: status,
                    isBusy: provider.isAppBusy(application.id),
                    onApprove: isPending
                        ? () {
                            Navigator.pop(sheetContext);
                            _updateStatus(
                              context,
                              application,
                              ApplicationStatus.accepted,
                              provider,
                            );
                          }
                        : null,
                    onReject: isPending
                        ? () {
                            Navigator.pop(sheetContext);
                            _updateStatus(
                              context,
                              application,
                              ApplicationStatus.rejected,
                              provider,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _studentNameLabel(ApplicationModel application) {
    return OpportunityMetadata.sanitizeText(application.studentName) ??
        _l10n.uiUnnamedCandidate;
  }

  List<_DetailRowItem> _opportunityDetailRows(OpportunityModel? opportunity) {
    if (opportunity == null) {
      return const [];
    }

    final rows = <_DetailRowItem>[
      _DetailRowItem(
        label: _l10n.uiLocation,
        value: _opportunityLocationLabel(opportunity),
        icon: Icons.place_outlined,
      ),
      _DetailRowItem(
        label: _l10n.uiDeadline,
        value: _deadlineLabel(opportunity),
        icon: Icons.event_available_outlined,
      ),
      _DetailRowItem(
        label: _l10n.uiCompensation,
        value: _compensationLabel(opportunity),
        icon: Icons.payments_outlined,
      ),
    ];

    return rows
        .where((row) => row.value.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<String> _opportunityMetadataItems(OpportunityModel? opportunity) {
    if (opportunity == null) {
      return const [];
    }

    return OpportunityMetadata.buildMetadataItems(
      type: opportunity.type,
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      fundingAmount: opportunity.fundingAmount,
      fundingCurrency: opportunity.fundingCurrency,
      fundingNote: opportunity.fundingNote,
      isPaid: opportunity.isPaid,
      employmentType: opportunity.employmentType,
      workMode: opportunity.workMode,
      duration: opportunity.duration,
      maxItems: 5,
    );
  }

  String _opportunityLocationLabel(OpportunityModel opportunity) {
    return OpportunityMetadata.sanitizeText(opportunity.location) ??
        _l10n.uiLocationNotSpecified;
  }

  String _deadlineLabel(OpportunityModel opportunity) {
    final deadline =
        opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadlineLabel);
    if (deadline != null) {
      return OpportunityMetadata.formatDateLabel(deadline);
    }

    return OpportunityMetadata.sanitizeText(opportunity.deadlineLabel) ??
        _l10n.uiNotSpecified;
  }

  String _compensationLabel(OpportunityModel opportunity) {
    if (OpportunityType.isSponsoring(opportunity.type)) {
      return opportunity.fundingLabel() ?? _l10n.uiNotSpecified;
    }

    return OpportunityMetadata.buildCompensationLabel(
          salaryMin: opportunity.salaryMin,
          salaryMax: opportunity.salaryMax,
          salaryCurrency: opportunity.salaryCurrency,
          salaryPeriod: opportunity.salaryPeriod,
          compensationText: opportunity.compensationText,
          isPaid: opportunity.isPaid,
        ) ??
        _l10n.uiNotSpecified;
  }

  void _openOpportunityDetailsFromSheet(
    BuildContext sheetContext,
    OpportunityModel? opportunity,
  ) {
    if (opportunity == null) {
      context.showAppSnackBar(
        _l10n.uiTheLinkedOpportunityIsNoLongerAvailable,
        title: _l10n.uiOpportunityUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    Navigator.pop(sheetContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showOpportunityDetailsSheet(opportunity);
    });
  }

  Future<void> _showOpportunityDetailsSheet(
    OpportunityModel opportunity,
  ) async {
    final tone = _toneForOpportunity(opportunity);
    final metadata = _opportunityMetadataItems(opportunity);
    final detailRows = _opportunityDetailRows(opportunity);
    final description =
        OpportunityMetadata.sanitizeText(opportunity.description) ??
        _l10n.uiNoDescriptionProvided;
    final requirements = _opportunityRequirementItems(opportunity);
    final benefits = _opportunityBenefits(opportunity);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          maxChildSize: 0.94,
          minChildSize: 0.48,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _ApplicationsPalette.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                children: [
                  _SheetHeaderBar(
                    title: _l10n.uiOpportunityDetails,
                    subtitle: _l10n.uiTheRoleThisCandidateAppliedFor,
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 14),
                  _OpportunityDetailsHero(
                    opportunity: opportunity,
                    tone: tone,
                    location: _opportunityLocationLabel(opportunity),
                    statusLabel: _opportunityStatusLabel(opportunity.status),
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSectionCard(
                      title: _l10n.uiRoleDetails,
                      icon: Icons.tune_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: metadata
                            .map(
                              (label) => _MetaPill(
                                icon: Icons.check_circle_outline_rounded,
                                label: label,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                  if (detailRows.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSectionCard(
                      title: _l10n.uiTimelineAndLocation,
                      icon: Icons.event_note_outlined,
                      child: _DetailRows(rows: detailRows),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DetailSectionCard(
                    title: OpportunityType.descriptionLabel(
                      opportunity.type,
                      _l10n,
                    ),
                    icon: Icons.notes_outlined,
                    child: _DetailBodyText(description),
                  ),
                  const SizedBox(height: 14),
                  _DetailSectionCard(
                    title: OpportunityType.requirementsLabel(
                      opportunity.type,
                      _l10n,
                    ),
                    icon: Icons.checklist_rounded,
                    child: requirements.isEmpty
                        ? _DetailBodyText(
                            AppLocalizations.of(
                              context,
                            )!.uiNoRequirementsProvided,
                          )
                        : _DetailBulletList(items: requirements),
                  ),
                  if (benefits.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSectionCard(
                      title: _l10n.uiBenefits,
                      icon: Icons.workspace_premium_outlined,
                      child: _DetailBulletList(items: benefits),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _opportunityRequirementItems(OpportunityModel opportunity) {
    if (opportunity.requirementItems.isNotEmpty) {
      return opportunity.requirementItems;
    }

    final fallback = OpportunityMetadata.sanitizeText(opportunity.requirements);
    return fallback == null ? const [] : [fallback];
  }

  List<String> _opportunityBenefits(OpportunityModel opportunity) {
    if (opportunity.benefits.isNotEmpty) {
      return opportunity.benefits;
    }

    return OpportunityMetadata.stringListFromValue(
      opportunity.firstValue([
        'benefits',
        'benefitList',
        'perks',
        'advantages',
        'support',
      ]),
      maxItems: 6,
    );
  }

  String _opportunityStatusLabel(String rawStatus) {
    final normalized = rawStatus
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return _l10n.uiStatusUnavailable;
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void _openStudentProfile(ApplicationModel application) {
    showFloatingUserProfilePreview(
      context,
      userId: application.studentId,
      fallbackName: application.studentName,
      fallbackRole: 'student',
      contextLabel: _l10n.uiApplication,
    );
  }

  Future<void> _openChatWithStudent(ApplicationModel application) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      return;
    }

    try {
      final conversation = await chatProvider.getOrCreateConversation(
        studentId: application.studentId,
        studentName: application.studentName,
        companyId: currentUser.uid,
        companyName: currentUser.companyName ?? currentUser.fullName,
        contextType: 'application',
        contextLabel: _l10n.uiApplicationConversation,
        currentUserId: currentUser.uid,
        currentUserRole: currentUser.role,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            otherName: conversation.studentName,
            recipientId: conversation.studentId,
            otherRole: 'student',
            contextLabel: _l10n.uiApplicationConversation,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        _l10n.uiCouldNotOpenChatValue(error),
        title: _l10n.uiChatUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    ApplicationModel application,
    String status,
    CompanyProvider provider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    final error = await provider.updateApplicationStatus(
      appId: application.id,
      status: status,
    );

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _l10n.updateUnavailableTitle,
        type: AppFeedbackType.error,
      );
      return;
    }

    if (currentUserId != null) {
      await provider.loadApplications(currentUserId);
    }

    if (!context.mounted) {
      return;
    }

    context.showAppSnackBar(
      _l10n.uiApplicationStatusValue(
        ApplicationStatus.sentenceLabel(status, _l10n),
      ),
      title: _l10n.uiApplicationUpdated,
      type: AppFeedbackType.success,
    );
  }

  Future<void> _showCvSheet(
    BuildContext context,
    ApplicationModel application,
    CompanyProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FutureBuilder<CvModel?>(
          future: provider.getApplicationCv(application.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: _ApplicationsPalette.primary,
                  ),
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
                      style: AppTypography.product(
                        color: _ApplicationsPalette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final cv = snapshot.data;

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              maxChildSize: 0.92,
              minChildSize: 0.34,
              expand: false,
              builder: (_, scrollController) {
                if (cv == null) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _ApplicationsPalette.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _ApplicationsPalette.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: _ApplicationsPalette.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _l10n.uiNoCvAvailableForValue(
                            application.studentName,
                          ),
                          style: AppTypography.product(
                            color: _ApplicationsPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: _ApplicationsPalette.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _ApplicationsPalette.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ReviewerCvHeader(
                        name: cv.fullName.isNotEmpty
                            ? cv.fullName
                            : application.studentName,
                        accentColor: _ApplicationsPalette.primary,
                        details: [cv.email, cv.phone, cv.address],
                      ),
                      const SizedBox(height: 18),
                      ReviewerCvDocumentCard(
                        title: _l10n.uiPrimaryCvPdf,
                        subtitle: cv.hasUploadedCv
                            ? '${_l10n.uiFile}: ${cv.uploadedCvDisplayName}\n${_l10n.uiUploadedUploadedatlabel(_formatDate(cv.uploadedCvUploadedAt))}'
                            : _l10n.uiNoUploadedCv,
                        accentColor: _ApplicationsPalette.primary,
                        viewLabel: _l10n.uiViewCv,
                        downloadLabel: _l10n.uiDownloadCv,
                        warningText: cv.hasUploadedCv && !cv.isUploadedCvPdf
                            ? _l10n.uiTheRequestedFileIsNotAValidPdf
                            : null,
                        onView: cv.hasUploadedCv && cv.isUploadedCvPdf
                            ? () => _openApplicationDocument(
                                application,
                                variant: 'primary',
                                requirePdf: true,
                              )
                            : null,
                        onDownload: cv.hasUploadedCv
                            ? () => _openApplicationDocument(
                                application,
                                variant: 'primary',
                                download: true,
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      ReviewerCvDocumentCard(
                        title: _l10n.uiBuiltCv,
                        subtitle: cv.hasExportedPdf
                            ? _l10n.uiBuiltCvPdfReadyForReview
                            : cv.hasBuilderContent
                            ? _l10n.uiBuiltCvDetailsAvailableNoPdfYet
                            : _l10n.uiNoBuiltCvDetailsAvailable,
                        accentColor: _ApplicationsPalette.secondaryDark,
                        viewLabel: _l10n.uiViewBuiltCv,
                        downloadLabel: _l10n.uiDownloadBuiltCv,
                        onView: cv.hasExportedPdf
                            ? () => _openApplicationDocument(
                                application,
                                variant: 'built',
                                requirePdf: true,
                              )
                            : null,
                        onDownload: cv.hasExportedPdf
                            ? () => _openApplicationDocument(
                                application,
                                variant: 'built',
                                download: true,
                              )
                            : null,
                      ),
                      if (cv.summary.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildCvSection(_l10n.uiSummary, [cv.summary]),
                      ],
                      if (cv.education.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildCvSection(
                          _l10n.uiEducation,
                          cv.education
                              .map(
                                (entry) =>
                                    '${entry['degree'] ?? ''} - ${entry['institution'] ?? ''} (${entry['year'] ?? ''})',
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (cv.experience.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildCvSection(
                          _l10n.uiExperience,
                          cv.experience
                              .map(
                                (entry) =>
                                    '${entry['position'] ?? entry['title'] ?? ''} - ${entry['company'] ?? ''} (${entry['duration'] ?? ''})',
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (cv.skills.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _l10n.uiSkills,
                          style: AppTypography.product(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _ApplicationsPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: cv.skills
                              .map(
                                (skill) => _TypePill(
                                  label: skill,
                                  tone: _OpportunityTypeTone(
                                    background:
                                        _ApplicationsPalette.primarySoft,
                                    foreground: _ApplicationsPalette.primary,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (cv.languages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _l10n.uiLanguages,
                          style: AppTypography.product(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _ApplicationsPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: cv.languages
                              .map(
                                (language) => _MetaPill(
                                  icon: Icons.language_rounded,
                                  label: language,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openApplicationDocument(
    ApplicationModel application, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    try {
      final document = await _documentAccessService.getApplicationCvDocument(
        applicationId: application.id,
        variant: variant,
      );
      if (!mounted) {
        return;
      }

      if (requirePdf && !document.isPdf) {
        context.showAppSnackBar(
          _l10n.uiTheRequestedFileIsNotAValidPdf,
          title: _l10n.uiPreviewUnavailable,
          type: AppFeedbackType.warning,
        );
        return;
      }

      await DocumentLaunchHelper.openSecureDocument(
        context,
        document: document,
        download: download,
        requirePdf: requirePdf,
        notPdfMessage: _l10n.uiTheRequestedFileIsNotAValidPdf,
        notPdfTitle: _l10n.uiPreviewUnavailable,
        unavailableMessage: _l10n.uiCouldNotOpenTheDocumentRightNow,
        unavailableTitle: _l10n.uiDocumentUnavailable,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        _documentErrorMessage(error),
        title: _l10n.uiDocumentUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  String _formatDate(Timestamp? value) {
    if (value == null) {
      return _l10n.uiNotSpecified;
    }
    return DateFormat.yMMMd(_localeName).format(value.toDate());
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('403')) {
      return _l10n.uiPermissionDeniedWhileOpeningTheDocument;
    }
    if (message.contains('404') || message.contains('not found')) {
      return _l10n.uiTheRequestedFileIsNoLongerAvailable;
    }
    return _l10n.uiCouldNotOpenTheDocumentRightNow;
  }

  Widget _buildCvSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.product(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _ApplicationsPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: AppTypography.product(
                fontSize: 13,
                color: _ApplicationsPalette.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicationsPalette {
  static Color get primary => CompanyDashboardPalette.primary;
  static Color get primarySoft => CompanyDashboardPalette.primarySoft;
  static Color get secondaryDark => CompanyDashboardPalette.secondaryDark;
  static Color get accent => CompanyDashboardPalette.accent;
  static Color get accentSoft => AppColors.current.accentSoft;
  static Color get surface => CompanyDashboardPalette.surface;
  static Color get surfaceAlt => AppColors.current.surfaceMuted;
  static Color get border => CompanyDashboardPalette.border;
  static Color get textPrimary => CompanyDashboardPalette.textPrimary;
  static Color get textSecondary => CompanyDashboardPalette.textSecondary;
  static Color get textMuted => AppColors.current.textMuted;
  static Color get success => CompanyDashboardPalette.success;
  static Color get warning => CompanyDashboardPalette.warning;
  static Color get error => CompanyDashboardPalette.error;
}

class _ApplicationListItem {
  final ApplicationModel application;
  final OpportunityModel? opportunity;

  const _ApplicationListItem({
    required this.application,
    required this.opportunity,
  });
}

class _OpportunityTypeTone {
  final Color background;
  final Color foreground;

  const _OpportunityTypeTone({
    required this.background,
    required this.foreground,
  });
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _ApplicationsPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _ApplicationsPalette.border),
          ),
          child: Icon(icon, color: _ApplicationsPalette.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationIconButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HeaderIconButton(icon: Icons.notifications_none_rounded, onTap: onTap),
        if (unreadCount > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _ApplicationsPalette.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _ApplicationsPalette.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: AppTypography.product(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _KpiDivider extends StatelessWidget {
  const _KpiDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: _ApplicationsPalette.border,
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HeroStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.product(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _ApplicationsPalette.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.product(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ApplicationsPalette.textPrimary,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ApplicationsPalette.border),
      ),
      child: TextField(
        controller: controller,
        cursorColor: _ApplicationsPalette.primary,
        style: AppTypography.product(
          fontSize: 13,
          color: _ApplicationsPalette.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(
              Icons.search_rounded,
              color: _ApplicationsPalette.textMuted,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 20,
          ),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _ApplicationsPalette.textMuted,
                  ),
                ),
          hintText: hintText,
          hintStyle: AppTypography.product(
            fontSize: 13,
            color: _ApplicationsPalette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final int count;
  final String? label;

  const _CounterBadge({required this.count, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.primarySoft,
        border: Border.all(
          color: _ApplicationsPalette.primary.withValues(alpha: 0.10),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((label ?? '').trim().isNotEmpty) ...[
            Text(
              label!,
              style: AppTypography.product(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _ApplicationsPalette.primary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$count',
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _ApplicationsPalette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final IconData? icon;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.activeColor,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.10)
              : _ApplicationsPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.32)
                : _ApplicationsPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? activeColor : _ApplicationsPalette.textMuted,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.product(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? activeColor
                    : _ApplicationsPalette.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.12)
                    : _ApplicationsPalette.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTypography.product(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? activeColor
                      : _ApplicationsPalette.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final _OpportunityTypeTone tone;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tone.background : _ApplicationsPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? tone.foreground.withValues(alpha: 0.32)
                : _ApplicationsPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? tone.foreground
                    : _ApplicationsPalette.textMuted,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.product(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? tone.foreground
                    : _ApplicationsPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpportunityFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _OpportunityFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _ApplicationsPalette.primarySoft
              : _ApplicationsPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _ApplicationsPalette.primary.withValues(alpha: 0.32)
                : _ApplicationsPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? _ApplicationsPalette.primary
                      : _ApplicationsPalette.textSecondary,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? _ApplicationsPalette.primary.withValues(alpha: 0.12)
                      : _ApplicationsPalette.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.product(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? _ApplicationsPalette.primary
                        : _ApplicationsPalette.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusedApplicationBanner extends StatelessWidget {
  final int count;

  const _FocusedApplicationBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _InlineBanner(
      icon: Icons.filter_alt_outlined,
      title: l10n.uiFocusedApplicationView,
      message: count == 1
          ? l10n.uiShowingTheApplicationYouOpenedDirectly
          : l10n.uiThisApplicationIsNoLongerAvailable,
      tone: _ApplicationsPalette.primary,
      background: _ApplicationsPalette.primarySoft,
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color tone;
  final Color background;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    required this.background,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ApplicationsPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.product(
                    fontSize: 12,
                    color: _ApplicationsPalette.textSecondary,
                  ),
                ),
                if ((actionLabel ?? '').trim().isNotEmpty &&
                    onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      actionLabel!,
                      style: AppTypography.product(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: tone,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: _ApplicationsPalette.primary,
              strokeWidth: 2.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.uiLoadingYourApplications,
            style: AppTypography.product(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _ApplicationsPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplicationsState extends StatelessWidget {
  final bool hasFilters;
  final bool isFocusedView;

  const _EmptyApplicationsState({
    required this.hasFilters,
    required this.isFocusedView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isFocusedView
        ? l10n.uiThisApplicationIsNoLongerAvailable
        : hasFilters
        ? l10n.uiNoApplicationsMatchThisView
        : l10n.uiNoApplicationsYet;
    final message = isFocusedView
        ? l10n.uiTheApplicationYouOpenedIsNoLongerAvailableItMayHaveBeenRemovedOrMayNoLongerBelongToThisCompany
        : hasFilters
        ? l10n.uiTryClearingTheFiltersOrBroadeningTheSearchToSeeMoreCandidates
        : l10n.uiCandidateApplicationsAreListedHereWithQuickReviewActionsAndCvAccess;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _ApplicationsPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _ApplicationsPalette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _ApplicationsPalette.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 30,
                  color: _ApplicationsPalette.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.product(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ApplicationsPalette.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.product(
                  fontSize: 13,
                  height: 1.5,
                  color: _ApplicationsPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final _OpportunityTypeTone tone;

  const _TypePill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.background,
        border: Border.all(color: tone.foreground.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: tone.foreground,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surfaceAlt,
        border: Border.all(color: _ApplicationsPalette.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _ApplicationsPalette.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ApplicationsPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowItem {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRowItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _SheetHeaderBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _SheetHeaderBar({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ApplicationsPalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: _ApplicationsPalette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: _ApplicationsPalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.product(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ApplicationsPalette.textPrimary,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.product(
              fontSize: 12.5,
              height: 1.45,
              color: _ApplicationsPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  final List<Widget> children;

  const _ActionRail({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}

class _OpportunityLinkButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  const _OpportunityLinkButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tone.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.product(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ApplicationsPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.product(
                          fontSize: 11.5,
                          color: _ApplicationsPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, size: 22, color: tone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityDetailsHero extends StatelessWidget {
  final OpportunityModel opportunity;
  final _OpportunityTypeTone tone;
  final String location;
  final String statusLabel;

  const _OpportunityDetailsHero({
    required this.opportunity,
    required this.tone,
    required this.location,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        OpportunityMetadata.sanitizeText(opportunity.title) ??
        AppLocalizations.of(context)!.uiOpportunityUnavailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.foreground.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _ApplicationsPalette.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  OpportunityType.icon(opportunity.type),
                  color: tone.foreground,
                  size: 22,
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
                      style: AppTypography.product(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ApplicationsPalette.textPrimary,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: _ApplicationsPalette.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 12,
                              color: _ApplicationsPalette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypePill(
                label: OpportunityType.label(
                  opportunity.type,
                  AppLocalizations.of(context)!,
                ).toUpperCase(),
                tone: tone,
              ),
              _MetaPill(
                icon: Icons.radio_button_checked_rounded,
                label: statusLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ApplicationsPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _ApplicationsPalette.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _ApplicationsPalette.border),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: _ApplicationsPalette.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _ApplicationsPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailBodyText extends StatelessWidget {
  final String text;

  const _DetailBodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.product(
        fontSize: 12.5,
        height: 1.6,
        color: _ApplicationsPalette.textSecondary,
      ),
    );
  }
}

class _DetailBulletList extends StatelessWidget {
  final List<String> items;

  const _DetailBulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: _ApplicationsPalette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _DetailBodyText(item)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DetailRows extends StatelessWidget {
  final List<_DetailRowItem> rows;

  const _DetailRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _DetailInfoRow(item: rows[index]),
          if (index != rows.length - 1)
            Divider(height: 16, color: _ApplicationsPalette.border),
        ],
      ],
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final _DetailRowItem item;

  const _DetailInfoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, size: 17, color: _ApplicationsPalette.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: AppTypography.product(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ApplicationsPalette.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            item.value,
            textAlign: TextAlign.right,
            style: AppTypography.product(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _ApplicationsPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  final String status;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _DecisionPanel({
    required this.status,
    required this.isBusy,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = ApplicationStatus.parse(status);
    final tone = switch (normalizedStatus) {
      ApplicationStatus.accepted => _ApplicationsPalette.success,
      ApplicationStatus.rejected => _ApplicationsPalette.error,
      ApplicationStatus.withdrawn => _ApplicationsPalette.textMuted,
      _ => _ApplicationsPalette.accent,
    };
    final icon = switch (normalizedStatus) {
      ApplicationStatus.accepted => Icons.verified_outlined,
      ApplicationStatus.rejected => Icons.block_outlined,
      ApplicationStatus.withdrawn => Icons.undo_outlined,
      _ => Icons.rate_review_outlined,
    };
    final title = switch (normalizedStatus) {
      ApplicationStatus.accepted => AppLocalizations.of(
        context,
      )!.uiCandidateApproved,
      ApplicationStatus.rejected => AppLocalizations.of(
        context,
      )!.uiCandidateRejected,
      ApplicationStatus.withdrawn => AppLocalizations.of(
        context,
      )!.uiApplicationWithdrawn,
      _ => AppLocalizations.of(context)!.uiReadyForDecision,
    };
    final message = switch (normalizedStatus) {
      ApplicationStatus.accepted => AppLocalizations.of(
        context,
      )!.uiThisApplicationIsApprovedUseMessageOrCvReviewForNextSteps,
      ApplicationStatus.rejected => AppLocalizations.of(
        context,
      )!.uiThisApplicationIsRejectedTheProfileAndCvRemainAvailableForReference,
      ApplicationStatus.withdrawn => AppLocalizations.of(
        context,
      )!.uiThisApplicationHasBeenWithdrawnByTheCandidate,
      _ => AppLocalizations.of(
        context,
      )!.uiApproveTheCandidateToMoveThemForwardOrRejectIfTheFitIsNotRight,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _ApplicationsPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTypography.product(
                        fontSize: 12,
                        height: 1.45,
                        color: _ApplicationsPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (normalizedStatus == ApplicationStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DecisionButton(
                    label: isBusy
                        ? AppLocalizations.of(context)!.uiWorking
                        : AppLocalizations.of(context)!.uiApprove,
                    icon: Icons.check_rounded,
                    background: _ApplicationsPalette.success,
                    onTap: isBusy ? null : onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DecisionButton(
                    label: isBusy
                        ? AppLocalizations.of(context)!.uiWorking
                        : AppLocalizations.of(context)!.uiReject,
                    icon: Icons.close_rounded,
                    background: _ApplicationsPalette.error,
                    onTap: isBusy ? null : onReject,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback? onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.product(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  final String studentName;
  final String opportunityTitle;
  final String? appliedLabel;
  final String? relativeAppliedLabel;
  final String? typeLabel;
  final _OpportunityTypeTone typeTone;
  final String status;
  final String studentId;
  final VoidCallback? onTapProfile;

  const _DetailHeroCard({
    required this.studentName,
    required this.opportunityTitle,
    required this.appliedLabel,
    required this.relativeAppliedLabel,
    required this.typeLabel,
    required this.typeTone,
    required this.status,
    required this.studentId,
    this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final appliedText = relativeAppliedLabel ?? appliedLabel;

    return Semantics(
      button: onTapProfile != null,
      label: AppLocalizations.of(
        context,
      )!.uiOpenCandidateProfileForStudentname(studentName),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapProfile,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ApplicationsPalette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ApplicationsPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ProfileAvatar(
                          radius: 30,
                          userId: studentId,
                          fallbackName: studentName,
                          role: 'student',
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: typeTone.foreground,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _ApplicationsPalette.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _ApplicationsPalette.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opportunityTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 12.5,
                              height: 1.35,
                              color: _ApplicationsPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ApplicationStatusBadge(status: status, fontSize: 10.5),
                  ],
                ),
                if (typeLabel != null || appliedText != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (typeLabel != null)
                        _TypePill(label: typeLabel!, tone: typeTone),
                      if (appliedText != null)
                        _MetaPill(
                          icon: Icons.schedule_rounded,
                          label: AppLocalizations.of(
                            context,
                          )!.uiAppliedAppliedtext(appliedText),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WideActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _WideActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: foreground.withValues(alpha: 0.16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
