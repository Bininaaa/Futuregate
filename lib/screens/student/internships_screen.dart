import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/application_status.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_workspace_shell.dart';
import 'applied_opportunities_screen.dart';
import 'opportunity_detail_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class InternshipsScreen extends StatefulWidget {
  const InternshipsScreen({super.key});

  @override
  State<InternshipsScreen> createState() => _InternshipsScreenState();
}

enum _InternshipQuickFilter { remote, paid, summer, tech, marketing }

enum _InternshipsViewMode { grid, list }

class _InternshipVisualPalette {
  const _InternshipVisualPalette._();

  static Color get surface => OpportunityDashboardPalette.surface;
  static Color get mint => OpportunityDashboardPalette.secondary;
  static Color get deepTeal => OpportunityDashboardPalette.secondary;
  static Color get oceanTeal => OpportunityDashboardPalette.secondary;
  static Color get glowMint => OpportunityDashboardPalette.secondary;
  static Color get border => OpportunityDashboardPalette.border;
  static Color get textPrimary => OpportunityDashboardPalette.textPrimary;
  static Color get textSecondary => OpportunityDashboardPalette.textSecondary;
}

class _InternshipsScreenState extends State<InternshipsScreen> {
  List<_QuickFilterDefinition> _buildQuickFilters(AppLocalizations l10n) => [
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.remote,
      label: l10n.uiRemote,
    ),
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.paid,
      label: l10n.uiPaid,
    ),
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.summer,
      label: l10n.uiSummer,
    ),
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.tech,
      label: l10n.uiTech,
    ),
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.marketing,
      label: l10n.uiMarketing,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _availableSectionKey = GlobalKey();

  String _searchQuery = '';
  _InternshipQuickFilter? _selectedQuickFilter;
  _InternshipsViewMode _viewMode = _InternshipsViewMode.grid;

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
    final savedProvider = context.read<SavedOpportunityProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[opportunityProvider.fetchOpportunities()];

    if (userId != null && userId.isNotEmpty) {
      futures.add(savedProvider.fetchSavedOpportunities(userId));
      futures.add(applicationProvider.fetchSubmittedApplications(userId));
    }

    await Future.wait(futures);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openSavedItems() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedScreen()),
    );
  }

  void _openAppliedItems() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppliedOpportunitiesScreen()),
    );
  }

  void _openOpportunity(OpportunityModel opportunity) {
    OpportunityDetailScreen.show(context, opportunity);
  }

  Future<void> _toggleSavedOpportunity(OpportunityModel opportunity) async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final userId = authProvider.userModel?.uid;

    if (userId == null || userId.isEmpty) {
      context.showAppSnackBar(
        'Sign in to save internships for later.',
        title: AppLocalizations.of(context)!.uiLoginRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final matchingSaved = savedProvider.savedOpportunities
        .where((item) => item.opportunityId == opportunity.id)
        .toList();
    final existingSaved = matchingSaved.isNotEmpty ? matchingSaved.first : null;

    String? error;
    var message = 'Internship saved';

    if (existingSaved != null) {
      error = await savedProvider.unsaveOpportunity(existingSaved.id, userId);
      message = 'Removed from saved internships';
    } else {
      error = await savedProvider.saveOpportunity(
        studentId: userId,
        opportunityId: opportunity.id,
        title: DisplayText.opportunityTitle(
          opportunity.title,
          fallback: 'Open Internship',
        ),
        companyName: opportunity.companyName,
        type: opportunity.type,
        location: opportunity.location,
        deadline: opportunity.deadlineLabel,
      );
    }

    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      error ?? message,
      title: error == null ? 'Saved items updated' : 'Save unavailable',
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _scrollToAvailableSection() async {
    final sectionContext = _availableSectionKey.currentContext;
    if (sectionContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  List<_InternshipCardModel> _buildLiveInternships(
    List<OpportunityModel> opportunities,
    Set<String> savedIds,
  ) {
    return opportunities
        .where(
          (opportunity) =>
              opportunity.isVisibleToStudents() &&
              OpportunityType.parse(opportunity.type) ==
                  OpportunityType.internship,
        )
        .map((opportunity) => _mapOpportunityToCardModel(opportunity, savedIds))
        .toList();
  }

  List<_InternshipCardModel> _applyFilters(List<_InternshipCardModel> items) {
    final query = _searchQuery.trim().toLowerCase();

    return items.where((item) {
      final matchesQuery = query.isEmpty || item.searchText.contains(query);
      final matchesChip = switch (_selectedQuickFilter) {
        null => true,
        _InternshipQuickFilter.remote => item.workMode == 'Remote',
        _InternshipQuickFilter.paid => item.isPaid,
        _InternshipQuickFilter.summer => item.matchesSummer,
        _InternshipQuickFilter.tech => item.matchesTech,
        _InternshipQuickFilter.marketing => item.matchesMarketing,
      };

      return matchesQuery && matchesChip;
    }).toList();
  }

  List<_InternshipCardModel> _selectApplyThisWeek(
    List<_InternshipCardModel> items,
  ) {
    final result = <_InternshipCardModel>[];
    final seen = <String>{};

    void addCandidates(Iterable<_InternshipCardModel> candidates) {
      for (final candidate in candidates) {
        if (result.length >= 6) {
          return;
        }

        if (seen.add(candidate.uniqueKey)) {
          result.add(candidate);
        }
      }
    }

    addCandidates(items.where((item) => item.isFeaturedPreferred));
    addCandidates(
      items.where(
        (item) =>
            item.daysUntilDeadline != null && item.daysUntilDeadline! <= 7,
      ),
    );
    addCandidates(items);

    return result;
  }

  List<_InternshipCardModel> _selectAvailableInternships(
    List<_InternshipCardModel> items,
  ) {
    final sorted = [...items];

    sorted.sort((a, b) {
      final scoreDiff = _priorityScore(b).compareTo(_priorityScore(a));
      if (scoreDiff != 0) {
        return scoreDiff;
      }

      final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
      final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
      return bCreated.compareTo(aCreated);
    });

    return sorted;
  }

  int _priorityScore(_InternshipCardModel item) {
    var score = 0;

    if (item.isFeaturedPreferred) {
      score += 120;
    }
    if (item.isPaid) {
      score += 30;
    }
    if (item.workMode == 'Remote' || item.workMode == 'Hybrid') {
      score += 12;
    }
    if (item.deadline != null) {
      final days = item.daysUntilDeadline;
      if (days != null && days >= 0) {
        score += days <= 7 ? 60 - days : 8;
      }
    }

    return score;
  }

  _InternshipCardModel _mapOpportunityToCardModel(
    OpportunityModel opportunity,
    Set<String> savedIds,
  ) {
    final companyName = _companyName(opportunity);
    final companyLabel = companyName.toUpperCase();
    final workMode = _workModeLabel(opportunity);
    final location = _locationLabel(opportunity);
    final secondaryDetail = workMode ?? location;
    final secondaryText = secondaryDetail == null
        ? companyName
        : '$companyName | $secondaryDetail';
    final deadline = _deadlineFor(opportunity);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final daysUntilDeadline = deadline?.difference(normalizedToday).inDays;
    final isPaid = _effectiveIsPaid(opportunity);
    final compensation = _compensationText(opportunity);
    final duration = OpportunityMetadata.normalizeDuration(
      opportunity.duration,
    );
    final categoryLabel = _categoryLabel(opportunity);
    final searchText = [
      opportunity.title,
      companyName,
      opportunity.description,
      opportunity.requirements,
      companyLabel,
      workMode ?? '',
      location ?? '',
      categoryLabel ?? '',
      duration ?? '',
      compensation ?? '',
      deadline == null ? '' : OpportunityMetadata.formatDateLabel(deadline),
      opportunity.readString([
            'department',
            'team',
            'category',
            'field',
            'industry',
            'tags',
            'skills',
            'track',
            'program',
          ]) ??
          '',
    ].join(' ').toLowerCase();

    return _InternshipCardModel(
      id: opportunity.id,
      title: DisplayText.opportunityTitle(
        opportunity.title,
        fallback: 'Open Internship',
      ),
      companyName: companyName,
      companyLabel: companyLabel,
      secondaryText: secondaryText,
      logoUrl: opportunity.companyLogo.trim(),
      fallbackLabel: companyName.isEmpty
          ? 'A'
          : companyName.characters.first.toUpperCase(),
      workMode: workMode,
      location: location,
      deadline: deadline,
      daysUntilDeadline: daysUntilDeadline,
      deadlinePill: _deadlinePillText(deadline, daysUntilDeadline),
      applyByText: _applyByText(deadline),
      isPaid: isPaid == true || compensation != null,
      compensation: compensation,
      duration: duration,
      categoryLabel: categoryLabel,
      isFeaturedPreferred: opportunity.isFeatured,
      matchesSummer: _matchesSummerKeywords(opportunity, searchText),
      matchesTech: _matchesTechKeywords(opportunity, searchText),
      matchesMarketing: _matchesMarketingKeywords(opportunity, searchText),
      createdAt: opportunity.createdAt?.toDate(),
      searchText: searchText,
      opportunity: opportunity,
      isSaved: savedIds.contains(opportunity.id),
    );
  }

  bool _matchesSummerKeywords(OpportunityModel opportunity, String searchText) {
    if (searchText.contains('summer')) {
      return true;
    }

    final deadline = _deadlineFor(opportunity);
    if (deadline == null) {
      return false;
    }

    return deadline.month >= 5 && deadline.month <= 8;
  }

  bool _matchesTechKeywords(OpportunityModel opportunity, String searchText) {
    final category = _categoryLabel(opportunity);
    if (category == 'Engineering' || category == 'Tech') {
      return true;
    }

    const keywords = [
      'engineer',
      'engineering',
      'developer',
      'frontend',
      'backend',
      'mobile',
      'flutter',
      'software',
      'data',
      'tech',
      'product',
      'platform',
      'security',
      'cloud',
      'devops',
      'ai',
    ];

    return keywords.any(searchText.contains);
  }

  bool _matchesMarketingKeywords(
    OpportunityModel opportunity,
    String searchText,
  ) {
    if (_categoryLabel(opportunity) == 'Marketing') {
      return true;
    }

    const keywords = [
      'marketing',
      'brand',
      'content',
      'campaign',
      'community',
      'growth',
      'seo',
      'social media',
      'communications',
      'strategy',
    ];

    return keywords.any(searchText.contains);
  }

  String _companyName(OpportunityModel opportunity) {
    final trimmed = opportunity.companyName.trim();
    return trimmed.isEmpty ? 'FutureGate Partner' : trimmed;
  }

  String? _locationLabel(OpportunityModel opportunity) {
    final location = opportunity.location.trim();
    if (location.isNotEmpty) {
      return location;
    }

    return opportunity.readString([
      'city',
      'region',
      'country',
      'officeLocation',
      'address',
      'place',
    ]);
  }

  String? _workModeLabel(OpportunityModel opportunity) {
    final normalizedMode =
        opportunity.workMode ??
        OpportunityMetadata.extractWorkMode(opportunity.rawData);
    final formatted = OpportunityMetadata.formatWorkMode(normalizedMode);
    if (formatted != null) {
      return formatted;
    }

    final searchable = [
      opportunity.location,
      opportunity.description,
      opportunity.requirements,
    ].join(' ').toLowerCase();

    if (searchable.contains('hybrid')) {
      return 'Hybrid';
    }
    if (searchable.contains('remote')) {
      return 'Remote';
    }
    if (searchable.contains('on-site') ||
        searchable.contains('onsite') ||
        searchable.contains('on site')) {
      return 'On-site';
    }

    return null;
  }

  bool? _effectiveIsPaid(OpportunityModel opportunity) {
    return opportunity.isPaid ??
        OpportunityMetadata.extractIsPaid(opportunity.rawData);
  }

  DateTime? _deadlineFor(OpportunityModel opportunity) {
    return opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadlineLabel);
  }

  String _applyByText(DateTime? deadline) {
    if (deadline == null) {
      return 'Applications open';
    }

    return 'Applying by ${OpportunityMetadata.formatDateLabel(deadline, pattern: 'MMM d')}';
  }

  String? _deadlinePillText(DateTime? deadline, int? daysUntilDeadline) {
    if (deadline == null ||
        daysUntilDeadline == null ||
        daysUntilDeadline < 0) {
      return null;
    }
    if (daysUntilDeadline == 0) {
      return 'Today';
    }
    if (daysUntilDeadline == 1) {
      return '1 day left';
    }
    if (daysUntilDeadline <= 21) {
      return '$daysUntilDeadline days left';
    }

    return OpportunityMetadata.formatDateLabel(deadline, pattern: 'MMM d');
  }

  String? _compensationText(OpportunityModel opportunity) {
    final label =
        OpportunityMetadata.formatSalaryRange(
          salaryMin: opportunity.salaryMin,
          salaryMax: opportunity.salaryMax,
          salaryCurrency: opportunity.salaryCurrency,
          salaryPeriod: opportunity.salaryPeriod,
        ) ??
        OpportunityMetadata.formatPaidLabel(_effectiveIsPaid(opportunity));
    if (label == null) {
      return null;
    }

    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'unpaid') {
      return null;
    }

    return label;
  }

  String? _categoryLabel(OpportunityModel opportunity) {
    final explicit = opportunity.readString([
      'department',
      'team',
      'category',
      'field',
      'industry',
      'track',
      'focus',
    ]);
    if (explicit != null && explicit.trim().isNotEmpty) {
      final firstSegment = explicit
          .split(RegExp(r'[/|,&]'))
          .first
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .join(' ');
      if (firstSegment.isNotEmpty) {
        return _normalizeCategoryLabel(firstSegment);
      }
    }

    final searchable = [
      opportunity.title,
      opportunity.description,
      opportunity.requirements,
    ].join(' ').toLowerCase();

    if (RegExp(
      r'\b(ui|ux|design|designer|creative|brand)\b',
    ).hasMatch(searchable)) {
      return 'Design';
    }
    if (RegExp(
      r'\b(marketing|campaign|growth|content|community|seo|social)\b',
    ).hasMatch(searchable)) {
      return 'Marketing';
    }
    if (RegExp(
      r'\b(strategy|operations|business|consulting|analyst)\b',
    ).hasMatch(searchable)) {
      return 'Strategy';
    }
    if (RegExp(
      r'\b(engineer|engineering|developer|software|frontend|backend|mobile|tech|data|cloud|devops)\b',
    ).hasMatch(searchable)) {
      return 'Engineering';
    }

    return null;
  }

  String _normalizeCategoryLabel(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Internship';
    }

    final lower = normalized.toLowerCase();
    if (lower.contains('marketing')) {
      return 'Marketing';
    }
    if (lower.contains('design') ||
        lower.contains('ux') ||
        lower.contains('ui')) {
      return 'Design';
    }
    if (lower.contains('strategy') || lower.contains('business')) {
      return 'Strategy';
    }
    if (lower.contains('engineer') ||
        lower.contains('software') ||
        lower.contains('tech')) {
      return 'Engineering';
    }

    return normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final opportunityProvider = context.watch<OpportunityProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isCompact = screenSize.width < 390 || screenSize.height < 780;
    final isExtraCompact = screenSize.width < 360 || screenSize.height < 700;
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();
    final appliedStatuses = applicationProvider.appliedStatusMap;
    final liveInternships = _buildLiveInternships(
      opportunityProvider.opportunities,
      savedIds,
    );
    final filteredInternships = _applyFilters(liveInternships);
    final featuredInternships = _selectApplyThisWeek(filteredInternships);
    final availableInternships = _selectAvailableInternships(
      filteredInternships,
    );
    final availableCountLabel = availableInternships.length == 1
        ? '1 internship'
        : '${availableInternships.length} internships';
    final gridCrossAxisCount = 2;
    final gridSpacing = isExtraCompact ? 12.0 : 14.0;
    final gridMainExtent = isExtraCompact
        ? 168.0
        : isCompact
        ? 172.0
        : 182.0;
    final contentBottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            StudentWorkspaceUtilityHeader(
              user: authProvider.userModel,
              title: AppLocalizations.of(context)!.uiInternships,
              onProfileTap: _openProfile,
              onOpenSaved: _openSavedItems,
              onOpenApplied: _openAppliedItems,
              compact: isCompact,
              backgroundColor: Colors.transparent,
              borderColor: _InternshipVisualPalette.oceanTeal.withValues(
                alpha: 0.18,
              ),
              titleColor: _InternshipVisualPalette.deepTeal,
              accentColor: _InternshipVisualPalette.oceanTeal,
            ),
            if (opportunityProvider.isLoading && liveInternships.isNotEmpty)
              LinearProgressIndicator(
                minHeight: 2,
                color: _InternshipVisualPalette.mint,
              ),
            Expanded(
              child: RefreshIndicator(
                color: _InternshipVisualPalette.mint,
                backgroundColor: _InternshipVisualPalette.surface,
                onRefresh: () => _loadData(force: true),
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    contentBottomPadding,
                  ),
                  children: [
                    const _InternshipsIntro(),
                    const SizedBox(height: 16),
                    _InternshipSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onClear: _searchQuery.isEmpty
                          ? null
                          : _searchController.clear,
                    ),
                    const SizedBox(height: 10),
                    _InternshipFilterChipRow(
                      activeFilter: _selectedQuickFilter,
                      filters: _buildQuickFilters(
                        AppLocalizations.of(context)!,
                      ),
                      onSelected: (filter) {
                        setState(() {
                          _selectedQuickFilter = _selectedQuickFilter == filter
                              ? null
                              : filter;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _InternshipSectionHeader(
                      title: AppLocalizations.of(
                        context,
                      )!.uiFeaturedInternships,
                      actionLabel: 'Browse all',
                      onAction: _scrollToAvailableSection,
                    ),
                    const SizedBox(height: 10),
                    if (filteredInternships.isEmpty)
                      _InternshipsEmptyState(
                        title: liveInternships.isEmpty
                            ? 'No internships available right now'
                            : 'No internships match this view',
                        subtitle: liveInternships.isEmpty
                            ? 'Check back soon for new internship listings.'
                            : 'Try adjusting your search or filters to explore more opportunities.',
                      )
                    else
                      _ApplyThisWeekSection(
                        items: featuredInternships,
                        appliedStatuses: appliedStatuses,
                        onOpenOpportunity: (item) {
                          if (item.opportunity != null) {
                            _openOpportunity(item.opportunity!);
                          }
                        },
                        onToggleSaved: (item) {
                          if (item.opportunity != null) {
                            _toggleSavedOpportunity(item.opportunity!);
                          }
                        },
                        isSaving: savedProvider.isLoading,
                      ),
                    const SizedBox(height: 20),
                    Container(
                      key: _availableSectionKey,
                      child: _InternshipSectionHeader(
                        title: AppLocalizations.of(
                          context,
                        )!.uiAvailableInternships,
                        countLabel: availableCountLabel,
                        trailing: _InternshipViewToggle(
                          viewMode: _viewMode,
                          onChanged: (nextViewMode) {
                            setState(() {
                              _viewMode = nextViewMode;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredInternships.isEmpty)
                      _InternshipsEmptyState(
                        title: liveInternships.isEmpty
                            ? 'No internships available right now'
                            : 'No internships match this view',
                        subtitle: liveInternships.isEmpty
                            ? 'Check back soon for new internship listings.'
                            : 'Try adjusting your search to see more internship matches.',
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: child,
                            ),
                          );
                        },
                        child: _viewMode == _InternshipsViewMode.grid
                            ? GridView.builder(
                                key: const ValueKey('internships-grid'),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: availableInternships.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gridCrossAxisCount,
                                      crossAxisSpacing: gridSpacing,
                                      mainAxisSpacing: gridSpacing,
                                      mainAxisExtent: gridMainExtent,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = availableInternships[index];
                                  final statusData =
                                      _internshipStatusDataForOpportunity(
                                        item.opportunity,
                                        appliedStatuses,
                                        AppLocalizations.of(context)!,
                                      );
                                  return _AvailableInternshipCard(
                                    item: item,
                                    statusData: statusData,
                                    onTap: item.opportunity == null
                                        ? null
                                        : () => _openOpportunity(
                                            item.opportunity!,
                                          ),
                                    onToggleSaved: item.opportunity == null
                                        ? null
                                        : () => _toggleSavedOpportunity(
                                            item.opportunity!,
                                          ),
                                    isSaving: savedProvider.isLoading,
                                  );
                                },
                              )
                            : Column(
                                key: const ValueKey('internships-list'),
                                children: [
                                  for (
                                    var index = 0;
                                    index < availableInternships.length;
                                    index++
                                  )
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            index ==
                                                availableInternships.length - 1
                                            ? 0
                                            : 12,
                                      ),
                                      child: _AvailableInternshipListTile(
                                        item: availableInternships[index],
                                        statusData:
                                            _internshipStatusDataForOpportunity(
                                              availableInternships[index]
                                                  .opportunity,
                                              appliedStatuses,
                                              AppLocalizations.of(context)!,
                                            ),
                                        onTap:
                                            availableInternships[index]
                                                    .opportunity ==
                                                null
                                            ? null
                                            : () => _openOpportunity(
                                                availableInternships[index]
                                                    .opportunity!,
                                              ),
                                        onToggleSaved:
                                            availableInternships[index]
                                                    .opportunity ==
                                                null
                                            ? null
                                            : () => _toggleSavedOpportunity(
                                                availableInternships[index]
                                                    .opportunity!,
                                              ),
                                        isSaving: savedProvider.isLoading,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    if (liveInternships.isEmpty &&
                        opportunityProvider.isLoading) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Loading live internships...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _InternshipVisualPalette.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternshipsIntro extends StatelessWidget {
  const _InternshipsIntro();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Find your next\n',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.08,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          TextSpan(
            text: 'placement',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.08,
              color: _InternshipVisualPalette.deepTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InternshipSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onClear;

  const _InternshipSearchBar({
    required this.controller,
    required this.focusNode,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: OpportunityDashboardPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search internships...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: OpportunityDashboardPalette.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: _InternshipVisualPalette.deepTeal,
        ),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  color: _InternshipVisualPalette.deepTeal,
                ),
              ),
        filled: true,
        fillColor: AppColors.current.secondarySoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: _InternshipVisualPalette.deepTeal),
        ),
      ),
    );
  }
}

class _InternshipFilterChipRow extends StatelessWidget {
  final _InternshipQuickFilter? activeFilter;
  final List<_QuickFilterDefinition> filters;
  final ValueChanged<_InternshipQuickFilter> onSelected;

  const _InternshipFilterChipRow({
    required this.activeFilter,
    required this.filters,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = filter.value == activeFilter;

          return GestureDetector(
            onTap: () => onSelected(filter.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? _InternshipVisualPalette.mint
                    : OpportunityDashboardPalette.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive
                      ? _InternshipVisualPalette.mint
                      : OpportunityDashboardPalette.border,
                ),
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : OpportunityDashboardPalette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InternshipSectionHeader extends StatelessWidget {
  final String title;
  final String? countLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const _InternshipSectionHeader({
    required this.title,
    this.countLabel,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.textPrimary,
                ),
              ),
              if (countLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: OpportunityDashboardPalette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: OpportunityDashboardPalette.border,
                    ),
                  ),
                  child: Text(
                    countLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ] else if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: OpportunityDashboardPalette.border.withValues(
                      alpha: 0.9,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: OpportunityDashboardPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: OpportunityDashboardPalette.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

enum _InternshipFeaturedDecorationVariant {
  auroraBloom,
  glassPanel,
  meshPattern,
  lineStudio,
  haloGlow,
}

class _InternshipFeaturedVariantStyle {
  final _InternshipFeaturedDecorationVariant decorationVariant;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Color accentColor;
  final Color glowColor;
  final Color logoSurface;
  final Color logoForeground;
  final Color badgeBackground;
  final Color badgeBorderColor;
  final List<Color> buttonGradientColors;
  final Color buttonTextColor;

  const _InternshipFeaturedVariantStyle({
    required this.decorationVariant,
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.accentColor,
    required this.glowColor,
    required this.logoSurface,
    required this.logoForeground,
    required this.badgeBackground,
    required this.badgeBorderColor,
    required this.buttonGradientColors,
    required this.buttonTextColor,
  });
}

_InternshipFeaturedVariantStyle _featuredInternshipStyleFor(int index) {
  final styles = <_InternshipFeaturedVariantStyle>[
    _InternshipFeaturedVariantStyle(
      decorationVariant: _InternshipFeaturedDecorationVariant.auroraBloom,
      gradientColors: [Color(0xFF33D0BF), Color(0xFF14B8A6), Color(0xFF0F766E)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      accentColor: Color(0xFFBFF6EE),
      glowColor: Color(0xFF62E5D5),
      logoSurface: Color(0xFFF2FEFB),
      logoForeground: _InternshipVisualPalette.deepTeal,
      badgeBackground: Color(0x24FFFFFF),
      badgeBorderColor: Color(0x38FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFD9FAF4)],
      buttonTextColor: _InternshipVisualPalette.deepTeal,
    ),
    _InternshipFeaturedVariantStyle(
      decorationVariant: _InternshipFeaturedDecorationVariant.glassPanel,
      gradientColors: [Color(0xFF26C6B8), Color(0xFF0D9488), Color(0xFF115E59)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomCenter,
      accentColor: Color(0xFFC9FBF3),
      glowColor: Color(0xFF46DCCA),
      logoSurface: Color(0xFFF1FDFC),
      logoForeground: _InternshipVisualPalette.oceanTeal,
      badgeBackground: Color(0x22FFFFFF),
      badgeBorderColor: Color(0x36FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFDFFAF6)],
      buttonTextColor: _InternshipVisualPalette.oceanTeal,
    ),
    _InternshipFeaturedVariantStyle(
      decorationVariant: _InternshipFeaturedDecorationVariant.meshPattern,
      gradientColors: [Color(0xFF34D6C3), Color(0xFF0EA5A0), Color(0xFF0F766E)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomRight,
      accentColor: Color(0xFFD5FCF6),
      glowColor: Color(0xFF71E7D9),
      logoSurface: Color(0xFFF3FDFC),
      logoForeground: Color(0xFF0F766E),
      badgeBackground: Color(0x24FFFFFF),
      badgeBorderColor: Color(0x38FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFDDFBF6)],
      buttonTextColor: Color(0xFF0F766E),
    ),
    _InternshipFeaturedVariantStyle(
      decorationVariant: _InternshipFeaturedDecorationVariant.lineStudio,
      gradientColors: [Color(0xFF17BDAA), Color(0xFF0F766E), Color(0xFF134E4A)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      accentColor: Color(0xFFBDEFE8),
      glowColor: Color(0xFF49D9C8),
      logoSurface: Color(0xFFF1FCFB),
      logoForeground: Color(0xFF115E59),
      badgeBackground: Color(0x24FFFFFF),
      badgeBorderColor: Color(0x36FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFD7F8F1)],
      buttonTextColor: Color(0xFF115E59),
    ),
    _InternshipFeaturedVariantStyle(
      decorationVariant: _InternshipFeaturedDecorationVariant.haloGlow,
      gradientColors: [Color(0xFF22C8B6), Color(0xFF14B8A6), Color(0xFF115E59)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      accentColor: Color(0xFFC9FBF3),
      glowColor: Color(0xFF5CE0CF),
      logoSurface: Color(0xFFF1FDFC),
      logoForeground: _InternshipVisualPalette.deepTeal,
      badgeBackground: Color(0x24FFFFFF),
      badgeBorderColor: Color(0x38FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFDCF9F4)],
      buttonTextColor: _InternshipVisualPalette.deepTeal,
    ),
  ];

  final style = styles[index % styles.length];
  if (!AppColors.isDark) {
    return style;
  }

  final colors = AppColors.current;
  return _InternshipFeaturedVariantStyle(
    decorationVariant: style.decorationVariant,
    gradientColors: style.gradientColors,
    gradientBegin: style.gradientBegin,
    gradientEnd: style.gradientEnd,
    accentColor: style.accentColor,
    glowColor: style.glowColor,
    logoSurface: colors.surfaceElevated,
    logoForeground: style.logoForeground,
    badgeBackground: style.badgeBackground,
    badgeBorderColor: style.badgeBorderColor,
    buttonGradientColors: [colors.surfaceElevated, colors.secondarySoft],
    buttonTextColor: colors.secondary,
  );
}

class _ApplyThisWeekSection extends StatelessWidget {
  final List<_InternshipCardModel> items;
  final Map<String, String> appliedStatuses;
  final ValueChanged<_InternshipCardModel> onOpenOpportunity;
  final ValueChanged<_InternshipCardModel> onToggleSaved;
  final bool isSaving;

  const _ApplyThisWeekSection({
    required this.items,
    required this.appliedStatuses,
    required this.onOpenOpportunity,
    required this.onToggleSaved,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 390 || screenSize.height < 780;
    final isExtraCompact = screenSize.width < 360 || screenSize.height < 700;
    final cardWidth = screenSize.width * (isExtraCompact ? 0.76 : 0.78);
    final cardHeight = isExtraCompact
        ? 204.0
        : isCompact
        ? 212.0
        : 248.0;
    final cardSpacing = isExtraCompact ? 12.0 : 16.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 10),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(width: cardSpacing),
        itemBuilder: (context, index) {
          final item = items[index];
          final statusData = _internshipStatusDataForOpportunity(
            item.opportunity,
            appliedStatuses,
            AppLocalizations.of(context)!,
          );

          return SizedBox(
            width: cardWidth,
            child: _InternshipFeaturedCard(
              item: item,
              style: _featuredInternshipStyleFor(index),
              statusData: statusData,
              onTap: item.opportunity == null
                  ? null
                  : () => onOpenOpportunity(item),
              onAction: item.opportunity == null || statusData != null
                  ? null
                  : () => onOpenOpportunity(item),
              onToggleSaved: item.opportunity == null
                  ? null
                  : () => onToggleSaved(item),
              isSaving: isSaving,
            ),
          );
        },
      ),
    );
  }
}

class _InternshipFeaturedCard extends StatelessWidget {
  final _InternshipCardModel item;
  final _InternshipFeaturedVariantStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final VoidCallback? onToggleSaved;
  final bool isSaving;
  final _InternshipStatusData? statusData;

  const _InternshipFeaturedCard({
    required this.item,
    required this.style,
    this.onTap,
    this.onAction,
    this.onToggleSaved,
    required this.isSaving,
    this.statusData,
  });

  String _supportingLine() {
    final location = item.location?.trim();
    if (location != null && location.isNotEmpty) {
      return '${item.companyName} • $location';
    }

    final workMode = item.workMode?.trim();
    if (workMode != null && workMode.isNotEmpty) {
      return '${item.companyName} • $workMode';
    }

    return item.companyName;
  }

  String? _metadataLine() {
    final parts = <String>[
      if (item.duration?.trim().isNotEmpty ?? false) item.duration!.trim(),
      if (item.deadlinePill?.trim().isNotEmpty ?? false)
        item.deadlinePill!.trim(),
    ];

    if (parts.isEmpty) {
      return null;
    }

    return parts.take(2).join(' • ');
  }

  List<Widget> _buildDecorations() {
    switch (style.decorationVariant) {
      case _InternshipFeaturedDecorationVariant.auroraBloom:
        return [
          Positioned(
            top: -46,
            right: -14,
            child: _GlowOrb(
              size: 148,
              color: Colors.white.withValues(alpha: 0.44),
            ),
          ),
          Positioned(
            bottom: -54,
            left: -26,
            child: _GlowOrb(
              size: 176,
              color: style.glowColor.withValues(alpha: 0.36),
            ),
          ),
        ];
      case _InternshipFeaturedDecorationVariant.glassPanel:
        return [
          Positioned(
            top: 16,
            right: 18,
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 82,
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -34,
            right: -18,
            child: _GlowOrb(
              size: 158,
              color: style.glowColor.withValues(alpha: 0.34),
            ),
          ),
        ];
      case _InternshipFeaturedDecorationVariant.meshPattern:
        return [
          Positioned(
            top: -34,
            left: -20,
            child: _GlowOrb(
              size: 120,
              color: Colors.white.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            bottom: -44,
            left: 18,
            child: _GlowOrb(
              size: 128,
              color: style.glowColor.withValues(alpha: 0.24),
            ),
          ),
        ];
      case _InternshipFeaturedDecorationVariant.lineStudio:
        return [
          Positioned(
            top: 10,
            right: -4,
            child: Transform.rotate(
              angle: 0.16,
              child: _DecorativeLineArtLoop(
                width: 108,
                height: 108,
                color: Colors.white.withValues(alpha: 0.34),
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            left: -10,
            child: Transform.rotate(
              angle: -0.22,
              child: _DecorativeLineArtLoop(
                width: 86,
                height: 86,
                color: style.glowColor.withValues(alpha: 0.28),
              ),
            ),
          ),
        ];
      case _InternshipFeaturedDecorationVariant.haloGlow:
        return [
          Positioned(
            top: 16,
            left: 20,
            child: _GlowOrb(
              size: 96,
              color: Colors.white.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            bottom: -38,
            right: -18,
            child: _GlowOrb(
              size: 170,
              color: style.glowColor.withValues(alpha: 0.46),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 24,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final topTag = _featuredHeroTag(item);
    final supportingLine = _supportingLine();
    final metadataLine = _metadataLine();
    final compensationLabel = _compensationLineFor(item)?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight =
            constraints.maxHeight < 220 || constraints.maxWidth < 304;
        final denseLayout =
            isTight ||
            item.title.length > 22 ||
            supportingLine.length > 26 ||
            (metadataLine?.length ?? 0) > 24;
        final cardPadding = denseLayout
            ? EdgeInsets.fromLTRB(
                isTight ? 14 : 18,
                isTight ? 14 : 16,
                isTight ? 14 : 18,
                isTight ? 12 : 14,
              )
            : const EdgeInsets.fromLTRB(20, 20, 20, 18);
        final logoSize = denseLayout
            ? (isTight ? 38.0 : 42.0)
            : (isTight ? 40.0 : 46.0);
        final titleFontSize = denseLayout
            ? (isTight ? 18.2 : 21.0)
            : (isTight ? 19.2 : 23.0);
        final supportingFontSize = denseLayout
            ? (isTight ? 11.4 : 12.1)
            : (isTight ? 11.8 : 12.8);
        final metadataFontSize = denseLayout
            ? (isTight ? 10.0 : 10.8)
            : (isTight ? 10.4 : 11.2);
        final compensationFontSize = denseLayout
            ? (isTight ? 12.0 : 13.4)
            : (isTight ? 12.6 : 14.6);
        final cardRadiusValue = isTight ? 24.0 : 30.0;
        final cardRadius = BorderRadius.circular(cardRadiusValue);
        final hasCompensation =
            compensationLabel != null && compensationLabel.isNotEmpty;
        final actionLabel = statusData?.label ?? 'Apply Now';
        final useStackedFooter =
            constraints.maxWidth < 286 ||
            ((compensationLabel?.length ?? 0) > (isTight ? 18 : 20) &&
                constraints.maxWidth < 316);
        final compensationWidget = !hasCompensation
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: isTight ? 13 : 15,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  SizedBox(width: isTight ? 6 : 8),
                  Flexible(
                    child: Text(
                      compensationLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compensationFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.96),
                        height: 1.08,
                      ),
                    ),
                  ),
                ],
              );
        final footer = useStackedFooter
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...?compensationWidget == null
                      ? null
                      : <Widget>[
                          compensationWidget,
                          SizedBox(height: isTight ? 8 : 10),
                        ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: _InternshipFeaturedCtaButton(
                      label: actionLabel,
                      icon: statusData?.icon,
                      accentColor: statusData?.color,
                      onTap: onAction,
                      backgroundColors: style.buttonGradientColors,
                      textColor: style.buttonTextColor,
                      compact: denseLayout,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: compensationWidget == null
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: compensationWidget,
                          ),
                  ),
                  SizedBox(width: isTight ? 10 : 12),
                  _InternshipFeaturedCtaButton(
                    label: actionLabel,
                    icon: statusData?.icon,
                    accentColor: statusData?.color,
                    onTap: onAction,
                    backgroundColors: style.buttonGradientColors,
                    textColor: style.buttonTextColor,
                    compact: denseLayout,
                  ),
                ],
              );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardRadius,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: style.gradientColors,
                  begin: style.gradientBegin,
                  end: style.gradientEnd,
                ),
                borderRadius: cardRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: style.glowColor.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: cardRadius,
                child: Stack(
                  children: [
                    ..._buildDecorations(),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              style.accentColor.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTight ? 2.5 : 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    isTight ? 18 : 20,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.30),
                                      Colors.white.withValues(alpha: 0.10),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: _CompanyLogoTile(
                                  logoUrl: item.logoUrl,
                                  fallbackLabel: item.fallbackLabel,
                                  size: logoSize,
                                  borderRadius: isTight ? 15 : 17,
                                  backgroundColor: style.logoSurface,
                                  foregroundColor: style.logoForeground,
                                ),
                              ),
                              const Spacer(),
                              if (topTag != null) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: denseLayout
                                        ? (isTight ? 8 : 10)
                                        : (isTight ? 10 : 12),
                                    vertical: denseLayout
                                        ? (isTight ? 5 : 6)
                                        : (isTight ? 6 : 8),
                                  ),
                                  decoration: BoxDecoration(
                                    color: style.badgeBackground,
                                    borderRadius: BorderRadius.circular(
                                      denseLayout
                                          ? (isTight ? 12 : 14)
                                          : (isTight ? 14 : 16),
                                    ),
                                    border: Border.all(
                                      color: style.badgeBorderColor,
                                    ),
                                  ),
                                  child: Text(
                                    topTag,
                                    style: GoogleFonts.poppins(
                                      fontSize: denseLayout
                                          ? (isTight ? 8.4 : 9.2)
                                          : (isTight ? 9 : 10),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTight ? 8 : 10),
                              ],
                              _BookmarkIconButton(
                                isSaved: item.isSaved,
                                isSaving: isSaving,
                                onTap: onToggleSaved,
                                size: denseLayout
                                    ? (isTight ? 32 : 34)
                                    : (isTight ? 34 : 36),
                                iconSize: denseLayout
                                    ? (isTight ? 16 : 17)
                                    : (isTight ? 17 : 18),
                                borderRadius: denseLayout
                                    ? (isTight ? 12 : 14)
                                    : (isTight ? 13 : 15),
                                activeColor: Colors.white,
                                activeBackgroundColor: Colors.white.withValues(
                                  alpha: 0.20,
                                ),
                                activeBorderColor: Colors.white.withValues(
                                  alpha: 0.28,
                                ),
                                inactiveColor: Colors.white,
                                inactiveBackgroundColor: Colors.white
                                    .withValues(alpha: 0.12),
                                inactiveBorderColor: Colors.white.withValues(
                                  alpha: 0.20,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              height: denseLayout ? 1.04 : 1.10,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: denseLayout
                                ? (isTight ? 6 : 8)
                                : (isTight ? 8 : 10),
                          ),
                          Text(
                            supportingLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: supportingFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          if (metadataLine != null &&
                              metadataLine.trim().isNotEmpty) ...[
                            SizedBox(
                              height: denseLayout
                                  ? (isTight ? 3 : 4)
                                  : (isTight ? 4 : 6),
                            ),
                            Text(
                              metadataLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: metadataFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.80),
                              ),
                            ),
                          ],
                          SizedBox(
                            height: denseLayout
                                ? (isTight ? 10 : 14)
                                : (isTight ? 12 : 18),
                          ),
                          footer,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InternshipFeaturedCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accentColor;
  final List<Color> backgroundColors;
  final Color textColor;
  final bool compact;

  const _InternshipFeaturedCtaButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.accentColor,
    required this.backgroundColors,
    required this.textColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTextColor = accentColor ?? textColor;
    final resolvedBackgroundColors = accentColor == null
        ? backgroundColors
        : [
            AppColors.isDark ? AppColors.current.surfaceElevated : Colors.white,
            AppColors.isDark ? AppColors.current.surfaceElevated : Colors.white,
          ];
    final resolvedBorderColor =
        accentColor?.withValues(alpha: 0.52) ??
        Colors.white.withValues(alpha: 0.58);
    final resolvedShadows = accentColor == null
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: accentColor!.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ];

    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null && accentColor == null ? 0.82 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 13,
                vertical: compact ? 6 : 7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: resolvedBackgroundColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(compact ? 16 : 18),
                border: Border.all(color: resolvedBorderColor),
                boxShadow: resolvedShadows,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: compact ? 11.5 : 12.5,
                      color: resolvedTextColor,
                    ),
                    SizedBox(width: compact ? 5 : 6),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 10.2 : 11.2,
                      fontWeight: FontWeight.w800,
                      color: resolvedTextColor,
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

enum _AvailableInternshipDecorationStyle {
  cornerBloom,
  topMist,
  dotMatrix,
  ribbonLoop,
}

class _AvailableInternshipPalette {
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Color accentColor;
  final Color borderColor;
  final Color surfaceTint;
  final Color glowColor;
  final _AvailableInternshipDecorationStyle decorationStyle;

  const _AvailableInternshipPalette({
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.accentColor,
    required this.borderColor,
    required this.surfaceTint,
    required this.glowColor,
    required this.decorationStyle,
  });
}

_AvailableInternshipPalette _availableInternshipPaletteFor(String uniqueKey) {
  final colors = AppColors.current;

  if (colors.isDarkMode) {
    final darkPalettes = <_AvailableInternshipPalette>[
      _AvailableInternshipPalette(
        gradientColors: [
          Color.alphaBlend(
            _InternshipVisualPalette.deepTeal.withValues(alpha: 0.10),
            colors.surfaceElevated,
          ),
          Color.alphaBlend(
            _InternshipVisualPalette.mint.withValues(alpha: 0.08),
            colors.surfaceMuted,
          ),
          colors.surface,
        ],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: _InternshipVisualPalette.deepTeal,
        borderColor: colors.border,
        surfaceTint: Color.alphaBlend(
          _InternshipVisualPalette.mint.withValues(alpha: 0.14),
          colors.surfaceMuted,
        ),
        glowColor: _InternshipVisualPalette.glowMint,
        decorationStyle: _AvailableInternshipDecorationStyle.cornerBloom,
      ),
      _AvailableInternshipPalette(
        gradientColors: [
          Color.alphaBlend(
            _InternshipVisualPalette.oceanTeal.withValues(alpha: 0.12),
            colors.surfaceElevated,
          ),
          colors.surfaceMuted,
          colors.surface,
        ],
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomRight,
        accentColor: _InternshipVisualPalette.oceanTeal,
        borderColor: colors.border,
        surfaceTint: Color.alphaBlend(
          _InternshipVisualPalette.oceanTeal.withValues(alpha: 0.14),
          colors.surfaceMuted,
        ),
        glowColor: _InternshipVisualPalette.oceanTeal,
        decorationStyle: _AvailableInternshipDecorationStyle.topMist,
      ),
      _AvailableInternshipPalette(
        gradientColors: [
          colors.surfaceElevated,
          Color.alphaBlend(
            _InternshipVisualPalette.deepTeal.withValues(alpha: 0.10),
            colors.surfaceMuted,
          ),
          colors.surface,
        ],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomCenter,
        accentColor: _InternshipVisualPalette.deepTeal,
        borderColor: colors.border,
        surfaceTint: Color.alphaBlend(
          _InternshipVisualPalette.deepTeal.withValues(alpha: 0.12),
          colors.surfaceMuted,
        ),
        glowColor: _InternshipVisualPalette.glowMint,
        decorationStyle: _AvailableInternshipDecorationStyle.dotMatrix,
      ),
      _AvailableInternshipPalette(
        gradientColors: [
          colors.surfaceMuted,
          Color.alphaBlend(
            _InternshipVisualPalette.mint.withValues(alpha: 0.09),
            colors.surfaceElevated,
          ),
          colors.surface,
        ],
        gradientBegin: Alignment.topRight,
        gradientEnd: Alignment.bottomLeft,
        accentColor: _InternshipVisualPalette.deepTeal,
        borderColor: colors.border,
        surfaceTint: Color.alphaBlend(
          _InternshipVisualPalette.mint.withValues(alpha: 0.12),
          colors.surfaceMuted,
        ),
        glowColor: _InternshipVisualPalette.glowMint,
        decorationStyle: _AvailableInternshipDecorationStyle.ribbonLoop,
      ),
    ];

    return darkPalettes[uniqueKey.hashCode.abs() % darkPalettes.length];
  }

  final palettes = <_AvailableInternshipPalette>[
    _AvailableInternshipPalette(
      gradientColors: [Color(0xFFF3FCF9), Color(0xFFEAF8F4), Color(0xFFDEF4EE)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      accentColor: _InternshipVisualPalette.deepTeal,
      borderColor: Color(0xFFD6EEE8),
      surfaceTint: Color(0xFFD9F1EB),
      glowColor: Color(0xFFC6EFE7),
      decorationStyle: _AvailableInternshipDecorationStyle.cornerBloom,
    ),
    _AvailableInternshipPalette(
      gradientColors: [Color(0xFFF4FCFA), Color(0xFFEAF9F6), Color(0xFFE1F5F1)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomRight,
      accentColor: _InternshipVisualPalette.oceanTeal,
      borderColor: Color(0xFFD5EFEB),
      surfaceTint: Color(0xFFDDF4F0),
      glowColor: Color(0xFFCAF1EA),
      decorationStyle: _AvailableInternshipDecorationStyle.topMist,
    ),
    _AvailableInternshipPalette(
      gradientColors: [Color(0xFFF3FCF9), Color(0xFFE9F8F5), Color(0xFFDFF3EF)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomCenter,
      accentColor: Color(0xFF0F766E),
      borderColor: Color(0xFFD7EEEA),
      surfaceTint: Color(0xFFDFF4F0),
      glowColor: Color(0xFFCBEFEA),
      decorationStyle: _AvailableInternshipDecorationStyle.dotMatrix,
    ),
    _AvailableInternshipPalette(
      gradientColors: [Color(0xFFF2FBF8), Color(0xFFE8F8F4), Color(0xFFDBF1EC)],
      gradientBegin: Alignment.topRight,
      gradientEnd: Alignment.bottomLeft,
      accentColor: Color(0xFF115E59),
      borderColor: Color(0xFFD4ECE7),
      surfaceTint: Color(0xFFD8F0EA),
      glowColor: Color(0xFFC3ECE3),
      decorationStyle: _AvailableInternshipDecorationStyle.ribbonLoop,
    ),
  ];

  return palettes[uniqueKey.hashCode.abs() % palettes.length];
}

List<Widget> _buildAvailableInternshipDecorations({
  required _AvailableInternshipPalette palette,
  required bool listLayout,
}) {
  switch (palette.decorationStyle) {
    case _AvailableInternshipDecorationStyle.cornerBloom:
      return [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: listLayout
                    ? const Alignment(0.92, -0.14)
                    : const Alignment(0.96, -0.18),
                radius: listLayout ? 1.18 : 1.08,
                colors: [
                  palette.glowColor.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -18,
          right: -16,
          child: _GlowOrb(
            size: listLayout ? 116 : 92,
            color: palette.glowColor.withValues(alpha: 0.16),
          ),
        ),
      ];
    case _AvailableInternshipDecorationStyle.topMist:
      return [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: listLayout ? 56 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.58),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          right: -18,
          top: 22,
          child: _GlowOrb(
            size: listLayout ? 108 : 86,
            color: palette.glowColor.withValues(alpha: 0.18),
          ),
        ),
      ];
    case _AvailableInternshipDecorationStyle.dotMatrix:
      return [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.26),
                  Colors.transparent,
                  palette.glowColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ];
    case _AvailableInternshipDecorationStyle.ribbonLoop:
      return [
        Positioned(
          top: 10,
          right: 14,
          child: Transform.rotate(
            angle: 0.24,
            child: Container(
              width: listLayout ? 76 : 60,
              height: listLayout ? 130 : 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          left: -8,
          child: _DecorativeLineArtLoop(
            width: listLayout ? 86 : 70,
            height: listLayout ? 86 : 70,
            color: palette.glowColor.withValues(alpha: 0.24),
          ),
        ),
      ];
  }
}

class _AvailableInternshipCard extends StatelessWidget {
  final _InternshipCardModel item;
  final _InternshipStatusData? statusData;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;
  final bool isSaving;

  const _AvailableInternshipCard({
    required this.item,
    this.statusData,
    this.onTap,
    this.onToggleSaved,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final compact = screenSize.width < 390 || screenSize.height < 780;
    final palette = _availableInternshipPaletteFor(item.uniqueKey);
    final compensationLabel = _compensationLineFor(item);
    final topBadge = _availableTopBadge(item);
    final cardRadius = BorderRadius.circular(compact ? 20 : 24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette.gradientColors,
              begin: palette.gradientBegin,
              end: palette.gradientEnd,
            ),
            borderRadius: cardRadius,
            border: Border.all(
              color: palette.accentColor.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.glowColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTight =
                    compact ||
                    constraints.maxWidth < 170 ||
                    constraints.maxHeight < 172;
                final cardPadding = EdgeInsets.fromLTRB(
                  isTight ? 11 : 13,
                  isTight ? 10 : 12,
                  isTight ? 11 : 13,
                  isTight ? 9 : 11,
                );
                final iconTileSize = isTight ? 32.0 : 36.0;
                final titleSize = isTight ? 12.5 : 13.6;
                final subtitleSize = isTight ? 9.6 : 10.3;
                final detailSize = isTight ? 9.0 : 9.8;
                final chipSize = isTight ? 8.6 : 9.1;

                return Stack(
                  children: [
                    ..._buildAvailableInternshipDecorations(
                      palette: palette,
                      listLayout: false,
                    ),
                    Padding(
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: iconTileSize,
                                height: iconTileSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.isDark
                                          ? AppColors.current.surfaceElevated
                                          : Colors.white.withValues(
                                              alpha: 0.94,
                                            ),
                                      palette.surfaceTint,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isTight ? 12 : 14,
                                  ),
                                  border: Border.all(
                                    color: palette.accentColor.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),
                                child: _CompanyLogoTile(
                                  logoUrl: item.logoUrl,
                                  fallbackLabel: item.fallbackLabel,
                                  size: iconTileSize,
                                  borderRadius: isTight ? 12 : 14,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: palette.accentColor,
                                ),
                              ),
                              const Spacer(),
                              if (topBadge != null)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.34,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTight ? 7 : 8,
                                      vertical: isTight ? 4 : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.accentColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        isTight ? 10 : 11,
                                      ),
                                      border: Border.all(
                                        color: palette.accentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      topBadge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: chipSize,
                                        fontWeight: FontWeight.w700,
                                        color: palette.accentColor,
                                        letterSpacing: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(width: isTight ? 6 : 7),
                              _BookmarkIconButton(
                                isSaved: item.isSaved,
                                isSaving: isSaving,
                                onTap: onToggleSaved,
                                size: isTight ? 26 : 28,
                                iconSize: isTight ? 14 : 15,
                                borderRadius: isTight ? 10 : 11,
                                activeColor: Colors.white,
                                activeBackgroundColor: palette.accentColor,
                                activeBorderColor: palette.accentColor,
                                inactiveColor: palette.accentColor,
                                inactiveBackgroundColor: AppColors.isDark
                                    ? AppColors.current.surfaceMuted
                                    : Colors.white.withValues(alpha: 0.82),
                                inactiveBorderColor: palette.accentColor
                                    .withValues(alpha: 0.10),
                              ),
                            ],
                          ),
                          SizedBox(height: isTight ? 6 : 8),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              color: OpportunityDashboardPalette.textPrimary,
                            ),
                          ),
                          SizedBox(height: isTight ? 2 : 3),
                          Text(
                            item.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w600,
                              color: OpportunityDashboardPalette.textSecondary,
                            ),
                          ),
                          SizedBox(height: isTight ? 5 : 6),
                          if (item.location != null &&
                              item.location!.trim().isNotEmpty) ...[
                            _InternshipMetaLine(
                              icon: Icons.place_rounded,
                              text: item.location!,
                              iconColor: palette.accentColor,
                              textColor:
                                  OpportunityDashboardPalette.textSecondary,
                              fontSize: detailSize,
                              iconSize: isTight ? 12.5 : 13.5,
                            ),
                            SizedBox(height: isTight ? 4 : 5),
                          ] else if (item.workMode != null &&
                              item.workMode!.trim().isNotEmpty) ...[
                            _InternshipMetaLine(
                              icon: Icons.laptop_chromebook_rounded,
                              text: item.workMode!,
                              iconColor: palette.accentColor,
                              textColor:
                                  OpportunityDashboardPalette.textSecondary,
                              fontSize: detailSize,
                              iconSize: isTight ? 12.5 : 13.5,
                            ),
                            SizedBox(height: isTight ? 4 : 5),
                          ],
                          if (compensationLabel != null)
                            _InternshipMetaLine(
                              icon: Icons.payments_rounded,
                              text: compensationLabel,
                              iconColor: palette.accentColor,
                              textColor: palette.accentColor,
                              fontSize: detailSize,
                              iconSize: isTight ? 12.5 : 13.5,
                            ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: statusData != null
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: _InternshipStatusChip(
                                          label: statusData!.label,
                                          color: statusData!.color,
                                          icon: statusData!.icon,
                                          compact: isTight,
                                        ),
                                      )
                                    : item.duration?.trim().isNotEmpty ?? false
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTight ? 7 : 8,
                                            vertical: isTight ? 4 : 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.accentColor
                                                .withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(
                                              isTight ? 11 : 12,
                                            ),
                                            border: Border.all(
                                              color: palette.accentColor
                                                  .withValues(alpha: 0.10),
                                            ),
                                          ),
                                          child: Text(
                                            item.duration!.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: chipSize,
                                              fontWeight: FontWeight.w700,
                                              color: palette.accentColor,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Container(
                                width: isTight ? 28 : 30,
                                height: isTight ? 28 : 30,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      palette.accentColor,
                                      palette.accentColor.withValues(
                                        alpha: 0.78,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableInternshipListTile extends StatelessWidget {
  final _InternshipCardModel item;
  final _InternshipStatusData? statusData;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;
  final bool isSaving;

  const _AvailableInternshipListTile({
    required this.item,
    this.statusData,
    this.onTap,
    this.onToggleSaved,
    required this.isSaving,
  });

  String _supportingLine() {
    final companyName = item.companyName.trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }

    final secondary = item.secondaryText.trim().replaceAll('|', '•');
    return secondary.isEmpty ? item.secondaryText.trim() : secondary;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final compact = screenSize.width < 390 || screenSize.height < 780;
    final palette = _availableInternshipPaletteFor(item.uniqueKey);
    final compensationLabel = _compensationLineFor(item);
    final topBadge = _availableTopBadge(item);
    final cardRadius = BorderRadius.circular(compact ? 17 : 19);
    final supportingLine = _supportingLine();
    final detailText = item.location?.trim().isNotEmpty ?? false
        ? item.location!.trim()
        : item.workMode?.trim();
    final showInlineBadge =
        topBadge != null &&
        topBadge.trim().isNotEmpty &&
        topBadge.trim().toUpperCase() !=
            (item.duration?.trim().toUpperCase() ?? '');
    final topSurface = Color.alphaBlend(
      palette.surfaceTint.withValues(alpha: 0.24),
      AppColors.isDark
          ? AppColors.current.surfaceElevated
          : const Color(0xFFFCFFFE),
    );
    final bottomSurface = Color.alphaBlend(
      palette.surfaceTint.withValues(alpha: 0.34),
      AppColors.isDark ? AppColors.current.surface : const Color(0xFFF1FBF8),
    );
    final iconSurface = Color.alphaBlend(
      palette.surfaceTint.withValues(alpha: 0.48),
      AppColors.isDark ? AppColors.current.surfaceElevated : Colors.white,
    );
    final metadataItems = <Widget>[
      if (compensationLabel?.trim().isNotEmpty ?? false)
        _AvailableInternshipListMetaItem(
          text: compensationLabel!.trim(),
          icon: Icons.payments_rounded,
          color: palette.accentColor,
          compact: compact,
          emphasize: true,
        ),
      if (detailText != null && detailText.isNotEmpty)
        _AvailableInternshipListMetaItem(
          text: detailText,
          icon: item.location?.trim().isNotEmpty ?? false
              ? Icons.place_rounded
              : Icons.laptop_chromebook_rounded,
          color: _InternshipVisualPalette.textSecondary,
          compact: compact,
        ),
      if (item.duration?.trim().isNotEmpty ?? false)
        _AvailableInternshipListMetaItem(
          text: item.duration!.trim(),
          color: palette.accentColor.withValues(alpha: 0.82),
          compact: compact,
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [topSurface, bottomSurface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: cardRadius,
            border: Border.all(
              color: palette.accentColor.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.glowColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -22,
                  bottom: -30,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 11 : 13,
                    compact ? 11 : 12,
                    compact ? 11 : 13,
                    compact ? 11 : 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: iconSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: palette.accentColor.withValues(alpha: 0.10),
                          ),
                        ),
                        child: _CompanyLogoTile(
                          logoUrl: item.logoUrl,
                          fallbackLabel: item.fallbackLabel,
                          size: compact ? 34 : 38,
                          borderRadius: 14,
                          backgroundColor: Colors.transparent,
                          foregroundColor: palette.accentColor,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: compact ? 13.6 : 14.6,
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                      color: OpportunityDashboardPalette
                                          .textPrimary,
                                    ),
                                  ),
                                ),
                                if (showInlineBadge) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    topBadge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: compact ? 9.0 : 9.6,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.24,
                                      color: palette.accentColor.withValues(
                                        alpha: 0.80,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              supportingLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: compact ? 10.6 : 11.2,
                                fontWeight: FontWeight.w600,
                                color:
                                    OpportunityDashboardPalette.textSecondary,
                              ),
                            ),
                            SizedBox(height: compact ? 5 : 6),
                            Wrap(
                              spacing: compact ? 9 : 11,
                              runSpacing: compact ? 3 : 4,
                              children: metadataItems,
                            ),
                            if (statusData != null) ...[
                              SizedBox(height: compact ? 6 : 7),
                              _InternshipStatusChip(
                                label: statusData!.label,
                                color: statusData!.color,
                                icon: statusData!.icon,
                                compact: compact,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BookmarkIconButton(
                            isSaved: item.isSaved,
                            isSaving: isSaving,
                            onTap: onToggleSaved,
                            size: compact ? 28 : 30,
                            iconSize: compact ? 15 : 16,
                            borderRadius: compact ? 11 : 12,
                            activeColor: Colors.white,
                            activeBackgroundColor: palette.accentColor,
                            activeBorderColor: palette.accentColor,
                            inactiveColor: palette.accentColor,
                            inactiveBackgroundColor: AppColors.isDark
                                ? AppColors.current.surfaceMuted
                                : Colors.white.withValues(alpha: 0.82),
                            inactiveBorderColor: palette.accentColor.withValues(
                              alpha: 0.10,
                            ),
                          ),
                          SizedBox(width: compact ? 7 : 8),
                          Container(
                            width: compact ? 28 : 30,
                            height: compact ? 28 : 30,
                            decoration: BoxDecoration(
                              color: palette.accentColor.withValues(
                                alpha: 0.10,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: palette.accentColor.withValues(
                                alpha: 0.82,
                              ),
                              size: compact ? 15 : 16,
                            ),
                          ),
                        ],
                      ),
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
}

class _AvailableInternshipListMetaItem extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool compact;
  final bool emphasize;

  const _AvailableInternshipListMetaItem({
    required this.text,
    required this.color,
    this.icon,
    required this.compact,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 12 : 13, color: color),
          SizedBox(width: compact ? 4 : 5),
        ],
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: compact ? 9.8 : 10.4,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            color: color,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _InternshipViewToggle extends StatelessWidget {
  final _InternshipsViewMode viewMode;
  final ValueChanged<_InternshipsViewMode> onChanged;

  const _InternshipViewToggle({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InternshipToggleIconButton(
            icon: Icons.grid_view_rounded,
            isActive: viewMode == _InternshipsViewMode.grid,
            onTap: () => onChanged(_InternshipsViewMode.grid),
          ),
          const SizedBox(width: 4),
          _InternshipToggleIconButton(
            icon: Icons.view_list_rounded,
            isActive: viewMode == _InternshipsViewMode.list,
            onTap: () => onChanged(_InternshipsViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _InternshipToggleIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _InternshipToggleIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppColors.current.surfaceElevated,
                      AppColors.current.secondarySoft,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? _InternshipVisualPalette.mint.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _InternshipVisualPalette.glowMint.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? _InternshipVisualPalette.deepTeal
                : _InternshipVisualPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InternshipMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final double fontSize;
  final double iconSize;

  const _InternshipMetaLine({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.fontSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _DecorativeLineArtLoop extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _DecorativeLineArtLoop({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.32),
        border: Border.all(color: color, width: 1.4),
      ),
    );
  }
}

class _BookmarkIconButton extends StatelessWidget {
  final bool isSaved;
  final bool isSaving;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? activeColor;
  final Color? activeBackgroundColor;
  final Color? activeBorderColor;
  final Color? inactiveColor;
  final Color? inactiveBackgroundColor;
  final Color? inactiveBorderColor;

  const _BookmarkIconButton({
    required this.isSaved,
    required this.isSaving,
    required this.onTap,
    this.size = 34,
    this.iconSize = 18,
    this.borderRadius = 14,
    this.activeColor,
    this.activeBackgroundColor,
    this.activeBorderColor,
    this.inactiveColor,
    this.inactiveBackgroundColor,
    this.inactiveBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedActiveColor =
        activeColor ?? _InternshipVisualPalette.deepTeal;
    final resolvedInactiveColor =
        inactiveColor ?? _InternshipVisualPalette.textSecondary;
    final resolvedActiveBackgroundColor =
        activeBackgroundColor ??
        _InternshipVisualPalette.deepTeal.withValues(alpha: 0.12);
    final resolvedInactiveBackgroundColor =
        inactiveBackgroundColor ?? _InternshipVisualPalette.surface;
    final resolvedActiveBorderColor =
        activeBorderColor ?? _InternshipVisualPalette.border;
    final resolvedInactiveBorderColor =
        inactiveBorderColor ?? _InternshipVisualPalette.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isSaved
                ? resolvedActiveBackgroundColor
                : resolvedInactiveBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSaved
                  ? resolvedActiveBorderColor
                  : resolvedInactiveBorderColor,
            ),
          ),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: iconSize,
            color: isSaved ? resolvedActiveColor : resolvedInactiveColor,
          ),
        ),
      ),
    );
  }
}

class _CompanyLogoTile extends StatelessWidget {
  final String logoUrl;
  final String fallbackLabel;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double borderRadius;

  const _CompanyLogoTile({
    required this.logoUrl,
    required this.fallbackLabel,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 48,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: logoUrl.isEmpty ? EdgeInsets.zero : EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                fallbackLabel,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => Center(
                child: Text(
                  fallbackLabel,
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
    );
  }
}

class _InternshipsEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InternshipsEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.current.secondarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _InternshipVisualPalette.mint.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              Icons.school_outlined,
              color: _InternshipVisualPalette.deepTeal,
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
                  style: GoogleFonts.poppins(
                    fontSize: 13.4,
                    fontWeight: FontWeight.w700,
                    color: _InternshipVisualPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.2,
                    height: 1.4,
                    color: _InternshipVisualPalette.textSecondary,
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

class _QuickFilterDefinition {
  final _InternshipQuickFilter value;
  final String label;

  const _QuickFilterDefinition({required this.value, required this.label});
}

class _InternshipCardModel {
  final String id;
  final String title;
  final String companyName;
  final String companyLabel;
  final String secondaryText;
  final String logoUrl;
  final String fallbackLabel;
  final String? workMode;
  final String? location;
  final DateTime? deadline;
  final int? daysUntilDeadline;
  final String? deadlinePill;
  final String applyByText;
  final bool isPaid;
  final String? compensation;
  final String? duration;
  final String? categoryLabel;
  final bool isFeaturedPreferred;
  final bool matchesSummer;
  final bool matchesTech;
  final bool matchesMarketing;
  final DateTime? createdAt;
  final String searchText;
  final OpportunityModel? opportunity;
  final bool isSaved;

  const _InternshipCardModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyLabel,
    required this.secondaryText,
    required this.logoUrl,
    required this.fallbackLabel,
    required this.workMode,
    required this.location,
    required this.deadline,
    required this.daysUntilDeadline,
    required this.deadlinePill,
    required this.applyByText,
    required this.isPaid,
    required this.compensation,
    required this.duration,
    required this.categoryLabel,
    required this.isFeaturedPreferred,
    required this.matchesSummer,
    required this.matchesTech,
    required this.matchesMarketing,
    required this.createdAt,
    required this.searchText,
    required this.opportunity,
    required this.isSaved,
  });

  String get uniqueKey => id.isEmpty ? '$title|$companyName' : id;
}

String? _featuredHeroTag(_InternshipCardModel item) {
  if (item.workMode != null && item.workMode!.trim().isNotEmpty) {
    return item.workMode!.toUpperCase();
  }
  if (item.duration != null && item.duration!.trim().isNotEmpty) {
    return item.duration!.trim().toUpperCase();
  }
  if (item.isPaid) {
    return 'PAID';
  }
  return null;
}

String? _compensationLineFor(_InternshipCardModel item) {
  final compensation = item.compensation?.trim();
  if (compensation != null && compensation.isNotEmpty) {
    return compensation;
  }
  return item.isPaid ? 'Paid internship' : null;
}

String? _availableTopBadge(_InternshipCardModel item) {
  if (item.workMode != null && item.workMode!.trim().isNotEmpty) {
    return item.workMode!.toUpperCase();
  }
  if (item.duration != null && item.duration!.trim().isNotEmpty) {
    return item.duration!.trim().toUpperCase();
  }
  if (item.isPaid) {
    return 'PAID';
  }
  return null;
}

_InternshipStatusData? _internshipStatusDataForOpportunity(
  OpportunityModel? opportunity,
  Map<String, String> appliedStatuses,
  AppLocalizations l10n,
) {
  if (opportunity == null) {
    return null;
  }

  final applicationStatus = appliedStatuses[opportunity.id];
  if (applicationStatus != null) {
    return _InternshipStatusData(
      label: ApplicationStatus.label(applicationStatus, l10n),
      color: ApplicationStatus.color(applicationStatus),
      icon: _internshipApplicationStatusIcon(applicationStatus),
    );
  }

  if (!opportunity.isVisibleToStudents()) {
    return _InternshipStatusData(
      label: l10n.uiUnavailable,
      color: const Color(0xFF64748B),
      icon: Icons.visibility_off_rounded,
    );
  }

  final normalizedStatus = opportunity.effectiveStatus();
  if (normalizedStatus.isNotEmpty && normalizedStatus != 'open') {
    return _InternshipStatusData(
      label: l10n.uiClosed,
      color: const Color(0xFF64748B),
      icon: Icons.lock_outline_rounded,
    );
  }

  return null;
}

IconData _internshipApplicationStatusIcon(String status) {
  switch (ApplicationStatus.parse(status)) {
    case ApplicationStatus.accepted:
      return Icons.check_circle_rounded;
    case ApplicationStatus.rejected:
      return Icons.cancel_rounded;
    case ApplicationStatus.pending:
    default:
      return Icons.hourglass_top_rounded;
  }
}

class _InternshipStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool compact;

  const _InternshipStatusChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 11 : 12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 13, color: color),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: compact ? 8.8 : 9.4,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InternshipStatusData {
  final String label;
  final Color color;
  final IconData icon;

  const _InternshipStatusData({
    required this.label,
    required this.color,
    required this.icon,
  });
}
