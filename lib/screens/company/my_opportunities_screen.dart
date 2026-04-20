import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import '../notifications_screen.dart';
import 'profile_screen.dart';
import 'publish_opportunity_screen.dart';

class MyOpportunitiesScreen extends StatefulWidget {
  final bool embedded;

  const MyOpportunitiesScreen({super.key, this.embedded = false});

  @override
  State<MyOpportunitiesScreen> createState() => _MyOpportunitiesScreenState();
}

enum _OpportunityFilter { all, open, closed }

enum _OpportunityTypeFilter { all, jobs, internships, sponsored }

class _MyOpportunitiesScreenState extends State<MyOpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  _OpportunityFilter _selectedFilter = _OpportunityFilter.all;
  _OpportunityTypeFilter _selectedTypeFilter = _OpportunityTypeFilter.all;
  bool _sortByApplicants = false;
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    Future.microtask(_loadCompanyData);
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

  Future<void> _loadCompanyData() async {
    if (!mounted) {
      return;
    }

    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      return;
    }

    final provider = context.read<CompanyProvider>();
    await Future.wait([
      provider.loadOpportunities(user.uid),
      provider.loadApplications(user.uid),
    ]);
  }

  bool get _hasActiveFilters {
    return _selectedFilter != _OpportunityFilter.all ||
        _selectedTypeFilter != _OpportunityTypeFilter.all ||
        _sortByApplicants ||
        _searchQuery.isNotEmpty;
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  Map<String, int> _applicationCounts(CompanyProvider provider) {
    final result = <String, int>{};
    for (final application in provider.applications) {
      result.update(
        application.opportunityId,
        (current) => current + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }

  List<OpportunityModel> _filteredOpportunities(
    CompanyProvider provider,
    Map<String, int> applicationCounts,
  ) {
    final normalizedQuery = _searchQuery.toLowerCase();
    final items = provider.opportunities.where((opportunity) {
      final effectiveStatus = opportunity.effectiveStatus();
      final matchesStatus = switch (_selectedFilter) {
        _OpportunityFilter.all => true,
        _OpportunityFilter.open => effectiveStatus == 'open',
        _OpportunityFilter.closed => effectiveStatus == 'closed',
      };
      final normalizedType = OpportunityType.parse(opportunity.type);
      final matchesType = switch (_selectedTypeFilter) {
        _OpportunityTypeFilter.all => true,
        _OpportunityTypeFilter.jobs => normalizedType == OpportunityType.job,
        _OpportunityTypeFilter.internships =>
          normalizedType == OpportunityType.internship,
        _OpportunityTypeFilter.sponsored =>
          normalizedType == OpportunityType.sponsoring,
      };

      if (!matchesStatus || !matchesType) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final haystack = <String>[
        opportunity.title,
        opportunity.location,
        opportunity.description,
        opportunity.requirements,
        opportunity.companyName,
        OpportunityType.label(opportunity.type, _l10n),
        ...opportunity.tags,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    items.sort((first, second) {
      if (_sortByApplicants) {
        final applicantCompare = (applicationCounts[second.id] ?? 0).compareTo(
          applicationCounts[first.id] ?? 0,
        );
        if (applicantCompare != 0) {
          return applicantCompare;
        }
      }

      final secondTime =
          second.updatedAt?.millisecondsSinceEpoch ??
          second.createdAt?.millisecondsSinceEpoch ??
          0;
      final firstTime =
          first.updatedAt?.millisecondsSinceEpoch ??
          first.createdAt?.millisecondsSinceEpoch ??
          0;
      return secondTime.compareTo(firstTime);
    });

    return items;
  }

  Color _toneTint(Color color, {double lightAlpha = 0.10}) {
    return color.withValues(alpha: AppColors.isDark ? 0.18 : lightAlpha);
  }

  _OpportunityTone _toneForType(String rawType) {
    switch (OpportunityType.parse(rawType)) {
      case OpportunityType.internship:
        return _OpportunityTone(
          background: _toneTint(OpportunityType.internshipColor),
          foreground: OpportunityType.internshipColor,
        );
      case OpportunityType.sponsoring:
        return _OpportunityTone(
          background: _toneTint(_OpportunityPalette.accent),
          foreground: _OpportunityPalette.accent,
        );
      case OpportunityType.job:
      default:
        return _OpportunityTone(
          background: _OpportunityPalette.primarySoft,
          foreground: _OpportunityPalette.primary,
        );
    }
  }

  _OpportunityTone _toneForStatus(String status) {
    if (status == 'closed') {
      return _OpportunityTone(
        background: _OpportunityPalette.surfaceMuted,
        foreground: _OpportunityPalette.textMuted,
      );
    }

    return _OpportunityTone(
      background: _toneTint(_OpportunityPalette.success, lightAlpha: 0.12),
      foreground: _OpportunityPalette.success,
    );
  }

  String _statusLabel(String status) => status == 'closed' ? 'Closed' : 'Open';

  DateTime? _deadlineDate(OpportunityModel opportunity) {
    return opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadline);
  }

  String _timeLeftLabel(OpportunityModel opportunity) {
    if (opportunity.effectiveStatus() == 'closed') {
      return 'Closed';
    }

    final deadline = _deadlineDate(opportunity);
    if (deadline == null) {
      return 'No deadline';
    }

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Expired';
    }
    if (remaining.inHours < 24) {
      final hours = remaining.inHours == 0 ? 1 : remaining.inHours;
      return '${hours}h left';
    }

    final days = remaining.inHours % 24 == 0
        ? remaining.inDays
        : remaining.inDays + 1;
    return '${days}d left';
  }

  String _postedLabel(OpportunityModel opportunity) {
    final createdAt = opportunity.createdAt?.toDate();
    if (createdAt == null) {
      return 'Recent';
    }

    return DateFormat('MMM d').format(createdAt);
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedFilter = _OpportunityFilter.all;
      _selectedTypeFilter = _OpportunityTypeFilter.all;
      _sortByApplicants = false;
    });
  }

  Future<void> _openPublish() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PublishOpportunityScreen()));
    await _loadCompanyData();
  }

  Future<void> _openEdit(String opportunityId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishOpportunityScreen(opportunityId: opportunityId),
      ),
    );
    await _loadCompanyData();
  }

  Future<void> _toggleStatus(OpportunityModel opportunity) async {
    final provider = context.read<CompanyProvider>();
    final currentStatus = opportunity.effectiveStatus();
    if (currentStatus == 'closed' && opportunity.isDeadlineExpired()) {
      context.showAppSnackBar(
        _l10n.uiMoveTheDeadlineIntoTheFutureBeforeReopeningThisOpportunity,
        title: _l10n.uiDeadlineExpired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final nextStatus = currentStatus == 'closed' ? 'open' : 'closed';
    final error = await provider.updateOpportunity(opportunity.id, {
      'status': nextStatus,
    });

    if (!mounted) {
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

    await _loadCompanyData();
  }

  Future<void> _deleteOpportunity(OpportunityModel opportunity) async {
    final provider = context.read<CompanyProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            _l10n.uiDeleteOpportunity,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _OpportunityPalette.textPrimary,
            ),
          ),
          content: Text(
            'Delete "${opportunity.title}"? If it already has applications, it will be closed instead so history is preserved.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _OpportunityPalette.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                _l10n.cancelLabel,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _OpportunityPalette.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                _l10n.uiDelete,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: _OpportunityPalette.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final wasClosed = await provider.deleteOpportunity(opportunity.id);
    final error = provider.mutationError;

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _l10n.uiDeleteUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    await _loadCompanyData();
    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      wasClosed == true
          ? _l10n.uiOpportunityClosedBecauseApplicationsAlreadyExist
          : _l10n.uiOpportunityDeleted,
      title: wasClosed == true
          ? _l10n.uiOpportunityClosed
          : _l10n.uiOpportunityDeleted,
      type: AppFeedbackType.success,
    );
  }

  Future<void> _showOpportunityDetails(
    OpportunityModel opportunity,
    int applicantCount,
  ) async {
    final tone = _toneForType(opportunity.type);
    final effectiveStatus = opportunity.effectiveStatus();
    final statusTone = _toneForStatus(effectiveStatus);
    final deadline = _deadlineDate(opportunity);
    final metadata = OpportunityMetadata.buildMetadataItems(
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
      maxItems: 6,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.86,
            maxChildSize: 0.95,
            minChildSize: 0.55,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _OpportunityPalette.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _OpportunityPalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: tone.background,
                            borderRadius: BorderRadius.circular(12),
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
                                opportunity.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _OpportunityPalette.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place_rounded,
                                    size: 13,
                                    color: _OpportunityPalette.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      opportunity.location.trim().isEmpty
                                          ? 'Location not specified'
                                          : opportunity.location.trim(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:
                                            _OpportunityPalette.textSecondary,
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
                    Row(
                      children: [
                        _SoftPill(
                          label: OpportunityType.label(opportunity.type, _l10n),
                          background: tone.background,
                          foreground: tone.foreground,
                        ),
                        const SizedBox(width: 6),
                        _SoftPill(
                          label: _statusLabel(effectiveStatus),
                          background: statusTone.background,
                          foreground: statusTone.foreground,
                        ),
                        const SizedBox(width: 6),
                        _SoftPill(
                          label: _timeLeftLabel(opportunity),
                          background: _OpportunityPalette.surfaceMuted,
                          foreground: _OpportunityPalette.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _OpportunityPalette.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _OpportunityPalette.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DetailStat(
                              label: 'Applicants',
                              value: '$applicantCount',
                              icon: Icons.groups_rounded,
                            ),
                          ),
                          const _DetailDivider(),
                          Expanded(
                            child: _DetailStat(
                              label: 'Posted',
                              value: _postedLabel(opportunity),
                              icon: Icons.event_note_rounded,
                            ),
                          ),
                          const _DetailDivider(),
                          Expanded(
                            child: _DetailStat(
                              label: 'Deadline',
                              value: deadline == null
                                  ? '—'
                                  : DateFormat('MMM d').format(deadline),
                              icon: Icons.schedule_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryActionButton(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openEdit(opportunity.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GhostActionButton(
                            label: effectiveStatus == 'closed'
                                ? 'Reopen'
                                : 'Close',
                            icon: effectiveStatus == 'closed'
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                            foreground: effectiveStatus == 'closed'
                                ? _OpportunityPalette.success
                                : _OpportunityPalette.warning,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _toggleStatus(opportunity);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SectionTitle('Role details'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: metadata
                            .map((item) => _MetaChip(label: item))
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SectionTitle('Description'),
                    const SizedBox(height: 8),
                    Text(
                      opportunity.description.trim().isEmpty
                          ? 'No description provided.'
                          : opportunity.description.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.6,
                        color: _OpportunityPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      OpportunityType.requirementsLabel(
                        opportunity.type,
                        _l10n,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildRequirementItems(opportunity, tone),
                    const SizedBox(height: 18),
                    _SectionTitle('Publishing'),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Status',
                      value: _statusLabel(effectiveStatus),
                    ),
                    _DetailRow(
                      label: 'Posted',
                      value: _postedLabel(opportunity),
                    ),
                    _DetailRow(
                      label: 'Deadline',
                      value: deadline == null
                          ? (opportunity.deadline.trim().isEmpty
                                ? 'Not specified'
                                : opportunity.deadline.trim())
                          : DateFormat('MMM d, yyyy').format(deadline),
                      isLast: true,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _deleteOpportunity(opportunity);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'Delete opportunity',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _OpportunityPalette.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildRequirementItems(
    OpportunityModel opportunity,
    _OpportunityTone tone,
  ) {
    final items =
        (opportunity.requirementItems.isNotEmpty
                ? opportunity.requirementItems
                : [opportunity.requirements.trim()])
            .where((item) => item.trim().isNotEmpty)
            .toList();

    if (items.isEmpty) {
      return [
        Text(
          'No requirements provided.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: _OpportunityPalette.textMuted,
          ),
        ),
      ];
    }

    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  decoration: BoxDecoration(
                    color: tone.foreground,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.trim(),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.55,
                      color: _OpportunityPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final provider = context.watch<CompanyProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    Widget wrapScaffold(Widget body) {
      final scaffold = Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: widget.embedded
              ? 'company-opportunity-fab-embedded'
              : 'company-opportunity-fab',
          backgroundColor: _OpportunityPalette.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openPublish,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'New',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

    final applicationCounts = _applicationCounts(provider);
    final opportunities = _filteredOpportunities(provider, applicationCounts);
    final totalApplicants = applicationCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final openCount = provider.opportunities
        .where((item) => item.effectiveStatus() == 'open')
        .length;

    return wrapScaffold(
      GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          color: _OpportunityPalette.primary,
          onRefresh: _loadCompanyData,
          child: CustomScrollView(
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
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.embedded) ...[
                        _buildTopBar(context, user, unreadCount),
                        const SizedBox(height: 16),
                      ],
                      _buildKpiRow(
                        total: provider.opportunities.length,
                        open: openCount,
                        applicants: totalApplicants,
                      ),
                      const SizedBox(height: 14),
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      _buildStatusRow(),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: _TypeFilterGroup(
                          selectedFilter: _selectedTypeFilter,
                          onSelected: (filter) {
                            setState(() => _selectedTypeFilter = filter);
                          },
                        ),
                      ),
                      if ((provider.opportunitiesError ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _InlineBanner(
                            icon: Icons.info_outline_rounded,
                            title: _l10n.uiCouldNotRefreshOpportunities,
                            message: provider.opportunitiesError!,
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildResultsBar(
                        opportunities.length,
                        provider.opportunities.length,
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.opportunitiesLoading &&
                  provider.opportunities.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingState(),
                )
              else if (opportunities.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    hasExistingOpportunities: provider.opportunities.isNotEmpty,
                    onCreate: _openPublish,
                    onClear: _hasActiveFilters ? _clearFilters : null,
                  ),
                )
              else if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final opportunity = opportunities[index];
                      final effectiveStatus = opportunity.effectiveStatus();
                      final applicantCount =
                          applicationCounts[opportunity.id] ?? 0;
                      return _OpportunityGridCard(
                        opportunity: opportunity,
                        applicantCount: applicantCount,
                        tone: _toneForType(opportunity.type),
                        statusTone: _toneForStatus(effectiveStatus),
                        timeLeftLabel: _timeLeftLabel(opportunity),
                        statusLabel: _statusLabel(effectiveStatus),
                        onTap: () => _showOpportunityDetails(
                          opportunity,
                          applicantCount,
                        ),
                      );
                    }, childCount: opportunities.length),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final opportunity = opportunities[index];
                      final effectiveStatus = opportunity.effectiveStatus();
                      final applicantCount =
                          applicationCounts[opportunity.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OpportunityListRow(
                          opportunity: opportunity,
                          applicantCount: applicantCount,
                          tone: _toneForType(opportunity.type),
                          statusTone: _toneForStatus(effectiveStatus),
                          timeLeftLabel: _timeLeftLabel(opportunity),
                          postedLabel: _postedLabel(opportunity),
                          statusLabel: _statusLabel(effectiveStatus),
                          onTap: () => _showOpportunityDetails(
                            opportunity,
                            applicantCount,
                          ),
                        ),
                      );
                    }, childCount: opportunities.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, dynamic user, int unreadCount) {
    return Row(
      children: [
        _HeaderIconButton(icon: Icons.work_outline_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opportunities',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _OpportunityPalette.textPrimary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your listings',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _OpportunityPalette.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
              color: _OpportunityPalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _OpportunityPalette.border),
            ),
            child: ProfileAvatar(user: user, radius: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow({
    required int total,
    required int open,
    required int applicants,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: _OpportunityPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _KpiCell(
                label: 'Total',
                value: '$total',
                icon: Icons.work_outline_rounded,
                color: _OpportunityPalette.primary,
              ),
            ),
            const _KpiDivider(),
            Expanded(
              child: _KpiCell(
                label: 'Live',
                value: '$open',
                icon: Icons.bolt_rounded,
                color: _OpportunityPalette.success,
              ),
            ),
            const _KpiDivider(),
            Expanded(
              child: _KpiCell(
                label: 'Applicants',
                value: '$applicants',
                icon: Icons.groups_rounded,
                color: _OpportunityPalette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _OpportunityPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: _OpportunityPalette.textPrimary,
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
              size: 18,
              color: _OpportunityPalette.textMuted,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : GestureDetector(
                  onTap: _searchController.clear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _OpportunityPalette.textMuted,
                  ),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 20,
          ),
          hintText: 'Search title, location, or keyword',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: _OpportunityPalette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Expanded(
          child: _SegmentGroup(
            selectedFilter: _selectedFilter,
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
        ),
        const SizedBox(width: 8),
        _SortButton(
          selected: _sortByApplicants,
          onTap: () {
            setState(() {
              _sortByApplicants = !_sortByApplicants;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResultsBar(int shown, int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$shown of $total',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _OpportunityPalette.textMuted,
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
                  fontWeight: FontWeight.w600,
                  color: _OpportunityPalette.primary,
                ),
              ),
            ),
          ),
        _ViewToggle(
          isGrid: _isGridView,
          onChanged: (grid) {
            setState(() => _isGridView = grid);
          },
        ),
      ],
    );
  }
}

class _OpportunityPalette {
  static Color get primary => CompanyDashboardPalette.primary;
  static Color get primarySoft => CompanyDashboardPalette.primarySoft;
  static Color get accent => CompanyDashboardPalette.accent;
  static Color get surface => CompanyDashboardPalette.surface;
  static Color get surfaceMuted => CompanyDashboardPalette.surfaceMuted;
  static Color get border => CompanyDashboardPalette.border;
  static Color get textPrimary => CompanyDashboardPalette.textPrimary;
  static Color get textSecondary => CompanyDashboardPalette.textSecondary;
  static Color get textMuted => AppColors.current.textMuted;
  static Color get success => CompanyDashboardPalette.success;
  static Color get warning => CompanyDashboardPalette.warning;
  static Color get error => CompanyDashboardPalette.error;
}

class _OpportunityTone {
  final Color background;
  final Color foreground;

  const _OpportunityTone({required this.background, required this.foreground});
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
            color: _OpportunityPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _OpportunityPalette.border),
          ),
          child: Icon(icon, color: _OpportunityPalette.textPrimary, size: 18),
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
                color: _OpportunityPalette.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _OpportunityPalette.surface,
                  width: 1.5,
                ),
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

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCell({
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
                  color: _OpportunityPalette.textMuted,
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
              color: _OpportunityPalette.textPrimary,
              height: 1.05,
            ),
          ),
        ],
      ),
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
      color: _OpportunityPalette.border,
    );
  }
}

class _SegmentGroup extends StatelessWidget {
  final _OpportunityFilter selectedFilter;
  final ValueChanged<_OpportunityFilter> onSelected;

  const _SegmentGroup({required this.selectedFilter, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _OpportunityPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'All',
              selected: selectedFilter == _OpportunityFilter.all,
              onTap: () => onSelected(_OpportunityFilter.all),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Open',
              selected: selectedFilter == _OpportunityFilter.open,
              onTap: () => onSelected(_OpportunityFilter.open),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Closed',
              selected: selectedFilter == _OpportunityFilter.closed,
              onTap: () => onSelected(_OpportunityFilter.closed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _OpportunityPalette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : _OpportunityPalette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _SortButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? _OpportunityPalette.primarySoft
              : _OpportunityPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _OpportunityPalette.primary.withValues(alpha: 0.3)
                : _OpportunityPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: selected
                  ? _OpportunityPalette.primary
                  : _OpportunityPalette.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Top',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? _OpportunityPalette.primary
                    : _OpportunityPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterGroup extends StatelessWidget {
  final _OpportunityTypeFilter selectedFilter;
  final ValueChanged<_OpportunityTypeFilter> onSelected;

  const _TypeFilterGroup({
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypeFilterChip(
          label: 'All',
          selected: selectedFilter == _OpportunityTypeFilter.all,
          foreground: _OpportunityPalette.primary,
          onTap: () => onSelected(_OpportunityTypeFilter.all),
        ),
        const SizedBox(width: 6),
        _TypeFilterChip(
          label: 'Jobs',
          selected: selectedFilter == _OpportunityTypeFilter.jobs,
          foreground: OpportunityType.jobColor,
          onTap: () => onSelected(_OpportunityTypeFilter.jobs),
        ),
        const SizedBox(width: 6),
        _TypeFilterChip(
          label: 'Internships',
          selected: selectedFilter == _OpportunityTypeFilter.internships,
          foreground: OpportunityType.internshipColor,
          onTap: () => onSelected(_OpportunityTypeFilter.internships),
        ),
        const SizedBox(width: 6),
        _TypeFilterChip(
          label: 'Sponsored',
          selected: selectedFilter == _OpportunityTypeFilter.sponsored,
          foreground: _OpportunityPalette.accent,
          onTap: () => onSelected(_OpportunityTypeFilter.sponsored),
        ),
      ],
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color foreground;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? foreground.withValues(alpha: 0.1)
              : _OpportunityPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? foreground.withValues(alpha: 0.35)
                : _OpportunityPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? foreground
                    : _OpportunityPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;

  const _ViewToggle({required this.isGrid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _OpportunityPalette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            selected: isGrid,
            onTap: () => onChanged(true),
          ),
          _ViewToggleButton(
            icon: Icons.view_agenda_outlined,
            selected: !isGrid,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 30,
        height: 28,
        decoration: BoxDecoration(
          color: selected
              ? _OpportunityPalette.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 15,
          color: selected
              ? _OpportunityPalette.primary
              : _OpportunityPalette.textMuted,
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _OpportunityPalette.error.withValues(
          alpha: AppColors.isDark ? 0.14 : 0.08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _OpportunityPalette.error.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _OpportunityPalette.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _OpportunityPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _OpportunityPalette.textSecondary,
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

class _OpportunityGridCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final int applicantCount;
  final _OpportunityTone tone;
  final _OpportunityTone statusTone;
  final String timeLeftLabel;
  final String statusLabel;
  final VoidCallback onTap;

  const _OpportunityGridCard({
    required this.opportunity,
    required this.applicantCount,
    required this.tone,
    required this.statusTone,
    required this.timeLeftLabel,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _OpportunityPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _OpportunityPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tone.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      OpportunityType.icon(opportunity.type),
                      size: 18,
                      color: tone.foreground,
                    ),
                  ),
                  const Spacer(),
                  _StatusDot(tone: statusTone, label: statusLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                OpportunityType.label(
                  opportunity.type,
                  AppLocalizations.of(context)!,
                ).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: tone.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opportunity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _OpportunityPalette.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 12,
                    color: _OpportunityPalette.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      opportunity.location.trim().isEmpty
                          ? 'Remote'
                          : opportunity.location.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: _OpportunityPalette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(height: 1, color: _OpportunityPalette.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 13,
                    color: _OpportunityPalette.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$applicantCount',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _OpportunityPalette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule_rounded,
                    size: 11,
                    color: _OpportunityPalette.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      timeLeftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _OpportunityPalette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityListRow extends StatelessWidget {
  final OpportunityModel opportunity;
  final int applicantCount;
  final _OpportunityTone tone;
  final _OpportunityTone statusTone;
  final String timeLeftLabel;
  final String postedLabel;
  final String statusLabel;
  final VoidCallback onTap;

  const _OpportunityListRow({
    required this.opportunity,
    required this.applicantCount,
    required this.tone,
    required this.statusTone,
    required this.timeLeftLabel,
    required this.postedLabel,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _OpportunityPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _OpportunityPalette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  OpportunityType.icon(opportunity.type),
                  size: 20,
                  color: tone.foreground,
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
                            opportunity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _OpportunityPalette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusDot(tone: statusTone, label: statusLabel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          OpportunityType.label(
                            opportunity.type,
                            AppLocalizations.of(context)!,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: tone.foreground,
                          ),
                        ),
                        _InlineDot(),
                        Icon(
                          Icons.place_rounded,
                          size: 11,
                          color: _OpportunityPalette.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            opportunity.location.trim().isEmpty
                                ? 'Remote'
                                : opportunity.location.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: _OpportunityPalette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 12,
                          color: _OpportunityPalette.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$applicantCount applicants',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _OpportunityPalette.textSecondary,
                          ),
                        ),
                        _InlineDot(),
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: _OpportunityPalette.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            timeLeftLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: _OpportunityPalette.textMuted,
                            ),
                          ),
                        ),
                        _InlineDot(),
                        Flexible(
                          child: Text(
                            postedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: _OpportunityPalette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: _OpportunityPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final _OpportunityTone tone;
  final String label;

  const _StatusDot({required this.tone, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: tone.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _OpportunityPalette.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _SoftPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _OpportunityPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _OpportunityPalette.textSecondary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _OpportunityPalette.textMuted,
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _OpportunityPalette.primary),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _OpportunityPalette.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: _OpportunityPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: _OpportunityPalette.border);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: _OpportunityPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _OpportunityPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _OpportunityPalette.primary,
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

class _GhostActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onTap;

  const _GhostActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: foreground.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: _OpportunityPalette.primary,
              strokeWidth: 2.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading opportunities...',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _OpportunityPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasExistingOpportunities;
  final VoidCallback onCreate;
  final VoidCallback? onClear;

  const _EmptyState({
    required this.hasExistingOpportunities,
    required this.onCreate,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _OpportunityPalette.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 26,
                color: _OpportunityPalette.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasExistingOpportunities
                  ? 'No matches found'
                  : 'No opportunities yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _OpportunityPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasExistingOpportunities
                  ? 'Try clearing the filters or adjusting your search.'
                  : 'Publish your first role to start hiring.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.5,
                color: _OpportunityPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (hasExistingOpportunities && onClear != null)
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _OpportunityPalette.primary,
                  side: BorderSide(color: _OpportunityPalette.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Create opportunity',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _OpportunityPalette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
