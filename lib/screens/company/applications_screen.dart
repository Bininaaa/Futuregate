import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/application_model.dart';
import '../../models/cv_model.dart';
import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/company_provider.dart';
import '../../services/document_access_service.dart';
import '../../utils/application_status.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/application_status_badge.dart';
import '../../widgets/profile_avatar.dart';
import 'chat_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final String? initialApplicationId;
  final bool showBackButton;

  const ApplicationsScreen({
    super.key,
    this.initialApplicationId,
    this.showBackButton = false,
  });

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
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
      OpportunityType.label(opportunity?.type ?? ''),
      ApplicationStatus.label(item.application.status),
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
      _ApplicationStatusFilter.all => 'All Applications',
      _ApplicationStatusFilter.pending => 'Pending',
      _ApplicationStatusFilter.approved => 'Approved',
      _ApplicationStatusFilter.rejected => 'Rejected',
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
    final items = _filteredItems(provider);
    final isFocusedView = (widget.initialApplicationId ?? '').trim().isNotEmpty;
    final resultsCount = items.length;
    final totalApplications = provider.applications.length;
    final pendingCount = _statusCount(
      provider,
      _ApplicationStatusFilter.pending,
    );
    final opportunityCounts = _applicationCountsByOpportunity(provider);
    final pendingOpportunityCount = _pendingOpportunityCount(provider);
    final companyName = [user?.companyName ?? '', user?.fullName ?? '']
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => 'Your company');

    _maybeOpenFocusedDetails(items, provider);

    return Scaffold(
      backgroundColor: _ApplicationsPalette.background,
      appBar: widget.showBackButton
          ? AppBar(
              title: Text(
                'Applications',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: _ApplicationsPalette.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              automaticallyImplyLeading: true,
              iconTheme: const IconThemeData(
                color: _ApplicationsPalette.textPrimary,
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: !widget.showBackButton,
          bottom: false,
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
                      20,
                      widget.showBackButton ? 8 : 14,
                      20,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildApplicationsHero(
                          companyName: companyName,
                          isFocusedView: isFocusedView,
                          totalApplications: totalApplications,
                          pendingCount: pendingCount,
                        ),
                        if (pendingOpportunityCount > 0) ...[
                          const SizedBox(height: 12),
                          _InlineBanner(
                            icon: Icons.warning_amber_rounded,
                            title: 'Pending opportunities need attention',
                            message: pendingCount == 1
                                ? '1 application is still waiting for review.'
                                : '$pendingCount applications across $pendingOpportunityCount ${pendingOpportunityCount == 1 ? 'opportunity' : 'opportunities'} are still waiting for a decision.',
                            tone: _ApplicationsPalette.accent,
                            background: _ApplicationsPalette.accentSoft,
                            actionLabel: isFocusedView ? null : 'Show pending',
                            onAction: isFocusedView
                                ? null
                                : _showPendingApplications,
                          ),
                        ],
                        if ((provider.applicationsError ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _InlineBanner(
                            icon: Icons.info_outline_rounded,
                            title: 'Application data is unavailable.',
                            message: provider.applicationsError!,
                            tone: _ApplicationsPalette.error,
                            background: const Color(0xFFFFF1F2),
                          ),
                        ],
                        if (isFocusedView) ...[
                          const SizedBox(height: 16),
                          _FocusedApplicationBanner(count: resultsCount),
                        ] else ...[
                          const SizedBox(height: 18),
                          _buildFiltersPanel(
                            provider,
                            resultsCount: resultsCount,
                            totalApplications: totalApplications,
                            opportunityCounts: opportunityCounts,
                          ),
                        ],
                        const SizedBox(height: 18),
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
                if (provider.applicationsLoading &&
                    provider.applications.isEmpty)
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return _buildApplicationCard(
                          item,
                          provider,
                          opportunityApplicantCount:
                              opportunityCounts[item
                                  .application
                                  .opportunityId] ??
                              0,
                        );
                      }, childCount: items.length),
                    ),
                  ),
              ],
            ),
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

  String _relativeDateLabel(Timestamp? value) {
    if (value == null) {
      return 'Date unavailable';
    }

    final appliedAt = value.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(appliedAt.year, appliedAt.month, appliedAt.day);
    final difference = today.difference(target).inDays;

    if (difference <= 0) {
      return 'today';
    }
    if (difference == 1) {
      return 'yesterday';
    }
    if (difference < 7) {
      return '$difference days ago';
    }
    if (difference < 30) {
      final weeks = (difference / 7).ceil();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    return DateFormat('MMM d').format(appliedAt);
  }

  Widget _buildApplicationsHero({
    required String companyName,
    required bool isFocusedView,
    required int totalApplications,
    required int pendingCount,
  }) {
    final subtitle = isFocusedView
        ? 'Focused review mode for a single application.'
        : 'Track and review incoming applications quickly.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            _ApplicationsPalette.primaryDark,
            _ApplicationsPalette.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _ApplicationsPalette.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Desk',
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$companyName - $subtitle',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStatTile(
                  label: 'Total',
                  value: '$totalApplications',
                  icon: Icons.inbox_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatTile(
                  label: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(
    CompanyProvider provider, {
    required int resultsCount,
    required int totalApplications,
    required Map<String, int> opportunityCounts,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _ApplicationsPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Controls',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ApplicationsPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing $resultsCount of $totalApplications applications',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: _ApplicationsPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeFilterCount > 0)
                _CounterBadge(count: _activeFilterCount, label: 'Active'),
            ],
          ),
          const SizedBox(height: 16),
          _SearchField(
            controller: _searchController,
            hintText: 'Search by candidate, opportunity, location, or type...',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Status',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ApplicationsPalette.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _hasActiveFilters ? _clearFilters : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _hasActiveFilters
                        ? _ApplicationsPalette.primary
                        : _ApplicationsPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ApplicationStatusFilter.values
                .map(
                  (filter) => _FilterChip(
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
                    activeColor: filter == _ApplicationStatusFilter.approved
                        ? _ApplicationsPalette.success
                        : filter == _ApplicationStatusFilter.rejected
                        ? _ApplicationsPalette.error
                        : filter == _ApplicationStatusFilter.pending
                        ? _ApplicationsPalette.warning
                        : _ApplicationsPalette.primary,
                    onTap: () => setState(() => _selectedStatusFilter = filter),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          Text(
            'Type',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ApplicationsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeFilterChip(
                label: 'All Types',
                icon: Icons.widgets_outlined,
                selected: _selectedTypeFilter == _allTypeFilter,
                tone: _toneForType(null),
                onTap: () =>
                    setState(() => _selectedTypeFilter = _allTypeFilter),
              ),
              _TypeFilterChip(
                label: 'Jobs',
                icon: OpportunityType.icon(OpportunityType.job),
                selected: _selectedTypeFilter == OpportunityType.job,
                tone: _toneForType(OpportunityType.job),
                onTap: () =>
                    setState(() => _selectedTypeFilter = OpportunityType.job),
              ),
              _TypeFilterChip(
                label: 'Internships',
                icon: OpportunityType.icon(OpportunityType.internship),
                selected: _selectedTypeFilter == OpportunityType.internship,
                tone: _toneForType(OpportunityType.internship),
                onTap: () => setState(
                  () => _selectedTypeFilter = OpportunityType.internship,
                ),
              ),
              _TypeFilterChip(
                label: 'Sponsored',
                icon: OpportunityType.icon(OpportunityType.sponsoring),
                selected: _selectedTypeFilter == OpportunityType.sponsoring,
                tone: _toneForType(OpportunityType.sponsoring),
                onTap: () => setState(
                  () => _selectedTypeFilter = OpportunityType.sponsoring,
                ),
              ),
            ],
          ),
          if (provider.opportunities.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Roles',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ApplicationsPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _OpportunityFilterChip(
                    label: 'All Roles',
                    count: totalApplications,
                    selected:
                        _selectedOpportunityFilter == _allOpportunityFilter,
                    onTap: () => setState(
                      () => _selectedOpportunityFilter = _allOpportunityFilter,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...provider.opportunities.map(
                    (opportunity) => Padding(
                      padding: const EdgeInsets.only(right: 8),
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
        ],
      ),
    );
  }

  Widget _buildQueueHeader({
    required int resultsCount,
    required int totalApplications,
    required bool isFocusedView,
  }) {
    final subtitle = isFocusedView
        ? 'Direct application review with all candidate details in one place.'
        : _hasActiveFilters
        ? 'Filtered results: $resultsCount of $totalApplications applications.'
        : 'Latest candidates ready for review, messaging, and CV checks.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFocusedView ? 'Application Spotlight' : 'Candidate Queue',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ApplicationsPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.45,
                  color: _ApplicationsPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CounterBadge(count: resultsCount, label: 'Visible'),
      ],
    );
  }

  _OpportunityTypeTone _toneForType(String? rawType) {
    switch (OpportunityType.parse(rawType)) {
      case OpportunityType.internship:
        return const _OpportunityTypeTone(
          background: Color(0xFFEAF3FF),
          foreground: OpportunityType.internshipColor,
        );
      case OpportunityType.sponsoring:
        return const _OpportunityTypeTone(
          background: _ApplicationsPalette.accentSoft,
          foreground: _ApplicationsPalette.accent,
        );
      case OpportunityType.job:
      default:
        return const _OpportunityTypeTone(
          background: _ApplicationsPalette.primarySoft,
          foreground: _ApplicationsPalette.primary,
        );
    }
  }

  String _typeLabel(String? rawType) {
    return OpportunityType.label(OpportunityType.parse(rawType)).toUpperCase();
  }

  String _appliedDateLabel(Timestamp? value) {
    if (value == null) {
      return 'Date unavailable';
    }
    return DateFormat('MMM d, yyyy').format(value.toDate());
  }

  Widget _buildApplicationCard(
    _ApplicationListItem item,
    CompanyProvider provider, {
    required int opportunityApplicantCount,
  }) {
    final application = item.application;
    final opportunity = item.opportunity;
    final typeTone = _toneForType(opportunity?.type);
    final isPending =
        ApplicationStatus.parse(application.status) ==
        ApplicationStatus.pending;
    final relativeAppliedLabel = _relativeDateLabel(application.appliedAt);
    final isFresh = _isFreshApplication(application.appliedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _showApplicationDetailsSheet(item, provider),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _ApplicationsPalette.surface,
                  typeTone.background.withValues(alpha: 0.58),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: typeTone.foreground.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: typeTone.foreground.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: typeTone.foreground.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ProfileAvatar(
                          radius: 22,
                          userId: application.studentId,
                          fallbackName: application.studentName,
                          role: 'student',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    application.studentName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _ApplicationsPalette.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isFresh) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _ApplicationsPalette.accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'NEW',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _ApplicationsPalette.accent,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opportunity?.title ?? 'Unknown opportunity',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: _ApplicationsPalette.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              opportunityApplicantCount <= 1
                                  ? 'Applied $relativeAppliedLabel'
                                  : 'Applied $relativeAppliedLabel • $opportunityApplicantCount applicants',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _ApplicationsPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ApplicationStatusBadge(status: application.status),
                          const SizedBox(height: 12),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.84),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: typeTone.foreground.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: Icon(
                              OpportunityType.icon(opportunity?.type ?? ''),
                              color: typeTone.foreground,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _TypePill(
                          label: _typeLabel(opportunity?.type),
                          tone: typeTone,
                        ),
                        if ((opportunity?.location ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _MetaPill(
                            icon: Icons.place_rounded,
                            label: opportunity!.location.trim(),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _MetaPill(
                          icon: Icons.event_rounded,
                          label: _appliedDateLabel(application.appliedAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionPillButton(
                        label: 'Message',
                        icon: Icons.chat_outlined,
                        foreground: _ApplicationsPalette.primary,
                        background: _ApplicationsPalette.primarySoft,
                        onTap: () => _openChatWithStudent(application),
                      ),
                      _ActionPillButton(
                        label: 'View CV',
                        icon: Icons.description_outlined,
                        foreground: _ApplicationsPalette.secondaryDark,
                        background: const Color(0xFFE8FFFB),
                        onTap: () =>
                            _showCvSheet(context, application, provider),
                      ),
                    ],
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _ApplicationsPalette.border.withValues(
                            alpha: 0.95,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _ApplicationsPalette.primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: _ApplicationsPalette.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pending review',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _ApplicationsPalette.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _DecisionButton(
                                  label: provider.isAppBusy(application.id)
                                      ? 'Working...'
                                      : 'Approve',
                                  background: _ApplicationsPalette.success,
                                  onTap: provider.isAppBusy(application.id)
                                      ? null
                                      : () => _updateStatus(
                                          context,
                                          application,
                                          ApplicationStatus.accepted,
                                          provider,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DecisionButton(
                                  label: provider.isAppBusy(application.id)
                                      ? 'Working...'
                                      : 'Reject',
                                  background: _ApplicationsPalette.error,
                                  onTap: provider.isAppBusy(application.id)
                                      ? null
                                      : () => _updateStatus(
                                          context,
                                          application,
                                          ApplicationStatus.rejected,
                                          provider,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showApplicationDetailsSheet(item, provider),
                        icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                        label: Text(
                          'Open review',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _ApplicationsPalette.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final tone = _toneForType(opportunity?.type);
    final isPending =
        ApplicationStatus.parse(application.status) ==
        ApplicationStatus.pending;
    final deadline =
        opportunity?.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity?.deadline);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            maxChildSize: 0.96,
            minChildSize: 0.58,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _ApplicationsPalette.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _ApplicationsPalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DetailHeroCard(
                      studentName: application.studentName,
                      opportunityTitle:
                          opportunity?.title ?? 'Unknown opportunity',
                      appliedLabel: _appliedDateLabel(application.appliedAt),
                      typeLabel: _typeLabel(opportunity?.type),
                      typeTone: tone,
                      status: application.status,
                      studentId: application.studentId,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _WideActionButton(
                            label: 'Message Student',
                            icon: Icons.chat_outlined,
                            background: _ApplicationsPalette.primarySoft,
                            foreground: _ApplicationsPalette.primary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openChatWithStudent(application);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WideActionButton(
                            label: 'View CV',
                            icon: Icons.description_outlined,
                            background: const Color(0xFFE8FFFB),
                            foreground: _ApplicationsPalette.secondaryDark,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showCvSheet(context, application, provider);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DecisionButton(
                              label: provider.isAppBusy(application.id)
                                  ? 'Working...'
                                  : 'Approve',
                              background: _ApplicationsPalette.success,
                              onTap: provider.isAppBusy(application.id)
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                      _updateStatus(
                                        context,
                                        application,
                                        ApplicationStatus.accepted,
                                        provider,
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DecisionButton(
                              label: provider.isAppBusy(application.id)
                                  ? 'Working...'
                                  : 'Reject',
                              background: _ApplicationsPalette.error,
                              onTap: provider.isAppBusy(application.id)
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                      _updateStatus(
                                        context,
                                        application,
                                        ApplicationStatus.rejected,
                                        provider,
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    _DetailSection(
                      title: 'Application Overview',
                      child: Column(
                        children: [
                          _DetailInfoRow(
                            label: 'Status',
                            value: ApplicationStatus.label(application.status),
                          ),
                          _DetailInfoRow(
                            label: 'Applied On',
                            value: _appliedDateLabel(application.appliedAt),
                          ),
                          _DetailInfoRow(
                            label: 'Application ID',
                            value: application.id,
                          ),
                          _DetailInfoRow(
                            label: 'CV ID',
                            value: application.cvId.isEmpty
                                ? 'Not available'
                                : application.cvId,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: 'Candidate',
                      child: Column(
                        children: [
                          _DetailInfoRow(
                            label: 'Student Name',
                            value: application.studentName,
                          ),
                          _DetailInfoRow(
                            label: 'Student ID',
                            value: application.studentId,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    if (opportunity != null) ...[
                      const SizedBox(height: 12),
                      _DetailSection(
                        title: 'Opportunity',
                        child: Column(
                          children: [
                            _DetailInfoRow(
                              label: 'Role',
                              value: opportunity.title,
                            ),
                            _DetailInfoRow(
                              label: 'Type',
                              value: OpportunityType.label(opportunity.type),
                            ),
                            _DetailInfoRow(
                              label: 'Location',
                              value: opportunity.location.trim().isEmpty
                                  ? 'Not specified'
                                  : opportunity.location.trim(),
                            ),
                            _DetailInfoRow(
                              label: 'Employment',
                              value:
                                  OpportunityMetadata.formatEmploymentType(
                                    opportunity.employmentType,
                                  ) ??
                                  'Not specified',
                            ),
                            _DetailInfoRow(
                              label: 'Work Mode',
                              value:
                                  OpportunityMetadata.formatWorkMode(
                                    opportunity.workMode,
                                  ) ??
                                  'Not specified',
                            ),
                            _DetailInfoRow(
                              label: 'Deadline',
                              value: deadline != null
                                  ? DateFormat('MMM d, yyyy').format(deadline)
                                  : opportunity.deadline.trim().isNotEmpty
                                  ? opportunity.deadline.trim()
                                  : 'Not specified',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      if (opportunity.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailSection(
                          title: 'Role Summary',
                          child: Text(
                            opportunity.description.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _ApplicationsPalette.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openChatWithStudent(ApplicationModel application) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
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
        currentUserId: currentUser.uid,
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
            contextLabel: 'Application conversation',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open chat: $error')),
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
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.updateApplicationStatus(
      appId: application.id,
      status: status,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (currentUserId != null) {
      await provider.loadApplications(currentUserId);
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Application ${ApplicationStatus.sentenceLabel(status)}.',
        ),
      ),
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
              return const SizedBox(
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
                      style: GoogleFonts.poppins(
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
                    decoration: const BoxDecoration(
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
                        const Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: _ApplicationsPalette.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No CV available for ${application.studentName}',
                          style: GoogleFonts.poppins(
                            color: _ApplicationsPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: const BoxDecoration(
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
                      Text(
                        cv.fullName.isNotEmpty
                            ? cv.fullName
                            : application.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _ApplicationsPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cv.email} - ${cv.phone}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _ApplicationsPalette.textSecondary,
                        ),
                      ),
                      if (cv.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cv.address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _ApplicationsPalette.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildDocumentReviewCard(
                        title: 'Primary CV PDF',
                        subtitle: cv.hasUploadedCv
                            ? 'File: ${cv.uploadedCvDisplayName}\nUploaded: ${_formatDate(cv.uploadedCvUploadedAt)}'
                            : 'No CV uploaded',
                        accentColor: _ApplicationsPalette.primary,
                        warningText: cv.hasUploadedCv && !cv.isUploadedCvPdf
                            ? 'This uploaded file is not a valid PDF. Ask the applicant to replace it with a PDF version.'
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
                      _buildDocumentReviewCard(
                        title: 'Built CV',
                        subtitle: cv.hasExportedPdf
                            ? 'Built CV PDF is ready for review.'
                            : cv.hasBuilderContent
                            ? 'Built CV information is available, but no PDF has been exported yet.'
                            : 'No built CV information available.',
                        accentColor: _ApplicationsPalette.secondaryDark,
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
                        _buildCvSection('Summary', [cv.summary]),
                      ],
                      if (cv.education.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildCvSection(
                          'Education',
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
                          'Experience',
                          cv.experience
                              .map(
                                (entry) =>
                                    '${entry['position'] ?? entry['title'] ?? ''} at ${entry['company'] ?? ''} (${entry['duration'] ?? ''})',
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (cv.skills.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Skills',
                          style: GoogleFonts.poppins(
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
                                  tone: const _OpportunityTypeTone(
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
                          'Languages',
                          style: GoogleFonts.poppins(
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
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getApplicationCvDocument(
        applicationId: application.id,
        variant: variant,
      );

      if (requirePdf && !document.isPdf) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('The requested file is not a valid PDF.'),
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_documentErrorMessage(error))),
      );
    }
  }

  Widget _buildDocumentReviewCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onView,
    VoidCallback? onDownload,
    String? warningText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ApplicationsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color: _ApplicationsPalette.textSecondary,
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 10),
            Text(
              warningText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.4,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (onView != null || onDownload != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onView != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View CV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(
                          color: accentColor.withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                if (onView != null && onDownload != null)
                  const SizedBox(width: 10),
                if (onDownload != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download CV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(Timestamp? value) {
    if (value == null) {
      return 'Not available';
    }
    return DateFormat('MMM d, yyyy').format(value.toDate());
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested file is no longer available.';
    }
    return 'Could not open the document right now.';
  }

  Widget _buildCvSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
  static const Color primary = Color(0xFF4328D8);
  static const Color primaryDark = Color(0xFF3721B8);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color secondaryDark = Color(0xFF0F9E90);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFFF7E6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
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

class _HeroStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
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
        color: _ApplicationsPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ApplicationsPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: _ApplicationsPalette.primary,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: _ApplicationsPalette.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(
              Icons.search_rounded,
              color: _ApplicationsPalette.primary,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 54,
            minHeight: 22,
          ),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _ApplicationsPalette.textMuted,
                  ),
                ),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _ApplicationsPalette.primary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$count',
            style: GoogleFonts.poppins(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.22)
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
              style: GoogleFonts.poppins(
                fontSize: 12,
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
                style: GoogleFonts.poppins(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tone.background : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? tone.foreground.withValues(alpha: 0.18)
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
              style: GoogleFonts.poppins(
                fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _ApplicationsPalette.primarySoft
              : _ApplicationsPalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _ApplicationsPalette.primary.withValues(alpha: 0.16)
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
                style: GoogleFonts.poppins(
                  fontSize: 12,
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
                  style: GoogleFonts.poppins(
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
    return _InlineBanner(
      icon: Icons.filter_alt_outlined,
      title: 'Focused application view',
      message: count == 1
          ? 'Showing the application you opened directly.'
          : 'The requested application could not be found.',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tone.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
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
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ApplicationsPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  _ApplicationsPalette.primaryDark,
                  _ApplicationsPalette.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading applications...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ApplicationsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pulling the latest candidate activity for your company.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _ApplicationsPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
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
    final title = isFocusedView
        ? 'This application is no longer available'
        : hasFilters
        ? 'No applications match these filters'
        : 'No applications yet';
    final message = isFocusedView
        ? 'The application you opened directly could not be found. It may have been removed or no longer belongs to this company.'
        : hasFilters
        ? 'Try clearing the filters or broadening the search to see more candidates.'
        : 'As soon as candidates start applying, they will appear here with quick review actions and CV access.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _ApplicationsPalette.surface,
                _ApplicationsPalette.primarySoft.withValues(alpha: 0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _ApplicationsPalette.primary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _ApplicationsPalette.primarySoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 30,
                  color: _ApplicationsPalette.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ApplicationsPalette.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(
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
        color: Colors.white.withValues(alpha: 0.82),
        border: Border.all(
          color: _ApplicationsPalette.border.withValues(alpha: 0.85),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _ApplicationsPalette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _ApplicationsPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: foreground.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color background;
  final VoidCallback? onTap;

  const _DecisionButton({
    required this.label,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: background.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  final String studentName;
  final String opportunityTitle;
  final String appliedLabel;
  final String typeLabel;
  final _OpportunityTypeTone typeTone;
  final String status;
  final String studentId;

  const _DetailHeroCard({
    required this.studentName,
    required this.opportunityTitle,
    required this.appliedLabel,
    required this.typeLabel,
    required this.typeTone,
    required this.status,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _ApplicationsPalette.surface,
            typeTone.background.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: typeTone.foreground.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: typeTone.foreground.withValues(alpha: 0.16),
                  ),
                ),
                child: ProfileAvatar(
                  radius: 24,
                  userId: studentId,
                  fallbackName: studentName,
                  role: 'student',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ApplicationsPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opportunityTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _ApplicationsPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ApplicationStatusBadge(status: status, fontSize: 10.5),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypePill(label: typeLabel, tone: typeTone),
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: 'Applied $appliedLabel',
              ),
            ],
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: foreground.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ApplicationsPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ApplicationsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _ApplicationsPalette.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _ApplicationsPalette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _ApplicationsPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: _ApplicationsPalette.border.withValues(alpha: 0.9),
            ),
          ],
        ],
      ),
    );
  }
}
