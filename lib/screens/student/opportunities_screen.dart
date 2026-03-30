import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/scholarship_provider.dart';
import '../../providers/training_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_dashboard_widgets.dart';
import 'opportunity_detail_screen.dart';
import 'scholarships_screen.dart';
import 'trainings_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  final String? initialFilter;

  const OpportunitiesScreen({super.key, this.initialFilter});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchSectionKey = GlobalKey();
  final GlobalKey _trendingSectionKey = GlobalKey();
  final GlobalKey _recentSectionKey = GlobalKey();

  late _OpportunityDashboardFilter _activeFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeFilter = _filterFromInitialValue(widget.initialFilter);
    _searchController.addListener(_handleSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextValue = _searchController.text.trim();
    if (_searchQuery == nextValue) {
      return;
    }

    setState(() {
      _searchQuery = nextValue;
    });
  }

  Future<void> _loadData({bool force = false}) async {
    final opportunityProvider = context.read<OpportunityProvider>();
    final trainingProvider = context.read<TrainingProvider>();
    final scholarshipProvider = context.read<ScholarshipProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[opportunityProvider.fetchOpportunities()];

    if (force || trainingProvider.trainings.isEmpty) {
      futures.add(trainingProvider.fetchTrainings());
    }

    if (force || scholarshipProvider.scholarships.isEmpty) {
      futures.add(scholarshipProvider.fetchScholarships());
    }

    if (userId != null && userId.isNotEmpty) {
      futures.add(savedProvider.fetchSavedOpportunities(userId));
    }

    await Future.wait(futures);
  }

  _OpportunityDashboardFilter _filterFromInitialValue(String? value) {
    switch (OpportunityType.parse(value)) {
      case OpportunityType.job:
        return _OpportunityDashboardFilter.job;
      case OpportunityType.internship:
        return _OpportunityDashboardFilter.internship;
      case OpportunityType.sponsoring:
        return _OpportunityDashboardFilter.sponsored;
      default:
        return _OpportunityDashboardFilter.all;
    }
  }

  List<OpportunityModel> _applyFilters(List<OpportunityModel> items) {
    final query = _searchQuery.toLowerCase();

    return items.where((opportunity) {
      if (!_matchesTypeFilter(opportunity)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchableFields = [
        opportunity.title,
        opportunity.companyName,
        opportunity.location,
        opportunity.description,
        opportunity.requirements,
        _typeLabel(opportunity.type),
      ];

      return searchableFields.any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();
  }

  bool _matchesTypeFilter(OpportunityModel opportunity) {
    final type = OpportunityType.parse(opportunity.type);

    switch (_activeFilter) {
      case _OpportunityDashboardFilter.all:
        return true;
      case _OpportunityDashboardFilter.jobsAndInternships:
        return type == OpportunityType.job ||
            type == OpportunityType.internship;
      case _OpportunityDashboardFilter.job:
        return type == OpportunityType.job;
      case _OpportunityDashboardFilter.internship:
        return type == OpportunityType.internship;
      case _OpportunityDashboardFilter.sponsored:
        return type == OpportunityType.sponsoring;
    }
  }

  Future<void> _focusSearchField() async {
    await _scrollToKey(_searchSectionKey);
    if (!mounted) {
      return;
    }
    _searchFocusNode.requestFocus();
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openOpportunity(OpportunityModel opportunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpportunityDetailScreen(opportunity: opportunity),
      ),
    );
  }

  void _openScholarships() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScholarshipsScreen()),
    );
  }

  void _openTrainings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingsScreen()),
    );
  }

  Future<void> _toggleSavedOpportunity(OpportunityModel opportunity) async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final userId = authProvider.userModel?.uid;

    if (userId == null || userId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save opportunities'),
        ),
      );
      return;
    }

    final matchingSaved = savedProvider.savedOpportunities
        .where((item) => item.opportunityId == opportunity.id)
        .toList();
    final existingSaved = matchingSaved.isNotEmpty ? matchingSaved.first : null;

    String? error;
    var message = 'Opportunity saved';

    if (existingSaved != null) {
      error = await savedProvider.unsaveOpportunity(existingSaved.id, userId);
      message = 'Removed from saved opportunities';
    } else {
      error = await savedProvider.saveOpportunity(
        studentId: userId,
        opportunityId: opportunity.id,
        title: opportunity.title,
        companyName: opportunity.companyName,
        type: opportunity.type,
        location: opportunity.location,
        deadline: opportunity.deadline,
      );
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(error ?? message)));
  }

  Future<void> _showFilterSheet() async {
    final selected = await showModalBottomSheet<_OpportunityDashboardFilter>(
      context: context,
      backgroundColor: OpportunityDashboardPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse categories',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep the existing data source, but tailor what you see.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: OpportunityDashboardPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _dashboardFilters.map((filter) {
                    final isSelected = filter.value == _activeFilter;

                    return ChoiceChip(
                      label: Text(filter.label),
                      avatar: Icon(filter.icon, size: 18),
                      selected: isSelected,
                      onSelected: (_) => Navigator.pop(context, filter.value),
                      selectedColor: OpportunityDashboardPalette.primary
                          .withValues(alpha: 0.14),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? OpportunityDashboardPalette.primary
                            : OpportunityDashboardPalette.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? OpportunityDashboardPalette.primary
                            : OpportunityDashboardPalette.border,
                      ),
                      backgroundColor: OpportunityDashboardPalette.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }).toList(),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Clear search'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _activeFilter = selected;
    });
  }

  void _setFilter(_OpportunityDashboardFilter filter) {
    if (_activeFilter == filter) {
      return;
    }

    setState(() {
      _activeFilter = filter;
    });
  }

  String _typeLabel(String type) {
    switch (OpportunityType.parse(type)) {
      case OpportunityType.internship:
        return 'Internships';
      case OpportunityType.sponsoring:
        return 'Sponsored';
      case OpportunityType.job:
      default:
        return 'Jobs';
    }
  }

  String _summaryText(int visibleCount, int totalCount) {
    final filterLabel = switch (_activeFilter) {
      _OpportunityDashboardFilter.all => 'opportunities',
      _OpportunityDashboardFilter.jobsAndInternships => 'jobs and internships',
      _OpportunityDashboardFilter.job => 'jobs',
      _OpportunityDashboardFilter.internship => 'internships',
      _OpportunityDashboardFilter.sponsored => 'sponsored opportunities',
    };

    if (_searchQuery.isEmpty &&
        _activeFilter == _OpportunityDashboardFilter.all) {
      return '$totalCount open opportunities curated for students.';
    }

    return 'Showing $visibleCount $filterLabel from $totalCount open listings.';
  }

  String _formatCount(int count, String singular, String plural) {
    if (count <= 0) {
      return plural;
    }

    return '$count ${count == 1 ? singular : plural}';
  }

  String _formatDeadlineDisplay(String rawDeadline) {
    final parsed = _parseDeadline(rawDeadline);
    if (parsed == null) {
      return rawDeadline.trim().isEmpty ? 'No deadline' : rawDeadline.trim();
    }

    return DateFormat('MMM d').format(parsed);
  }

  DateTime? _parseDeadline(String rawDeadline) {
    final trimmed = rawDeadline.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final hasExplicitTime = trimmed.contains(':') || trimmed.contains('T');
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) {
      return hasExplicitTime
          ? direct
          : DateTime(direct.year, direct.month, direct.day, 23, 59, 59);
    }

    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('MMM d, yyyy'),
      DateFormat('d MMM yyyy'),
      DateFormat('MMMM d, yyyy'),
      DateFormat('d MMMM yyyy'),
    ];

    for (final format in formats) {
      try {
        final parsed = format.parseStrict(trimmed);
        return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String _relativePostedTime(OpportunityModel opportunity) {
    final createdAt = opportunity.createdAt?.toDate();
    if (createdAt == null) {
      return 'Recently added';
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    if (difference.inDays < 30) {
      final weeks = math.max(1, (difference.inDays / 7).floor());
      return '${weeks}w ago';
    }

    return DateFormat('MMM d').format(createdAt);
  }

  bool _isNewOpportunity(OpportunityModel opportunity) {
    final createdAt = opportunity.createdAt?.toDate();
    if (createdAt == null) {
      return false;
    }

    return DateTime.now().difference(createdAt).inDays < 3;
  }

  String _closingSoonText(OpportunityModel opportunity) {
    final deadline = _parseDeadline(opportunity.deadline);
    if (deadline == null) {
      return 'Deadline unavailable';
    }

    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Closes today';
    }
    if (difference.inHours < 1) {
      final minutes = math.max(1, difference.inMinutes);
      return 'Closes in $minutes min';
    }
    if (difference.inHours < 24) {
      return 'Closes in ${difference.inHours} hours';
    }
    if (difference.inDays == 1) {
      return 'Closes tomorrow';
    }

    return 'Closes in ${difference.inDays} days';
  }

  Color _closingSoonColor(OpportunityModel opportunity) {
    final deadline = _parseDeadline(opportunity.deadline);
    if (deadline == null) {
      return OpportunityDashboardPalette.warning;
    }

    final difference = deadline.difference(DateTime.now());
    return difference.inHours <= 24
        ? OpportunityDashboardPalette.error
        : OpportunityDashboardPalette.warning;
  }

  String _deriveTrendingTag(OpportunityModel opportunity) {
    final text = [
      opportunity.title,
      opportunity.description,
      opportunity.requirements,
    ].join(' ').toLowerCase();

    if (text.contains('design') ||
        text.contains('ui') ||
        text.contains('ux') ||
        text.contains('graphic')) {
      return 'DESIGN';
    }
    if (text.contains('market') ||
        text.contains('business') ||
        text.contains('sales')) {
      return 'BUSINESS';
    }
    if (text.contains('research') ||
        text.contains('lab') ||
        text.contains('analysis')) {
      return 'RESEARCH';
    }
    if (text.contains('data') ||
        text.contains('software') ||
        text.contains('engineer') ||
        text.contains('developer') ||
        text.contains('tech')) {
      return 'TECH';
    }

    return switch (OpportunityType.parse(opportunity.type)) {
      OpportunityType.internship => 'INTERNSHIP',
      OpportunityType.sponsoring => 'SPONSORED',
      _ => 'JOB',
    };
  }

  List<OpportunityModel> _buildTrendingItems(List<OpportunityModel> visible) {
    final featured = visible.where((item) => item.isFeatured).toList();
    final items = <OpportunityModel>[...featured];

    for (final opportunity in visible) {
      if (items.any((item) => item.id == opportunity.id)) {
        continue;
      }
      items.add(opportunity);
      if (items.length >= 6) {
        break;
      }
    }

    return items.take(6).toList();
  }

  List<OpportunityModel> _buildClosingSoonItems(
    List<OpportunityModel> visible,
  ) {
    final items = visible.where((opportunity) {
      final deadline = _parseDeadline(opportunity.deadline);
      if (deadline == null) {
        return false;
      }

      final difference = deadline.difference(DateTime.now());
      return !difference.isNegative && difference.inDays <= 21;
    }).toList();

    items.sort((a, b) {
      final first = _parseDeadline(a.deadline);
      final second = _parseDeadline(b.deadline);
      if (first == null && second == null) {
        return 0;
      }
      if (first == null) {
        return 1;
      }
      if (second == null) {
        return -1;
      }

      return first.compareTo(second);
    });

    return items.take(5).toList();
  }

  Widget _buildHeaderSection(int visibleCount, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find your path.',
          style: GoogleFonts.poppins(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: OpportunityDashboardPalette.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Discover curated opportunities tailored for your academic and professional growth.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            height: 1.5,
            color: OpportunityDashboardPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        KeyedSubtree(
          key: _searchSectionKey,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search internships, jobs, or programs',
              hintStyle: GoogleFonts.poppins(
                color: OpportunityDashboardPalette.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: OpportunityDashboardPalette.textSecondary,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: OpportunityDashboardPalette.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: OpportunityDashboardPalette.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: OpportunityDashboardPalette.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dashboardFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final filter = _dashboardFilters[index];
              final isActive = filter.value == _activeFilter;

              return GestureDetector(
                onTap: () => _setFilter(filter.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? OpportunityDashboardPalette.primary.withValues(
                            alpha: 0.12,
                          )
                        : OpportunityDashboardPalette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? OpportunityDashboardPalette.primary
                          : OpportunityDashboardPalette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        size: 16,
                        color: isActive
                            ? OpportunityDashboardPalette.primary
                            : OpportunityDashboardPalette.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? OpportunityDashboardPalette.primary
                              : OpportunityDashboardPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _summaryText(visibleCount, totalCount),
            key: ValueKey(
              'summary-$visibleCount-$totalCount-$_activeFilter-$_searchQuery',
            ),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: OpportunityDashboardPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final opportunityProvider = context.watch<OpportunityProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final scholarshipProvider = context.watch<ScholarshipProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();

    final allOpportunities = opportunityProvider.opportunities;
    final visibleOpportunities = _applyFilters(allOpportunities);
    final jobsAndInternships = allOpportunities.where((opportunity) {
      final type = OpportunityType.parse(opportunity.type);
      return type == OpportunityType.job || type == OpportunityType.internship;
    }).toList();
    final sponsoredItems = allOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) ==
              OpportunityType.sponsoring,
        )
        .toList();
    final trainingItems = trainingProvider.trainings
        .where((training) => training.isApproved)
        .toList();
    final trendingItems = _buildTrendingItems(visibleOpportunities);
    final closingSoonItems = _buildClosingSoonItems(visibleOpportunities);
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();

    return Scaffold(
      backgroundColor: OpportunityDashboardPalette.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: OpportunityDashboardPalette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'AvenirDZ',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Focus search',
            onPressed: _focusSearchField,
            icon: const Icon(
              Icons.search_rounded,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          IconButton(
            tooltip: 'Filter opportunities',
            onPressed: _showFilterSheet,
            icon: const Icon(
              Icons.tune_rounded,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: opportunityProvider.isLoading && allOpportunities.isEmpty
          ? const OpportunityDashboardLoadingSkeleton()
          : RefreshIndicator(
              color: OpportunityDashboardPalette.primary,
              backgroundColor: OpportunityDashboardPalette.surface,
              onRefresh: () => _loadData(force: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  if (opportunityProvider.isLoading &&
                      allOpportunities.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeaderSection(
                        visibleOpportunities.length,
                        allOpportunities.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: OpportunityHeroCard(
                        title: 'Jobs & Internships',
                        subtitle:
                            'Explore career openings and student-first placements from trusted partners.',
                        supportingLabel: _formatCount(
                          jobsAndInternships.length,
                          'open position',
                          'open positions',
                        ),
                        icon: Icons.workspace_premium_outlined,
                        onTap: () async {
                          _setFilter(
                            _OpportunityDashboardFilter.jobsAndInternships,
                          );
                          await _scrollToKey(_trendingSectionKey);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 164,
                        child: Row(
                          children: [
                            Expanded(
                              child: OpportunityCategoryCard(
                                title: 'Scholarships',
                                subtitle: 'Funding & grants',
                                caption: scholarshipProvider.isLoading
                                    ? 'Loading...'
                                    : _formatCount(
                                        scholarshipProvider.scholarships.length,
                                        'live listing',
                                        'live listings',
                                      ),
                                icon: Icons.workspace_premium_outlined,
                                color: OpportunityDashboardPalette.secondary,
                                backgroundColor: OpportunityDashboardPalette
                                    .secondary
                                    .withValues(alpha: 0.10),
                                onTap: _openScholarships,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OpportunityCategoryCard(
                                title: 'Sponsored',
                                subtitle: 'Partner-backed support',
                                caption: _formatCount(
                                  sponsoredItems.length,
                                  'active track',
                                  'active tracks',
                                ),
                                icon: Icons.campaign_outlined,
                                color: OpportunityDashboardPalette.accent,
                                backgroundColor: OpportunityDashboardPalette
                                    .accent
                                    .withValues(alpha: 0.10),
                                onTap: () async {
                                  _setFilter(
                                    _OpportunityDashboardFilter.sponsored,
                                  );
                                  await _scrollToKey(_recentSectionKey);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: TrainingProgramsCard(
                        title: 'Training Programs',
                        subtitle: 'Certification & Bootcamps',
                        badgeLabel: trainingProvider.isLoading
                            ? 'Loading...'
                            : _formatCount(
                                trainingItems.length,
                                'resource',
                                'resources',
                              ),
                        onTap: _openTrainings,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    sliver: SliverToBoxAdapter(
                      key: _trendingSectionKey,
                      child: OpportunitySectionHeader(
                        title: 'Trending Opportunities',
                        subtitle: 'Based on student activity this week',
                        actionLabel: 'View All',
                        onAction: () async {
                          _setFilter(_OpportunityDashboardFilter.all);
                          await _scrollToKey(_recentSectionKey);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
                    sliver: SliverToBoxAdapter(
                      child: trendingItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: OpportunityDashboardEmptyState(
                                icon: Icons.trending_up_rounded,
                                title: 'No trending items right now',
                                subtitle:
                                    'Fresh recommendations will appear here as new listings arrive.',
                                color: OpportunityDashboardPalette.primary,
                              ),
                            )
                          : SizedBox(
                              height: 290,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(right: 20),
                                itemCount: trendingItems.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final opportunity = trendingItems[index];

                                  return TrendingOpportunityCard(
                                    opportunity: opportunity,
                                    badgeLabel: _deriveTrendingTag(opportunity),
                                    primaryMeta:
                                        '${opportunity.companyName.isEmpty ? 'AvenirDZ partner' : opportunity.companyName} | ${opportunity.location.isEmpty ? 'Remote friendly' : opportunity.location}',
                                    secondaryMeta: opportunity.deadline.isEmpty
                                        ? _relativePostedTime(opportunity)
                                        : 'Deadline ${_formatDeadlineDisplay(opportunity.deadline)}',
                                    isSaved: savedIds.contains(opportunity.id),
                                    isBusy: savedProvider.isLoading,
                                    onTap: () => _openOpportunity(opportunity),
                                    onToggleSaved: () =>
                                        _toggleSavedOpportunity(opportunity),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    sliver: SliverToBoxAdapter(
                      key: _recentSectionKey,
                      child: const OpportunitySectionHeader(
                        title: 'Recently Posted',
                        subtitle:
                            'Fresh listings curated for quick exploration',
                        accentColor: OpportunityDashboardPalette.success,
                      ),
                    ),
                  ),
                  if (visibleOpportunities.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: OpportunityDashboardEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No recent opportunities found',
                          subtitle:
                              'Try adjusting your search or filters to uncover more matches.',
                          color: OpportunityDashboardPalette.success,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      sliver: SliverList.separated(
                        itemCount: visibleOpportunities.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final opportunity = visibleOpportunities[index];
                          return OpportunityListTile(
                            compact: true,
                            opportunity: opportunity,
                            metaText: _relativePostedTime(opportunity),
                            supportingText: opportunity.location.isNotEmpty
                                ? opportunity.location
                                : _typeLabel(opportunity.type),
                            badgeText: _isNewOpportunity(opportunity)
                                ? 'NEW'
                                : null,
                            badgeColor: OpportunityDashboardPalette.success,
                            onTap: () => _openOpportunity(opportunity),
                          );
                        },
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: const OpportunitySectionHeader(
                        title: 'Closing Soon',
                        subtitle:
                            'Prioritize urgent applications before they expire',
                        accentColor: OpportunityDashboardPalette.error,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    sliver: closingSoonItems.isEmpty
                        ? SliverToBoxAdapter(
                            child: OpportunityDashboardEmptyState(
                              icon: Icons.hourglass_bottom_rounded,
                              title: 'No urgent deadlines yet',
                              subtitle:
                                  'Once a listing is nearing its deadline, it will show up here.',
                              color: OpportunityDashboardPalette.error,
                            ),
                          )
                        : SliverList.separated(
                            itemCount: closingSoonItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final opportunity = closingSoonItems[index];
                              final badgeColor = _closingSoonColor(opportunity);

                              return OpportunityListTile(
                                compact: true,
                                opportunity: opportunity,
                                metaText: _closingSoonText(opportunity),
                                supportingText: opportunity.deadline.isEmpty
                                    ? opportunity.location
                                    : 'Deadline ${_formatDeadlineDisplay(opportunity.deadline)}',
                                badgeText: 'URGENT',
                                badgeColor: badgeColor,
                                onTap: () => _openOpportunity(opportunity),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

enum _OpportunityDashboardFilter {
  all,
  jobsAndInternships,
  job,
  internship,
  sponsored,
}

class _DashboardFilterDefinition {
  final _OpportunityDashboardFilter value;
  final String label;
  final IconData icon;

  const _DashboardFilterDefinition({
    required this.value,
    required this.label,
    required this.icon,
  });
}

const List<_DashboardFilterDefinition> _dashboardFilters = [
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.all,
    label: 'All',
    icon: Icons.apps_rounded,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.jobsAndInternships,
    label: 'Jobs & Internships',
    icon: Icons.explore_outlined,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.job,
    label: 'Jobs',
    icon: Icons.work_outline_rounded,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.internship,
    label: 'Internships',
    icon: Icons.school_outlined,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.sponsored,
    label: 'Sponsored',
    icon: Icons.campaign_outlined,
  ),
];
