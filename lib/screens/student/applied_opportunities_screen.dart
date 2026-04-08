import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/student_application_item_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/application_status.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../../widgets/student_opportunity_hub_widgets.dart';
import 'opportunities_screen.dart';
import 'opportunity_detail_screen.dart';

class AppliedOpportunitiesScreen extends StatefulWidget {
  const AppliedOpportunitiesScreen({super.key});

  @override
  State<AppliedOpportunitiesScreen> createState() =>
      _AppliedOpportunitiesScreenState();
}

enum _ApplicationFilter { all, pending, approved, rejected }

class _AppliedOpportunitiesScreenState
    extends State<AppliedOpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  _ApplicationFilter _selectedFilter = _ApplicationFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApplications());
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

  Future<void> _loadApplications() async {
    if (!mounted) {
      return;
    }

    final studentId = context.read<AuthProvider>().userModel?.uid.trim();
    if (studentId == null || studentId.isEmpty) {
      return;
    }

    await context.read<ApplicationProvider>().fetchSubmittedApplications(
      studentId,
    );
  }

  List<StudentApplicationItemModel> _filteredItems(
    ApplicationProvider provider,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    final items = provider.submittedApplications
        .where((item) {
          if (!_matchesFilter(item)) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final searchText = <String>[
            item.title,
            item.companyName,
            item.location,
            OpportunityType.label(item.type),
            ApplicationStatus.label(item.status),
          ].join(' ').toLowerCase();

          return searchText.contains(query);
        })
        .toList(growable: false);

    items.sort((first, second) {
      final firstTime = first.appliedAt?.millisecondsSinceEpoch ?? 0;
      final secondTime = second.appliedAt?.millisecondsSinceEpoch ?? 0;
      return secondTime.compareTo(firstTime);
    });

    return items;
  }

  bool _matchesFilter(StudentApplicationItemModel item) {
    final status = ApplicationStatus.parse(item.status);

    return switch (_selectedFilter) {
      _ApplicationFilter.all => true,
      _ApplicationFilter.pending => status == ApplicationStatus.pending,
      _ApplicationFilter.approved => status == ApplicationStatus.accepted,
      _ApplicationFilter.rejected => status == ApplicationStatus.rejected,
    };
  }

  int _countFor(ApplicationProvider provider, _ApplicationFilter filter) {
    return provider.submittedApplications.where((item) {
      final status = ApplicationStatus.parse(item.status);
      return switch (filter) {
        _ApplicationFilter.all => true,
        _ApplicationFilter.pending => status == ApplicationStatus.pending,
        _ApplicationFilter.approved => status == ApplicationStatus.accepted,
        _ApplicationFilter.rejected => status == ApplicationStatus.rejected,
      };
    }).length;
  }

  String _filterLabel(_ApplicationFilter filter) {
    return switch (filter) {
      _ApplicationFilter.all => 'All',
      _ApplicationFilter.pending => 'Pending',
      _ApplicationFilter.approved => 'Approved',
      _ApplicationFilter.rejected => 'Rejected',
    };
  }

  Color _filterColor(_ApplicationFilter filter) {
    return switch (filter) {
      _ApplicationFilter.all => StudentOpportunityHubPalette.primary,
      _ApplicationFilter.pending => StudentOpportunityHubPalette.warning,
      _ApplicationFilter.approved => StudentOpportunityHubPalette.success,
      _ApplicationFilter.rejected => StudentOpportunityHubPalette.error,
    };
  }

  Future<void> _openOpportunity(StudentApplicationItemModel item) async {
    final opportunity = item.opportunity;
    if (opportunity == null || item.isUnavailable) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This opportunity is no longer available to open.'),
        ),
      );
      return;
    }

    await OpportunityDetailScreen.show(context, opportunity);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final items = _filteredItems(provider);
    final totalCount = provider.submittedApplications.length;
    final pendingCount = _countFor(provider, _ApplicationFilter.pending);
    final approvedCount = _countFor(provider, _ApplicationFilter.approved);
    final rejectedCount = _countFor(provider, _ApplicationFilter.rejected);
    final hasFilters =
        _selectedFilter != _ApplicationFilter.all || _searchQuery.isNotEmpty;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudentWorkspaceAppBar(
          title: 'Applied Opportunities',
          subtitle: 'Your submitted roles in one clean, compact timeline.',
          icon: Icons.assignment_turned_in_rounded,
          showBackButton: true,
          onBack: () => Navigator.maybePop(context),
          actions: [
            StudentWorkspaceActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh',
              onTap: _loadApplications,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: StudentOpportunityHubPalette.primary,
            onRefresh: _loadApplications,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AppliedCompactSummary(
                          total: totalCount,
                          pending: pendingCount,
                          approved: approvedCount,
                          rejected: rejectedCount,
                        ),
                        const SizedBox(height: 12),
                        if ((provider.submittedApplicationsError ?? '')
                            .trim()
                            .isNotEmpty)
                          _InlineBanner(
                            icon: Icons.info_outline_rounded,
                            title: 'Application data is unavailable right now.',
                            message: provider.submittedApplicationsError!,
                            tone: StudentOpportunityHubPalette.error,
                            background: const Color(0xFFFFF1F2),
                          ),
                        if ((provider.submittedApplicationsError ?? '')
                            .trim()
                            .isNotEmpty)
                          const SizedBox(height: 12),
                        StudentOpportunitySearchField(
                          controller: _searchController,
                          hintText:
                              'Search by role, company, location, or status',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _ApplicationFilter.values
                                .map(
                                  (filter) => Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          filter ==
                                              _ApplicationFilter.values.last
                                          ? 0
                                          : 8,
                                    ),
                                    child: StudentOpportunityFilterChip(
                                      label:
                                          '${_filterLabel(filter)} (${_countFor(provider, filter)})',
                                      selected: filter == _selectedFilter,
                                      color: _filterColor(filter),
                                      onTap: () {
                                        if (_selectedFilter == filter) {
                                          return;
                                        }
                                        setState(
                                          () => _selectedFilter = filter,
                                        );
                                      },
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          hasFilters
                              ? '${items.length} applications shown'
                              : totalCount == 1
                              ? '1 applied opportunity'
                              : '$totalCount applied opportunities',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: StudentOpportunityHubPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.submittedApplicationsLoading &&
                    provider.submittedApplications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: StudentOpportunityLoadingState(
                      title: 'Loading applied opportunities...',
                      message:
                          'Pulling together your submitted opportunities and their latest statuses.',
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: StudentOpportunityEmptyState(
                      icon: hasFilters
                          ? Icons.filter_alt_off_rounded
                          : Icons.assignment_outlined,
                      title: hasFilters
                          ? 'No applications match this view'
                          : 'You have not applied yet',
                      message: hasFilters
                          ? 'Try a different search or filter to bring more of your application history back into view.'
                          : 'Once you start applying, your submitted opportunities will show up here.',
                      actionLabel: 'Browse opportunities',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OpportunitiesScreen(),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == items.length - 1 ? 0 : 8,
                          ),
                          child: _AppliedHistoryCard(
                            item: item,
                            onOpen: item.canOpenDetails
                                ? () => _openOpportunity(item)
                                : null,
                          ),
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
}

class _AppliedCompactSummary extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _AppliedCompactSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: StudentOpportunityHubPalette.border.withValues(alpha: 0.95),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: StudentOpportunityHubPalette.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: StudentOpportunityHubPalette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applied history',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StudentOpportunityHubPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Everything you submitted, in one simple list.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: StudentOpportunityHubPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final tileWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _AppliedMiniStat(
                      label: 'Total',
                      value: '$total',
                      color: StudentOpportunityHubPalette.primary,
                      icon: Icons.layers_rounded,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _AppliedMiniStat(
                      label: 'Pending',
                      value: '$pending',
                      color: StudentOpportunityHubPalette.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _AppliedMiniStat(
                      label: 'Approved',
                      value: '$approved',
                      color: StudentOpportunityHubPalette.success,
                      icon: Icons.verified_rounded,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _AppliedMiniStat(
                      label: 'Rejected',
                      value: '$rejected',
                      color: StudentOpportunityHubPalette.error,
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AppliedMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _AppliedMiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: StudentOpportunityHubPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: StudentOpportunityHubPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedHistoryCard extends StatelessWidget {
  final StudentApplicationItemModel item;
  final VoidCallback? onOpen;

  const _AppliedHistoryCard({required this.item, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final accent = item.hasOpportunity
        ? OpportunityType.color(item.type)
        : StudentOpportunityHubPalette.textMuted;
    final deadline = item.deadline;
    final statusTone = ApplicationStatus.color(item.status);
    final summary = _summaryText(item);
    final leadingIcon = item.hasOpportunity
        ? OpportunityType.icon(item.type)
        : Icons.archive_outlined;
    final leadingTone = item.hasOpportunity
        ? accent
        : StudentOpportunityHubPalette.textMuted;
    final locationLabel = _compactLocationLabel(item.location);

    return _AppliedCardFrame(
      accent: accent,
      highlight: statusTone,
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: leadingTone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(leadingIcon, color: leadingTone, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _AppliedCardText.title,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AppliedLabelChip(
                      label: ApplicationStatus.label(item.status),
                      tone: statusTone,
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.companyName,
                        style: _AppliedCardText.subtitle,
                      ),
                      TextSpan(
                        text: '  •  ',
                        style: GoogleFonts.poppins(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                          color: StudentOpportunityHubPalette.textMuted,
                        ),
                      ),
                      TextSpan(
                        text: item.hasOpportunity
                            ? OpportunityType.label(item.type)
                            : 'Archived',
                        style: GoogleFonts.poppins(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.1,
                      fontWeight: FontWeight.w600,
                      color: statusTone,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _AppliedMetaChip(
                      icon: Icons.schedule_rounded,
                      label: _relativeAppliedLabel(item.appliedAt),
                    ),
                    _AppliedMetaChip(
                      icon: _deadlineIcon(deadline),
                      label: _deadlineLabel(deadline),
                      tone: _deadlineTone(deadline),
                    ),
                    if (locationLabel != null)
                      _AppliedMetaChip(
                        icon: Icons.location_on_outlined,
                        label: locationLabel,
                      ),
                    _AppliedMetaChip(
                      icon: _availabilityIcon(item),
                      label: _availabilityLabel(item),
                      tone: _availabilityTone(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (onOpen == null ? leadingTone : accent).withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              onOpen == null
                  ? Icons.block_rounded
                  : Icons.chevron_right_rounded,
              color: onOpen == null ? leadingTone : accent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedCardFrame extends StatelessWidget {
  final Color accent;
  final Color highlight;
  final Widget child;
  final VoidCallback? onTap;

  const _AppliedCardFrame({
    required this.accent,
    required this.highlight,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, highlight],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppliedLabelChip extends StatelessWidget {
  final String label;
  final Color tone;
  final bool filled;

  const _AppliedLabelChip({
    required this.label,
    this.tone = StudentOpportunityHubPalette.textMuted,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? tone.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled
              ? tone.withValues(alpha: 0.18)
              : StudentOpportunityHubPalette.border.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.4,
              fontWeight: FontWeight.w600,
              color: filled ? tone : StudentOpportunityHubPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tone;

  const _AppliedMetaChip({required this.icon, required this.label, this.tone});

  @override
  Widget build(BuildContext context) {
    final resolvedTone = tone ?? StudentOpportunityHubPalette.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tone == null
            ? Colors.white.withValues(alpha: 0.86)
            : resolvedTone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tone == null
              ? StudentOpportunityHubPalette.border.withValues(alpha: 0.90)
              : resolvedTone.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: resolvedTone),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.6,
              fontWeight: FontWeight.w600,
              color: tone == null
                  ? StudentOpportunityHubPalette.textSecondary
                  : resolvedTone,
            ),
          ),
        ],
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
                    color: StudentOpportunityHubPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.5,
                    color: StudentOpportunityHubPalette.textSecondary,
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

abstract final class _AppliedCardText {
  static final TextStyle title = GoogleFonts.poppins(
    fontSize: 14.6,
    height: 1.18,
    fontWeight: FontWeight.w700,
    color: StudentOpportunityHubPalette.textPrimary,
  );

  static final TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 11.4,
    fontWeight: FontWeight.w600,
    color: StudentOpportunityHubPalette.textSecondary,
  );
}

String _summaryText(StudentApplicationItemModel item) {
  final normalized = item.description.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isNotEmpty) {
    if (normalized.length <= 88) {
      return normalized;
    }
    return '${normalized.substring(0, 85).trimRight()}...';
  }

  return switch (ApplicationStatus.parse(item.status)) {
    ApplicationStatus.accepted => 'Moved forward. Watch for next steps.',
    ApplicationStatus.rejected => 'Not selected, but kept in your history.',
    ApplicationStatus.pending => 'Awaiting a decision from the company.',
    _ => 'Awaiting a decision from the company.',
  };
}

String _relativeAppliedLabel(DateTime? value) {
  if (value == null) {
    return 'Date unavailable';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final difference = today.difference(target).inDays;

  if (difference <= 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  if (difference < 7) {
    return '${difference}d ago';
  }
  if (difference < 30) {
    final weeks = (difference / 7).ceil();
    return '${weeks}w ago';
  }

  return DateFormat('MMM d').format(value);
}

IconData _deadlineIcon(DateTime? deadline) {
  if (deadline == null) {
    return Icons.event_busy_outlined;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(deadline.year, deadline.month, deadline.day);
  return target.difference(today).inDays < 0
      ? Icons.event_busy_outlined
      : Icons.flag_outlined;
}

String _deadlineLabel(DateTime? deadline) {
  if (deadline == null) {
    return 'No deadline';
  }

  return DateFormat('MMM d').format(deadline);
}

Color? _deadlineTone(DateTime? deadline) {
  if (deadline == null) {
    return null;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(deadline.year, deadline.month, deadline.day);
  final difference = target.difference(today).inDays;

  if (difference < 0) {
    return StudentOpportunityHubPalette.error;
  }
  if (difference <= 5) {
    return StudentOpportunityHubPalette.accent;
  }
  return StudentOpportunityHubPalette.secondary;
}

String _availabilityLabel(StudentApplicationItemModel item) {
  if (item.isUnavailable) {
    return 'Archived';
  }
  if (item.isOpen) {
    return 'Open';
  }
  return 'Closed';
}

String? _compactLocationLabel(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty || normalized == 'Location not specified') {
    return null;
  }
  if (normalized.length <= 20) {
    return normalized;
  }
  return '${normalized.substring(0, 17).trimRight()}...';
}

IconData _availabilityIcon(StudentApplicationItemModel item) {
  if (item.isUnavailable) {
    return Icons.visibility_off_outlined;
  }
  if (item.isOpen) {
    return Icons.public_rounded;
  }
  return Icons.lock_outline_rounded;
}

Color _availabilityTone(StudentApplicationItemModel item) {
  if (item.isUnavailable) {
    return StudentOpportunityHubPalette.textMuted;
  }
  if (item.isOpen) {
    return StudentOpportunityHubPalette.secondary;
  }
  return StudentOpportunityHubPalette.accent;
}
