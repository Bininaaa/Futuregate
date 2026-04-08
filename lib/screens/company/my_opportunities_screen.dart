import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'profile_screen.dart';
import 'publish_opportunity_screen.dart';

class MyOpportunitiesScreen extends StatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  State<MyOpportunitiesScreen> createState() => _MyOpportunitiesScreenState();
}

enum _OpportunityFilter { all, open, closed }

enum _OpportunityTypeFilter { all, jobs, internships, sponsored }

class _MyOpportunitiesScreenState extends State<MyOpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  _OpportunityFilter _selectedFilter = _OpportunityFilter.all;
  _OpportunityTypeFilter _selectedTypeFilter = _OpportunityTypeFilter.all;
  bool _sortByApplicants = true;
  bool _isCompactListView = false;
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

  int get _activeFilterCount {
    var count = 0;
    if (_selectedFilter != _OpportunityFilter.all) {
      count++;
    }
    if (_selectedTypeFilter != _OpportunityTypeFilter.all) {
      count++;
    }
    if (_sortByApplicants) {
      count++;
    }
    if (_searchQuery.isNotEmpty) {
      count++;
    }
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

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
      final matchesStatus = switch (_selectedFilter) {
        _OpportunityFilter.all => true,
        _OpportunityFilter.open => opportunity.status == 'open',
        _OpportunityFilter.closed => opportunity.status == 'closed',
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
        OpportunityType.label(opportunity.type),
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

  _OpportunityTone _toneForType(String rawType) {
    switch (OpportunityType.parse(rawType)) {
      case OpportunityType.internship:
        return const _OpportunityTone(
          background: Color(0xFFEAF3FF),
          foreground: OpportunityType.internshipColor,
        );
      case OpportunityType.sponsoring:
        return const _OpportunityTone(
          background: _OpportunityPalette.accentSoft,
          foreground: _OpportunityPalette.accent,
        );
      case OpportunityType.job:
      default:
        return const _OpportunityTone(
          background: _OpportunityPalette.primarySoft,
          foreground: _OpportunityPalette.primary,
        );
    }
  }

  _OpportunityTone _toneForStatus(String status) {
    if (status == 'closed') {
      return const _OpportunityTone(
        background: Color(0xFFF1F5F9),
        foreground: _OpportunityPalette.textSecondary,
      );
    }

    return const _OpportunityTone(
      background: Color(0xFFECFDF3),
      foreground: _OpportunityPalette.success,
    );
  }

  String _statusLabel(String status) => status == 'closed' ? 'Closed' : 'Open';

  DateTime? _deadlineDate(OpportunityModel opportunity) {
    return opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadline);
  }

  String _timeLeftLabel(OpportunityModel opportunity) {
    if (opportunity.status == 'closed') {
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
      return '$hours h left';
    }

    final days = remaining.inHours % 24 == 0
        ? remaining.inDays
        : remaining.inDays + 1;
    return '$days ${days == 1 ? 'day' : 'days'}';
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
    final messenger = ScaffoldMessenger.of(context);
    final nextStatus = opportunity.status == 'closed' ? 'open' : 'closed';
    final error = await provider.updateOpportunity(opportunity.id, {
      'status': nextStatus,
    });

    if (!mounted) {
      return;
    }

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await _loadCompanyData();
  }

  Future<void> _deleteOpportunity(OpportunityModel opportunity) async {
    final provider = context.read<CompanyProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete opportunity',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: _OpportunityPalette.textPrimary,
            ),
          ),
          content: Text(
            'Delete "${opportunity.title}"? If it already has applications, it will be closed instead so history is preserved.',
            style: GoogleFonts.poppins(
              color: _OpportunityPalette.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: _OpportunityPalette.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: _OpportunityPalette.error),
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
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await _loadCompanyData();
    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasClosed == true
              ? 'Opportunity closed because applications already exist.'
              : 'Opportunity deleted.',
        ),
      ),
    );
  }

  Future<void> _showOpportunityDetails(
    OpportunityModel opportunity,
    int applicantCount,
  ) async {
    final tone = _toneForType(opportunity.type);
    final statusTone = _toneForStatus(opportunity.status);
    final deadline = _deadlineDate(opportunity);
    final metadata = OpportunityMetadata.buildMetadataItems(
      type: opportunity.type,
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      isPaid: opportunity.isPaid,
      employmentType: opportunity.employmentType,
      workMode: opportunity.workMode,
      duration: opportunity.duration,
      maxItems: 5,
    );

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
                decoration: const BoxDecoration(
                  color: _OpportunityPalette.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
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
                          color: _OpportunityPalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tone.background,
                            _OpportunityPalette.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: tone.foreground.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  OpportunityType.icon(opportunity.type),
                                  color: tone.foreground,
                                  size: 26,
                                ),
                              ),
                              const Spacer(),
                              _MiniPill(
                                label: OpportunityType.label(opportunity.type),
                                background: tone.background,
                                foreground: tone.foreground,
                              ),
                              const SizedBox(width: 8),
                              _MiniPill(
                                label: _statusLabel(opportunity.status),
                                background: statusTone.background,
                                foreground: statusTone.foreground,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            opportunity.title,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _OpportunityPalette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: _OpportunityPalette.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opportunity.location.trim().isEmpty
                                      ? 'Location not specified'
                                      : opportunity.location.trim(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _OpportunityPalette.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaChip(
                                icon: Icons.groups_rounded,
                                label:
                                    '$applicantCount ${applicantCount == 1 ? 'applicant' : 'applicants'}',
                              ),
                              _MetaChip(
                                icon: Icons.schedule_rounded,
                                label: _timeLeftLabel(opportunity),
                              ),
                              if (deadline != null)
                                _MetaChip(
                                  icon: Icons.event_rounded,
                                  label:
                                      'Deadline ${DateFormat('MMM d, yyyy').format(deadline)}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryActionButton(
                            label: 'Edit Opportunity',
                            icon: Icons.edit_outlined,
                            background: _OpportunityPalette.primary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openEdit(opportunity.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GhostActionButton(
                            label: opportunity.status == 'closed'
                                ? 'Reopen'
                                : 'Close',
                            icon: opportunity.status == 'closed'
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                            foreground: opportunity.status == 'closed'
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
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Role Details',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: metadata
                              .map((item) => _MetaChip(label: item))
                              .toList(growable: false),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Description',
                      child: Text(
                        opportunity.description.trim().isEmpty
                            ? 'No description provided.'
                            : opportunity.description.trim(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.6,
                          color: _OpportunityPalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: OpportunityType.requirementsLabel(
                        opportunity.type,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (opportunity.requirementItems.isNotEmpty
                                    ? opportunity.requirementItems
                                    : [opportunity.requirements.trim()])
                                .where((item) => item.trim().isNotEmpty)
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(
                                            top: 6,
                                            right: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tone.foreground,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            item.trim(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              height: 1.55,
                                              color: _OpportunityPalette
                                                  .textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Publishing',
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Status',
                            value: _statusLabel(opportunity.status),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _deleteOpportunity(opportunity);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        'Delete opportunity',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _OpportunityPalette.error,
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final provider = context.watch<CompanyProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final applicationCounts = _applicationCounts(provider);
    final opportunities = _filteredOpportunities(provider, applicationCounts);
    final totalApplicants = applicationCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final openCount = provider.opportunities
        .where((item) => item.status == 'open')
        .length;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'company-opportunity-fab',
          backgroundColor: _OpportunityPalette.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          onPressed: _openPublish,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            bottom: false,
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
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _HeaderIconButton(
                                icon: Icons.menu_rounded,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Opportunities',
                                      style: GoogleFonts.poppins(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        color: _OpportunityPalette.textPrimary,
                                        height: 1.05,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Manage roles and keep listings polished.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        height: 1.35,
                                        color:
                                            _OpportunityPalette.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              _NotificationIconButton(
                                unreadCount: unreadCount,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CompanyProfileScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: _OpportunityPalette.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _OpportunityPalette.border,
                                    ),
                                  ),
                                  child: ProfileAvatar(user: user, radius: 17),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  _OpportunityPalette.primary,
                                  CompanyDashboardPalette.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _OpportunityPalette.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Company pipeline',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.16,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '$openCount live',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _HeroMetric(
                                        label: 'Total',
                                        value:
                                            '${provider.opportunities.length}',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _HeroMetric(
                                        label: 'Live',
                                        value: '$openCount',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _HeroMetric(
                                        label: 'Applicants',
                                        value: '$totalApplicants',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  totalApplicants == 0
                                      ? 'Your opportunities are ready for new applicants.'
                                      : 'Track openings and applicant flow in one place.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: _OpportunityPalette.surface,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: _OpportunityPalette.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _OpportunityPalette.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: _OpportunityPalette.textMuted,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 58,
                                  minHeight: 22,
                                ),
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: _searchController.clear,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: _OpportunityPalette.textMuted,
                                        ),
                                      ),
                                hintText:
                                    'Search by title, location, or keyword',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: _OpportunityPalette.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                'ACTIVE FILTERS',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  letterSpacing: 0.9,
                                  fontWeight: FontWeight.w700,
                                  color: _OpportunityPalette.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CounterBadge(count: _activeFilterCount),
                              const Spacer(),
                              TextButton(
                                onPressed: _hasActiveFilters
                                    ? _clearFilters
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear all',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _hasActiveFilters
                                        ? _OpportunityPalette.textSecondary
                                        : _OpportunityPalette.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _SegmentGroup(
                                  selectedFilter: _selectedFilter,
                                  onSelected: (filter) {
                                    setState(() => _selectedFilter = filter);
                                  },
                                ),
                                const SizedBox(width: 10),
                                _SortButton(
                                  selected: _sortByApplicants,
                                  onTap: () {
                                    setState(() {
                                      _sortByApplicants = !_sortByApplicants;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
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
                          if ((provider.opportunitiesError ?? '')
                              .trim()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _InlineBanner(
                                icon: Icons.info_outline_rounded,
                                title: 'Could not refresh opportunities',
                                message: provider.opportunitiesError!,
                                tone: _OpportunityPalette.error,
                                background: const Color(0xFFFFF1F2),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Showing ${opportunities.length} / ${provider.opportunities.length} opportunities',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: _OpportunityPalette.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _ViewToggle(
                                isCompact: _isCompactListView,
                                onChanged: (compact) {
                                  setState(() => _isCompactListView = compact);
                                },
                              ),
                            ],
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
                        hasExistingOpportunities:
                            provider.opportunities.isNotEmpty,
                        onCreate: _openPublish,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final opportunity = opportunities[index];
                          final applicantCount =
                              applicationCounts[opportunity.id] ?? 0;
                          final metadata =
                              OpportunityMetadata.buildMetadataItems(
                                type: opportunity.type,
                                salaryMin: opportunity.salaryMin,
                                salaryMax: opportunity.salaryMax,
                                salaryCurrency: opportunity.salaryCurrency,
                                salaryPeriod: opportunity.salaryPeriod,
                                compensationText: opportunity.compensationText,
                                isPaid: opportunity.isPaid,
                                employmentType: opportunity.employmentType,
                                workMode: opportunity.workMode,
                                duration: opportunity.duration,
                                maxItems: 2,
                              );
                          void handleTap() {
                            _showOpportunityDetails(
                              opportunity,
                              applicantCount,
                            );
                          }

                          if (_isCompactListView) {
                            return _OpportunityListTile(
                              opportunity: opportunity,
                              applicantCount: applicantCount,
                              tone: _toneForType(opportunity.type),
                              statusTone: _toneForStatus(opportunity.status),
                              timeLeftLabel: _timeLeftLabel(opportunity),
                              postedLabel: _postedLabel(opportunity),
                              metadata: metadata,
                              statusLabel: _statusLabel(opportunity.status),
                              onTap: handleTap,
                            );
                          }

                          return _OpportunityCard(
                            opportunity: opportunity,
                            applicantCount: applicantCount,
                            tone: _toneForType(opportunity.type),
                            statusTone: _toneForStatus(opportunity.status),
                            timeLeftLabel: _timeLeftLabel(opportunity),
                            postedLabel: _postedLabel(opportunity),
                            metadata: metadata,
                            statusLabel: _statusLabel(opportunity.status),
                            onTap: handleTap,
                          );
                        }, childCount: opportunities.length),
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
}

class _OpportunityPalette {
  static const Color primary = CompanyDashboardPalette.primary;
  static const Color primarySoft = CompanyDashboardPalette.primarySoft;
  static const Color accent = Color(0xFFE9B05A);
  static const Color accentSoft = Color(0xFFFFF8EE);
  static const Color surface = CompanyDashboardPalette.surface;
  static const Color border = CompanyDashboardPalette.border;
  static const Color textPrimary = CompanyDashboardPalette.textPrimary;
  static const Color textSecondary = CompanyDashboardPalette.textSecondary;
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color success = CompanyDashboardPalette.success;
  static const Color warning = CompanyDashboardPalette.warning;
  static const Color error = CompanyDashboardPalette.error;
}

class _OpportunityTone {
  final Color background;
  final Color foreground;

  const _OpportunityTone({required this.background, required this.foreground});
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _OpportunityPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _OpportunityPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: _OpportunityPalette.textPrimary, size: 20),
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
            top: 4,
            right: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _OpportunityPalette.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
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

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: count == 0
            ? const Color(0xFFF1F5F9)
            : _OpportunityPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: count == 0
              ? _OpportunityPalette.textSecondary
              : _OpportunityPalette.primary,
        ),
      ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentButton(
            label: 'All',
            selected: selectedFilter == _OpportunityFilter.all,
            onTap: () => onSelected(_OpportunityFilter.all),
          ),
          _SegmentButton(
            label: 'Open',
            selected: selectedFilter == _OpportunityFilter.open,
            onTap: () => onSelected(_OpportunityFilter.open),
          ),
          _SegmentButton(
            label: 'Closed',
            selected: selectedFilter == _OpportunityFilter.closed,
            onTap: () => onSelected(_OpportunityFilter.closed),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _OpportunityPalette.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected
                ? _OpportunityPalette.primary
                : _OpportunityPalette.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _OpportunityPalette.primarySoft
              : _OpportunityPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _OpportunityPalette.primary.withValues(alpha: 0.16)
                : _OpportunityPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: selected
                  ? _OpportunityPalette.primary
                  : _OpportunityPalette.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Most Applicants',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
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
          label: 'All types',
          selected: selectedFilter == _OpportunityTypeFilter.all,
          foreground: _OpportunityPalette.primary,
          background: _OpportunityPalette.primarySoft,
          onTap: () => onSelected(_OpportunityTypeFilter.all),
        ),
        const SizedBox(width: 8),
        _TypeFilterChip(
          label: 'Jobs',
          selected: selectedFilter == _OpportunityTypeFilter.jobs,
          foreground: OpportunityType.jobColor,
          background: _OpportunityPalette.primarySoft,
          onTap: () => onSelected(_OpportunityTypeFilter.jobs),
        ),
        const SizedBox(width: 8),
        _TypeFilterChip(
          label: 'Internships',
          selected: selectedFilter == _OpportunityTypeFilter.internships,
          foreground: OpportunityType.internshipColor,
          background: const Color(0xFFEAF3FF),
          onTap: () => onSelected(_OpportunityTypeFilter.internships),
        ),
        const SizedBox(width: 8),
        _TypeFilterChip(
          label: 'Sponsored',
          selected: selectedFilter == _OpportunityTypeFilter.sponsored,
          foreground: _OpportunityPalette.accent,
          background: _OpportunityPalette.accentSoft,
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
  final Color background;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? background : _OpportunityPalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? foreground.withValues(alpha: 0.18)
                : _OpportunityPalette.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: foreground.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? foreground : _OpportunityPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isCompact;
  final ValueChanged<bool> onChanged;

  const _ViewToggle({required this.isCompact, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _OpportunityPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.dashboard_customize_outlined,
            selected: !isCompact,
            onTap: () => onChanged(false),
          ),
          _ViewToggleButton(
            icon: Icons.view_list_rounded,
            selected: isCompact,
            onTap: () => onChanged(true),
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? _OpportunityPalette.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? _OpportunityPalette.primary
              : _OpportunityPalette.textSecondary,
        ),
      ),
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
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: tone),
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
                    color: _OpportunityPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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

class _OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final int applicantCount;
  final _OpportunityTone tone;
  final _OpportunityTone statusTone;
  final String timeLeftLabel;
  final String postedLabel;
  final List<String> metadata;
  final String statusLabel;
  final VoidCallback onTap;

  const _OpportunityCard({
    required this.opportunity,
    required this.applicantCount,
    required this.tone,
    required this.statusTone,
    required this.timeLeftLabel,
    required this.postedLabel,
    required this.metadata,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    tone.background.withValues(alpha: 0.78),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.64, 1],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: tone.foreground.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: tone.foreground.withValues(alpha: 0.07),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -34,
                    right: -24,
                    child: _CardAura(
                      size: 116,
                      color: tone.foreground.withValues(alpha: 0.07),
                    ),
                  ),
                  Positioned(
                    bottom: -44,
                    left: -28,
                    child: _CardAura(
                      size: 108,
                      color: tone.background.withValues(alpha: 0.92),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: tone.foreground.withValues(alpha: 0.18),
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
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: tone.background,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    OpportunityType.icon(opportunity.type),
                                    color: tone.foreground,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _MiniPill(
                                            label: OpportunityType.label(
                                              opportunity.type,
                                            ),
                                            background: tone.background,
                                            foreground: tone.foreground,
                                          ),
                                          _MiniPill(
                                            label: statusLabel,
                                            background: statusTone.background,
                                            foreground: statusTone.foreground,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        opportunity.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              _OpportunityPalette.textPrimary,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place_rounded,
                                            size: 16,
                                            color:
                                                _OpportunityPalette.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              opportunity.location
                                                      .trim()
                                                      .isEmpty
                                                  ? 'Location pending'
                                                  : opportunity.location.trim(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: _OpportunityPalette
                                                    .textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tone.foreground.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _OpportunityPalette.primary,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            if (metadata.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: metadata
                                    .map((item) => _MetaChip(label: item))
                                    .toList(growable: false),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: _OpportunityPalette.border.withValues(
                                alpha: 0.75,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatBlock(
                                    label: 'Applicants',
                                    value: '$applicantCount',
                                    icon: Icons.groups_rounded,
                                    tone: const _OpportunityTone(
                                      background:
                                          _OpportunityPalette.primarySoft,
                                      foreground: _OpportunityPalette.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatBlock(
                                    label: 'Timeline',
                                    value: timeLeftLabel,
                                    icon: Icons.schedule_rounded,
                                    tone: const _OpportunityTone(
                                      background:
                                          _OpportunityPalette.accentSoft,
                                      foreground: _OpportunityPalette.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatBlock(
                                    label: 'Updated',
                                    value: postedLabel,
                                    icon: Icons.update_rounded,
                                    tone: const _OpportunityTone(
                                      background: Color(0xFFF1F5F9),
                                      foreground:
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityListTile extends StatelessWidget {
  final OpportunityModel opportunity;
  final int applicantCount;
  final _OpportunityTone tone;
  final _OpportunityTone statusTone;
  final String timeLeftLabel;
  final String postedLabel;
  final List<String> metadata;
  final String statusLabel;
  final VoidCallback onTap;

  const _OpportunityListTile({
    required this.opportunity,
    required this.applicantCount,
    required this.tone,
    required this.statusTone,
    required this.timeLeftLabel,
    required this.postedLabel,
    required this.metadata,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    tone.background.withValues(alpha: 0.74),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.66, 1],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: tone.foreground.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: tone.foreground.withValues(alpha: 0.06),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -28,
                    right: -20,
                    child: _CardAura(
                      size: 92,
                      color: tone.foreground.withValues(alpha: 0.06),
                    ),
                  ),
                  Positioned(
                    bottom: -34,
                    left: -20,
                    child: _CardAura(
                      size: 84,
                      color: tone.background.withValues(alpha: 0.90),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 5,
                        color: tone.foreground.withValues(alpha: 0.16),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: tone.background,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    OpportunityType.icon(opportunity.type),
                                    color: tone.foreground,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _MiniPill(
                                            label: OpportunityType.label(
                                              opportunity.type,
                                            ),
                                            background: tone.background,
                                            foreground: tone.foreground,
                                          ),
                                          _MiniPill(
                                            label: statusLabel,
                                            background: statusTone.background,
                                            foreground: statusTone.foreground,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        opportunity.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              _OpportunityPalette.textPrimary,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place_rounded,
                                            size: 15,
                                            color:
                                                _OpportunityPalette.textMuted,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              opportunity.location
                                                      .trim()
                                                      .isEmpty
                                                  ? 'Location pending'
                                                  : opportunity.location.trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.5,
                                                color: _OpportunityPalette
                                                    .textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tone.foreground.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _OpportunityPalette.primary,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            if (metadata.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: metadata
                                      .map((item) => _MetaChip(label: item))
                                      .toList(growable: false),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _CompactInfoRow(
                                    icon: Icons.groups_rounded,
                                    tone: const _OpportunityTone(
                                      background:
                                          _OpportunityPalette.primarySoft,
                                      foreground: _OpportunityPalette.primary,
                                    ),
                                    label: 'Applicants',
                                    value: '$applicantCount',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _CompactInfoRow(
                                    icon: Icons.schedule_rounded,
                                    tone: const _OpportunityTone(
                                      background:
                                          _OpportunityPalette.accentSoft,
                                      foreground: _OpportunityPalette.accent,
                                    ),
                                    label: 'Timeline',
                                    value: timeLeftLabel,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _CompactInfoRow(
                                    icon: Icons.update_rounded,
                                    tone: const _OpportunityTone(
                                      background: Color(0xFFF1F5F9),
                                      foreground:
                                          _OpportunityPalette.textSecondary,
                                    ),
                                    label: 'Updated',
                                    value: postedLabel,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardAura extends StatelessWidget {
  final double size;
  final Color color;

  const _CardAura({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniPill({
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
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _MetaChip({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: _OpportunityPalette.textMuted),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _OpportunityPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final _OpportunityTone tone;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: tone.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: _OpportunityPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: _OpportunityPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final _OpportunityTone tone;
  final String label;
  final String value;

  const _CompactInfoRow({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: tone.foreground),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: _OpportunityPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _OpportunityPalette.textPrimary,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _OpportunityPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _OpportunityPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _OpportunityPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
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
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _OpportunityPalette.textMuted,
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
                    fontWeight: FontWeight.w600,
                    color: _OpportunityPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: _OpportunityPalette.border.withValues(alpha: 0.9),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: foreground.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _OpportunityPalette.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: _OpportunityPalette.primary,
                strokeWidth: 2.6,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading your opportunities...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _OpportunityPalette.textPrimary,
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

  const _EmptyState({
    required this.hasExistingOpportunities,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _OpportunityPalette.surface,
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _OpportunityPalette.primarySoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 30,
                  color: _OpportunityPalette.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasExistingOpportunities
                    ? 'No opportunities match this view'
                    : 'No opportunities published yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _OpportunityPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasExistingOpportunities
                    ? 'Try clearing the filters or broadening your search to see more listings.'
                    : 'Create your first role to start building your hiring pipeline.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.55,
                  color: _OpportunityPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  hasExistingOpportunities
                      ? 'Add another opportunity'
                      : 'Create opportunity',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _OpportunityPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
