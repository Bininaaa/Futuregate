import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications_screen.dart';
import 'opportunity_detail_screen.dart';

class InternshipsScreen extends StatefulWidget {
  const InternshipsScreen({super.key});

  @override
  State<InternshipsScreen> createState() => _InternshipsScreenState();
}

enum _InternshipQuickFilter { remote, paid, summer, tech, marketing }

class _InternshipsScreenState extends State<InternshipsScreen> {
  static const List<_QuickFilterDefinition> _quickFilters = [
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.remote,
      label: 'Remote',
    ),
    _QuickFilterDefinition(value: _InternshipQuickFilter.paid, label: 'Paid'),
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.summer,
      label: 'Summer',
    ),
    _QuickFilterDefinition(value: _InternshipQuickFilter.tech, label: 'Tech'),
    _QuickFilterDefinition(
      value: _InternshipQuickFilter.marketing,
      label: 'Marketing',
    ),
  ];
  static const List<Color> _weeklyAccentColors = [
    OpportunityDashboardPalette.accent,
    OpportunityDashboardPalette.primary,
    OpportunityDashboardPalette.secondary,
    OpportunityDashboardPalette.primaryDark,
    OpportunityDashboardPalette.warning,
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _popularSectionKey = GlobalKey();

  String _searchQuery = '';
  _InternshipQuickFilter? _selectedQuickFilter;

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
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[opportunityProvider.fetchOpportunities()];

    if (userId != null &&
        userId.isNotEmpty &&
        (force || savedProvider.savedOpportunities.isEmpty)) {
      futures.add(savedProvider.fetchSavedOpportunities(userId));
    }

    await Future.wait(futures);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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

  Future<void> _toggleSavedOpportunity(OpportunityModel opportunity) async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final userId = authProvider.userModel?.uid;

    if (userId == null || userId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save internships'),
        ),
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
        title: opportunity.title,
        companyName: opportunity.companyName,
        type: opportunity.type,
        location: opportunity.location,
        deadline: opportunity.deadlineLabel,
      );
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(error ?? message)));
  }

  Future<void> _scrollToPopularSection() async {
    final sectionContext = _popularSectionKey.currentContext;
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

  void _clearFilters() {
    setState(() {
      _selectedQuickFilter = null;
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
      }
    });
  }

  List<_InternshipCardModel> _buildLiveInternships(
    List<OpportunityModel> opportunities,
    Set<String> savedIds,
  ) {
    return opportunities
        .where(
          (opportunity) =>
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

  List<_InternshipCardModel> _selectPopularInternships(
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
      title: opportunity.title.trim().isEmpty
          ? 'Open Internship'
          : opportunity.title.trim(),
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
      isPlaceholder: false,
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
    return trimmed.isEmpty ? 'AvenirDZ Partner' : trimmed;
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
    final label = OpportunityMetadata.buildCompensationLabel(
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      isPaid: opportunity.isPaid,
      preferCompensationText: true,
    );
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

  List<_InternshipBadgeData> _popularBadgesFor(_InternshipCardModel item) {
    final badges = <_InternshipBadgeData>[];

    if (item.isPaid) {
      badges.add(
        const _InternshipBadgeData(
          label: 'PAID',
          backgroundColor: Color(0xFFDCFCE7),
          foregroundColor: OpportunityDashboardPalette.success,
        ),
      );
    }

    if (item.workMode != null) {
      badges.add(
        _InternshipBadgeData(
          label: item.workMode!.toUpperCase(),
          backgroundColor: item.workMode == 'Remote'
              ? const Color(0xFFCCFBF1)
              : const Color(0xFFDBEAFE),
          foregroundColor: item.workMode == 'Remote'
              ? const Color(0xFF0F766E)
              : OpportunityDashboardPalette.primaryDark,
        ),
      );
    }

    if (item.duration != null && item.duration!.isNotEmpty) {
      badges.add(
        _InternshipBadgeData(
          label: item.duration!.toUpperCase(),
          backgroundColor: const Color(0xFFFFEDD5),
          foregroundColor: OpportunityDashboardPalette.accent,
        ),
      );
    }

    if (item.categoryLabel != null && item.categoryLabel!.isNotEmpty) {
      badges.add(
        _InternshipBadgeData(
          label: item.categoryLabel!.toUpperCase(),
          backgroundColor: const Color(0xFFEDE9FE),
          foregroundColor: OpportunityDashboardPalette.primary,
        ),
      );
    }

    if (badges.isEmpty) {
      badges.add(
        const _InternshipBadgeData(
          label: 'INTERNSHIP',
          backgroundColor: Color(0xFFE2E8F0),
          foregroundColor: OpportunityDashboardPalette.textSecondary,
        ),
      );
    }

    return badges.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final opportunityProvider = context.watch<OpportunityProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();
    final liveInternships = _buildLiveInternships(
      opportunityProvider.opportunities,
      savedIds,
    );
    final hasLiveData = liveInternships.isNotEmpty;
    final filteredInternships = hasLiveData
        ? _applyFilters(liveInternships)
        : const <_InternshipCardModel>[];
    final applyThisWeek = hasLiveData
        ? _selectApplyThisWeek(filteredInternships)
        : _placeholderWeeklyInternships;
    final popularInternships = hasLiveData
        ? _selectPopularInternships(filteredInternships)
        : _placeholderPopularInternships;
    final contentBottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: OpportunityDashboardPalette.background,
      body: Column(
        children: [
          _InternshipsHeaderBar(
            user: authProvider.userModel,
            unreadCount: notificationProvider.unreadCount,
            onNotificationsPressed: _openNotifications,
          ),
          if (opportunityProvider.isLoading && hasLiveData)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              color: OpportunityDashboardPalette.primary,
              backgroundColor: OpportunityDashboardPalette.surface,
              onRefresh: () => _loadData(force: true),
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16, 18, 16, contentBottomPadding),
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
                    filters: _quickFilters,
                    onSelected: (filter) {
                      setState(() {
                        _selectedQuickFilter = _selectedQuickFilter == filter
                            ? null
                            : filter;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Apply This Week',
                    actionLabel: 'View All',
                    showAccentDot: true,
                    onAction: _scrollToPopularSection,
                  ),
                  const SizedBox(height: 10),
                  if (hasLiveData && filteredInternships.isEmpty)
                    const _InternshipsEmptyState(
                      title: 'No internships match these filters',
                      subtitle:
                          'Try another search or remove a chip to reveal more opportunities.',
                    )
                  else
                    _ApplyThisWeekSection(
                      items: applyThisWeek,
                      accentColors: _weeklyAccentColors,
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
                    key: _popularSectionKey,
                    child: _SectionHeader(
                      title: 'Popular Internships',
                      actionLabel: 'View all',
                      onAction: _clearFilters,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (hasLiveData && filteredInternships.isEmpty)
                    const _InternshipsEmptyState(
                      title: 'Nothing to show right now',
                      subtitle:
                          'Live internships will appear here as soon as they match your search.',
                    )
                  else
                    ...popularInternships.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PopularInternshipCard(
                          item: item,
                          badges: _popularBadgesFor(item),
                          onTap: item.opportunity == null
                              ? null
                              : () => _openOpportunity(item.opportunity!),
                          onApply: item.opportunity == null
                              ? null
                              : () => _openOpportunity(item.opportunity!),
                          onToggleSaved: item.opportunity == null
                              ? null
                              : () =>
                                    _toggleSavedOpportunity(item.opportunity!),
                          isSaving: savedProvider.isLoading,
                        ),
                      ),
                    ),
                  if (!hasLiveData && opportunityProvider.isLoading) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Loading live internships...',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: OpportunityDashboardPalette.textSecondary,
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
    );
  }
}

class _InternshipsHeaderBar extends StatelessWidget {
  final UserModel? user;
  final int unreadCount;
  final VoidCallback onNotificationsPressed;

  const _InternshipsHeaderBar({
    required this.user,
    required this.unreadCount,
    required this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        border: Border(
          bottom: BorderSide(color: OpportunityDashboardPalette.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: OpportunityDashboardPalette.primary.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ),
                child: ProfileAvatar(user: user, radius: 14, fallbackName: 'I'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Internships',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.primary,
                  ),
                ),
              ),
              _NotificationBellButton(
                unreadCount: unreadCount,
                onTap: onNotificationsPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBellButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OpportunityDashboardPalette.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: OpportunityDashboardPalette.textPrimary,
                size: 21,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      color: OpportunityDashboardPalette.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

class _InternshipsIntro extends StatelessWidget {
  const _InternshipsIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Internships',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.05,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Explore learning opportunities designed for your growth.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: OpportunityDashboardPalette.textSecondary,
          ),
        ),
      ],
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
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: OpportunityDashboardPalette.textSecondary,
        ),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: OpportunityDashboardPalette.textSecondary,
                ),
              ),
        filled: true,
        fillColor: const Color(0xFFEEF2FF),
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
          borderSide: const BorderSide(
            color: OpportunityDashboardPalette.primary,
          ),
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
                    ? OpportunityDashboardPalette.secondary
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive
                      ? OpportunityDashboardPalette.secondary
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final bool showAccentDot;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.showAccentDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
              ),
              if (showAccentDot) ...[
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: OpportunityDashboardPalette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: OpportunityDashboardPalette.primary,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          child: Text(
            actionLabel,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: OpportunityDashboardPalette.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplyThisWeekSection extends StatelessWidget {
  final List<_InternshipCardModel> items;
  final List<Color> accentColors;
  final ValueChanged<_InternshipCardModel> onOpenOpportunity;
  final ValueChanged<_InternshipCardModel> onToggleSaved;
  final bool isSaving;

  const _ApplyThisWeekSection({
    required this.items,
    required this.accentColors,
    required this.onOpenOpportunity,
    required this.onToggleSaved,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.sizeOf(context).width * 0.60)
        .clamp(186.0, 208.0)
        .toDouble();

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final accentColor = accentColors[index % accentColors.length];

          return SizedBox(
            width: cardWidth,
            child: _WeeklyInternshipCard(
              item: item,
              accentColor: accentColor,
              onTap: item.opportunity == null
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

class _WeeklyInternshipCard extends StatelessWidget {
  final _InternshipCardModel item;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;
  final bool isSaving;

  const _WeeklyInternshipCard({
    required this.item,
    required this.accentColor,
    this.onTap,
    this.onToggleSaved,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CompanyLogoTile(
                                logoUrl: item.logoUrl,
                                fallbackLabel: item.fallbackLabel,
                                size: 28,
                                borderRadius: 10,
                                backgroundColor: accentColor.withValues(
                                  alpha: 0.12,
                                ),
                                foregroundColor: accentColor,
                              ),
                              const Spacer(),
                              _BookmarkIconButton(
                                isSaved: item.isSaved,
                                isSaving: isSaving,
                                onTap: onToggleSaved,
                                size: 24,
                                iconSize: 14,
                                borderRadius: 10,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.companyLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: OpportunityDashboardPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.08,
                              color: OpportunityDashboardPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item.deadlinePill != null)
                            _MiniPill(
                              label: item.deadlinePill!,
                              backgroundColor: const Color(0xFFFFF1E8),
                              foregroundColor:
                                  OpportunityDashboardPalette.accent,
                              fontSize: 9,
                              verticalPadding: 4,
                              horizontalPadding: 8,
                            ),
                          if (item.isPaid)
                            _MiniPill(
                              label: 'Paid',
                              backgroundColor: Color(0xFFDCFCE7),
                              foregroundColor:
                                  OpportunityDashboardPalette.success,
                              fontSize: 9,
                              verticalPadding: 4,
                              horizontalPadding: 8,
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
    );
  }
}

class _PopularInternshipCard extends StatelessWidget {
  final _InternshipCardModel item;
  final List<_InternshipBadgeData> badges;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSaved;
  final bool isSaving;

  const _PopularInternshipCard({
    required this.item,
    required this.badges,
    this.onTap,
    this.onApply,
    this.onToggleSaved,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.9),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogoAvatar(
                    logoUrl: item.logoUrl,
                    fallbackLabel: item.fallbackLabel,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: OpportunityDashboardPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: OpportunityDashboardPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BookmarkIconButton(
                    isSaved: item.isSaved,
                    isSaving: isSaving,
                    onTap: onToggleSaved,
                    size: 30,
                    iconSize: 16,
                    borderRadius: 12,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: badges
                      .map(
                        (badge) => _MiniPill(
                          label: badge.label,
                          backgroundColor: badge.backgroundColor,
                          foregroundColor: badge.foregroundColor,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: OpportunityDashboardPalette.border.withValues(
                  alpha: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: OpportunityDashboardPalette.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.applyByText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onApply,
                    child: Text(
                      'Apply Now',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.primary,
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

class _BookmarkIconButton extends StatelessWidget {
  final bool isSaved;
  final bool isSaving;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double borderRadius;

  const _BookmarkIconButton({
    required this.isSaved,
    required this.isSaving,
    required this.onTap,
    this.size = 34,
    this.iconSize = 18,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
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
                ? OpportunityDashboardPalette.primary.withValues(alpha: 0.10)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSaved
                  ? OpportunityDashboardPalette.primary.withValues(alpha: 0.16)
                  : OpportunityDashboardPalette.border,
            ),
          ),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: iconSize,
            color: isSaved
                ? OpportunityDashboardPalette.primary
                : OpportunityDashboardPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _MiniPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.fontSize = 11,
    this.horizontalPadding = 10,
    this.verticalPadding = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
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
              fit: BoxFit.cover,
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

class _CompanyLogoAvatar extends StatelessWidget {
  final String logoUrl;
  final String fallbackLabel;

  const _CompanyLogoAvatar({
    required this.logoUrl,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(
          color: OpportunityDashboardPalette.border.withValues(alpha: 0.9),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                fallbackLabel,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.primary,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(
                child: Text(
                  fallbackLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.primary,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: OpportunityDashboardPalette.primary,
              size: 20,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.4,
                    color: OpportunityDashboardPalette.textSecondary,
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

class _InternshipBadgeData {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _InternshipBadgeData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
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
  final bool isPlaceholder;

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
    required this.isPlaceholder,
  });

  factory _InternshipCardModel.placeholder({
    required String id,
    required String title,
    required String companyName,
    required String companyLabel,
    required String secondaryText,
    required String fallbackLabel,
    required String? deadlinePill,
    required String applyByText,
    required bool isPaid,
    required String? workMode,
    required String? duration,
    required String? categoryLabel,
    required bool matchesSummer,
    required bool matchesTech,
    required bool matchesMarketing,
    bool isFeaturedPreferred = false,
  }) {
    return _InternshipCardModel(
      id: id,
      title: title,
      companyName: companyName,
      companyLabel: companyLabel,
      secondaryText: secondaryText,
      logoUrl: '',
      fallbackLabel: fallbackLabel,
      workMode: workMode,
      location: null,
      deadline: null,
      daysUntilDeadline: null,
      deadlinePill: deadlinePill,
      applyByText: applyByText,
      isPaid: isPaid,
      duration: duration,
      categoryLabel: categoryLabel,
      isFeaturedPreferred: isFeaturedPreferred,
      matchesSummer: matchesSummer,
      matchesTech: matchesTech,
      matchesMarketing: matchesMarketing,
      createdAt: null,
      searchText: [
        title,
        companyName,
        secondaryText,
        workMode ?? '',
        duration ?? '',
        categoryLabel ?? '',
      ].join(' ').toLowerCase(),
      opportunity: null,
      isSaved: false,
      isPlaceholder: true,
    );
  }

  String get uniqueKey => id.isEmpty ? '$title|$companyName' : id;
}

final List<_InternshipCardModel> _placeholderWeeklyInternships = [
  _InternshipCardModel.placeholder(
    id: 'spotify-uiux',
    title: 'UI/UX Designer',
    companyName: 'Spotify',
    companyLabel: 'SPOTIFY',
    secondaryText: 'Spotify | Remote',
    fallbackLabel: 'S',
    deadlinePill: '3 days left',
    applyByText: 'Applying by Oct 12',
    isPaid: true,
    workMode: 'Remote',
    duration: '3 months',
    categoryLabel: 'Design',
    matchesSummer: false,
    matchesTech: false,
    matchesMarketing: false,
    isFeaturedPreferred: true,
  ),
  _InternshipCardModel.placeholder(
    id: 'notion-product',
    title: 'Product Design Intern',
    companyName: 'Notion',
    companyLabel: 'NOTION',
    secondaryText: 'Notion | Hybrid',
    fallbackLabel: 'N',
    deadlinePill: '5 days left',
    applyByText: 'Applying by Oct 16',
    isPaid: true,
    workMode: 'Hybrid',
    duration: '4 months',
    categoryLabel: 'Design',
    matchesSummer: false,
    matchesTech: true,
    matchesMarketing: false,
    isFeaturedPreferred: true,
  ),
  _InternshipCardModel.placeholder(
    id: 'agency-growth',
    title: 'Growth Marketing Intern',
    companyName: 'Agency X',
    companyLabel: 'AGENCY X',
    secondaryText: 'Agency X | Paris, FR',
    fallbackLabel: 'A',
    deadlinePill: '1 week left',
    applyByText: 'Applying by Oct 21',
    isPaid: true,
    workMode: null,
    duration: '10 weeks',
    categoryLabel: 'Marketing',
    matchesSummer: true,
    matchesTech: false,
    matchesMarketing: true,
  ),
];

final List<_InternshipCardModel> _placeholderPopularInternships = [
  _InternshipCardModel.placeholder(
    id: 'google-ux',
    title: 'UX Design Intern',
    companyName: 'Google',
    companyLabel: 'GOOGLE',
    secondaryText: 'Google | Hybrid',
    fallbackLabel: 'G',
    deadlinePill: '3 days left',
    applyByText: 'Applying by Oct 12',
    isPaid: true,
    workMode: 'Hybrid',
    duration: '3 months',
    categoryLabel: 'Design',
    matchesSummer: false,
    matchesTech: true,
    matchesMarketing: false,
    isFeaturedPreferred: true,
  ),
  _InternshipCardModel.placeholder(
    id: 'vercel-frontend',
    title: 'Frontend Engineer Intern',
    companyName: 'Vercel',
    companyLabel: 'VERCEL',
    secondaryText: 'Vercel | Remote',
    fallbackLabel: 'V',
    deadlinePill: '6 days left',
    applyByText: 'Applying by Oct 18',
    isPaid: true,
    workMode: 'Remote',
    duration: '3 months',
    categoryLabel: 'Engineering',
    matchesSummer: false,
    matchesTech: true,
    matchesMarketing: false,
  ),
  _InternshipCardModel.placeholder(
    id: 'agency-strategy',
    title: 'Marketing Strategy Intern',
    companyName: 'Agency X',
    companyLabel: 'AGENCY X',
    secondaryText: 'Agency X | Paris, FR',
    fallbackLabel: 'A',
    deadlinePill: '10 days left',
    applyByText: 'Applying by Oct 24',
    isPaid: false,
    workMode: null,
    duration: 'Credit only',
    categoryLabel: 'Strategy',
    matchesSummer: true,
    matchesTech: false,
    matchesMarketing: true,
  ),
];
