import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import 'opportunity_detail_screen.dart';

class SponsoredOpportunitiesScreen extends StatefulWidget {
  const SponsoredOpportunitiesScreen({super.key});

  @override
  State<SponsoredOpportunitiesScreen> createState() =>
      _SponsoredOpportunitiesScreenState();
}

enum _SponsoredFilter {
  all,
  funding,
  startup,
  competition,
  grants,
  internships,
}

class _SponsoredOpportunitiesScreenState
    extends State<SponsoredOpportunitiesScreen> {
  static const List<_SponsoredFilterDefinition> _filters = [
    _SponsoredFilterDefinition(value: _SponsoredFilter.all, label: 'All'),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.funding,
      label: 'Funding',
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.startup,
      label: 'Startup',
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.competition,
      label: 'Competition',
    ),
    _SponsoredFilterDefinition(value: _SponsoredFilter.grants, label: 'Grants'),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.internships,
      label: 'Internships',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _busyApplyIds = <String>{};

  String _searchQuery = '';
  _SponsoredFilter _activeFilter = _SponsoredFilter.all;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextValue = _searchController.text.trim();
    if (nextValue == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextValue;
    });
  }

  Future<void> _loadData({bool force = false}) async {
    final provider = context.read<OpportunityProvider>();
    if (force || provider.opportunities.isEmpty) {
      await provider.fetchOpportunities();
    }
  }

  void _openOpportunity(OpportunityModel opportunity) {
    OpportunityDetailScreen.show(context, opportunity);
  }

  Future<void> _applyNow(_SponsoredOpportunityCardModel item) async {
    final opportunity = item.opportunity;
    final messenger = ScaffoldMessenger.of(context);

    if (opportunity == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This sponsored opportunity preview has no live record yet',
          ),
        ),
      );
      return;
    }

    if (_busyApplyIds.contains(opportunity.id)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final cvProvider = context.read<CvProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be logged in to apply')),
      );
      return;
    }

    setState(() {
      _busyApplyIds.add(opportunity.id);
    });

    try {
      final eligibility = await applicationProvider.getEligibility(
        studentId: currentUser.uid,
        opportunityId: opportunity.id,
      );

      if (!mounted) {
        return;
      }

      if (eligibility != ApplicationEligibilityStatus.available) {
        messenger.showSnackBar(
          SnackBar(content: Text(_messageForEligibility(eligibility))),
        );
        return;
      }

      await cvProvider.loadCv(currentUser.uid);

      if (!mounted) {
        return;
      }

      final cv = cvProvider.cv;
      if (cv == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please create your CV before applying'),
          ),
        );
        return;
      }

      final error = await applicationProvider.applyToOpportunity(
        studentId: currentUser.uid,
        studentName: currentUser.fullName,
        opportunityId: opportunity.id,
        cvId: cv.id,
      );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(error ?? 'Application submitted successfully')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyApplyIds.remove(opportunity.id);
        });
      }
    }
  }

  String _messageForEligibility(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return 'You must be logged in to apply';
      case ApplicationEligibilityStatus.available:
        return 'You can apply to this opportunity';
      case ApplicationEligibilityStatus.alreadyApplied:
        return 'You have already applied to this opportunity';
      case ApplicationEligibilityStatus.closed:
        return 'This opportunity is closed';
      case ApplicationEligibilityStatus.unavailable:
        return 'This opportunity is no longer available';
    }
  }

  List<_SponsoredOpportunityCardModel> _buildCardModels(
    List<OpportunityModel> opportunities,
  ) {
    final liveSponsored = opportunities.where(_isLiveSponsored).toList();
    final inferredSponsored = opportunities.where(_looksSponsored).toList();

    final source = liveSponsored.isNotEmpty
        ? liveSponsored
        : inferredSponsored.isNotEmpty
        ? inferredSponsored
        : const <OpportunityModel>[];

    final cards = source.map(_mapOpportunityToCardModel).toList()
      ..sort(_sortSponsoredCards);

    if (cards.isNotEmpty) {
      return cards;
    }

    return _placeholderSponsoredCards;
  }

  bool _isLiveSponsored(OpportunityModel opportunity) {
    final type = OpportunityType.parse(opportunity.type);
    if (type != OpportunityType.sponsoring) {
      return false;
    }

    return _isOpenOpportunity(opportunity);
  }

  bool _looksSponsored(OpportunityModel opportunity) {
    if (!_isOpenOpportunity(opportunity)) {
      return false;
    }

    final normalized = _normalizedSearchText(opportunity);
    const keywords = [
      'sponsor',
      'sponsored',
      'funding',
      'funded',
      'grant',
      'grants',
      'stipend',
      'award',
      'reward',
      'accelerator',
      'incubator',
      'startup',
      'fellowship',
      'ambassador',
      'competition',
      'challenge',
      'hackathon',
      'summit',
      'innovation',
    ];

    return keywords.any(normalized.contains);
  }

  bool _isOpenOpportunity(OpportunityModel opportunity) {
    final normalized = opportunity.status.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'open';
  }

  int _sortSponsoredCards(
    _SponsoredOpportunityCardModel a,
    _SponsoredOpportunityCardModel b,
  ) {
    final scoreDiff = _priorityScore(b).compareTo(_priorityScore(a));
    if (scoreDiff != 0) {
      return scoreDiff;
    }

    final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
    final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
    return bCreated.compareTo(aCreated);
  }

  int _priorityScore(_SponsoredOpportunityCardModel item) {
    var score = 0;

    if (item.opportunity?.isFeatured == true) {
      score += 80;
    }
    if (item.badge.label == 'CLOSING SOON') {
      score += 48;
    }
    if (item.badge.label == 'FULLY FUNDED') {
      score += 36;
    }
    if (item.filters.contains(_SponsoredFilter.grants)) {
      score += 18;
    }
    if (item.filters.contains(_SponsoredFilter.funding)) {
      score += 14;
    }
    if (item.urgency != null &&
        item.urgency!.text.toLowerCase().contains('day')) {
      score += 10;
    }
    if (!item.isPlaceholder) {
      score += 12;
    }

    return score;
  }

  List<_SponsoredOpportunityCardModel> _applyFilters(
    List<_SponsoredOpportunityCardModel> items,
  ) {
    final query = _searchQuery.toLowerCase();

    return items.where((item) {
      final matchesQuery = query.isEmpty || item.searchText.contains(query);
      final matchesFilter =
          _activeFilter == _SponsoredFilter.all ||
          item.filters.contains(_activeFilter);

      return matchesQuery && matchesFilter;
    }).toList();
  }

  _SponsoredOpportunityCardModel _mapOpportunityToCardModel(
    OpportunityModel opportunity,
  ) {
    final title = opportunity.title.trim().isEmpty
        ? 'Sponsored Opportunity'
        : opportunity.title.trim();
    final description = _descriptionFor(opportunity);
    final filters = _filtersForOpportunity(opportunity);
    final theme = _themeFor(filters);
    final badge = _badgeForOpportunity(opportunity, filters);
    final urgency = _urgencyFor(opportunity);
    final primaryStat = _primaryStatFor(opportunity, filters);
    final secondaryStat = _secondaryStatFor(opportunity);
    final companyName = _companyName(opportunity);
    final searchText = [
      title,
      companyName,
      description,
      opportunity.location,
      opportunity.requirements,
      badge.label,
      urgency?.text ?? '',
      primaryStat?.label ?? '',
      primaryStat?.value ?? '',
      secondaryStat?.label ?? '',
      secondaryStat?.value ?? '',
      ...filters.map((filter) => filter.name),
    ].join(' ').toLowerCase();

    return _SponsoredOpportunityCardModel(
      id: opportunity.id,
      title: title,
      description: description,
      companyName: companyName,
      logoUrl: opportunity.companyLogo.trim(),
      iconData: theme.icon,
      iconBackgroundColor: theme.backgroundColor,
      iconForegroundColor: theme.foregroundColor,
      badge: badge,
      urgency: urgency,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
      filters: filters,
      opportunity: opportunity,
      searchText: searchText,
      isPlaceholder: false,
      createdAt: opportunity.createdAt?.toDate(),
    );
  }

  String _companyName(OpportunityModel opportunity) {
    final companyName = opportunity.companyName.trim();
    return companyName.isEmpty ? 'AvenirDZ Partner' : companyName;
  }

  String _descriptionFor(OpportunityModel opportunity) {
    final description = opportunity.description.trim();
    if (description.isNotEmpty) {
      return description;
    }

    final companyName = _companyName(opportunity);
    final filters = _filtersForOpportunity(opportunity);
    if (filters.contains(_SponsoredFilter.startup)) {
      return '$companyName is opening a partner-backed startup track for ambitious students ready to build and learn fast.';
    }
    if (filters.contains(_SponsoredFilter.competition)) {
      return '$companyName is inviting students to a sponsored challenge with mentorship, visibility, and hands-on exposure.';
    }
    if (filters.contains(_SponsoredFilter.grants) ||
        filters.contains(_SponsoredFilter.funding)) {
      return '$companyName is supporting student ideas through a sponsored program with funding and guided application support.';
    }

    return '$companyName is offering a sponsored opportunity designed to help students grow through real support and curated access.';
  }

  Set<_SponsoredFilter> _filtersForOpportunity(OpportunityModel opportunity) {
    final normalized = _normalizedSearchText(opportunity);
    final filters = <_SponsoredFilter>{};

    if (OpportunityType.parse(opportunity.type) == OpportunityType.internship ||
        normalized.contains('intern') ||
        normalized.contains('ambassador')) {
      filters.add(_SponsoredFilter.internships);
    }

    if (normalized.contains('startup') ||
        normalized.contains('accelerator') ||
        normalized.contains('incubator') ||
        normalized.contains('venture') ||
        normalized.contains('founder')) {
      filters.add(_SponsoredFilter.startup);
    }

    if (normalized.contains('competition') ||
        normalized.contains('challenge') ||
        normalized.contains('hackathon') ||
        normalized.contains('contest') ||
        normalized.contains('summit') ||
        normalized.contains('pitch')) {
      filters.add(_SponsoredFilter.competition);
    }

    if (normalized.contains('grant') ||
        normalized.contains('grants') ||
        normalized.contains('scholarship') ||
        normalized.contains('award')) {
      filters.add(_SponsoredFilter.grants);
    }

    if (normalized.contains('fund') ||
        normalized.contains('funding') ||
        normalized.contains('funded') ||
        normalized.contains('stipend') ||
        normalized.contains('reward') ||
        normalized.contains('budget') ||
        normalized.contains('support')) {
      filters.add(_SponsoredFilter.funding);
    }

    final compensation = _compensationText(opportunity);
    if (compensation != null) {
      filters.add(_SponsoredFilter.funding);
      if (_containsAny(compensation.toLowerCase(), const ['grant', 'award'])) {
        filters.add(_SponsoredFilter.grants);
      }
    }

    if (filters.isEmpty) {
      filters.add(_SponsoredFilter.funding);
    }

    return filters;
  }

  String _normalizedSearchText(OpportunityModel opportunity) {
    return [
      opportunity.title,
      opportunity.description,
      opportunity.requirements,
      opportunity.location,
      opportunity.companyName,
      opportunity.readString([
            'category',
            'track',
            'program',
            'programType',
            'initiative',
            'tags',
            'industry',
            'focus',
            'theme',
          ]) ??
          '',
      _compensationText(opportunity) ?? '',
      opportunity.duration ?? '',
    ].join(' ').toLowerCase();
  }

  String? _compensationText(OpportunityModel opportunity) {
    final structuredLabel = OpportunityMetadata.buildCompensationLabel(
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      isPaid: opportunity.isPaid,
      preferCompensationText: true,
    );
    if (structuredLabel != null) {
      return _compactValueText(structuredLabel);
    }

    final rawValue = OpportunityMetadata.extractCompensationText(
      opportunity.rawData,
    );
    if (rawValue == null) {
      return null;
    }

    return _compactValueText(rawValue);
  }

  String _compactValueText(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('USD', '\$')
        .replaceAll(' / month', ' / mo')
        .replaceAll(' / year', ' / yr')
        .replaceAll(' / week', ' / wk')
        .replaceAll(' / hour', ' / hr')
        .replaceAll(' per month', ' / mo')
        .replaceAll(' per year', ' / yr')
        .replaceAll(' per week', ' / wk')
        .replaceAll(' per hour', ' / hr');
  }

  _SponsoredBadgeData _badgeForOpportunity(
    OpportunityModel opportunity,
    Set<_SponsoredFilter> filters,
  ) {
    final normalized = _normalizedSearchText(opportunity);
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);

    if (daysUntilDeadline != null &&
        daysUntilDeadline >= 0 &&
        daysUntilDeadline <= 4) {
      return const _SponsoredBadgeData(
        label: 'CLOSING SOON',
        backgroundColor: Color(0xFFFEE2E2),
        foregroundColor: OpportunityDashboardPalette.error,
      );
    }

    if (_containsAny(normalized, const [
      'fully funded',
      'full funding',
      'all expenses',
    ])) {
      return const _SponsoredBadgeData(
        label: 'FULLY FUNDED',
        backgroundColor: Color(0xFFFFEDD5),
        foregroundColor: Color(0xFFC2410C),
      );
    }

    if (_containsAny(normalized, const [
      'limited',
      'limited seats',
      'limited spots',
      'exclusive',
    ])) {
      return const _SponsoredBadgeData(
        label: 'LIMITED',
        backgroundColor: Color(0xFFFFEDD5),
        foregroundColor: OpportunityDashboardPalette.accent,
      );
    }

    if (filters.contains(_SponsoredFilter.funding) &&
        filters.contains(_SponsoredFilter.grants)) {
      return const _SponsoredBadgeData(
        label: 'FULLY FUNDED',
        backgroundColor: Color(0xFFFFEDD5),
        foregroundColor: Color(0xFFC2410C),
      );
    }

    return const _SponsoredBadgeData(
      label: 'ONGOING',
      backgroundColor: Color(0xFFCCFBF1),
      foregroundColor: Color(0xFF0F766E),
    );
  }

  _SponsoredUrgencyData? _urgencyFor(OpportunityModel opportunity) {
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);

    if (daysUntilDeadline == null) {
      return const _SponsoredUrgencyData(
        text: 'Applications open',
        color: OpportunityDashboardPalette.secondary,
        icon: Icons.schedule_rounded,
      );
    }

    if (daysUntilDeadline < 0) {
      return null;
    }

    if (daysUntilDeadline == 0) {
      return const _SponsoredUrgencyData(
        text: 'Closes today',
        color: OpportunityDashboardPalette.error,
        icon: Icons.error_outline_rounded,
      );
    }

    if (daysUntilDeadline == 1) {
      return const _SponsoredUrgencyData(
        text: '1 day left',
        color: OpportunityDashboardPalette.error,
        icon: Icons.timelapse_rounded,
      );
    }

    if (daysUntilDeadline <= 7) {
      return _SponsoredUrgencyData(
        text: 'Closing in $daysUntilDeadline days',
        color: const Color(0xFFEA580C),
        icon: Icons.timelapse_rounded,
      );
    }

    return const _SponsoredUrgencyData(
      text: 'Applications open',
      color: OpportunityDashboardPalette.secondary,
      icon: Icons.schedule_rounded,
    );
  }

  _SponsoredStatData? _primaryStatFor(
    OpportunityModel opportunity,
    Set<_SponsoredFilter> filters,
  ) {
    final compensation = _compensationText(opportunity);
    if (compensation != null) {
      final lower = compensation.toLowerCase();
      final label = switch (true) {
        _ when lower.contains('stipend') => 'STIPEND',
        _ when lower.contains('grant') => 'GRANT',
        _ when lower.contains('award') => 'AWARD',
        _ when lower.contains('reward') => 'REWARD',
        _ => 'FUNDING',
      };

      return _SponsoredStatData(label: label, value: compensation);
    }

    if (filters.contains(_SponsoredFilter.startup)) {
      return const _SponsoredStatData(label: 'TRACK', value: 'Startup');
    }
    if (filters.contains(_SponsoredFilter.competition)) {
      return const _SponsoredStatData(label: 'FORMAT', value: 'Competition');
    }
    if (filters.contains(_SponsoredFilter.internships)) {
      return const _SponsoredStatData(label: 'FORMAT', value: 'Internship');
    }

    return const _SponsoredStatData(label: 'FORMAT', value: 'Sponsored');
  }

  _SponsoredStatData? _secondaryStatFor(OpportunityModel opportunity) {
    final duration = OpportunityMetadata.normalizeDuration(
      opportunity.duration,
    );
    if (duration != null) {
      return _SponsoredStatData(
        label: 'DURATION',
        value: _compactDuration(duration),
      );
    }

    return null;
  }

  DateTime? _deadlineFor(OpportunityModel opportunity) {
    return opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadlineLabel);
  }

  int? _daysUntil(DateTime? deadline) {
    if (deadline == null) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    return target.difference(today).inDays;
  }

  String _compactDuration(String value) {
    return value
        .replaceAll('months', 'mo')
        .replaceAll('month', 'mo')
        .replaceAll('weeks', 'wk')
        .replaceAll('week', 'wk');
  }

  _SponsoredVisualTheme _themeFor(Set<_SponsoredFilter> filters) {
    if (filters.contains(_SponsoredFilter.startup)) {
      return const _SponsoredVisualTheme(
        icon: Icons.rocket_launch_rounded,
        backgroundColor: Color(0xFFEDE9FE),
        foregroundColor: OpportunityDashboardPalette.primary,
      );
    }
    if (filters.contains(_SponsoredFilter.competition)) {
      return const _SponsoredVisualTheme(
        icon: Icons.emoji_events_rounded,
        backgroundColor: Color(0xFFFFEDD5),
        foregroundColor: OpportunityDashboardPalette.accent,
      );
    }
    if (filters.contains(_SponsoredFilter.grants)) {
      return const _SponsoredVisualTheme(
        icon: Icons.workspace_premium_rounded,
        backgroundColor: Color(0xFFFEF3C7),
        foregroundColor: OpportunityDashboardPalette.warning,
      );
    }
    if (filters.contains(_SponsoredFilter.internships)) {
      return const _SponsoredVisualTheme(
        icon: Icons.school_rounded,
        backgroundColor: Color(0xFFDBEAFE),
        foregroundColor: OpportunityDashboardPalette.primaryDark,
      );
    }

    return const _SponsoredVisualTheme(
      icon: Icons.volunteer_activism_rounded,
      backgroundColor: Color(0xFFCCFBF1),
      foregroundColor: OpportunityDashboardPalette.secondary,
    );
  }

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  @override
  Widget build(BuildContext context) {
    final opportunityProvider = context.watch<OpportunityProvider>();
    final allOpportunities = opportunityProvider.opportunities;
    final allCards = _buildCardModels(allOpportunities);
    final visibleCards = _applyFilters(allCards);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: OpportunityDashboardPalette.primary,
            backgroundColor: OpportunityDashboardPalette.surface,
            onRefresh: () => _loadData(force: true),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                if (opportunityProvider.isLoading &&
                    allOpportunities.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SponsoredHeaderBar(
                      onSearchTap: () => _searchFocusNode.requestFocus(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Sponsored\nOpportunities',
                      style: GoogleFonts.poppins(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        height: 1.04,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SponsoredSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onClear: _searchQuery.isEmpty
                          ? null
                          : () => _searchController.clear(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isActive = filter.value == _activeFilter;

                          return _SponsoredFilterChip(
                            label: filter.label,
                            isActive: isActive,
                            onTap: () {
                              if (_activeFilter == filter.value) {
                                return;
                              }
                              setState(() {
                                _activeFilter = filter.value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (opportunityProvider.isLoading && allOpportunities.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visibleCards.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _SponsoredEmptyState(
                        title: 'No sponsored opportunities found',
                        subtitle:
                            'Try adjusting your search or filters to uncover more partner-backed programs.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    sliver: SliverList.separated(
                      itemCount: visibleCards.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = visibleCards[index];
                        final opportunity = item.opportunity;
                        final isBusy =
                            opportunity != null &&
                            _busyApplyIds.contains(opportunity.id);

                        return _SponsoredOpportunityCard(
                          item: item,
                          isApplying: isBusy,
                          onTap: opportunity == null
                              ? null
                              : () => _openOpportunity(opportunity),
                          onApply: () => _applyNow(item),
                          onViewDetails: opportunity == null
                              ? null
                              : () => _openOpportunity(opportunity),
                        );
                      },
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

class _SponsoredHeaderBar extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _SponsoredHeaderBar({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _AvenirBrandAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'AvenirDZ',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.primary,
            ),
          ),
        ),
        _HeaderIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
      ],
    );
  }
}

class _AvenirBrandAvatar extends StatelessWidget {
  const _AvenirBrandAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            OpportunityDashboardPalette.primaryDark,
            OpportunityDashboardPalette.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          'A',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OpportunityDashboardPalette.border),
          ),
          child: Icon(
            icon,
            color: OpportunityDashboardPalette.textPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _SponsoredSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onClear;

  const _SponsoredSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: OpportunityDashboardPalette.primary,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: OpportunityDashboardPalette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search scholarships, grants, or internships...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: OpportunityDashboardPalette.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: OpportunityDashboardPalette.textSecondary,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: OpportunityDashboardPalette.textSecondary,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SponsoredFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SponsoredFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? OpportunityDashboardPalette.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? OpportunityDashboardPalette.primary
                  : OpportunityDashboardPalette.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : OpportunityDashboardPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredOpportunityCard extends StatelessWidget {
  final _SponsoredOpportunityCardModel item;
  final bool isApplying;
  final VoidCallback? onTap;
  final VoidCallback onApply;
  final VoidCallback? onViewDetails;

  const _SponsoredOpportunityCard({
    required this.item,
    required this.isApplying,
    required this.onTap,
    required this.onApply,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(26);
    final innerRadius = BorderRadius.circular(24);
    final accentSurface = item.iconBackgroundColor;
    final accentColor = item.iconForegroundColor;
    final warmTint = const Color(0xFFFFF2E2);
    final warmGlow = const Color(0xFFF8C98B);
    final warmStroke = const Color(0xFFE8B16A);

    return Material(
      color: Colors.transparent,
      borderRadius: outerRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: outerRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(accentSurface, warmTint, 0.48)!,
                warmTint,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: outerRadius,
            border: Border.all(
              color: Color.lerp(
                accentColor,
                warmStroke,
                0.55,
              )!.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: warmStroke.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -42,
                right: -16,
                child: _SponsoredCardGlow(
                  size: 120,
                  color: warmGlow.withValues(alpha: 0.28),
                ),
              ),
              Positioned(
                bottom: -52,
                left: -20,
                child: _SponsoredCardGlow(
                  size: 128,
                  color: warmGlow.withValues(alpha: 0.18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(1.5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, warmTint.withValues(alpha: 0.56)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: innerRadius,
                    border: Border.all(
                      color: OpportunityDashboardPalette.border.withValues(
                        alpha: 0.95,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(innerRadius.topLeft.x),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                warmGlow.withValues(alpha: 0.24),
                                accentSurface.withValues(alpha: 0.42),
                                accentSurface.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -20,
                        right: -14,
                        child: _SponsoredCardGlow(
                          size: 96,
                          color: Colors.white.withValues(alpha: 0.76),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          item.iconData,
                          size: 84,
                          color: Color.lerp(
                            accentColor,
                            warmStroke,
                            0.65,
                          )!.withValues(alpha: 0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SponsoredIconTile(item: item),
                                const Spacer(),
                                _SponsoredStatusBadge(badge: item.badge),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16.8,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                                color: OpportunityDashboardPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                                color:
                                    OpportunityDashboardPalette.textSecondary,
                              ),
                            ),
                            if (item.urgency != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: item.urgency!.color.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: item.urgency!.color.withValues(
                                      alpha: 0.14,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.urgency!.icon,
                                      size: 14,
                                      color: item.urgency!.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        item.urgency!.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.3,
                                          fontWeight: FontWeight.w600,
                                          color: item.urgency!.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (item.primaryStat != null) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SponsoredStatBox(
                                      stat: item.primaryStat!,
                                      accentColor: accentSurface,
                                    ),
                                  ),
                                  if (item.secondaryStat != null) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _SponsoredStatBox(
                                        stat: item.secondaryStat!,
                                        accentColor: accentSurface,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            _SponsoredPrimaryActionButton(
                              label: 'Apply Now',
                              isLoading: isApplying,
                              onTap: onApply,
                            ),
                            const SizedBox(height: 8),
                            _SponsoredSecondaryActionButton(
                              label: 'View Details',
                              onTap: onViewDetails,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _SponsoredIconTile extends StatelessWidget {
  final _SponsoredOpportunityCardModel item;

  const _SponsoredIconTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.iconBackgroundColor),
        boxShadow: [
          BoxShadow(
            color: item.iconForegroundColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: item.iconBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: item.logoUrl.isEmpty
            ? Icon(item.iconData, color: item.iconForegroundColor, size: 26)
            : CachedNetworkImage(
                imageUrl: item.logoUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  item.iconData,
                  color: item.iconForegroundColor,
                  size: 26,
                ),
              ),
      ),
    );
  }
}

class _SponsoredStatusBadge extends StatelessWidget {
  final _SponsoredBadgeData badge;

  const _SponsoredStatusBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: badge.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: badge.foregroundColor.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        badge.label,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
          color: badge.foregroundColor,
        ),
      ),
    );
  }
}

class _SponsoredStatBox extends StatelessWidget {
  final _SponsoredStatData stat;
  final Color accentColor;

  const _SponsoredStatBox({required this.stat, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final warmTint = const Color(0xFFFFF5E9);
    final warmStroke = const Color(0xFFE9B87A);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color.lerp(accentColor.withValues(alpha: 0.14), warmTint, 0.82)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color.lerp(
            accentColor,
            warmStroke,
            0.72,
          )!.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.45,
              color: OpportunityDashboardPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsoredPrimaryActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _SponsoredPrimaryActionButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLoading
                  ? [
                      OpportunityDashboardPalette.primary.withValues(
                        alpha: 0.55,
                      ),
                      OpportunityDashboardPalette.primaryDark.withValues(
                        alpha: 0.55,
                      ),
                    ]
                  : const [
                      OpportunityDashboardPalette.primary,
                      OpportunityDashboardPalette.primaryDark,
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredSecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SponsoredSecondaryActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3D2A6)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD48827),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredCardGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _SponsoredCardGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _SponsoredEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SponsoredEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: OpportunityDashboardPalette.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: OpportunityDashboardPalette.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.55,
              color: OpportunityDashboardPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsoredFilterDefinition {
  final _SponsoredFilter value;
  final String label;

  const _SponsoredFilterDefinition({required this.value, required this.label});
}

class _SponsoredOpportunityCardModel {
  final String id;
  final String title;
  final String description;
  final String companyName;
  final String logoUrl;
  final IconData iconData;
  final Color iconBackgroundColor;
  final Color iconForegroundColor;
  final _SponsoredBadgeData badge;
  final _SponsoredUrgencyData? urgency;
  final _SponsoredStatData? primaryStat;
  final _SponsoredStatData? secondaryStat;
  final Set<_SponsoredFilter> filters;
  final OpportunityModel? opportunity;
  final String searchText;
  final bool isPlaceholder;
  final DateTime? createdAt;

  const _SponsoredOpportunityCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.logoUrl,
    required this.iconData,
    required this.iconBackgroundColor,
    required this.iconForegroundColor,
    required this.badge,
    required this.urgency,
    required this.primaryStat,
    required this.secondaryStat,
    required this.filters,
    required this.opportunity,
    required this.searchText,
    required this.isPlaceholder,
    required this.createdAt,
  });

  factory _SponsoredOpportunityCardModel.placeholder({
    required String id,
    required String title,
    required String description,
    required String companyName,
    required IconData iconData,
    required Color iconBackgroundColor,
    required Color iconForegroundColor,
    required _SponsoredBadgeData badge,
    required _SponsoredUrgencyData? urgency,
    required _SponsoredStatData? primaryStat,
    required _SponsoredStatData? secondaryStat,
    required Set<_SponsoredFilter> filters,
  }) {
    return _SponsoredOpportunityCardModel(
      id: id,
      title: title,
      description: description,
      companyName: companyName,
      logoUrl: '',
      iconData: iconData,
      iconBackgroundColor: iconBackgroundColor,
      iconForegroundColor: iconForegroundColor,
      badge: badge,
      urgency: urgency,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
      filters: filters,
      opportunity: null,
      searchText: [
        title,
        description,
        companyName,
        ...filters.map((filter) => filter.name),
        primaryStat?.label ?? '',
        primaryStat?.value ?? '',
        secondaryStat?.label ?? '',
        secondaryStat?.value ?? '',
      ].join(' ').toLowerCase(),
      isPlaceholder: true,
      createdAt: null,
    );
  }
}

class _SponsoredVisualTheme {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SponsoredVisualTheme({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class _SponsoredBadgeData {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SponsoredBadgeData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class _SponsoredUrgencyData {
  final String text;
  final Color color;
  final IconData icon;

  const _SponsoredUrgencyData({
    required this.text,
    required this.color,
    required this.icon,
  });
}

class _SponsoredStatData {
  final String label;
  final String value;

  const _SponsoredStatData({required this.label, required this.value});
}

final List<_SponsoredOpportunityCardModel> _placeholderSponsoredCards = [
  _SponsoredOpportunityCardModel.placeholder(
    id: 'jp-morgan-fintech',
    title: 'JP Morgan Fintech Summit',
    description:
        'A partner-backed summit for ambitious students exploring finance, technology, and innovation-led product building.',
    companyName: 'JP Morgan',
    iconData: Icons.emoji_events_rounded,
    iconBackgroundColor: Color(0xFFFFEDD5),
    iconForegroundColor: OpportunityDashboardPalette.accent,
    badge: _SponsoredBadgeData(
      label: 'FULLY FUNDED',
      backgroundColor: Color(0xFFFFEDD5),
      foregroundColor: Color(0xFFC2410C),
    ),
    urgency: _SponsoredUrgencyData(
      text: 'Closing in 5 days',
      color: Color(0xFFEA580C),
      icon: Icons.timelapse_rounded,
    ),
    primaryStat: _SponsoredStatData(label: 'GRANT', value: '\$5,000'),
    secondaryStat: _SponsoredStatData(label: 'DURATION', value: '3 days'),
    filters: {
      _SponsoredFilter.funding,
      _SponsoredFilter.grants,
      _SponsoredFilter.competition,
    },
  ),
  _SponsoredOpportunityCardModel.placeholder(
    id: 'aws-ambassador',
    title: 'AWS Student Ambassador',
    description:
        'A sponsored student ambassador track with mentorship, community leadership, and premium cloud learning access.',
    companyName: 'AWS',
    iconData: Icons.school_rounded,
    iconBackgroundColor: Color(0xFFDBEAFE),
    iconForegroundColor: OpportunityDashboardPalette.primaryDark,
    badge: _SponsoredBadgeData(
      label: 'ONGOING',
      backgroundColor: Color(0xFFCCFBF1),
      foregroundColor: Color(0xFF0F766E),
    ),
    urgency: _SponsoredUrgencyData(
      text: 'Applications open',
      color: OpportunityDashboardPalette.secondary,
      icon: Icons.schedule_rounded,
    ),
    primaryStat: _SponsoredStatData(label: 'STIPEND', value: '\$1,200 / mo'),
    secondaryStat: _SponsoredStatData(label: 'DURATION', value: '6 mo'),
    filters: {_SponsoredFilter.funding, _SponsoredFilter.internships},
  ),
  _SponsoredOpportunityCardModel.placeholder(
    id: 'innovation-grant',
    title: 'International Innovation Grant',
    description:
        'A premium support program for students building new ideas through mentorship, funding access, and expert review.',
    companyName: 'AvenirDZ Partner',
    iconData: Icons.workspace_premium_rounded,
    iconBackgroundColor: Color(0xFFFEF3C7),
    iconForegroundColor: OpportunityDashboardPalette.warning,
    badge: _SponsoredBadgeData(
      label: 'LIMITED',
      backgroundColor: Color(0xFFFFEDD5),
      foregroundColor: OpportunityDashboardPalette.accent,
    ),
    urgency: _SponsoredUrgencyData(
      text: 'Closing in 8 days',
      color: OpportunityDashboardPalette.warning,
      icon: Icons.schedule_rounded,
    ),
    primaryStat: _SponsoredStatData(label: 'GRANT', value: '\$8,000'),
    secondaryStat: _SponsoredStatData(label: 'DURATION', value: '12 wk'),
    filters: {
      _SponsoredFilter.funding,
      _SponsoredFilter.grants,
      _SponsoredFilter.startup,
    },
  ),
];
