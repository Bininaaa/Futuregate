import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/application_status.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_search_field.dart';
import '../../widgets/student/student_workspace_shell.dart';
import 'applied_opportunities_screen.dart';
import 'opportunity_detail_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';
import '../../l10n/generated/app_localizations.dart';

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

  static Color get accent => OpportunityDashboardPalette.accent;
  static Color get accentDark => AppColors.current.warning;
  static Color get accentSurface => AppColors.current.warningSoft;
  static Color get accentBorder => AppColors.current.warning;
  static Color get heroMid => AppColors.current.warning;
  static Color get heroEnd => OpportunityDashboardPalette.accent;
  static Color get surface => OpportunityDashboardPalette.surface;
  static Color get surfaceElevated => AppColors.current.surfaceElevated;
  static Color get surfaceMuted => AppColors.current.surfaceMuted;
  static Color get border => OpportunityDashboardPalette.border;
  static Color get textPrimary => OpportunityDashboardPalette.textPrimary;
  static Color get textSecondary => OpportunityDashboardPalette.textSecondary;
  static Color get shadow => AppColors.current.shadow;
  static bool get isDark => AppColors.isDark;
}

class _SponsoredOpportunitiesScreenState
    extends State<SponsoredOpportunitiesScreen> {
  List<_SponsoredFilterDefinition> _buildFilters(AppLocalizations l10n) => [
    _SponsoredFilterDefinition(value: _SponsoredFilter.all, label: l10n.uiAll),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.funding,
      label: l10n.uiFunding,
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.startup,
      label: l10n.uiStartup,
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.competition,
      label: l10n.uiCompetition,
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.grants,
      label: l10n.uiGrants,
    ),
    _SponsoredFilterDefinition(
      value: _SponsoredFilter.internships,
      label: l10n.uiInternships,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
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

    if (_busySaveIds.contains(opportunity.id)) {
      return;
    }

    if (userId == null || userId.isEmpty) {
      context.showAppSnackBar(
        'Sign in to save opportunities for later.',
        title: AppLocalizations.of(context)!.uiLoginRequired,
        type: AppFeedbackType.warning,
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
          title: DisplayText.opportunityTitle(
            opportunity.title,
            fallback: 'Sponsored Opportunity',
          ),
          companyName: opportunity.companyName.trim(),
          type: opportunity.type,
          location: opportunity.location,
          deadline: opportunity.deadlineLabel,
          fundingLabel: opportunity.fundingLabel() ?? '',
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

    if (_busyApplyIds.contains(opportunity.id)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final cvProvider = context.read<CvProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      context.showAppSnackBar(
        'Sign in to continue with your application.',
        title: AppLocalizations.of(context)!.uiLoginRequired,
        type: AppFeedbackType.warning,
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
        context.showAppSnackBar(
          _messageForEligibility(eligibility),
          title: AppLocalizations.of(context)!.uiApplicationBlocked,
          type: AppFeedbackType.warning,
        );
        return;
      }

      await cvProvider.loadCv(currentUser.uid);

      if (!mounted) {
        return;
      }

      final cv = cvProvider.cv;
      if (cv == null) {
        context.showAppSnackBar(
          'Create your CV before applying to this opportunity.',
          title: AppLocalizations.of(context)!.uiCvRequired,
          type: AppFeedbackType.warning,
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

      context.showAppSnackBar(
        error ?? 'Your application has been submitted successfully.',
        title: error == null ? 'Application sent' : 'Application unavailable',
        type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
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
    OpportunityModel opportunity,
    Map<String, String> appliedStatuses,
  ) {
    final applicationStatus = appliedStatuses[opportunity.id];
    if (applicationStatus != null &&
        ApplicationStatus.parse(applicationStatus) !=
            ApplicationStatus.withdrawn) {
      return _SponsoredActionState(
        label: ApplicationStatus.label(
          applicationStatus,
          AppLocalizations.of(context)!,
        ),
        color: ApplicationStatus.color(applicationStatus),
        icon: _sponsoredApplicationStatusIcon(applicationStatus),
      );
    }

    if (!opportunity.isVisibleToStudents()) {
      return _SponsoredActionState(
        label: AppLocalizations.of(context)!.uiUnavailable,
        color: const Color(0xFF94A3B8),
        icon: Icons.visibility_off_rounded,
      );
    }

    final normalizedStatus = opportunity.effectiveStatus();
    if (normalizedStatus.isNotEmpty && normalizedStatus != 'open') {
      return _SponsoredActionState(
        label: AppLocalizations.of(context)!.uiClosed,
        color: const Color(0xFF94A3B8),
        icon: Icons.lock_outline_rounded,
      );
    }

    return const _SponsoredActionState(label: 'Apply Now');
  }

  List<_SponsoredCardModel> _buildCardModels(
    List<OpportunityModel> opportunities,
  ) {
    final cards =
        opportunities
            .where(_isLiveSponsored)
            .where((opportunity) => opportunity.title.trim().isNotEmpty)
            .map(_mapOpportunityToCardModel)
            .toList()
          ..sort(_sortSponsoredCards);

    return cards;
  }

  bool _isLiveSponsored(OpportunityModel opportunity) {
    final type = OpportunityType.parse(opportunity.type);
    if (type != OpportunityType.sponsoring) {
      return false;
    }

    return _isOpenOpportunity(opportunity);
  }

  bool _isOpenOpportunity(OpportunityModel opportunity) {
    return opportunity.isVisibleToStudents() &&
        opportunity.effectiveStatus() == 'open';
  }

  int _sortSponsoredCards(_SponsoredCardModel a, _SponsoredCardModel b) {
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

    if (item.opportunity.isFeatured) {
      score += 80;
    }
    if (item.badgeLabel == 'Closing soon') {
      score += 48;
    }
    if (item.badgeLabel == 'Fully funded') {
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
    score += 12;

    return score;
  }

  List<_SponsoredCardModel> _applyFilters(List<_SponsoredCardModel> items) {
    final query = _searchQuery.toLowerCase();

    return items.where((item) {
      final matchesQuery = query.isEmpty || item.searchText.contains(query);
      final matchesFilter =
          _activeFilter == _SponsoredFilter.all ||
          item.filters.contains(_activeFilter);

      return matchesQuery && matchesFilter;
    }).toList();
  }

  String _labelForFilter(_SponsoredFilter filter, AppLocalizations l10n) {
    for (final item in _buildFilters(l10n)) {
      if (item.value == filter) {
        return item.label;
      }
    }
    return l10n.uiAll;
  }

  _SponsoredCardModel _mapOpportunityToCardModel(OpportunityModel opportunity) {
    final title = DisplayText.opportunityTitle(
      opportunity.title,
      fallback: 'Sponsored Opportunity',
    );
    final description = opportunity.description.trim();
    final filters = _filtersForOpportunity(opportunity);
    final theme = _themeFor(filters);
    final badgeLabel = _badgeLabelForOpportunity(opportunity, filters);
    final badgeColor = _badgeColorForLabel(badgeLabel);
    final urgencyText = _urgencyTextFor(opportunity);
    final urgencyColor = _urgencyColorFor(opportunity);
    final compensation = _compensationText(opportunity);
    final duration = _durationFor(opportunity);
    final trackLabel = _trackLabelFor(opportunity);
    final locationLabel = _locationLabelFor(opportunity);
    final companyName = opportunity.companyName.trim();
    final deadline = _deadlineFor(opportunity);
    final daysUntilDeadline = _daysUntil(deadline);
    final searchText = [
      title,
      companyName,
      description,
      locationLabel ?? opportunity.location,
      opportunity.requirements,
      trackLabel ?? '',
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
      trackLabel: trackLabel,
      locationLabel: locationLabel,
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
      createdAt: opportunity.createdAt?.toDate(),
    );
  }

  String? _trackLabelFor(OpportunityModel opportunity) {
    final rawValue = opportunity.readString(const <String>[
      'track',
      'program',
      'programType',
      'initiative',
      'category',
    ]);
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return null;
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String? _locationLabelFor(OpportunityModel opportunity) {
    final location = opportunity.location.trim();
    if (location.isEmpty) {
      return null;
    }

    return _compactValueText(location);
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
    final structuredLabel = opportunity.fundingLabel();
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
      return 'Closing soon';
    }

    if (_containsAny(normalized, const [
      'fully funded',
      'full funding',
      'all expenses',
    ])) {
      return 'Fully funded';
    }

    if (_containsAny(normalized, const [
      'limited',
      'limited seats',
      'limited spots',
      'exclusive',
    ])) {
      return 'Limited';
    }

    if (filters.contains(_SponsoredFilter.funding) &&
        filters.contains(_SponsoredFilter.grants)) {
      return 'Fully funded';
    }

    return 'Open';
  }

  Color _badgeColorForLabel(String label) {
    switch (label) {
      case 'Closing soon':
        return OpportunityDashboardPalette.error;
      case 'Fully funded':
        return OpportunityDashboardPalette.warning;
      case 'Limited':
        return _SponsoredPalette.accent;
      default:
        return OpportunityDashboardPalette.secondary;
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
      return OpportunityDashboardPalette.warning;
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
      return _SponsoredVisualTheme(
        icon: Icons.rocket_launch_rounded,
        backgroundColor: AppColors.current.primarySoft,
        foregroundColor: OpportunityDashboardPalette.primary,
      );
    }
    if (filters.contains(_SponsoredFilter.competition)) {
      return _SponsoredVisualTheme(
        icon: Icons.emoji_events_rounded,
        backgroundColor: _SponsoredPalette.accentSurface,
        foregroundColor: _SponsoredPalette.accent,
      );
    }
    if (filters.contains(_SponsoredFilter.grants)) {
      return _SponsoredVisualTheme(
        icon: Icons.workspace_premium_rounded,
        backgroundColor: _SponsoredPalette.accentSurface,
        foregroundColor: OpportunityDashboardPalette.warning,
      );
    }
    if (filters.contains(_SponsoredFilter.internships)) {
      return _SponsoredVisualTheme(
        icon: Icons.school_rounded,
        backgroundColor: AppColors.current.infoSoft,
        foregroundColor: OpportunityDashboardPalette.primaryDark,
      );
    }

    return _SponsoredVisualTheme(
      icon: Icons.volunteer_activism_rounded,
      backgroundColor: AppColors.current.secondarySoft,
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
    final allOpportunities = opportunityProvider.opportunities;
    final allCards = _buildCardModels(allOpportunities);
    final visibleCards = _applyFilters(allCards);
    final appliedStatuses = applicationProvider.appliedStatusMap;
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();
    final hasActiveFilters =
        _searchQuery.isNotEmpty || _activeFilter != _SponsoredFilter.all;
    final l10n = AppLocalizations.of(context)!;
    final activeFilterLabel = _labelForFilter(_activeFilter, l10n);
    final showCatalogEmptyState = allCards.isEmpty && !hasActiveFilters;
    final countLabel = visibleCards.length == 1
        ? '1 program live now'
        : '${visibleCards.length} programs live now';
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
    final cardSpacing = isExtraCompact ? 12.0 : 14.0;
    final bottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            StudentWorkspaceUtilityHeader(
              user: authProvider.userModel,
              title: AppLocalizations.of(context)!.uiSponsored,
              onProfileTap: _openProfile,
              onOpenSaved: _openSavedItems,
              onOpenApplied: _openAppliedItems,
              compact: isCompact,
              backgroundColor: Colors.transparent,
              borderColor: _SponsoredPalette.accent.withValues(alpha: 0.18),
              titleColor: _SponsoredPalette.accentDark,
              accentColor: _SponsoredPalette.accent,
            ),
            if (opportunityProvider.isLoading && allOpportunities.isNotEmpty)
              LinearProgressIndicator(
                minHeight: 2,
                color: _SponsoredPalette.accent,
              ),
            Expanded(
              child: RefreshIndicator(
                color: _SponsoredPalette.accent,
                backgroundColor: _SponsoredPalette.surface,
                onRefresh: () => _loadData(force: true),
                child: opportunityProvider.isLoading && allOpportunities.isEmpty
                    ? ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          SizedBox(
                            height: 420,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _SponsoredPalette.accent,
                              ),
                            ),
                          ),
                        ],
                      )
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
                                    text: 'Find your next\n',
                                    style: GoogleFonts.poppins(
                                      fontSize: headlineFontSize,
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                      color: _SponsoredPalette.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'funded path',
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
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : 12),
                          SizedBox(
                            height: isCompact ? 34 : 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              itemCount: _buildFilters(l10n).length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final filter = _buildFilters(l10n)[index];
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
                          SizedBox(height: isCompact ? 18 : 24),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _SponsoredSectionHeader(
                              title: AppLocalizations.of(
                                context,
                              )!.uiAllSponsoredPrograms,
                              countLabel: hasActiveFilters
                                  ? '$countLabel matched in ${activeFilterLabel.toLowerCase()}'
                                  : countLabel,
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
                          SizedBox(height: isCompact ? 10 : 14),
                          if (visibleCards.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: _SponsoredEmptyState(
                                title: showCatalogEmptyState
                                    ? 'No sponsored programs available right now'
                                    : 'No sponsored programs match this view',
                                message: showCatalogEmptyState
                                    ? 'Check back soon for new sponsored programs.'
                                    : 'Try adjusting your search or filters to see matching programs.',
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
                                    ? Column(
                                        key: const ValueKey('sponsored-grid'),
                                        children: [
                                          for (
                                            var index = 0;
                                            index < visibleCards.length;
                                            index++
                                          )
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom:
                                                    index ==
                                                        visibleCards.length - 1
                                                    ? 0
                                                    : cardSpacing,
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  final item =
                                                      visibleCards[index];
                                                  final opportunity =
                                                      item.opportunity;
                                                  final actionState =
                                                      _actionStateForOpportunity(
                                                        opportunity,
                                                        appliedStatuses,
                                                      );

                                                  return _SponsoredGridCard(
                                                    item: item,
                                                    actionState: actionState,
                                                    isSaved: savedIds.contains(
                                                      opportunity.id,
                                                    ),
                                                    isSaveBusy: _busySaveIds
                                                        .contains(
                                                          opportunity.id,
                                                        ),
                                                    isApplying: _busyApplyIds
                                                        .contains(
                                                          opportunity.id,
                                                        ),
                                                    compact: isCompact,
                                                    onTap: () =>
                                                        _openOpportunity(
                                                          opportunity,
                                                        ),
                                                    onApply:
                                                        actionState.isEnabled
                                                        ? () => _applyNow(item)
                                                        : null,
                                                    onToggleSaved: () =>
                                                        _toggleSavedOpportunity(
                                                          opportunity,
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      )
                                    : Column(
                                        key: const ValueKey('sponsored-list'),
                                        children: [
                                          for (
                                            var index = 0;
                                            index < visibleCards.length;
                                            index++
                                          )
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom:
                                                    index ==
                                                        visibleCards.length - 1
                                                    ? 0
                                                    : cardSpacing,
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
                                                    isSaved: savedIds.contains(
                                                      listOpp.id,
                                                    ),
                                                    isSaveBusy: _busySaveIds
                                                        .contains(listOpp.id),
                                                    isApplying: _busyApplyIds
                                                        .contains(listOpp.id),
                                                    onTap: () =>
                                                        _openOpportunity(
                                                          listOpp,
                                                        ),
                                                    onApply:
                                                        listAction.isEnabled
                                                        ? () => _applyNow(
                                                            listItem,
                                                          )
                                                        : null,
                                                    onToggleSaved: () =>
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

class _BackdropShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double opacity;
  final double radius;
  final double rotation;

  const _BackdropShape({
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
    required this.radius,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
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
    return StudentSearchField(
      controller: controller,
      focusNode: focusNode,
      hintText: AppLocalizations.of(context)!.uiSearchPrograms,
      onClear: onClear,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      _SponsoredPalette.heroMid,
                      _SponsoredPalette.heroEnd,
                    ],
                  )
                : null,
            color: isActive
                ? null
                : _SponsoredPalette.surface.withValues(
                    alpha: _SponsoredPalette.isDark ? 0.96 : 0.86,
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? Colors.transparent : _SponsoredPalette.border,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _SponsoredPalette.accent.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.6,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : _SponsoredPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredSectionHeader extends StatelessWidget {
  final String title;
  final String? countLabel;
  final Widget? trailing;
  final bool compact;

  const _SponsoredSectionHeader({
    required this.title,
    this.countLabel,
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
      ],
    );
  }
}

class _SponsoredViewToggle extends StatelessWidget {
  final _SponsoredViewMode viewMode;
  final ValueChanged<_SponsoredViewMode> onChanged;

  const _SponsoredViewToggle({required this.viewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SponsoredPalette.surface.withValues(
          alpha: _SponsoredPalette.isDark ? 0.96 : 0.88,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SponsoredPalette.accentBorder),
      ),
      padding: const EdgeInsets.all(4),
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
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    _SponsoredPalette.heroMid,
                    _SponsoredPalette.heroEnd,
                  ],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _SponsoredPalette.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : _SponsoredPalette.textSecondary,
        ),
      ),
    );
  }
}

// ignore: unused_element
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
                color: _SponsoredPalette.shadow.withValues(
                  alpha: _SponsoredPalette.isDark ? 0.26 : 0.04,
                ),
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
                  gradient: LinearGradient(
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
                                  Icons.savings_outlined,
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
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSaved;

  const _SponsoredGridCard({
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
    final radius = BorderRadius.circular(compact ? 22 : 24);
    final heroColors = [
      item.iconColor.withValues(alpha: 0.94),
      item.badgeColor.withValues(alpha: 0.86),
      _SponsoredPalette.heroEnd,
    ];

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _SponsoredPalette.surface,
                _SponsoredPalette.surfaceMuted,
              ],
            ),
            borderRadius: radius,
            border: Border.all(color: item.badgeColor.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: item.badgeColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 18,
                  compact ? 16 : 18,
                  compact ? 16 : 18,
                  compact ? 18 : 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: heroColors,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius.topLeft.x),
                    topRight: Radius.circular(radius.topRight.x),
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -8,
                      right: -2,
                      child: _BackdropShape(
                        width: 82,
                        height: 82,
                        color: Colors.white,
                        opacity: 0.09,
                        radius: 24,
                        rotation: -0.28,
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      left: -10,
                      child: _BackdropShape(
                        width: 54,
                        height: 54,
                        color: Colors.white,
                        opacity: 0.08,
                        radius: 18,
                        rotation: 0.26,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _SponsoredMetaChip(
                                    icon: Icons.workspace_premium_rounded,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.uiSponsored,
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderColor: Colors.white.withValues(
                                      alpha: 0.14,
                                    ),
                                  ),
                                  if (item.trackLabel != null)
                                    _SponsoredMetaChip(
                                      icon: Icons.bolt_rounded,
                                      label: item.trackLabel!,
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderColor: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                ],
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
                        SizedBox(height: compact ? 16 : 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: _CompanyIcon(
                                logoUrl: item.logoUrl,
                                iconData: item.iconData,
                                iconColor: item.iconColor,
                                iconBgColor: item.iconBgColor,
                                size: compact ? 46 : 50,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: compact ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                      height: 1.18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (item.companyName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.companyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.84,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 18,
                  16,
                  compact ? 16 : 18,
                  compact ? 16 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description.isNotEmpty) ...[
                      Text(
                        item.description,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 11.5 : 12.5,
                          height: 1.55,
                          color: _SponsoredPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.compensation != null)
                          _SponsoredMetaChip(
                            icon: Icons.savings_outlined,
                            label: item.compensation!,
                            foregroundColor: _SponsoredPalette.accentDark,
                            backgroundColor: _SponsoredPalette.accentSurface,
                            borderColor: _SponsoredPalette.accentBorder,
                          ),
                        if (item.duration != null)
                          _SponsoredMetaChip(
                            icon: Icons.timelapse_rounded,
                            label: item.duration!,
                            foregroundColor: _SponsoredPalette.textPrimary,
                            backgroundColor: _SponsoredPalette.surfaceElevated,
                            borderColor: _SponsoredPalette.border,
                          ),
                        if (item.locationLabel != null)
                          _SponsoredMetaChip(
                            icon: Icons.place_outlined,
                            label: item.locationLabel!,
                            foregroundColor: _SponsoredPalette.textPrimary,
                            backgroundColor: _SponsoredPalette.surfaceElevated,
                            borderColor: _SponsoredPalette.border,
                          ),
                        if (item.urgencyText != null)
                          _SponsoredMetaChip(
                            icon: Icons.schedule_rounded,
                            label: item.urgencyText!,
                            foregroundColor:
                                item.urgencyColor ?? _SponsoredPalette.accent,
                            backgroundColor:
                                (item.urgencyColor ?? _SponsoredPalette.accent)
                                    .withValues(alpha: 0.08),
                            borderColor:
                                (item.urgencyColor ?? _SponsoredPalette.accent)
                                    .withValues(alpha: 0.16),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _BadgePill(
                          label: item.badgeLabel,
                          color: item.badgeColor,
                        ),
                        const Spacer(),
                        Text(
                          'Tap card for details',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: _SponsoredPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                color: _SponsoredPalette.shadow.withValues(
                  alpha: _SponsoredPalette.isDark ? 0.26 : 0.04,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [item.iconColor, item.badgeColor],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius.topLeft.x),
                      bottomLeft: Radius.circular(radius.bottomLeft.x),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _SponsoredPalette.textPrimary,
                                  ),
                                ),
                              ),
                              if (onToggleSaved != null) ...[
                                const SizedBox(width: 8),
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
                            ],
                          ),
                          if (item.companyName.isNotEmpty) ...[
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
                          ] else
                            const SizedBox(height: 1),
                          const SizedBox(height: 7),
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
                              ] else if (item.urgencyText != null) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    item.urgencyText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.2,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          item.urgencyColor ??
                                          _SponsoredPalette.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 88,
                      height: 32,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SponsoredMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  const _SponsoredMetaChip({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasWidthCap = constraints.hasBoundedWidth;
        final text = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        );
        final chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: foregroundColor),
              const SizedBox(width: 6),
              if (hasWidthCap) Flexible(child: text) else text,
            ],
          ),
        );

        if (!hasWidthCap) {
          return chip;
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: chip,
        );
      },
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
      padding: logoUrl.isEmpty ? EdgeInsets.zero : EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Icon(iconData, color: iconColor, size: size * 0.5)
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
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
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
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
                : _SponsoredPalette.surfaceMuted,
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
                      valueColor: AlwaysStoppedAnimation<Color>(
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
            child: Icon(
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
    case ApplicationStatus.withdrawn:
      return Icons.undo_rounded;
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
  final String? trackLabel;
  final String? locationLabel;
  final String badgeLabel;
  final Color badgeColor;
  final String? urgencyText;
  final Color? urgencyColor;
  final String? compensation;
  final String? duration;
  final int? daysUntilDeadline;
  final Set<_SponsoredFilter> filters;
  final OpportunityModel opportunity;
  final String searchText;
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
    required this.trackLabel,
    required this.locationLabel,
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
    required this.createdAt,
  });
}
