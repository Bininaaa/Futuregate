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
    final provider = context.watch<CompanyProvider>();
    final items = _filteredItems(provider);
    final isFocusedView = (widget.initialApplicationId ?? '').trim().isNotEmpty;
    final resultsCount = items.length;
    final totalApplications = provider.applications.length;

    _maybeOpenFocusedDetails(items, provider);

    return Scaffold(
      backgroundColor: _ApplicationsPalette.background,
      appBar: AppBar(
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
        automaticallyImplyLeading: widget.showBackButton,
        iconTheme: const IconThemeData(color: _ApplicationsPalette.textPrimary),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          color: _ApplicationsPalette.primary,
          onRefresh: _loadApplicationsData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isFocusedView) ...[
                        _SearchField(
                          controller: _searchController,
                          hintText:
                              'Search applications by student, role, location, or type...',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              'APPLICATION FILTERS',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _ApplicationsPalette.textSecondary,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CounterBadge(count: resultsCount),
                            const Spacer(),
                            TextButton(
                              onPressed: _hasActiveFilters
                                  ? _clearFilters
                                  : null,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Clear all',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _hasActiveFilters
                                      ? _ApplicationsPalette.textSecondary
                                      : _ApplicationsPalette.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Showing $resultsCount of $totalApplications applications',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _ApplicationsPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 46,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _ApplicationStatusFilter.values
                                .map(
                                  (filter) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _FilterChip(
                                      label: _statusLabel(filter),
                                      count: _statusCount(provider, filter),
                                      selected: _selectedStatusFilter == filter,
                                      activeColor:
                                          filter ==
                                              _ApplicationStatusFilter.approved
                                          ? _ApplicationsPalette.success
                                          : filter ==
                                                _ApplicationStatusFilter
                                                    .rejected
                                          ? _ApplicationsPalette.error
                                          : filter ==
                                                _ApplicationStatusFilter.pending
                                          ? _ApplicationsPalette.warning
                                          : _ApplicationsPalette.primary,
                                      onTap: () => setState(
                                        () => _selectedStatusFilter = filter,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _TypeFilterChip(
                                label: 'All Types',
                                selected: _selectedTypeFilter == _allTypeFilter,
                                tone: _toneForType(null),
                                onTap: () => setState(
                                  () => _selectedTypeFilter = _allTypeFilter,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _TypeFilterChip(
                                label: 'Jobs',
                                selected:
                                    _selectedTypeFilter == OpportunityType.job,
                                tone: _toneForType(OpportunityType.job),
                                onTap: () => setState(
                                  () =>
                                      _selectedTypeFilter = OpportunityType.job,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _TypeFilterChip(
                                label: 'Internships',
                                selected:
                                    _selectedTypeFilter ==
                                    OpportunityType.internship,
                                tone: _toneForType(OpportunityType.internship),
                                onTap: () => setState(
                                  () => _selectedTypeFilter =
                                      OpportunityType.internship,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _TypeFilterChip(
                                label: 'Sponsored',
                                selected:
                                    _selectedTypeFilter ==
                                    OpportunityType.sponsoring,
                                tone: _toneForType(OpportunityType.sponsoring),
                                onTap: () => setState(
                                  () => _selectedTypeFilter =
                                      OpportunityType.sponsoring,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        _FocusedApplicationBanner(count: resultsCount),
                      if (!isFocusedView &&
                          provider.opportunities.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _OpportunityFilterChip(
                                label: 'All Roles',
                                selected:
                                    _selectedOpportunityFilter ==
                                    _allOpportunityFilter,
                                onTap: () => setState(
                                  () => _selectedOpportunityFilter =
                                      _allOpportunityFilter,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...provider.opportunities.map(
                                (opportunity) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _OpportunityFilterChip(
                                    label: opportunity.title,
                                    selected:
                                        _selectedOpportunityFilter ==
                                        opportunity.id,
                                    onTap: () => setState(
                                      () => _selectedOpportunityFilter =
                                          opportunity.id,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if ((provider.applicationsError ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _InlineBanner(
                            icon: Icons.info_outline_rounded,
                            title: 'Application data is unavailable.',
                            message: provider.applicationsError!,
                            tone: _ApplicationsPalette.error,
                            background: const Color(0xFFFFF1F2),
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
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyApplicationsState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildApplicationCard(items[index], provider),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _OpportunityTypeTone _toneForType(String? rawType) {
    switch (OpportunityType.parse(rawType)) {
      case OpportunityType.internship:
        return const _OpportunityTypeTone(
          background: _ApplicationsPalette.accentSoft,
          foreground: _ApplicationsPalette.accent,
        );
      case OpportunityType.sponsoring:
        return const _OpportunityTypeTone(
          background: Color(0xFFE8FFFB),
          foreground: _ApplicationsPalette.secondaryDark,
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
    CompanyProvider provider,
  ) {
    final application = item.application;
    final opportunity = item.opportunity;
    final typeTone = _toneForType(opportunity?.type);
    final isPending =
        ApplicationStatus.parse(application.status) ==
        ApplicationStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _showApplicationDetailsSheet(item, provider),
          child: Container(
            decoration: BoxDecoration(
              color: _ApplicationsPalette.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: typeTone.foreground.withValues(alpha: 0.18),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: typeTone.foreground.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                            child: ProfileAvatar(
                              radius: 21,
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
                                Text(
                                  application.studentName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _ApplicationsPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opportunity?.title ?? 'Unknown opportunity',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _ApplicationsPalette.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ApplicationStatusBadge(
                                status: application.status,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _ApplicationsPalette.surfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _ApplicationsPalette.textMuted,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TypePill(
                            label: _typeLabel(opportunity?.type),
                            tone: typeTone,
                          ),
                          if ((opportunity?.location ?? '').trim().isNotEmpty)
                            _MetaPill(
                              icon: Icons.place_rounded,
                              label: opportunity!.location.trim(),
                            ),
                          _MetaPill(
                            icon: Icons.schedule_rounded,
                            label: _appliedDateLabel(application.appliedAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ],
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ApplicationsPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: _ApplicationsPalette.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: _ApplicationsPalette.textMuted,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 58,
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

  const _CounterBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _ApplicationsPalette.primary,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.activeColor,
    required this.onTap,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.22)
                : _ApplicationsPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
  final _OpportunityTypeTone tone;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tone.background : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? tone.foreground.withValues(alpha: 0.18)
                : _ApplicationsPalette.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? tone.foreground
                : _ApplicationsPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OpportunityFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OpportunityFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _ApplicationsPalette.primarySoft
              : _ApplicationsPalette.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? _ApplicationsPalette.primary.withValues(alpha: 0.16)
                : _ApplicationsPalette.border,
          ),
        ),
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

  const _InlineBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _ApplicationsPalette.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: _ApplicationsPalette.primary,
                strokeWidth: 2.6,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading applications...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _ApplicationsPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplicationsState extends StatelessWidget {
  const _EmptyApplicationsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _ApplicationsPalette.surface,
            borderRadius: BorderRadius.circular(30),
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
                'No applications match these filters',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ApplicationsPalette.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Try clearing the filters or broadening the search to see more candidates.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: tone.background,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.surfaceAlt,
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
          borderRadius: BorderRadius.circular(16),
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
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        color: _ApplicationsPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
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
          borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ApplicationsPalette.border),
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
          Row(
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
