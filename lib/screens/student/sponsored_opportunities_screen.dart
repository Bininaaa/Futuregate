import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../models/user_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../utils/application_status.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications_screen.dart';
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

enum _SponsoredViewMode { grid, list }

class _SponsoredPalette {
  const _SponsoredPalette._();

  static const Color accent = OpportunityDashboardPalette.accent;
  static const Color accentDark = Color(0xFFEA580C);
  static const Color accentSurface = Color(0xFFFFF7ED);
  static const Color accentBorder = Color(0xFFFED7AA);
  static const Color surface = OpportunityDashboardPalette.surface;
  static const Color border = OpportunityDashboardPalette.border;
  static const Color textPrimary = OpportunityDashboardPalette.textPrimary;
  static const Color textSecondary = OpportunityDashboardPalette.textSecondary;
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
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.grants,
      label: 'Grants',
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.internships,
      label: 'Internships',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _allProgramsSectionKey = GlobalKey();
  final Set<String> _busyApplyIds = <String>{};
  final Set<String> _busySaveIds = <String>{};

  String _searchQuery = '';
  _SponsoredFilter _activeFilter = _SponsoredFilter.all;
  _SponsoredViewMode _viewMode = _SponsoredViewMode.grid;

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
    if (nextValue == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextValue;
    });
  }

  Future<void> _loadData({bool force = false}) async {
    final provider = context.read<OpportunityProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[];
    if (force || provider.opportunities.isEmpty) {
      futures.add(provider.fetchOpportunities());
    }

    if (userId != null && userId.isNotEmpty) {
      futures.add(applicationProvider.fetchSubmittedApplications(userId));
      if (force || savedProvider.savedOpportunities.isEmpty) {
        futures.add(savedProvider.fetchSavedOpportunities(userId));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openOpportunity(OpportunityModel opportunity) {
    OpportunityDetailScreen.show(context, opportunity);
  }

  Future<void> _toggleSavedOpportunity(OpportunityModel opportunity) async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final userId = authProvider.userModel?.uid;

    if (_busySaveIds.contains(opportunity.id)) {
      return;
    }

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

    setState(() {
      _busySaveIds.add(opportunity.id);
    });

    try {
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
          companyName: _companyName(opportunity),
          type: opportunity.type,
          location: opportunity.location,
          deadline: opportunity.deadlineLabel,
        );
      }

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(error ?? message)));
    } finally {
      if (mounted) {
        setState(() {
          _busySaveIds.remove(opportunity.id);
        });
      }
    }
  }

  Future<void> _applyNow(_SponsoredCardModel item) async {
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

  _SponsoredActionState _actionStateForOpportunity(
    OpportunityModel? opportunity,
    Map<String, String> appliedStatuses,
  ) {
    if (opportunity == null) {
      return const _SponsoredActionState(
        label: 'Preview',
        color: Color(0xFF94A3B8),
        icon: Icons.remove_red_eye_outlined,
      );
    }

    final applicationStatus = appliedStatuses[opportunity.id];
    if (applicationStatus != null) {
      return _SponsoredActionState(
        label: ApplicationStatus.label(applicationStatus),
        color: ApplicationStatus.color(applicationStatus),
        icon: _sponsoredApplicationStatusIcon(applicationStatus),
      );
    }

    if (opportunity.isHidden) {
      return const _SponsoredActionState(
        label: 'Unavailable',
        color: Color(0xFF94A3B8),
        icon: Icons.visibility_off_rounded,
      );
    }

    final normalizedStatus = opportunity.status.trim().toLowerCase();
    if (normalizedStatus.isNotEmpty && normalizedStatus != 'open') {
      return const _SponsoredActionState(
        label: 'Closed',
        color: Color(0xFF94A3B8),
        icon: Icons.lock_outline_rounded,
      );
    }

    return const _SponsoredActionState(label: 'Apply Now');
  }

  List<_SponsoredCardModel> _buildCardModels(
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
    _SponsoredCardModel a,
    _SponsoredCardModel b,
  ) {
    final scoreDiff = _priorityScore(b).compareTo(_priorityScore(a));
    if (scoreDiff != 0) {
      return scoreDiff;
    }

    final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
    final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
    return bCreated.compareTo(aCreated);
  }

  int _priorityScore(_SponsoredCardModel item) {
    var score = 0;

    if (item.opportunity?.isFeatured == true) {
      score += 80;
    }
    if (item.badgeLabel == 'CLOSING SOON') {
      score += 48;
    }
    if (item.badgeLabel == 'FULLY FUNDED') {
      score += 36;
    }
    if (item.filters.contains(_SponsoredFilter.grants)) {
      score += 18;
    }
    if (item.filters.contains(_SponsoredFilter.funding)) {
      score += 14;
    }
    if (item.urgencyText != null &&
        item.urgencyText!.toLowerCase().contains('day')) {
      score += 10;
    }
    if (!item.isPlaceholder) {
      score += 12;
    }

    return score;
  }

  List<_SponsoredCardModel> _applyFilters(
    List<_SponsoredCardModel> items,
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

  List<_SponsoredCardModel> _selectFeatured(List<_SponsoredCardModel> items) {
    final result = <_SponsoredCardModel>[];
    final seen = <String>{};

    void addCandidates(Iterable<_SponsoredCardModel> candidates) {
      for (final candidate in candidates) {
        if (result.length >= 6) {
          return;
        }
        if (seen.add(candidate.id)) {
          result.add(candidate);
        }
      }
    }

    addCandidates(
      items.where((item) => item.opportunity?.isFeatured == true),
    );
    addCandidates(
      items.where((item) => item.badgeLabel == 'FULLY FUNDED'),
    );
    addCandidates(
      items.where(
        (item) =>
            item.daysUntilDeadline != null && item.daysUntilDeadline! <= 7,
      ),
    );
    addCandidates(items);

    return result;
  }

  _SponsoredCardModel _mapOpportunityToCardModel(
    OpportunityModel opportunity,
  ) {
    final title = opportunity.title.trim().isEmpty
        ? 'Sponsored Opportunity'
        : opportunity.title.trim();
    final description = _descriptionFor(opportunity);
    final filters = _filtersForOpportunity(opportunity);
    final theme = _themeFor(filters);
    final badgeLabel = _badgeLabelForOpportunity(opportunity, filters);
    final badgeColor = _badgeColorForLabel(badgeLabel);
    final urgencyText = _urgencyTextFor(opportunity);
    final urgencyColor = _urgencyColorFor(opportunity);
    final compensation = _compensationText(opportunity);
    final duration = _durationFor(opportunity);
    final companyName = _companyName(opportunity);
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);
    final searchText = [
      title,
      companyName,
      description,
      opportunity.location,
      opportunity.requirements,
      badgeLabel,
      urgencyText ?? '',
      compensation ?? '',
      duration ?? '',
      ...filters.map((filter) => filter.name),
    ].join(' ').toLowerCase();

    return _SponsoredCardModel(
      id: opportunity.id,
      title: title,
      description: description,
      companyName: companyName,
      logoUrl: opportunity.companyLogo.trim(),
      iconData: theme.icon,
      iconColor: theme.foregroundColor,
      iconBgColor: theme.backgroundColor,
      badgeLabel: badgeLabel,
      badgeColor: badgeColor,
      urgencyText: urgencyText,
      urgencyColor: urgencyColor,
      compensation: compensation,
      duration: duration,
      daysUntilDeadline: daysUntilDeadline,
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

  String _badgeLabelForOpportunity(
    OpportunityModel opportunity,
    Set<_SponsoredFilter> filters,
  ) {
    final normalized = _normalizedSearchText(opportunity);
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);

    if (daysUntilDeadline != null &&
        daysUntilDeadline >= 0 &&
        daysUntilDeadline <= 4) {
      return 'CLOSING SOON';
    }

    if (_containsAny(normalized, const [
      'fully funded',
      'full funding',
      'all expenses',
    ])) {
      return 'FULLY FUNDED';
    }

    if (_containsAny(normalized, const [
      'limited',
      'limited seats',
      'limited spots',
      'exclusive',
    ])) {
      return 'LIMITED';
    }

    if (filters.contains(_SponsoredFilter.funding) &&
        filters.contains(_SponsoredFilter.grants)) {
      return 'FULLY FUNDED';
    }

    return 'OPEN';
  }

  Color _badgeColorForLabel(String label) {
    switch (label) {
      case 'CLOSING SOON':
        return OpportunityDashboardPalette.error;
      case 'FULLY FUNDED':
        return const Color(0xFFC2410C);
      case 'LIMITED':
        return _SponsoredPalette.accent;
      default:
        return const Color(0xFF0F766E);
    }
  }

  String? _urgencyTextFor(OpportunityModel opportunity) {
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);

    if (daysUntilDeadline == null) {
      return 'Applications open';
    }

    if (daysUntilDeadline < 0) {
      return null;
    }

    if (daysUntilDeadline == 0) {
      return 'Closes today';
    }

    if (daysUntilDeadline == 1) {
      return '1 day left';
    }

    if (daysUntilDeadline <= 7) {
      return 'Closing in $daysUntilDeadline days';
    }

    return 'Apply by ${OpportunityMetadata.formatDateLabel(deadline!, pattern: 'MMM d')}';
  }

  Color? _urgencyColorFor(OpportunityModel opportunity) {
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);

    if (daysUntilDeadline == null || daysUntilDeadline < 0) {
      return OpportunityDashboardPalette.secondary;
    }

    if (daysUntilDeadline <= 2) {
      return OpportunityDashboardPalette.error;
    }

    if (daysUntilDeadline <= 7) {
      return const Color(0xFFEA580C);
    }

    return _SponsoredPalette.accent;
  }

  String? _durationFor(OpportunityModel opportunity) {
    final duration = OpportunityMetadata.normalizeDuration(
      opportunity.duration,
    );
    if (duration == null) {
      return null;
    }

    return duration
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
        foregroundColor: _SponsoredPalette.accent,
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

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  Future<void> _scrollToAllPrograms() async {
    final sectionContext = _allProgramsSectionKey.currentContext;
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final opportunityProvider = context.watch<OpportunityProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isCompact = screenSize.width < 390 || screenSize.height < 780;
    final isExtraCompact = screenSize.width < 360 || screenSize.height < 700;
    final allOpportunities = opportunityProvider.opportunities;
    final allCards = _buildCardModels(allOpportunities);
    final visibleCards = _applyFilters(allCards);
    final featuredCards = _selectFeatured(visibleCards);
    final appliedStatuses = applicationProvider.appliedStatusMap;
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();
    final countLabel = visibleCards.length == 1
        ? '1 program'
        : '${visibleCards.length} programs';
    final horizontalPadding = isExtraCompact
        ? 16.0
        : isCompact
        ? 18.0
        : 20.0;
    final headlineFontSize = isExtraCompact
        ? 25.0
        : isCompact
        ? 26.0
        : 32.0;
    final featuredHeight = isExtraCompact
        ? 220.0
        : isCompact
        ? 230.0
        : 260.0;
    final featuredCardWidth = screenSize.width * (isExtraCompact ? 0.76 : 0.78);
    final gridSpacing = isExtraCompact ? 12.0 : 14.0;
    final gridMainExtent = isExtraCompact
        ? 240.0
        : isCompact
        ? 250.0
        : 262.0;
    final bottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _SponsoredHeaderBar(
              user: authProvider.userModel,
              unreadCount: notificationProvider.unreadCount,
              onNotificationsPressed: _openNotifications,
            ),
            if (opportunityProvider.isLoading && allOpportunities.isNotEmpty)
              const LinearProgressIndicator(
                minHeight: 2,
                color: _SponsoredPalette.accent,
              ),
            Expanded(
              child: RefreshIndicator(
                color: _SponsoredPalette.accent,
                backgroundColor: _SponsoredPalette.surface,
                onRefresh: () => _loadData(force: true),
                child: opportunityProvider.isLoading && allOpportunities.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          0,
                          isCompact ? 10 : 16,
                          0,
                          bottomPadding,
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Sponsored\n',
                                    style: GoogleFonts.poppins(
                                      fontSize: headlineFontSize,
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                      color: _SponsoredPalette.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Programs',
                                    style: GoogleFonts.poppins(
                                      fontSize: headlineFontSize,
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                      color: _SponsoredPalette.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : 14),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _SponsoredSearchBar(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onClear: _searchQuery.isEmpty
                                  ? null
                                  : _searchController.clear,
                              compact: isCompact,
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : 12),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              itemCount: _filters.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final filter = _filters[index];
                                final isActive =
                                    filter.value == _activeFilter;

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
                          SizedBox(height: isCompact ? 16 : 22),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _SponsoredSectionHeader(
                              title: 'Featured Programs',
                              actionLabel: 'Browse all',
                              onAction: _scrollToAllPrograms,
                              compact: isCompact,
                            ),
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          if (visibleCards.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: const _SponsoredEmptyState(
                                title: 'No sponsored programs found',
                                message:
                                    'Try adjusting your search or filters to uncover more partner-backed programs.',
                              ),
                            )
                          else
                            SizedBox(
                              height: featuredHeight,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: featuredCards.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final item = featuredCards[index];
                                  final opportunity = item.opportunity;
                                  final actionState =
                                      _actionStateForOpportunity(
                                        opportunity,
                                        appliedStatuses,
                                      );

                                  return SizedBox(
                                    width: featuredCardWidth,
                                    child: _FeaturedSponsoredCard(
                                      item: item,
                                      actionState: actionState,
                                      isSaved: opportunity != null &&
                                          savedIds.contains(opportunity.id),
                                      isSaveBusy: opportunity != null &&
                                          _busySaveIds.contains(
                                            opportunity.id,
                                          ),
                                      isApplying: opportunity != null &&
                                          _busyApplyIds.contains(
                                            opportunity.id,
                                          ),
                                      compact: isCompact,
                                      onTap: opportunity == null
                                          ? null
                                          : () =>
                                              _openOpportunity(opportunity),
                                      onApply: actionState.isEnabled
                                          ? () => _applyNow(item)
                                          : null,
                                      onToggleSaved: opportunity == null
                                          ? null
                                          : () => _toggleSavedOpportunity(
                                              opportunity,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: isCompact ? 18 : 24),
                          Container(
                            key: _allProgramsSectionKey,
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _SponsoredSectionHeader(
                              title: 'All Programs',
                              countLabel: countLabel,
                              compact: isCompact,
                              trailing: _SponsoredViewToggle(
                                viewMode: _viewMode,
                                onChanged: (next) {
                                  setState(() {
                                    _viewMode = next;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          if (visibleCards.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: const _SponsoredEmptyState(
                                title: 'Nothing to show right now',
                                message:
                                    'Live sponsored programs will appear here as they match your search.',
                              ),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: _viewMode == _SponsoredViewMode.grid
                                    ? GridView.builder(
                                        key: const ValueKey(
                                          'sponsored-grid',
                                        ),
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: visibleCards.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: gridSpacing,
                                              mainAxisSpacing: gridSpacing,
                                              mainAxisExtent: gridMainExtent,
                                            ),
                                        itemBuilder: (context, index) {
                                          final item = visibleCards[index];
                                          final opportunity = item.opportunity;
                                          final actionState =
                                              _actionStateForOpportunity(
                                                opportunity,
                                                appliedStatuses,
                                              );

                                          return _SponsoredGridCard(
                                            item: item,
                                            actionState: actionState,
                                            isSaved: opportunity != null &&
                                                savedIds.contains(
                                                  opportunity.id,
                                                ),
                                            isSaveBusy: opportunity != null &&
                                                _busySaveIds.contains(
                                                  opportunity.id,
                                                ),
                                            isApplying: opportunity != null &&
                                                _busyApplyIds.contains(
                                                  opportunity.id,
                                                ),
                                            onTap: opportunity == null
                                                ? null
                                                : () => _openOpportunity(
                                                    opportunity,
                                                  ),
                                            onApply: actionState.isEnabled
                                                ? () => _applyNow(item)
                                                : null,
                                            onToggleSaved: opportunity == null
                                                ? null
                                                : () =>
                                                    _toggleSavedOpportunity(
                                                      opportunity,
                                                    ),
                                          );
                                        },
                                      )
                                    : Column(
                                        key: const ValueKey(
                                          'sponsored-list',
                                        ),
                                        children: [
                                          for (
                                            var index = 0;
                                            index < visibleCards.length;
                                            index++
                                          )
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: index ==
                                                        visibleCards.length - 1
                                                    ? 0
                                                    : 10,
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  final listItem =
                                                      visibleCards[index];
                                                  final listOpp =
                                                      listItem.opportunity;
                                                  final listAction =
                                                      _actionStateForOpportunity(
                                                        listOpp,
                                                        appliedStatuses,
                                                      );

                                                  return _SponsoredListTile(
                                                    item: listItem,
                                                    actionState: listAction,
                                                    isSaved: listOpp != null &&
                                                        savedIds.contains(
                                                          listOpp.id,
                                                        ),
                                                    isSaveBusy:
                                                        listOpp != null &&
                                                        _busySaveIds.contains(
                                                          listOpp.id,
                                                        ),
                                                    isApplying:
                                                        listOpp != null &&
                                                        _busyApplyIds.contains(
                                                          listOpp.id,
                                                        ),
                                                    onTap: listOpp == null
                                                        ? null
                                                        : () =>
                                                            _openOpportunity(
                                                              listOpp,
                                                            ),
                                                    onApply:
                                                        listAction.isEnabled
                                                        ? () => _applyNow(
                                                            listItem,
                                                          )
                                                        : null,
                                                    onToggleSaved:
                                                        listOpp == null
                                                        ? null
                                                        : () =>
                                                            _toggleSavedOpportunity(
                                                              listOpp,
                                                            ),
                                                  );
                                                },
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
          ],
        ),
      ),
    );
  }
}

class _SponsoredHeaderBar extends StatelessWidget {
  final UserModel? user;
  final int unreadCount;
  final VoidCallback onNotificationsPressed;

  const _SponsoredHeaderBar({
    required this.user,
    required this.unreadCount,
    required this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            ProfileAvatar(user: user, radius: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.fullName ?? 'Student',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _SponsoredPalette.textPrimary,
                    ),
                  ),
                  Text(
                    'Sponsored Programs',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _SponsoredPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNotificationsPressed,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _SponsoredPalette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _SponsoredPalette.border),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: _SponsoredPalette.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _SponsoredPalette.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsoredSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onClear;
  final bool compact;

  const _SponsoredSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SponsoredPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SponsoredPalette.border),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: _SponsoredPalette.accent,
        style: GoogleFonts.poppins(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w500,
          color: _SponsoredPalette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search grants, startups, competitions...',
          hintStyle: GoogleFonts.poppins(
            fontSize: compact ? 11.5 : 12,
            fontWeight: FontWeight.w500,
            color: _SponsoredPalette.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _SponsoredPalette.textSecondary,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _SponsoredPalette.textSecondary,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
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
                ? _SponsoredPalette.accent
                : _SponsoredPalette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? _SponsoredPalette.accent
                  : _SponsoredPalette.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : _SponsoredPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final String? countLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool compact;

  const _SponsoredSectionHeader({
    required this.title,
    this.actionLabel,
    this.countLabel,
    this.onAction,
    this.trailing,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: _SponsoredPalette.textPrimary,
                ),
              ),
              if (countLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    countLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _SponsoredPalette.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _SponsoredPalette.accent,
              ),
            ),
          ),
      ],
    );
  }
}

class _SponsoredViewToggle extends StatelessWidget {
  final _SponsoredViewMode viewMode;
  final ValueChanged<_SponsoredViewMode> onChanged;

  const _SponsoredViewToggle({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIcon(
            icon: Icons.grid_view_rounded,
            isActive: viewMode == _SponsoredViewMode.grid,
            onTap: () => onChanged(_SponsoredViewMode.grid),
          ),
          const SizedBox(width: 2),
          _ToggleIcon(
            icon: Icons.view_list_rounded,
            isActive: viewMode == _SponsoredViewMode.list,
            onTap: () => onChanged(_SponsoredViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.isActive,
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
          color: isActive ? _SponsoredPalette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? _SponsoredPalette.accent
              : _SponsoredPalette.textSecondary,
        ),
      ),
    );
  }
}

class _FeaturedSponsoredCard extends StatelessWidget {
  final _SponsoredCardModel item;
  final _SponsoredActionState actionState;
  final bool isSaved;
  final bool isSaveBusy;
  final bool isApplying;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSaved;

  const _FeaturedSponsoredCard({
    required this.item,
    required this.actionState,
    required this.isSaved,
    required this.isSaveBusy,
    required this.isApplying,
    required this.compact,
    required this.onTap,
    required this.onApply,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: _SponsoredPalette.surface,
            borderRadius: radius,
            border: Border.all(color: _SponsoredPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_SponsoredPalette.accent, Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius.topLeft.x),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CompanyIcon(
                            logoUrl: item.logoUrl,
                            iconData: item.iconData,
                            iconColor: item.iconColor,
                            iconBgColor: item.iconBgColor,
                            size: 40,
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
                                    fontSize: compact ? 13.5 : 14.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.18,
                                    color: _SponsoredPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.companyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _SponsoredPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _BadgePill(
                            label: item.badgeLabel,
                            color: item.badgeColor,
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (item.compensation != null || item.duration != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              if (item.compensation != null) ...[
                                Icon(
                                  Icons.payments_outlined,
                                  size: 13,
                                  color: _SponsoredPalette.accent,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.compensation!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _SponsoredPalette.accentDark,
                                    ),
                                  ),
                                ),
                              ],
                              if (item.compensation != null &&
                                  item.duration != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '·',
                                    style: TextStyle(
                                      color: _SponsoredPalette.textSecondary,
                                    ),
                                  ),
                                ),
                              if (item.duration != null)
                                Text(
                                  item.duration!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _SponsoredPalette.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (item.urgencyText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: item.urgencyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.urgencyText!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: item.urgencyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _ApplyButton(
                              label: actionState.label,
                              icon: actionState.icon,
                              accentColor: actionState.color,
                              isLoading: isApplying,
                              onTap: onApply,
                            ),
                          ),
                          if (onToggleSaved != null) ...[
                            const SizedBox(width: 8),
                            _BookmarkButton(
                              isSaved: isSaved,
                              isLoading: isSaveBusy,
                              onTap: onToggleSaved,
                            ),
                          ],
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

class _SponsoredGridCard extends StatelessWidget {
  final _SponsoredCardModel item;
  final _SponsoredActionState actionState;
  final bool isSaved;
  final bool isSaveBusy;
  final bool isApplying;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSaved;

  const _SponsoredGridCard({
    required this.item,
    required this.actionState,
    required this.isSaved,
    required this.isSaveBusy,
    required this.isApplying,
    required this.onTap,
    required this.onApply,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: _SponsoredPalette.surface,
            borderRadius: radius,
            border: Border.all(color: _SponsoredPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: item.iconColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius.topLeft.x),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CompanyIcon(
                            logoUrl: item.logoUrl,
                            iconData: item.iconData,
                            iconColor: item.iconColor,
                            iconBgColor: item.iconBgColor,
                            size: 34,
                          ),
                          const Spacer(),
                          if (onToggleSaved != null)
                            GestureDetector(
                              onTap: isSaveBusy ? null : onToggleSaved,
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                size: 18,
                                color: isSaved
                                    ? _SponsoredPalette.accent
                                    : _SponsoredPalette.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: _SponsoredPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: _SponsoredPalette.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (item.compensation != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item.compensation!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _SponsoredPalette.accentDark,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          _BadgePill(
                            label: item.badgeLabel,
                            color: item.badgeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _ApplyButton(
                        label: actionState.label,
                        icon: actionState.icon,
                        accentColor: actionState.color,
                        isLoading: isApplying,
                        onTap: onApply,
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

class _SponsoredListTile extends StatelessWidget {
  final _SponsoredCardModel item;
  final _SponsoredActionState actionState;
  final bool isSaved;
  final bool isSaveBusy;
  final bool isApplying;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSaved;

  const _SponsoredListTile({
    required this.item,
    required this.actionState,
    required this.isSaved,
    required this.isSaveBusy,
    required this.isApplying,
    required this.onTap,
    required this.onApply,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: _SponsoredPalette.surface,
            borderRadius: radius,
            border: Border.all(color: _SponsoredPalette.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyIcon(
                logoUrl: item.logoUrl,
                iconData: item.iconData,
                iconColor: item.iconColor,
                iconBgColor: item.iconBgColor,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _SponsoredPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _SponsoredPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _BadgePill(
                          label: item.badgeLabel,
                          color: item.badgeColor,
                        ),
                        if (item.compensation != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.compensation!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: _SponsoredPalette.accentDark,
                              ),
                            ),
                          ),
                        ],
                        if (item.urgencyText != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: item.urgencyColor,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              item.urgencyText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: item.urgencyColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onToggleSaved != null)
                    GestureDetector(
                      onTap: isSaveBusy ? null : onToggleSaved,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 20,
                          color: isSaved
                              ? _SponsoredPalette.accent
                              : _SponsoredPalette.textSecondary,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 72,
                    height: 30,
                    child: _ApplyButton(
                      label: actionState.label,
                      icon: null,
                      accentColor: actionState.color,
                      isLoading: isApplying,
                      onTap: onApply,
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

class _CompanyIcon extends StatelessWidget {
  final String logoUrl;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final double size;

  const _CompanyIcon({
    required this.logoUrl,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconBgColor,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Icon(iconData, color: iconColor, size: size * 0.5)
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  Icon(iconData, color: iconColor, size: size * 0.5),
            ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? accentColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ApplyButton({
    required this.label,
    this.icon,
    this.accentColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActionable = accentColor == null;
    final bgColor = isActionable
        ? _SponsoredPalette.accent
        : accentColor!.withValues(alpha: 0.12);
    final textColor = isActionable ? Colors.white : accentColor!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: textColor),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
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

class _BookmarkButton extends StatelessWidget {
  final bool isSaved;
  final bool isLoading;
  final VoidCallback? onTap;

  const _BookmarkButton({
    required this.isSaved,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSaved
                ? _SponsoredPalette.accentSurface
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSaved
                  ? _SponsoredPalette.accentBorder
                  : _SponsoredPalette.border,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _SponsoredPalette.accent,
                      ),
                    ),
                  )
                : Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 17,
                    color: isSaved
                        ? _SponsoredPalette.accent
                        : _SponsoredPalette.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _SponsoredEmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _SponsoredPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SponsoredPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _SponsoredPalette.accentSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: _SponsoredPalette.accent,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _SponsoredPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.45,
              color: _SponsoredPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _sponsoredApplicationStatusIcon(String status) {
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

class _SponsoredActionState {
  final String label;
  final Color? color;
  final IconData? icon;

  const _SponsoredActionState({required this.label, this.color, this.icon});

  bool get isEnabled => color == null;
}

class _SponsoredFilterDefinition {
  final _SponsoredFilter value;
  final String label;

  const _SponsoredFilterDefinition({required this.value, required this.label});
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

class _SponsoredCardModel {
  final String id;
  final String title;
  final String description;
  final String companyName;
  final String logoUrl;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final String badgeLabel;
  final Color badgeColor;
  final String? urgencyText;
  final Color? urgencyColor;
  final String? compensation;
  final String? duration;
  final int? daysUntilDeadline;
  final Set<_SponsoredFilter> filters;
  final OpportunityModel? opportunity;
  final String searchText;
  final bool isPlaceholder;
  final DateTime? createdAt;

  const _SponsoredCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.logoUrl,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.badgeLabel,
    required this.badgeColor,
    required this.urgencyText,
    required this.urgencyColor,
    required this.compensation,
    required this.duration,
    required this.daysUntilDeadline,
    required this.filters,
    required this.opportunity,
    required this.searchText,
    required this.isPlaceholder,
    required this.createdAt,
  });

  factory _SponsoredCardModel.placeholder({
    required String id,
    required String title,
    required String description,
    required String companyName,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeLabel,
    required Color badgeColor,
    required String? urgencyText,
    required Color? urgencyColor,
    required String? compensation,
    required String? duration,
    required Set<_SponsoredFilter> filters,
  }) {
    return _SponsoredCardModel(
      id: id,
      title: title,
      description: description,
      companyName: companyName,
      logoUrl: '',
      iconData: iconData,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      badgeLabel: badgeLabel,
      badgeColor: badgeColor,
      urgencyText: urgencyText,
      urgencyColor: urgencyColor,
      compensation: compensation,
      duration: duration,
      daysUntilDeadline: null,
      filters: filters,
      opportunity: null,
      searchText: [
        title,
        description,
        companyName,
        ...filters.map((filter) => filter.name),
      ].join(' ').toLowerCase(),
      isPlaceholder: true,
      createdAt: null,
    );
  }
}

final List<_SponsoredCardModel> _placeholderSponsoredCards = [
  _SponsoredCardModel.placeholder(
    id: 'jp-morgan-fintech',
    title: 'JP Morgan Fintech Summit',
    description:
        'A partner-backed summit for ambitious students exploring finance, technology, and innovation-led product building.',
    companyName: 'JP Morgan',
    iconData: Icons.emoji_events_rounded,
    iconColor: _SponsoredPalette.accent,
    iconBgColor: const Color(0xFFFFEDD5),
    badgeLabel: 'FULLY FUNDED',
    badgeColor: const Color(0xFFC2410C),
    urgencyText: 'Closing in 5 days',
    urgencyColor: const Color(0xFFEA580C),
    compensation: '\$5,000',
    duration: '3 days',
    filters: {
      _SponsoredFilter.funding,
      _SponsoredFilter.grants,
      _SponsoredFilter.competition,
    },
  ),
  _SponsoredCardModel.placeholder(
    id: 'aws-ambassador',
    title: 'AWS Student Ambassador',
    description:
        'A sponsored student ambassador track with mentorship, community leadership, and premium cloud learning access.',
    companyName: 'AWS',
    iconData: Icons.school_rounded,
    iconColor: OpportunityDashboardPalette.primaryDark,
    iconBgColor: const Color(0xFFDBEAFE),
    badgeLabel: 'OPEN',
    badgeColor: const Color(0xFF0F766E),
    urgencyText: 'Applications open',
    urgencyColor: OpportunityDashboardPalette.secondary,
    compensation: '\$1,200 / mo',
    duration: '6 mo',
    filters: {_SponsoredFilter.funding, _SponsoredFilter.internships},
  ),
  _SponsoredCardModel.placeholder(
    id: 'innovation-grant',
    title: 'International Innovation Grant',
    description:
        'A premium support program for students building new ideas through mentorship, funding access, and expert review.',
    companyName: 'AvenirDZ Partner',
    iconData: Icons.workspace_premium_rounded,
    iconColor: OpportunityDashboardPalette.warning,
    iconBgColor: const Color(0xFFFEF3C7),
    badgeLabel: 'LIMITED',
    badgeColor: _SponsoredPalette.accent,
    urgencyText: 'Closing in 8 days',
    urgencyColor: OpportunityDashboardPalette.warning,
    compensation: '\$8,000',
    duration: '12 wk',
    filters: {
      _SponsoredFilter.funding,
      _SponsoredFilter.grants,
      _SponsoredFilter.startup,
    },
  ),
];
