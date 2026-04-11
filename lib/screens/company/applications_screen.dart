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
import '../../providers/notification_provider.dart';
import '../../services/document_access_service.dart';
import '../../utils/application_status.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/application_status_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../chat/user_profile_preview_screen.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

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
      _ApplicationStatusFilter.all => 'All',
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
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    if (user == null) {
      return AppShellBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Not logged in')),
        ),
      );
    }

    final items = _filteredItems(provider);
    final isFocusedView = (widget.initialApplicationId ?? '').trim().isNotEmpty;
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

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
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
                          ),
                          if (pendingOpportunityCount > 0 &&
                              !isFocusedView) ...[
                            const SizedBox(height: 12),
                            _InlineBanner(
                              icon: Icons.warning_amber_rounded,
                              title: 'Pending opportunities need attention',
                              message: pendingCount == 1
                                  ? '1 application is still waiting for review.'
                                  : '$pendingCount applications across $pendingOpportunityCount ${pendingOpportunityCount == 1 ? 'opportunity' : 'opportunities'} are still waiting for a decision.',
                              tone: _ApplicationsPalette.accent,
                              background: _ApplicationsPalette.accentSoft,
                              actionLabel: isFocusedView
                                  ? null
                                  : 'Show pending',
                              onAction: isFocusedView
                                  ? null
                                  : _showPendingApplications,
                            ),
                          ],
                          if ((provider.applicationsError ?? '')
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InlineBanner(
                              icon: Icons.info_outline_rounded,
                              title: 'Application data is unavailable.',
                              message: provider.applicationsError!,
                              tone: _ApplicationsPalette.error,
                              background: const Color(0xFFFFF1F2),
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

  Widget _buildTopBar({
    required dynamic user,
    required int unreadCount,
    required bool isFocusedView,
  }) {
    final subtitle = isFocusedView
        ? 'Focused review mode'
        : 'Review and respond to candidates';

    return Row(
      children: [
        _HeaderIconButton(
          icon: widget.showBackButton
              ? Icons.arrow_back_rounded
              : Icons.menu_rounded,
          onTap: () {
            if (widget.showBackButton) {
              Navigator.of(context).maybePop();
              return;
            }

            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Applications',
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(
          user: user,
          unreadCount: unreadCount,
          isFocusedView: isFocusedView,
        ),
        const SizedBox(height: 16),
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
                    label: 'Total',
                    value: '$totalApplications',
                    icon: Icons.inbox_rounded,
                    color: _ApplicationsPalette.primary,
                  ),
                ),
                const _KpiDivider(),
                Expanded(
                  child: _HeroStatTile(
                    label: 'Pending',
                    value: '$pendingCount',
                    icon: Icons.schedule_rounded,
                    color: _ApplicationsPalette.warning,
                  ),
                ),
                const _KpiDivider(),
                Expanded(
                  child: _HeroStatTile(
                    label: 'Reviewed',
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
    final sectionLabelStyle = GoogleFonts.poppins(
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
            Text('FILTERS', style: sectionLabelStyle),
            const Spacer(),
            if (_activeFilterCount > 0)
              _CounterBadge(count: _activeFilterCount, label: 'Active'),
          ],
        ),
        const SizedBox(height: 10),
        _SearchField(
          controller: _searchController,
          hintText: 'Search by candidate, opportunity, location, or type...',
        ),
        const SizedBox(height: 12),
        Text('STATUS', style: sectionLabelStyle),
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
        Text('TYPE', style: sectionLabelStyle),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _TypeFilterChip(
                label: 'All',
                icon: Icons.widgets_outlined,
                selected: _selectedTypeFilter == _allTypeFilter,
                tone: _toneForType(null),
                onTap: () =>
                    setState(() => _selectedTypeFilter = _allTypeFilter),
              ),
              const SizedBox(width: 6),
              _TypeFilterChip(
                label: 'Jobs',
                icon: OpportunityType.icon(OpportunityType.job),
                selected: _selectedTypeFilter == OpportunityType.job,
                tone: _toneForType(OpportunityType.job),
                onTap: () =>
                    setState(() => _selectedTypeFilter = OpportunityType.job),
              ),
              const SizedBox(width: 6),
              _TypeFilterChip(
                label: 'Internships',
                icon: OpportunityType.icon(OpportunityType.internship),
                selected: _selectedTypeFilter == OpportunityType.internship,
                tone: _toneForType(OpportunityType.internship),
                onTap: () => setState(
                  () => _selectedTypeFilter = OpportunityType.internship,
                ),
              ),
              const SizedBox(width: 6),
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
        ),
        if (provider.opportunities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('ROLES', style: sectionLabelStyle),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _OpportunityFilterChip(
                  label: 'All Roles',
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
                'Showing $resultsCount of $totalApplications applications',
                style: GoogleFonts.poppins(
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
                    'Clear',
                    style: GoogleFonts.poppins(
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
        ? 'Direct application review with all candidate details in one place.'
        : _hasActiveFilters
        ? 'Filtered results: $resultsCount of $totalApplications applications.'
        : 'Latest candidates ready for review, messaging, and CV checks.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFocusedView ? 'Application Spotlight' : 'Candidate Queue',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ApplicationsPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
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
      return const _OpportunityTypeTone(
        background: _ApplicationsPalette.surfaceAlt,
        foreground: _ApplicationsPalette.textSecondary,
      );
    }

    return _toneForType(opportunity.type);
  }

  String _typeLabel(String? rawType) {
    return OpportunityType.label(OpportunityType.parse(rawType)).toUpperCase();
  }

  String? _appliedDateLabel(Timestamp? value) {
    if (value == null) {
      return null;
    }
    return DateFormat('MMM d, yyyy').format(value.toDate());
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: _ApplicationsPalette
                                              .textPrimary,
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
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                _ApplicationsPalette.accent,
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
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          _ApplicationsPalette.textSecondary,
                                    ),
                                  ),
                                ],
                                if (relativeAppliedLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Applied $relativeAppliedLabel',
                                    style: GoogleFonts.poppins(
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
                              const Icon(
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
    final isPending =
        ApplicationStatus.parse(application.status) ==
        ApplicationStatus.pending;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.58,
            maxChildSize: 0.9,
            minChildSize: 0.45,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _ApplicationsPalette.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _ApplicationsPalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailHeroCard(
                      studentName: application.studentName,
                      opportunityTitle: _opportunityTitleLabel(opportunity),
                      appliedLabel: _appliedDateLabel(application.appliedAt),
                      typeLabel: opportunity == null
                          ? null
                          : _typeLabel(opportunity.type),
                      typeTone: tone,
                      status: application.status,
                      studentId: application.studentId,
                      onTapProfile: () {
                        Navigator.pop(sheetContext);
                        _openStudentProfile(application);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _WideActionButton(
                            label: 'Profile',
                            icon: Icons.person_outline_rounded,
                            background: _ApplicationsPalette.primarySoft,
                            foreground: _ApplicationsPalette.primary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openStudentProfile(application);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _WideActionButton(
                            label: 'Message',
                            icon: Icons.chat_bubble_outline_rounded,
                            background: const Color(0xFFE8FFFB),
                            foreground: _ApplicationsPalette.secondaryDark,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openChatWithStudent(application);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _WideActionButton(
                            label: 'View CV',
                            icon: Icons.description_outlined,
                            background: const Color(0xFFFFF6E4),
                            foreground: _ApplicationsPalette.accent,
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openStudentProfile(ApplicationModel application) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePreviewScreen(
          userId: application.studentId,
          fallbackName: application.studentName,
          fallbackRole: 'student',
          contextLabel: 'Application',
        ),
      ),
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
      context.showAppSnackBar(
        'Could not open chat: $error',
        title: 'Chat unavailable',
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
        title: 'Update unavailable',
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
      'Application ${ApplicationStatus.sentenceLabel(status)}.',
      title: 'Application updated',
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
                            : 'No uploaded CV',
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
                            : 'No built CV details available.',
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
          'The requested file is not a valid PDF.',
          title: 'Preview unavailable',
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
      if (!mounted) {
        return;
      }
      if (!launched) {
        context.showAppSnackBar(
          'We couldn\'t open the document right now.',
          title: 'Document unavailable',
          type: AppFeedbackType.error,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        _documentErrorMessage(error),
        title: 'Document unavailable',
        type: AppFeedbackType.error,
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
    return 'We couldn\'t open the document right now.';
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
  static const Color primary = CompanyDashboardPalette.primary;
  static const Color primarySoft = CompanyDashboardPalette.primarySoft;
  static const Color secondaryDark = CompanyDashboardPalette.secondaryDark;
  static const Color accent = CompanyDashboardPalette.accent;
  static const Color accentSoft = Color(0xFFFFF7E6);
  static const Color surface = CompanyDashboardPalette.surface;
  static const Color surfaceAlt = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = CompanyDashboardPalette.textPrimary;
  static const Color textSecondary = CompanyDashboardPalette.textSecondary;
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color success = CompanyDashboardPalette.success;
  static const Color warning = CompanyDashboardPalette.warning;
  static const Color error = CompanyDashboardPalette.error;
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
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

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
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(
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
          prefixIcon: const Padding(
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
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
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
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
          : 'The requested application is no longer available.',
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
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: _ApplicationsPalette.primary,
              strokeWidth: 2.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading your applications...',
            style: GoogleFonts.poppins(
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
    final title = isFocusedView
        ? 'This application is no longer available'
        : hasFilters
        ? 'No applications match this view'
        : 'No applications yet';
    final message = isFocusedView
        ? 'The application you opened is no longer available. It may have been removed or may no longer belong to this company.'
        : hasFilters
        ? 'Try clearing the filters or broadening the search to see more candidates.'
        : 'Candidate applications are listed here with quick review actions and CV access.';

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
        color: _ApplicationsPalette.surfaceAlt,
        border: Border.all(color: _ApplicationsPalette.border),
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  final String studentName;
  final String? opportunityTitle;
  final String? appliedLabel;
  final String? typeLabel;
  final _OpportunityTypeTone typeTone;
  final String status;
  final String studentId;
  final VoidCallback? onTapProfile;

  const _DetailHeroCard({
    required this.studentName,
    required this.opportunityTitle,
    required this.appliedLabel,
    required this.typeLabel,
    required this.typeTone,
    required this.status,
    required this.studentId,
    this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ApplicationsPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onTapProfile,
                borderRadius: BorderRadius.circular(999),
                child: ProfileAvatar(
                  radius: 26,
                  userId: studentId,
                  fallbackName: studentName,
                  role: 'student',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onTapProfile,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ApplicationsPalette.textPrimary,
                        ),
                      ),
                      if (opportunityTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          opportunityTitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: _ApplicationsPalette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ApplicationStatusBadge(status: status, fontSize: 10.5),
            ],
          ),
          if (typeLabel != null || appliedLabel != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (typeLabel != null)
                  _TypePill(label: typeLabel!, tone: typeTone),
                if (appliedLabel != null)
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: 'Applied $appliedLabel',
                  ),
              ],
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: foreground.withValues(alpha: 0.16)),
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

