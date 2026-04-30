import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/training_provider.dart';
import '../../theme/app_typography.dart';
import '../../utils/display_text.dart';
import '../../utils/localized_display.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/opportunity_dashboard_widgets.dart';
import '../../widgets/saved_limit_upgrade_modal.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_search_field.dart';
import '../../widgets/student/student_workspace_shell.dart';
import 'internships_screen.dart';
import 'jobs_screen.dart';
import 'opportunity_detail_screen.dart';
import 'premium_pass_screen.dart';
import 'sponsored_opportunities_screen.dart';
import 'student_home_navigation.dart';
import 'trainings_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class OpportunitiesScreen extends StatefulWidget {
  final String? initialFilter;
  final bool embedded;

  const OpportunitiesScreen({
    super.key,
    this.initialFilter,
    this.embedded = false,
  });

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  static const int _latestItemsLimit = 5;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchSectionKey = GlobalKey();
  final GlobalKey _trendingSectionKey = GlobalKey();
  final GlobalKey _latestSectionKey = GlobalKey();

  late _OpportunityDashboardFilter _activeFilter;
  String _searchQuery = '';
  String? _selectedEmploymentFilter;
  String? _selectedWorkModeFilter;
  bool _paidOnly = false;
  bool _closingSoonOnly = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = _filterFromInitialValue(_resolveInitialFilter());
    _searchController.addListener(_handleSearchChanged);
    if (widget.embedded) {
      StudentHomeNavigation.requestedDiscoverFilter.addListener(
        _handleRequestedDiscoverFilter,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    if (widget.embedded) {
      StudentHomeNavigation.requestedDiscoverFilter.removeListener(
        _handleRequestedDiscoverFilter,
      );
    }
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _resolveInitialFilter() {
    if (!widget.embedded) {
      return widget.initialFilter;
    }

    return StudentHomeNavigation.takeRequestedDiscoverFilter() ??
        widget.initialFilter;
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

  void _handleRequestedDiscoverFilter() {
    if (!mounted) {
      return;
    }

    _applyNavigationFilter(StudentHomeNavigation.takeRequestedDiscoverFilter());
  }

  void _applyNavigationFilter(String? value) {
    final nextFilter = _filterFromInitialValue(value);
    final shouldClearSearch = _searchController.text.isNotEmpty;
    final hasStructuredFilters =
        _selectedEmploymentFilter != null ||
        _selectedWorkModeFilter != null ||
        _paidOnly ||
        _closingSoonOnly;

    if (!shouldClearSearch &&
        !hasStructuredFilters &&
        nextFilter == _activeFilter) {
      return;
    }

    setState(() {
      _activeFilter = nextFilter;
      _searchQuery = '';
      _selectedEmploymentFilter = null;
      _selectedWorkModeFilter = null;
      _paidOnly = false;
      _closingSoonOnly = false;
    });

    if (shouldClearSearch) {
      _searchController.clear();
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadData({bool force = false}) async {
    final opportunityProvider = context.read<OpportunityProvider>();
    final trainingProvider = context.read<TrainingProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[opportunityProvider.fetchOpportunities()];

    if (force || trainingProvider.trainings.isEmpty) {
      futures.add(trainingProvider.fetchTrainings());
    }

    if (userId != null && userId.isNotEmpty) {
      futures.add(savedProvider.fetchSavedOpportunities(userId));
      futures.add(applicationProvider.fetchSubmittedApplications(userId));
    }

    await Future.wait(futures);
  }

  _OpportunityDashboardFilter _filterFromInitialValue(String? value) {
    if (value == null || value.isEmpty) {
      return _OpportunityDashboardFilter.all;
    }

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
      if (!opportunity.isVisibleToStudents()) {
        return false;
      }

      if (!_matchesTypeFilter(opportunity)) {
        return false;
      }

      if (!_matchesStructuredFilters(opportunity)) {
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
        _deriveTrendingTag(opportunity),
        _employmentTypeLabel(opportunity) ?? '',
        _workModeLabel(opportunity) ?? '',
        _compensationText(opportunity) ?? '',
        OpportunityMetadata.formatPaidLabel(_effectiveIsPaid(opportunity)) ??
            '',
        OpportunityMetadata.normalizeDuration(opportunity.duration) ?? '',
        opportunity.deadlineLabel,
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
      case _OpportunityDashboardFilter.job:
        return type == OpportunityType.job;
      case _OpportunityDashboardFilter.internship:
        return type == OpportunityType.internship;
      case _OpportunityDashboardFilter.sponsored:
        return type == OpportunityType.sponsoring;
    }
  }

  bool _matchesStructuredFilters(OpportunityModel opportunity) {
    if (_selectedEmploymentFilter != null &&
        opportunity.employmentType != _selectedEmploymentFilter) {
      return false;
    }

    if (_selectedWorkModeFilter != null &&
        _normalizedWorkMode(opportunity) != _selectedWorkModeFilter) {
      return false;
    }

    if (_paidOnly && _effectiveIsPaid(opportunity) != true) {
      return false;
    }

    if (_closingSoonOnly) {
      final deadline = _deadlineFor(opportunity);
      if (deadline == null) {
        return false;
      }
      final difference = deadline.difference(DateTime.now());
      if (difference.isNegative || difference.inDays > 14) {
        return false;
      }
    }

    return true;
  }

  Future<void> _focusSearchField() async {
    await _scrollToKey(_searchSectionKey);
    if (!mounted) {
      return;
    }
    _searchFocusNode.requestFocus();
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openOpportunity(OpportunityModel opportunity) {
    OpportunityDetailScreen.show(context, opportunity);
  }

  void _openTrainings() {
    if (widget.embedded) {
      StudentHomeNavigation.switchToTab(
        context,
        StudentHomeNavigation.trainingTab,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingsScreen()),
    );
  }

  Future<void> _toggleSavedOpportunity(OpportunityModel opportunity) async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final userId = authProvider.userModel?.uid;
    final l10n = AppLocalizations.of(context)!;

    if (userId == null || userId.isEmpty) {
      context.showAppSnackBar(
        l10n.studentSignInSaveOpportunities,
        title: l10n.uiLoginRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final matchingSaved = savedProvider.savedOpportunities
        .where((item) => item.opportunityId == opportunity.id)
        .toList();
    final existingSaved = matchingSaved.isNotEmpty ? matchingSaved.first : null;

    String? error;
    var message = l10n.studentOpportunitySaved;

    if (existingSaved != null) {
      error = await savedProvider.unsaveOpportunity(existingSaved.id, userId);
      message = l10n.studentRemovedFromSavedOpportunities;
    } else {
      try {
        error = await savedProvider.saveOpportunity(
          studentId: userId,
          opportunityId: opportunity.id,
          title: DisplayText.opportunityTitle(
            opportunity.title,
            fallback: l10n.opportunityOpenFallback,
          ),
          companyName: opportunity.companyName,
          type: opportunity.type,
          location: opportunity.location,
          deadline: opportunity.deadlineLabel,
          fundingLabel: OpportunityType.isSponsoring(opportunity.type)
              ? opportunity.fundingLabel() ?? ''
              : '',
        );
      } on SavedLimitReachedException catch (e) {
        if (!mounted) return;
        await showSavedLimitUpgradeModal(
          context,
          limit: e.limit,
          onUpgrade: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumPassScreen()),
          ),
        );
        return;
      } catch (e) {
        error = e.toString();
      }
    }

    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      error ?? message,
      title: error == null
          ? l10n.trainingSavedUpdatedTitle
          : l10n.uiSaveUnavailable,
      type: error == null
          ? (existingSaved != null
                ? AppFeedbackType.removed
                : AppFeedbackType.success)
          : AppFeedbackType.error,
      icon: error == null && existingSaved != null
          ? Icons.bookmark_remove_outlined
          : null,
    );
  }

  Future<void> _showFilterSheet() async {
    var draftFilter = _activeFilter;
    var draftEmploymentType = _selectedEmploymentFilter;
    var draftWorkMode = _selectedWorkModeFilter;
    var draftPaidOnly = _paidOnly;
    var draftClosingSoonOnly = _closingSoonOnly;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OpportunityDashboardPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              IconData? icon,
            }) {
              return ChoiceChip(
                label: Text(label),
                avatar: icon == null ? null : Icon(icon, size: 18),
                selected: selected,
                onSelected: (_) => onTap(),
                selectedColor: OpportunityDashboardPalette.primary.withValues(
                  alpha: 0.14,
                ),
                labelStyle: AppTypography.product(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? OpportunityDashboardPalette.primary
                      : OpportunityDashboardPalette.textSecondary,
                ),
                side: BorderSide(
                  color: selected
                      ? OpportunityDashboardPalette.primary
                      : OpportunityDashboardPalette.border,
                ),
                backgroundColor: OpportunityDashboardPalette.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.uiBrowseCategories,
                        style: AppTypography.product(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.uiKeepTheExistingDataSourceButTailorWhatYouSee,
                        style: AppTypography.product(
                          fontSize: 13,
                          color: OpportunityDashboardPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _buildDashboardFilters(
                              AppLocalizations.of(context)!,
                            ).map((filter) {
                              return buildChip(
                                label: filter.label,
                                icon: filter.icon,
                                selected: filter.value == draftFilter,
                                onTap: () {
                                  setModalState(() {
                                    draftFilter = filter.value;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.uiEmploymentType,
                        style: AppTypography.product(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildChip(
                            label: AppLocalizations.of(context)!.uiAny,
                            selected: draftEmploymentType == null,
                            onTap: () {
                              setModalState(() {
                                draftEmploymentType = null;
                              });
                            },
                          ),
                          ...OpportunityMetadata.employmentTypes.map((type) {
                            final label =
                                OpportunityMetadata.formatEmploymentType(
                                  type,
                                ) ??
                                type;
                            return buildChip(
                              label: label,
                              selected: draftEmploymentType == type,
                              onTap: () {
                                setModalState(() {
                                  draftEmploymentType = type;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.uiWorkMode,
                        style: AppTypography.product(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildChip(
                            label: AppLocalizations.of(context)!.uiAny,
                            selected: draftWorkMode == null,
                            onTap: () {
                              setModalState(() {
                                draftWorkMode = null;
                              });
                            },
                          ),
                          ...OpportunityMetadata.workModes.map((mode) {
                            final label = _workModeFilterLabel(mode);
                            return buildChip(
                              label: label,
                              selected: draftWorkMode == mode,
                              onTap: () {
                                setModalState(() {
                                  draftWorkMode = mode;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.uiQuickFilters,
                        style: AppTypography.product(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildChip(
                            label: AppLocalizations.of(context)!.uiPaidOnly,
                            selected: draftPaidOnly,
                            onTap: () {
                              setModalState(() {
                                draftPaidOnly = !draftPaidOnly;
                              });
                            },
                            icon: Icons.payments_outlined,
                          ),
                          buildChip(
                            label: AppLocalizations.of(context)!.uiClosingSoon,
                            selected: draftClosingSoonOnly,
                            onTap: () {
                              setModalState(() {
                                draftClosingSoonOnly = !draftClosingSoonOnly;
                              });
                            },
                            icon: Icons.hourglass_bottom_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _activeFilter =
                                      _OpportunityDashboardFilter.all;
                                  _selectedEmploymentFilter = null;
                                  _selectedWorkModeFilter = null;
                                  _paidOnly = false;
                                  _closingSoonOnly = false;
                                  if (_searchQuery.isNotEmpty) {
                                    _searchController.clear();
                                  }
                                });
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    OpportunityDashboardPalette.textSecondary,
                                side: BorderSide(
                                  color: OpportunityDashboardPalette.border,
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.uiClear,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _activeFilter = draftFilter;
                                  _selectedEmploymentFilter =
                                      draftEmploymentType;
                                  _selectedWorkModeFilter = draftWorkMode;
                                  _paidOnly = draftPaidOnly;
                                  _closingSoonOnly = draftClosingSoonOnly;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    OpportunityDashboardPalette.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.uiApply,
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
          },
        );
      },
    );
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
    return OpportunityType.label(type, AppLocalizations.of(context)!);
  }

  String _summaryText(int visibleCount, int totalCount, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filterLabel = switch (_activeFilter) {
      _OpportunityDashboardFilter.all => l10n.uiOpportunities.toLowerCase(),
      _OpportunityDashboardFilter.job => l10n.uiJobs.toLowerCase(),
      _OpportunityDashboardFilter.internship =>
        l10n.uiInternships.toLowerCase(),
      _OpportunityDashboardFilter.sponsored => l10n.uiSponsored.toLowerCase(),
    };

    if (_searchQuery.isEmpty &&
        _activeFilter == _OpportunityDashboardFilter.all) {
      return l10n.uiCountOpenOpportunitiesCuratedForStudents(totalCount);
    }

    if (_searchQuery.isNotEmpty ||
        _selectedEmploymentFilter != null ||
        _selectedWorkModeFilter != null ||
        _paidOnly ||
        _closingSoonOnly) {
      return l10n.studentMatchingListingsFound(
        visibleCount,
        filterLabel == l10n.uiOpportunities.toLowerCase()
            ? l10n.studentListing
            : filterLabel,
      );
    }

    return l10n.studentOpenListingsFound(
      visibleCount,
      filterLabel == l10n.uiOpportunities.toLowerCase()
          ? l10n.studentListing
          : filterLabel,
    );
  }

  DateTime? _postedAt(OpportunityModel opportunity) {
    return opportunity.createdAt?.toDate() ??
        opportunity.readDateTime([
          'postedAt',
          'publishedAt',
          'created_at',
          'posted_at',
          'published_at',
        ]);
  }

  DateTime? _deadlineFor(OpportunityModel opportunity) {
    final explicitDeadline = opportunity.effectiveDeadline;
    if (explicitDeadline != null) {
      return explicitDeadline;
    }

    final fallback = opportunity.readDateTime([
      'deadlineAt',
      'closingDate',
      'closingAt',
      'expiresAt',
      'expiryDate',
      'endDate',
    ]);
    if (fallback == null) {
      return null;
    }

    return OpportunityMetadata.normalizeDeadline(fallback);
  }

  String _formatDeadlineDisplay(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = _deadlineFor(opportunity);
    if (parsed == null) {
      final fallback = opportunity.deadlineLabel.trim();
      return fallback.isEmpty ? l10n.studentNoDeadline : fallback;
    }

    return LocalizedDisplay.shortDate(context, parsed);
  }

  String _relativePostedTime(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final createdAt = _postedAt(opportunity);
    if (createdAt == null) {
      return l10n.studentRecentlyAdded;
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return l10n.uiJustNow;
    }
    if (difference.inHours < 1) {
      return l10n.studentMinutesAgoCompact(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return l10n.studentHoursAgoCompact(difference.inHours);
    }
    if (difference.inDays < 7) {
      return l10n.studentDaysAgoCompact(difference.inDays);
    }
    if (difference.inDays < 30) {
      final weeks = math.max(1, (difference.inDays / 7).floor());
      return l10n.studentWeeksAgoCompact(weeks);
    }

    return LocalizedDisplay.shortDate(context, createdAt);
  }

  String _toTitleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool _isNewOpportunity(OpportunityModel opportunity) {
    final createdAt = _postedAt(opportunity);
    if (createdAt == null) {
      return false;
    }

    return DateTime.now().difference(createdAt).inDays < 3;
  }

  String _closingSoonText(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final deadline = _deadlineFor(opportunity);
    if (deadline == null) {
      return l10n.studentDeadlineUnavailable;
    }

    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return l10n.studentClosesToday;
    }
    if (difference.inHours < 1) {
      final minutes = math.max(1, difference.inMinutes);
      return l10n.studentClosesInMinutes(minutes);
    }
    if (difference.inHours < 24) {
      return l10n.studentClosesInHours(difference.inHours);
    }
    if (difference.inDays == 1) {
      return l10n.studentClosesTomorrow;
    }

    return l10n.studentClosesInDays(difference.inDays);
  }

  Color _closingSoonColor(OpportunityModel opportunity) {
    final deadline = _deadlineFor(opportunity);
    if (deadline == null) {
      return OpportunityDashboardPalette.warning;
    }

    final difference = deadline.difference(DateTime.now());
    return difference.inHours <= 24
        ? OpportunityDashboardPalette.error
        : OpportunityDashboardPalette.warning;
  }

  String? _explicitCategoryTag(OpportunityModel opportunity) {
    final rawTag = opportunity.readString([
      'category',
      'tag',
      'field',
      'domain',
      'industry',
      'department',
      'track',
    ]);
    if (rawTag == null) {
      return null;
    }

    final compact = rawTag.split(RegExp(r'[/,&|-]')).first.trim();
    if (compact.isEmpty) {
      return null;
    }

    final words = compact
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final normalized = words.take(2).join(' ').toUpperCase();
    if (normalized.length <= 12) {
      return normalized;
    }

    return words.isEmpty ? null : words.first.toUpperCase();
  }

  String _deriveTrendingTag(OpportunityModel opportunity) {
    final explicitTag = _explicitCategoryTag(opportunity);
    if (explicitTag != null) {
      return explicitTag;
    }

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
    if (text.contains('finance') ||
        text.contains('account') ||
        text.contains('audit')) {
      return 'FINANCE';
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

  DateTime? _recencyFor(OpportunityModel opportunity) {
    return opportunity.updatedAt?.toDate() ?? _postedAt(opportunity);
  }

  DateTime? _latestDate(OpportunityModel opportunity) {
    return _postedAt(opportunity) ?? opportunity.updatedAt?.toDate();
  }

  int _compareLatestFirst(OpportunityModel left, OpportunityModel right) {
    final leftDate = _latestDate(left);
    final rightDate = _latestDate(right);
    if (leftDate != null || rightDate != null) {
      if (leftDate == null) {
        return 1;
      }
      if (rightDate == null) {
        return -1;
      }

      final dateDiff = rightDate.compareTo(leftDate);
      if (dateDiff != 0) {
        return dateDiff;
      }
    }

    final companyDiff = left.companyName.trim().toLowerCase().compareTo(
      right.companyName.trim().toLowerCase(),
    );
    if (companyDiff != 0) {
      return companyDiff;
    }

    final titleDiff = left.title.trim().toLowerCase().compareTo(
      right.title.trim().toLowerCase(),
    );
    if (titleDiff != 0) {
      return titleDiff;
    }

    return left.id.compareTo(right.id);
  }

  int _trendingScore(OpportunityModel opportunity) {
    var score = 0;

    if (opportunity.isFeatured) {
      score += 40;
    }
    if (_isNewOpportunity(opportunity)) {
      score += 28;
    }
    if (_compensationText(opportunity) != null) {
      score += 12;
    }

    final workMode = _workModeKey(opportunity);
    if (workMode == 'remote') {
      score += 10;
    } else if (workMode == 'hybrid') {
      score += 6;
    }

    final deadline = _deadlineFor(opportunity);
    if (deadline != null) {
      final difference = deadline.difference(DateTime.now());
      if (!difference.isNegative && difference.inDays <= 10) {
        score += 8;
      }
    }

    score += math.min(opportunity.tags.length, 3) * 2;
    return score;
  }

  String _trendingSignalLabel(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    if (opportunity.isFeatured) {
      return l10n.studentPartnerPick;
    }
    if (_isNewOpportunity(opportunity)) {
      return l10n.studentNewThisWeek;
    }

    final deadline = _deadlineFor(opportunity);
    if (deadline != null) {
      final difference = deadline.difference(DateTime.now());
      if (!difference.isNegative && difference.inDays <= 7) {
        return l10n.uiClosingSoon;
      }
    }

    final workMode = _workModeKey(opportunity);
    if (workMode == 'remote') {
      return l10n.studentRemoteFriendly;
    }
    if (workMode == 'hybrid') {
      return l10n.studentHybridSetup;
    }

    final compensation = _compensationText(opportunity)?.toLowerCase() ?? '';
    final paid = _effectiveIsPaid(opportunity);
    if (paid == true ||
        (paid == null && compensation.isNotEmpty && compensation != 'unpaid')) {
      return l10n.studentPaidTrack;
    }

    final explicitTag = _explicitCategoryTag(opportunity);
    if (explicitTag != null && explicitTag.isNotEmpty) {
      return _toTitleCase(explicitTag);
    }

    return switch (OpportunityType.parse(opportunity.type)) {
      OpportunityType.internship => l10n.studentStudentGrowth,
      OpportunityType.sponsoring => l10n.studentSponsoredSupport,
      OpportunityType.job => l10n.studentCareerMove,
      _ => l10n.studentOpenRole,
    };
  }

  List<String> _compactDetailItems(
    OpportunityModel opportunity, {
    int maxItems = 2,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final items = <String>[];
    final employment = _employmentTypeLabel(opportunity);
    final workMode = _workModeLabel(opportunity);
    final duration = OpportunityMetadata.normalizeDuration(
      opportunity.duration,
    );
    final deadline = _deadlineFor(opportunity);
    final postedAt = _postedAt(opportunity);

    if (workMode != null) {
      items.add(workMode);
    }

    if (OpportunityType.parse(opportunity.type) == OpportunityType.internship &&
        duration != null) {
      items.add(duration);
    }

    if (deadline != null) {
      final difference = deadline.difference(DateTime.now());
      if (!difference.isNegative && difference.inDays <= 10) {
        items.add(_closingSoonText(opportunity));
      }
    }

    if (postedAt != null) {
      items.add(_relativePostedTime(opportunity));
    }

    if (employment != null &&
        employment.toLowerCase() !=
            OpportunityType.label(
              opportunity.type,
              AppLocalizations.of(context)!,
            ).toLowerCase()) {
      items.add(employment);
    }

    if (items.isEmpty && deadline != null) {
      items.add(l10n.studentDeadlineDate(_formatDeadlineDisplay(opportunity)));
    }

    if (items.isEmpty) {
      items.add(
        OpportunityType.label(opportunity.type, AppLocalizations.of(context)!),
      );
    }

    return _uniqueValues(items).take(maxItems).toList(growable: false);
  }

  List<String> _trendingDetailChips(OpportunityModel opportunity) {
    return _compactDetailItems(opportunity, maxItems: 1);
  }

  List<OpportunityModel> _buildTrendingItems(List<OpportunityModel> visible) {
    final items = <OpportunityModel>[...visible];
    items.sort((left, right) {
      final scoreDiff = _trendingScore(right).compareTo(_trendingScore(left));
      if (scoreDiff != 0) {
        return scoreDiff;
      }

      final rightTime = _recencyFor(right);
      final leftTime = _recencyFor(left);
      if (leftTime == null && rightTime == null) {
        return 0;
      }
      if (leftTime == null) {
        return 1;
      }
      if (rightTime == null) {
        return -1;
      }

      return rightTime.compareTo(leftTime);
    });

    return items.take(6).toList(growable: false);
  }

  List<OpportunityModel> _buildLatestItems(List<OpportunityModel> visible) {
    final items = <OpportunityModel>[...visible];
    items.sort(_compareLatestFirst);

    return items.take(_latestItemsLimit).toList(growable: false);
  }

  bool _isShowcaseReadyOpportunity(OpportunityModel opportunity) {
    final title = opportunity.title.trim();
    final company = opportunity.companyName.trim();
    final description = opportunity.description.trim();
    final location = _locationLabel(opportunity)?.trim() ?? '';
    final compensation = _compensationText(opportunity)?.trim() ?? '';

    return title.isNotEmpty ||
        company.isNotEmpty ||
        description.isNotEmpty ||
        location.isNotEmpty ||
        compensation.isNotEmpty;
  }

  List<OpportunityModel> _buildClosingSoonItems(
    List<OpportunityModel> visible,
  ) {
    final items = visible.where((opportunity) {
      final deadline = _deadlineFor(opportunity);
      if (deadline == null) {
        return false;
      }

      final difference = deadline.difference(DateTime.now());
      return !difference.isNegative && difference.inDays <= 14;
    }).toList();

    items.sort((a, b) {
      final first = _deadlineFor(a);
      final second = _deadlineFor(b);
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

  String _companyName(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final companyName = opportunity.companyName.trim();
    return companyName.isEmpty ? l10n.studentFutureGatePartner : companyName;
  }

  String? _companyNameOrNull(OpportunityModel opportunity) {
    final companyName = opportunity.companyName.trim();
    return companyName.isEmpty ? null : companyName;
  }

  String? _locationLabel(OpportunityModel opportunity) {
    final location = opportunity.location.trim();
    if (location.isNotEmpty) {
      return location;
    }

    final fallback = opportunity.readString([
      'city',
      'region',
      'country',
      'officeLocation',
      'address',
      'place',
    ]);
    if (fallback != null) {
      return fallback;
    }

    final l10n = AppLocalizations.of(context)!;
    return switch (_workModeKey(opportunity)) {
      'remote' => l10n.workModeRemote,
      'hybrid' => l10n.workModeHybrid,
      _ => null,
    };
  }

  String _companyLocationText(OpportunityModel opportunity) {
    final company = _companyName(opportunity);
    final location = _locationLabel(opportunity);

    if (location == null || location.isEmpty) {
      return company;
    }

    return '$company - $location';
  }

  String? _compensationText(OpportunityModel opportunity) {
    if (OpportunityType.isSponsoring(opportunity.type)) {
      return opportunity.fundingLabel();
    }

    // Opportunity cards should only show structured salary data, not the
    // optional compensation note reserved for the detail screen.
    final structuredLabel = OpportunityMetadata.formatSalaryRange(
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
    );
    if (structuredLabel != null) {
      return LocalizedDisplay.compensation(context, structuredLabel);
    }

    final paidLabel = OpportunityMetadata.formatPaidLabel(
      _effectiveIsPaid(opportunity),
    );
    return paidLabel == null
        ? null
        : LocalizedDisplay.metadataLabel(context, paidLabel);
  }

  String? _workModeLabel(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final workMode = _workModeKey(opportunity);

    return switch (workMode) {
      'remote' => l10n.workModeRemote,
      'hybrid' => l10n.workModeHybrid,
      'onsite' => l10n.workModeOnsite,
      _ => null,
    };
  }

  String _workModeFilterLabel(String mode) {
    final l10n = AppLocalizations.of(context)!;
    final lower = mode.trim().toLowerCase();
    if (lower.contains('remote')) return l10n.workModeRemote;
    if (lower.contains('hybrid')) return l10n.workModeHybrid;
    if (lower.contains('onsite') || lower.contains('on-site')) {
      return l10n.workModeOnsite;
    }
    return OpportunityMetadata.formatWorkMode(mode) ?? mode;
  }

  String? _workModeKey(OpportunityModel opportunity) {
    final normalizedMode = _normalizedWorkMode(opportunity);
    if (normalizedMode != null) {
      final lower = normalizedMode.trim().toLowerCase();
      if (lower.contains('remote')) return 'remote';
      if (lower.contains('hybrid')) return 'hybrid';
      if (lower.contains('onsite') || lower.contains('on-site')) {
        return 'onsite';
      }
    }

    final searchable = [
      opportunity.location,
      opportunity.description,
      opportunity.requirements,
    ].whereType<String>().join(' ').toLowerCase();

    if (searchable.contains('hybrid')) {
      return 'hybrid';
    }
    if (searchable.contains('remote')) {
      return 'remote';
    }
    if (searchable.contains('on-site') ||
        searchable.contains('onsite') ||
        searchable.contains('on site')) {
      return 'onsite';
    }

    return null;
  }

  List<String> _latestStatusItems(OpportunityModel opportunity) {
    return _compactDetailItems(opportunity);
  }

  String? _employmentTypeLabel(OpportunityModel opportunity) {
    final label = OpportunityMetadata.formatEmploymentType(
      opportunity.employmentType,
    );
    return label == null
        ? null
        : LocalizedDisplay.metadataLabel(context, label);
  }

  String? _normalizedWorkMode(OpportunityModel opportunity) {
    return opportunity.workMode ??
        OpportunityMetadata.extractWorkMode(opportunity.rawData);
  }

  bool? _effectiveIsPaid(OpportunityModel opportunity) {
    return opportunity.isPaid ??
        OpportunityMetadata.extractIsPaid(opportunity.rawData);
  }

  List<String> _metadataItems(
    OpportunityModel opportunity, {
    int maxItems = 3,
  }) {
    final items = OpportunityMetadata.buildMetadataItems(
      type: opportunity.type,
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      fundingAmount: opportunity.fundingAmount,
      fundingCurrency: opportunity.fundingCurrency,
      fundingNote: opportunity.fundingNote,
      isPaid: _effectiveIsPaid(opportunity),
      employmentType: opportunity.employmentType,
      workMode: _normalizedWorkMode(opportunity),
      duration: opportunity.duration,
      maxItems: maxItems,
    );
    if (items.isNotEmpty) {
      return items
          .map((item) => LocalizedDisplay.metadataLabel(context, item))
          .toList(growable: false);
    }

    final legacyItems = <String>[];
    final workMode = _workModeLabel(opportunity);
    if (workMode != null) {
      legacyItems.add(workMode);
    }

    return OpportunityMetadata.uniqueNonEmpty(
      legacyItems,
    ).take(maxItems).toList();
  }

  List<String> _uniqueValues(List<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }

    return result;
  }

  Widget _buildHeaderSection(int visibleCount, int totalCount) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.uiFindYourNextMove,
          style: AppTypography.product(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: OpportunityDashboardPalette.textPrimary,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.uiBrowseJobsInternshipsSponsoredTracksAndTrainingPicksDesignedFor,
          style: AppTypography.product(
            fontSize: 12,
            height: 1.35,
            color: OpportunityDashboardPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _searchSectionKey,
          child: StudentSearchField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: l10n.uiSearchJobsInternshipsOrSponsoredRoles,
            onClear: _searchController.clear,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _buildDashboardFilters(
              AppLocalizations.of(context)!,
            ).length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _buildDashboardFilters(
                AppLocalizations.of(context)!,
              )[index];
              final isActive = filter.value == _activeFilter;

              return GestureDetector(
                onTap: () => _setFilter(filter.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
                        size: 14,
                        color: isActive
                            ? OpportunityDashboardPalette.primary
                            : OpportunityDashboardPalette.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter.label,
                        style: AppTypography.product(
                          fontSize: 11,
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
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _summaryText(visibleCount, totalCount, context),
            key: ValueKey(
              'summary-$visibleCount-$totalCount-$_activeFilter-$_searchQuery',
            ),
            style: AppTypography.product(
              fontSize: 11.5,
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
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final appliedStatuses = applicationProvider.appliedStatusMap;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isCompactTrendingLayout =
        MediaQuery.sizeOf(context).width < 380 || textScale > 1.08;
    final trendingCardHeight = isCompactTrendingLayout ? 226.0 : 208.0;

    final allOpportunities = opportunityProvider.opportunities;
    final visibleOpportunities = _applyFilters(allOpportunities);
    final jobItems = allOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) == OpportunityType.job,
        )
        .toList();
    final internshipItems = allOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) ==
              OpportunityType.internship,
        )
        .toList();
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
    final trainingBadgeCount =
        trainingProvider.isLoading ||
            (trainingProvider.errorMessage != null && trainingItems.isEmpty)
        ? null
        : trainingItems.length;
    final trainingBadgeLabel = trainingProvider.isLoading
        ? AppLocalizations.of(context)!.uiLoading
        : trainingProvider.errorMessage != null && trainingItems.isEmpty
        ? AppLocalizations.of(context)!.uiUnavailable
        : null;
    final showcaseOpportunities = visibleOpportunities
        .where(_isShowcaseReadyOpportunity)
        .toList(growable: false);
    final trendingItems = _buildTrendingItems(showcaseOpportunities);
    final latestItems = _buildLatestItems(showcaseOpportunities);
    final closingSoonItems = _buildClosingSoonItems(showcaseOpportunities);
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();
    final hasActiveDiscoveryFilters =
        _searchQuery.isNotEmpty ||
        _activeFilter != _OpportunityDashboardFilter.all ||
        _selectedEmploymentFilter != null ||
        _selectedWorkModeFilter != null ||
        _paidOnly ||
        _closingSoonOnly;
    final resultItems = <OpportunityModel>[...showcaseOpportunities]
      ..sort(_compareLatestFirst);

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.embedded
          ? null
          : StudentWorkspaceAppBar(
              title: AppLocalizations.of(context)!.uiDiscover,
              subtitle: AppLocalizations.of(
                context,
              )!.uiJobsInternshipsSponsoredTracksAndTrainingInOneStream,
              icon: Icons.explore_rounded,
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
              actions: [
                StudentWorkspaceActionButton(
                  icon: Icons.search_rounded,
                  tooltip: AppLocalizations.of(context)!.uiFocusSearch,
                  onTap: () => _focusSearchField(),
                ),
                StudentWorkspaceActionButton(
                  icon: Icons.tune_rounded,
                  tooltip: AppLocalizations.of(context)!.uiFilterOpportunities,
                  onTap: () => _showFilterSheet(),
                ),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeaderSection(
                        visibleOpportunities.length,
                        allOpportunities.length,
                      ),
                    ),
                  ),
                  if (hasActiveDiscoveryFilters) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        key: _latestSectionKey,
                        child: OpportunitySectionHeader(
                          title: AppLocalizations.of(
                            context,
                          )!.discoverResultsTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.discoverResultsSubtitle,
                          accentColor: OpportunityDashboardPalette.primary,
                        ),
                      ),
                    ),
                    if (resultItems.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        sliver: SliverToBoxAdapter(
                          child: OpportunityDashboardEmptyState(
                            icon: Icons.search_off_rounded,
                            title: AppLocalizations.of(
                              context,
                            )!.uiNoOpportunitiesMatchView,
                            subtitle: AppLocalizations.of(
                              context,
                            )!.discoverNoResultsHint,
                            color: OpportunityDashboardPalette.primary,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        sliver: SliverList.separated(
                          itemCount: resultItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final opportunity = resultItems[index];
                            return OpportunityListTile(
                              opportunity: opportunity,
                              typeLabel: OpportunityType.label(
                                opportunity.type,
                                AppLocalizations.of(context)!,
                              ),
                              companyLocationText: _companyLocationText(
                                opportunity,
                              ),
                              compensationText: _compensationText(opportunity),
                              detailChips: _latestStatusItems(opportunity),
                              badgeText: _isNewOpportunity(opportunity)
                                  ? AppLocalizations.of(
                                      context,
                                    )!.studentNewBadge
                                  : null,
                              badgeColor: OpportunityDashboardPalette.primary,
                              applicationStatus:
                                  appliedStatuses[opportunity.id],
                              isSaved: savedIds.contains(opportunity.id),
                              isBusy: savedProvider.isLoading,
                              onTap: () => _openOpportunity(opportunity),
                              onToggleSaved: () =>
                                  _toggleSavedOpportunity(opportunity),
                            );
                          },
                        ),
                      ),
                  ] else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            OpportunityHeroCard(
                              title: AppLocalizations.of(context)!.uiJobs,
                              subtitle: AppLocalizations.of(
                                context,
                              )!.uiDiscoverPremiumOpenRolesFromTrustedEmployersAndRemoteReady,
                              supportingLabel: AppLocalizations.of(
                                context,
                              )!.studentOpenPositionsCount(jobItems.length),
                              icon: Icons.work_outline_rounded,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JobsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 140,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OpportunityCategoryCard(
                                      title: AppLocalizations.of(
                                        context,
                                      )!.uiInternships,
                                      subtitle: AppLocalizations.of(
                                        context,
                                      )!.uiInternshipsSubtitle,
                                      caption: AppLocalizations.of(context)!
                                          .studentOpenInternshipsCount(
                                            internshipItems.length,
                                          ),
                                      icon: Icons.school_outlined,
                                      color:
                                          OpportunityDashboardPalette.secondary,
                                      backgroundColor:
                                          OpportunityDashboardPalette.secondary
                                              .withValues(alpha: 0.10),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const InternshipsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OpportunityCategoryCard(
                                      title: AppLocalizations.of(
                                        context,
                                      )!.uiSponsored,
                                      subtitle: AppLocalizations.of(
                                        context,
                                      )!.uiSponsoredSubtitle,
                                      caption: AppLocalizations.of(context)!
                                          .studentActiveTracksCount(
                                            sponsoredItems.length,
                                          ),
                                      icon: Icons.campaign_outlined,
                                      color: OpportunityDashboardPalette.accent,
                                      backgroundColor:
                                          OpportunityDashboardPalette.accent
                                              .withValues(alpha: 0.10),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SponsoredOpportunitiesScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TrainingProgramsCard(
                              title: AppLocalizations.of(context)!.uiTraining,
                              subtitle: '',
                              badgeCount: trainingBadgeCount,
                              badgeLabel: trainingBadgeLabel,
                              onTap: _openTrainings,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        key: _trendingSectionKey,
                        child: TrendingOpportunitySectionHeader(
                          title: AppLocalizations.of(
                            context,
                          )!.uiTrendingOpportunities,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.discoverTrendingSubtitle,
                          actionLabel: AppLocalizations.of(context)!.uiViewAll,
                          onAction: () async {
                            _setFilter(_OpportunityDashboardFilter.all);
                            await _scrollToKey(_latestSectionKey);
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        10,
                        0,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: trendingItems.isEmpty
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 20,
                                ),
                                child: OpportunityDashboardEmptyState(
                                  icon: Icons.trending_up_rounded,
                                  title: AppLocalizations.of(
                                    context,
                                  )!.uiNoTrendingOpportunities,
                                  subtitle: AppLocalizations.of(
                                    context,
                                  )!.discoverTrendingEmptyHint,
                                  color: OpportunityDashboardPalette.primary,
                                ),
                              )
                            : SizedBox(
                                height: trendingCardHeight,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 20,
                                  ),
                                  itemCount: trendingItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final opportunity = trendingItems[index];

                                    return TrendingOpportunityCard(
                                      opportunity: opportunity,
                                      rank: index + 1,
                                      typeLabel: OpportunityType.label(
                                        opportunity.type,
                                        AppLocalizations.of(context)!,
                                      ),
                                      trendLabel: _trendingSignalLabel(
                                        opportunity,
                                      ),
                                      companyName: _companyNameOrNull(
                                        opportunity,
                                      ),
                                      locationText: _locationLabel(opportunity),
                                      detailChips: _trendingDetailChips(
                                        opportunity,
                                      ),
                                      compensationText: _compensationText(
                                        opportunity,
                                      ),
                                      applicationStatus:
                                          appliedStatuses[opportunity.id],
                                      isSaved: savedIds.contains(
                                        opportunity.id,
                                      ),
                                      isBusy: savedProvider.isLoading,
                                      onTap: () =>
                                          _openOpportunity(opportunity),
                                      onToggleSaved: () =>
                                          _toggleSavedOpportunity(opportunity),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      sliver: SliverToBoxAdapter(
                        key: _latestSectionKey,
                        child: OpportunitySectionHeader(
                          title: AppLocalizations.of(
                            context,
                          )!.uiLatestOpportunities,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.discoverLatestSubtitle(_latestItemsLimit),
                          accentColor: OpportunityDashboardPalette.success,
                        ),
                      ),
                    ),
                    if (latestItems.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: OpportunityDashboardEmptyState(
                            icon: Icons.search_off_rounded,
                            title: AppLocalizations.of(
                              context,
                            )!.uiNoOpportunitiesMatchView,
                            subtitle: AppLocalizations.of(
                              context,
                            )!.discoverNoResultsHint,
                            color: OpportunityDashboardPalette.success,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverList.separated(
                          itemCount: latestItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final opportunity = latestItems[index];
                            return OpportunityListTile(
                              opportunity: opportunity,
                              typeLabel: OpportunityType.label(
                                opportunity.type,
                                AppLocalizations.of(context)!,
                              ),
                              companyLocationText: _companyLocationText(
                                opportunity,
                              ),
                              compensationText: _compensationText(opportunity),
                              detailChips: _latestStatusItems(opportunity),
                              badgeText: _isNewOpportunity(opportunity)
                                  ? AppLocalizations.of(
                                      context,
                                    )!.studentNewBadge
                                  : null,
                              badgeColor: OpportunityDashboardPalette.success,
                              applicationStatus:
                                  appliedStatuses[opportunity.id],
                              isSaved: savedIds.contains(opportunity.id),
                              isBusy: savedProvider.isLoading,
                              onTap: () => _openOpportunity(opportunity),
                              onToggleSaved: () =>
                                  _toggleSavedOpportunity(opportunity),
                            );
                          },
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: OpportunitySectionHeader(
                          title: AppLocalizations.of(context)!.uiClosingSoon,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.uiUrgentApplicationsThatNeedAttentionBeforeTheyExpire,
                          accentColor: OpportunityDashboardPalette.error,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      sliver: closingSoonItems.isEmpty
                          ? SliverToBoxAdapter(
                              child: OpportunityDashboardEmptyState(
                                icon: Icons.hourglass_bottom_rounded,
                                title: AppLocalizations.of(
                                  context,
                                )!.uiNoUrgentDeadlines,
                                subtitle: AppLocalizations.of(
                                  context,
                                )!.uiOpportunitiesNearingTheirDeadlinesAreHighlightedHere,
                                color: OpportunityDashboardPalette.error,
                              ),
                            )
                          : SliverList.separated(
                              itemCount: closingSoonItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final opportunity = closingSoonItems[index];
                                final urgencyColor = _closingSoonColor(
                                  opportunity,
                                );

                                return OpportunityListTile(
                                  opportunity: opportunity,
                                  typeLabel: OpportunityType.label(
                                    opportunity.type,
                                    AppLocalizations.of(context)!,
                                  ),
                                  companyLocationText: _companyLocationText(
                                    opportunity,
                                  ),
                                  compensationText: _compensationText(
                                    opportunity,
                                  ),
                                  detailChips: [
                                    _closingSoonText(opportunity),
                                    ..._metadataItems(
                                      opportunity,
                                      maxItems: 3,
                                    ).where(
                                      (item) =>
                                          item !=
                                          _compensationText(opportunity),
                                    ),
                                  ],
                                  badgeText: AppLocalizations.of(
                                    context,
                                  )!.studentUrgentBadge,
                                  badgeColor: urgencyColor,
                                  statusColor: urgencyColor,
                                  applicationStatus:
                                      appliedStatuses[opportunity.id],
                                  isSaved: savedIds.contains(opportunity.id),
                                  isBusy: savedProvider.isLoading,
                                  onTap: () => _openOpportunity(opportunity),
                                  onToggleSaved: () =>
                                      _toggleSavedOpportunity(opportunity),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );

    if (widget.embedded) {
      return scaffold;
    }

    return AppShellBackground(child: scaffold);
  }
}

enum _OpportunityDashboardFilter { all, job, internship, sponsored }

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

List<_DashboardFilterDefinition> _buildDashboardFilters(
  AppLocalizations l10n,
) => [
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.all,
    label: l10n.uiAll,
    icon: Icons.apps_rounded,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.job,
    label: l10n.uiJobs,
    icon: Icons.work_outline_rounded,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.internship,
    label: l10n.uiInternships,
    icon: Icons.school_outlined,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.sponsored,
    label: l10n.uiSponsored,
    icon: Icons.campaign_outlined,
  ),
];
