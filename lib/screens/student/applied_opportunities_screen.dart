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
import '../../widgets/application_status_badge.dart';
import '../../widgets/opportunity_type_badge.dart';
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

    return provider.submittedApplications
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpportunityDetailScreen(opportunity: opportunity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final items = _filteredItems(provider);
    final totalCount = provider.submittedApplications.length;
    final hasFilters =
        _selectedFilter != _ApplicationFilter.all || _searchQuery.isNotEmpty;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Applied Opportunities',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: StudentOpportunityHubPalette.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(
            color: StudentOpportunityHubPalette.textPrimary,
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh_rounded),
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
                        StudentOpportunityHubHero(
                          icon: Icons.assignment_turned_in_outlined,
                          eyebrow: 'STUDENT APPLICATIONS',
                          title: 'Track every move you made.',
                          subtitle:
                              'See what is still pending, what got approved, and which opportunities are worth revisiting next.',
                          stats: [
                            StudentOpportunityHeroStat(
                              label: 'Total',
                              value: '$totalCount',
                              icon: Icons.layers_outlined,
                              color: Colors.white,
                            ),
                            StudentOpportunityHeroStat(
                              label: 'Pending',
                              value:
                                  '${_countFor(provider, _ApplicationFilter.pending)}',
                              icon: Icons.hourglass_top_rounded,
                              color: Colors.white,
                            ),
                            StudentOpportunityHeroStat(
                              label: 'Approved',
                              value:
                                  '${_countFor(provider, _ApplicationFilter.approved)}',
                              icon: Icons.verified_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                          const SizedBox(height: 14),
                        StudentOpportunitySearchField(
                          controller: _searchController,
                          hintText:
                              'Search by role, company, location, or status',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
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
                                          '${_filterLabel(filter)} ${_countFor(provider, filter)}',
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
                        const SizedBox(height: 18),
                        Text(
                          hasFilters
                              ? '${items.length} applications in this view'
                              : totalCount == 1
                              ? '1 application in your history'
                              : '$totalCount applications in your history',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
                      title: 'Loading your applications...',
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
                          ? 'Try clearing the search or switching filters to bring more of your application history back into view.'
                          : 'Once you start applying, this page will become your clean timeline for tracking every submitted opportunity.',
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == items.length - 1 ? 0 : 14,
                          ),
                          child: _AppliedOpportunityCard(
                            item: item,
                            onViewDetails: item.canOpenDetails
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

class _AppliedOpportunityCard extends StatelessWidget {
  final StudentApplicationItemModel item;
  final VoidCallback? onViewDetails;

  const _AppliedOpportunityCard({required this.item, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final accent = item.hasOpportunity
        ? OpportunityType.color(item.type)
        : StudentOpportunityHubPalette.textMuted;
    final description = _summarizeDescription(item.description);
    final deadline = item.deadline;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: item.hasOpportunity
                    ? OpportunityTypeBadge(type: item.type)
                    : _UnavailableBadge(accent: accent),
              ),
              const SizedBox(width: 10),
              StudentOpportunityMetaPill(
                icon: Icons.schedule_rounded,
                label: _relativeAppliedLabel(item.appliedAt),
                tone: StudentOpportunityHubPalette.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: StudentOpportunityHubPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.companyName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentOpportunityHubPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ApplicationStatusBadge(status: item.status, fontSize: 10.5),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.55,
                color: StudentOpportunityHubPalette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudentOpportunityMetaPill(
                icon: Icons.location_on_outlined,
                label: item.location,
              ),
              StudentOpportunityMetaPill(
                icon: Icons.calendar_today_outlined,
                label: 'Applied ${_absoluteShortDate(item.appliedAt)}',
              ),
              StudentOpportunityMetaPill(
                icon: deadline == null
                    ? Icons.event_busy_outlined
                    : Icons.flag_outlined,
                label: deadline == null
                    ? 'Deadline unavailable'
                    : 'Closes ${DateFormat('MMM d').format(deadline)}',
                tone: _deadlineTone(deadline),
              ),
              StudentOpportunityMetaPill(
                icon: item.isOpen ? Icons.public_rounded : Icons.lock_outline,
                label: item.isUnavailable
                    ? 'No longer available'
                    : item.isOpen
                    ? 'Still open'
                    : 'Closed',
                tone: item.isUnavailable
                    ? StudentOpportunityHubPalette.textMuted
                    : item.isOpen
                    ? StudentOpportunityHubPalette.secondary
                    : StudentOpportunityHubPalette.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DecisionBanner(item: item),
          const SizedBox(height: 14),
          _AppliedActionButton(
            label: item.canOpenDetails
                ? 'View opportunity details'
                : 'Unavailable',
            icon: item.canOpenDetails
                ? Icons.north_east_rounded
                : Icons.block_rounded,
            background: item.canOpenDetails
                ? StudentOpportunityHubPalette.primary
                : StudentOpportunityHubPalette.surfaceAlt,
            foreground: item.canOpenDetails
                ? Colors.white
                : StudentOpportunityHubPalette.textMuted,
            onTap: onViewDetails,
          ),
        ],
      ),
    );
  }

  static String _summarizeDescription(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.length <= 140) {
      return normalized;
    }
    return '${normalized.substring(0, 137).trimRight()}...';
  }

  static String _relativeAppliedLabel(DateTime? value) {
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
      return '$difference days ago';
    }
    if (difference < 30) {
      final weeks = (difference / 7).ceil();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    return DateFormat('MMM d').format(value);
  }

  static String _absoluteShortDate(DateTime? value) {
    if (value == null) {
      return 'Unknown';
    }

    return DateFormat('MMM d').format(value);
  }

  static Color? _deadlineTone(DateTime? deadline) {
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
}

class _UnavailableBadge extends StatelessWidget {
  final Color accent;

  const _UnavailableBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Archived',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

class _DecisionBanner extends StatelessWidget {
  final StudentApplicationItemModel item;

  const _DecisionBanner({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = ApplicationStatus.parse(item.status);
    late final IconData icon;
    late final Color tone;
    late final Color background;
    late final String title;
    late final String message;

    switch (status) {
      case ApplicationStatus.accepted:
        icon = Icons.verified_rounded;
        tone = StudentOpportunityHubPalette.success;
        background = const Color(0xFFEFFCF4);
        title = 'Approved';
        message =
            'This application moved forward. Keep an eye on your messages for any next steps from the company.';
        break;
      case ApplicationStatus.rejected:
        icon = Icons.info_outline_rounded;
        tone = StudentOpportunityHubPalette.error;
        background = const Color(0xFFFFF1F2);
        title = 'Not selected';
        message =
            'This one did not move ahead, but your history stays here so you can learn from it and keep momentum.';
        break;
      case ApplicationStatus.pending:
      default:
        icon = Icons.hourglass_top_rounded;
        tone = StudentOpportunityHubPalette.warning;
        background = const Color(0xFFFFF7E8);
        title = 'Still under review';
        message =
            'The company has not made a final decision yet. You already did your part, so now it is a waiting game.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
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

class _AppliedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _AppliedActionButton({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  fontSize: 12.5,
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
