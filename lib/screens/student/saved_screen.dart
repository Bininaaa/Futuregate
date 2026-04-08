import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../models/opportunity_model.dart';
import '../../models/saved_idea_model.dart';
import '../../models/saved_opportunity_model.dart';
import '../../models/saved_scholarship_model.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/saved_scholarship_provider.dart';
import '../../providers/training_provider.dart';
import '../../services/opportunity_service.dart';
import '../../services/scholarship_service.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../../widgets/student_opportunity_hub_widgets.dart';
import 'idea_details_screen.dart';
import 'opportunities_screen.dart';
import 'opportunity_detail_screen.dart';
import 'scholarship_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

enum _SavedHubFilter { all, opportunities, scholarships, trainings, ideas }

class _SavedScreenState extends State<SavedScreen> {
  final OpportunityService _opportunityService = OpportunityService();
  final ScholarshipService _scholarshipService = ScholarshipService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _SavedHubFilter _selectedFilter = _SavedHubFilter.all;
  String? _selectedOpportunityType;
  String? _openingItemKey;
  String? _removingItemKey;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedContent());
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

  Future<void> _loadSavedContent() async {
    if (!mounted) {
      return;
    }

    final studentId = context.read<AuthProvider>().userModel?.uid.trim();
    if (studentId == null || studentId.isEmpty) {
      return;
    }

    await Future.wait([
      context.read<SavedOpportunityProvider>().fetchSavedOpportunities(
        studentId,
      ),
      context.read<SavedScholarshipProvider>().fetchSavedScholarships(
        studentId,
      ),
      context.read<TrainingProvider>().fetchSavedTrainings(studentId),
      context.read<ProjectIdeaProvider>().fetchSavedIdeas(studentId),
      context.read<OpportunityProvider>().fetchOpportunities(),
    ]);
  }

  List<_SavedHubItem> _buildItems({
    required List<SavedOpportunityModel> opportunities,
    required List<SavedScholarshipModel> scholarships,
    required List<TrainingModel> trainings,
    required List<SavedIdeaModel> ideas,
  }) {
    final items = <_SavedHubItem>[
      ...opportunities.map(_SavedHubItem.opportunity),
      ...scholarships.map(_SavedHubItem.scholarship),
      ...trainings.map(_SavedHubItem.training),
      ...ideas.map(_SavedHubItem.idea),
    ];

    final query = _searchQuery.trim().toLowerCase();

    final filtered =
        items.where((item) {
          if (!_matchesFilter(item)) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final searchText = <String>[
            item.title,
            item.subtitle,
            item.supporting,
            item.categoryLabel,
          ].join(' ').toLowerCase();

          return searchText.contains(query);
        }).toList()..sort((first, second) {
          final firstTime = first.savedAt?.millisecondsSinceEpoch ?? 0;
          final secondTime = second.savedAt?.millisecondsSinceEpoch ?? 0;
          return secondTime.compareTo(firstTime);
        });

    return filtered;
  }

  bool _matchesFilter(_SavedHubItem item) {
    final matchesMainFilter = switch (_selectedFilter) {
      _SavedHubFilter.all => true,
      _SavedHubFilter.opportunities =>
        item.kind == _SavedHubItemKind.opportunity,
      _SavedHubFilter.scholarships =>
        item.kind == _SavedHubItemKind.scholarship,
      _SavedHubFilter.trainings => item.kind == _SavedHubItemKind.training,
      _SavedHubFilter.ideas => item.kind == _SavedHubItemKind.idea,
    };

    if (!matchesMainFilter) {
      return false;
    }

    if (_selectedFilter != _SavedHubFilter.opportunities ||
        _selectedOpportunityType == null) {
      return true;
    }

    return item.kind == _SavedHubItemKind.opportunity &&
        OpportunityType.parse(item.opportunity!.type) ==
            _selectedOpportunityType;
  }

  int _countForFilter({
    required List<SavedOpportunityModel> opportunities,
    required List<SavedScholarshipModel> scholarships,
    required List<TrainingModel> trainings,
    required List<SavedIdeaModel> ideas,
    required _SavedHubFilter filter,
  }) {
    return switch (filter) {
      _SavedHubFilter.all =>
        opportunities.length +
            scholarships.length +
            trainings.length +
            ideas.length,
      _SavedHubFilter.opportunities => opportunities.length,
      _SavedHubFilter.scholarships => scholarships.length,
      _SavedHubFilter.trainings => trainings.length,
      _SavedHubFilter.ideas => ideas.length,
    };
  }

  String _filterLabel(_SavedHubFilter filter) {
    return switch (filter) {
      _SavedHubFilter.all => 'All',
      _SavedHubFilter.opportunities => 'Opportunities',
      _SavedHubFilter.scholarships => 'Scholarships',
      _SavedHubFilter.trainings => 'Trainings',
      _SavedHubFilter.ideas => 'Ideas',
    };
  }

  Color _filterColor(_SavedHubFilter filter) {
    return switch (filter) {
      _SavedHubFilter.all => StudentOpportunityHubPalette.primary,
      _SavedHubFilter.opportunities => StudentOpportunityHubPalette.accent,
      _SavedHubFilter.scholarships => StudentOpportunityHubPalette.secondary,
      _SavedHubFilter.trainings => const Color(0xFF6366F1),
      _SavedHubFilter.ideas => InnovationHubPalette.primary,
    };
  }

  String _opportunityTypeFilterLabel(String? type) {
    final normalized = OpportunityType.parse(type);
    switch (normalized) {
      case OpportunityType.internship:
        return 'Internships';
      case OpportunityType.sponsoring:
        return 'Sponsored';
      case OpportunityType.job:
      default:
        return 'Jobs';
    }
  }

  Color _opportunityTypeFilterColor(String? type) {
    if (type == null) {
      return StudentOpportunityHubPalette.primary;
    }

    return OpportunityType.color(type);
  }

  int _countForOpportunityTypeFilter(
    List<SavedOpportunityModel> opportunities,
    String? type,
  ) {
    if (type == null) {
      return opportunities.length;
    }

    final normalized = OpportunityType.parse(type);
    return opportunities
        .where((item) => OpportunityType.parse(item.type) == normalized)
        .length;
  }

  String _itemKey(_SavedHubItem item) => '${item.kind.name}:${item.id}';

  Future<void> _openItem(_SavedHubItem item) async {
    final key = _itemKey(item);
    if (_openingItemKey != null) {
      return;
    }

    setState(() => _openingItemKey = key);

    try {
      switch (item.kind) {
        case _SavedHubItemKind.opportunity:
          await _openOpportunity(item.opportunity!);
          break;
        case _SavedHubItemKind.scholarship:
          await _openScholarship(item.scholarship!);
          break;
        case _SavedHubItemKind.training:
          await _openTraining(item.training!);
          break;
        case _SavedHubItemKind.idea:
          await _openIdea(item.idea!);
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _openingItemKey = null);
      }
    }
  }

  Future<void> _openOpportunity(SavedOpportunityModel saved) async {
    OpportunityModel? opportunity;
    for (final item in context.read<OpportunityProvider>().opportunities) {
      if (item.id == saved.opportunityId) {
        opportunity = item;
        break;
      }
    }

    opportunity ??= await _opportunityService.getOpportunityById(
      saved.opportunityId,
    );

    if (!mounted) {
      return;
    }

    if (opportunity == null) {
      context.showAppSnackBar(
        'This opportunity is no longer available.',
        title: 'Opportunity unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    await OpportunityDetailScreen.show(context, opportunity);
  }

  Future<void> _openScholarship(SavedScholarshipModel saved) async {
    final scholarship = await _scholarshipService.getScholarshipById(
      saved.scholarshipId,
    );

    if (!mounted) {
      return;
    }

    if (scholarship == null) {
      context.showAppSnackBar(
        'This scholarship is no longer available.',
        title: 'Scholarship unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScholarshipDetailScreen(scholarship: scholarship),
      ),
    );
  }

  Future<void> _openTraining(TrainingModel training) async {
    final link = training.displayLink;
    if (link.isEmpty) {
      if (!mounted) return;
      context.showAppSnackBar(
        'This training does not have a link yet.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openIdea(SavedIdeaModel saved) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            IdeaDetailsScreen(ideaId: saved.ideaId, initialIdea: saved.idea),
      ),
    );
  }

  Future<void> _removeItem(_SavedHubItem item) async {
    final studentId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    if (studentId.isEmpty || _removingItemKey != null) {
      return;
    }

    final key = _itemKey(item);
    setState(() => _removingItemKey = key);

    String? error;
    String successMessage;

    switch (item.kind) {
      case _SavedHubItemKind.opportunity:
        error = await context
            .read<SavedOpportunityProvider>()
            .unsaveOpportunity(item.opportunity!.id, studentId);
        successMessage = 'Removed from saved opportunities';
        break;
      case _SavedHubItemKind.scholarship:
        error = await context
            .read<SavedScholarshipProvider>()
            .unsaveScholarship(item.scholarship!.id, studentId);
        successMessage = 'Removed from saved scholarships';
        break;
      case _SavedHubItemKind.training:
        error = await context.read<TrainingProvider>().unsaveTraining(
          userId: studentId,
          trainingId: item.training!.id,
        );
        successMessage = 'Removed from saved trainings';
        break;
      case _SavedHubItemKind.idea:
        error = await context.read<ProjectIdeaProvider>().toggleSave(
          item.idea!.idea,
          studentId,
        );
        successMessage = 'Removed from saved ideas';
        break;
    }

    if (!mounted) {
      return;
    }

    setState(() => _removingItemKey = null);

    context.showAppSnackBar(
      error == null
          ? successMessage
          : 'We couldn\'t remove this item right now.',
      title: error == null ? 'Saved items updated' : 'Update unavailable',
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedOpportunityProvider = context.watch<SavedOpportunityProvider>();
    final savedScholarshipProvider = context.watch<SavedScholarshipProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final savedIdeasProvider = context.watch<ProjectIdeaProvider>();

    final items = _buildItems(
      opportunities: savedOpportunityProvider.savedOpportunities,
      scholarships: savedScholarshipProvider.savedScholarships,
      trainings: trainingProvider.savedTrainings,
      ideas: savedIdeasProvider.savedIdeas,
    );
    final totalSaved = _countForFilter(
      opportunities: savedOpportunityProvider.savedOpportunities,
      scholarships: savedScholarshipProvider.savedScholarships,
      trainings: trainingProvider.savedTrainings,
      ideas: savedIdeasProvider.savedIdeas,
      filter: _SavedHubFilter.all,
    );
    final hasAnyItems = totalSaved > 0;
    final hasFilters =
        _selectedFilter != _SavedHubFilter.all || _searchQuery.isNotEmpty;
    final isInitialLoading =
        !hasAnyItems &&
        (savedOpportunityProvider.isLoading ||
            savedScholarshipProvider.isLoading ||
            trainingProvider.isSavedLoading ||
            savedIdeasProvider.savedIdeasLoading);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudentWorkspaceAppBar(
          title: 'Saved Items',
          subtitle:
              'Your saved opportunities, scholarships, trainings, and ideas.',
          icon: Icons.bookmark_rounded,
          showBackButton: true,
          onBack: () => Navigator.maybePop(context),
          actions: [
            StudentWorkspaceActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh',
              onTap: () => _loadSavedContent(),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: StudentOpportunityHubPalette.primary,
            onRefresh: _loadSavedContent,
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
                        _SavedCompactSummary(
                          total: totalSaved,
                          opportunities: savedOpportunityProvider
                              .savedOpportunities
                              .length,
                          scholarships:
                              savedScholarshipProvider.savedScholarships.length,
                          trainings: trainingProvider.savedTrainings.length,
                          ideas: savedIdeasProvider.savedIdeas.length,
                        ),
                        const SizedBox(height: 12),
                        if ((savedIdeasProvider.savedIdeasError ?? '')
                            .trim()
                            .isNotEmpty)
                          _InlineBanner(
                            icon: Icons.info_outline_rounded,
                            title: 'Some saved ideas could not load right now.',
                            message: savedIdeasProvider.savedIdeasError!,
                            tone: StudentOpportunityHubPalette.error,
                            background: const Color(0xFFFFF1F2),
                          ),
                        if ((savedIdeasProvider.savedIdeasError ?? '')
                            .trim()
                            .isNotEmpty)
                          const SizedBox(height: 12),
                        StudentOpportunitySearchField(
                          controller: _searchController,
                          hintText:
                              'Search by title, company, provider, or category',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _SavedHubFilter.values
                                .map(
                                  (filter) => Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          filter == _SavedHubFilter.values.last
                                          ? 0
                                          : 8,
                                    ),
                                    child: StudentOpportunityFilterChip(
                                      label:
                                          '${_filterLabel(filter)} (${_countForFilter(opportunities: savedOpportunityProvider.savedOpportunities, scholarships: savedScholarshipProvider.savedScholarships, trainings: trainingProvider.savedTrainings, ideas: savedIdeasProvider.savedIdeas, filter: filter)})',
                                      selected: filter == _selectedFilter,
                                      color: _filterColor(filter),
                                      onTap: () {
                                        if (_selectedFilter == filter) {
                                          return;
                                        }
                                        setState(() {
                                          _selectedFilter = filter;
                                          if (filter !=
                                              _SavedHubFilter.opportunities) {
                                            _selectedOpportunityType = null;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child:
                              _selectedFilter == _SavedHubFilter.opportunities
                              ? Padding(
                                  key: const ValueKey(
                                    'saved-opportunity-type-filters',
                                  ),
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Opportunity type',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w600,
                                          color: StudentOpportunityHubPalette
                                              .textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: StudentOpportunityFilterChip(
                                                label:
                                                    'All opps (${_countForOpportunityTypeFilter(savedOpportunityProvider.savedOpportunities, null)})',
                                                selected:
                                                    _selectedOpportunityType ==
                                                    null,
                                                color:
                                                    StudentOpportunityHubPalette
                                                        .primary,
                                                onTap: () {
                                                  if (_selectedOpportunityType ==
                                                      null) {
                                                    return;
                                                  }
                                                  setState(
                                                    () =>
                                                        _selectedOpportunityType =
                                                            null,
                                                  );
                                                },
                                              ),
                                            ),
                                            ...OpportunityType.values.map(
                                              (type) => Padding(
                                                padding: EdgeInsets.only(
                                                  right:
                                                      type ==
                                                          OpportunityType
                                                              .values
                                                              .last
                                                      ? 0
                                                      : 8,
                                                ),
                                                child: StudentOpportunityFilterChip(
                                                  label:
                                                      '${_opportunityTypeFilterLabel(type)} (${_countForOpportunityTypeFilter(savedOpportunityProvider.savedOpportunities, type)})',
                                                  selected:
                                                      _selectedOpportunityType ==
                                                      type,
                                                  color:
                                                      _opportunityTypeFilterColor(
                                                        type,
                                                      ),
                                                  onTap: () {
                                                    if (_selectedOpportunityType ==
                                                        type) {
                                                      return;
                                                    }
                                                    setState(
                                                      () =>
                                                          _selectedOpportunityType =
                                                              type,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          hasFilters
                              ? '${items.length} items shown'
                              : totalSaved == 1
                              ? '1 saved item'
                              : '$totalSaved saved items',
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
                if (isInitialLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: StudentOpportunityLoadingState(
                      title: 'Loading your saved items...',
                      message:
                          'Pulling together your saved opportunities, scholarships, trainings, and ideas.',
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: StudentOpportunityEmptyState(
                      icon: hasFilters
                          ? Icons.filter_alt_off_rounded
                          : Icons.bookmark_border_rounded,
                      title: hasFilters
                          ? 'No saved items match this view'
                          : 'No saved items yet',
                      message: hasFilters
                          ? 'Try a different search or filter to see more saved items.'
                          : 'Save opportunities, scholarships, trainings, or ideas to build your shortlist.',
                      actionLabel: 'Explore opportunities',
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
                        final itemKey = _itemKey(item);

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == items.length - 1 ? 0 : 10,
                          ),
                          child: _SavedHubCard(
                            item: item,
                            isOpening: _openingItemKey == itemKey,
                            isRemoving: _removingItemKey == itemKey,
                            onOpen: () => _openItem(item),
                            onRemove: () => _removeItem(item),
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

class _SavedHubCard extends StatelessWidget {
  final _SavedHubItem item;
  final bool isOpening;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _SavedHubCard({
    required this.item,
    required this.isOpening,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case _SavedHubItemKind.opportunity:
        return _SavedOpportunityCard(
          item: item.opportunity!,
          isOpening: isOpening,
          isRemoving: isRemoving,
          onOpen: onOpen,
          onRemove: onRemove,
        );
      case _SavedHubItemKind.scholarship:
        return _SavedScholarshipCard(
          item: item.scholarship!,
          isOpening: isOpening,
          isRemoving: isRemoving,
          onOpen: onOpen,
          onRemove: onRemove,
        );
      case _SavedHubItemKind.training:
        return _SavedTrainingCard(
          item: item.training!,
          isOpening: isOpening,
          isRemoving: isRemoving,
          onOpen: onOpen,
          onRemove: onRemove,
        );
      case _SavedHubItemKind.idea:
        return _SavedIdeaCard(
          item: item.idea!,
          isOpening: isOpening,
          isRemoving: isRemoving,
          onOpen: onOpen,
          onRemove: onRemove,
        );
    }
  }
}

class _SavedCompactSummary extends StatelessWidget {
  final int total;
  final int opportunities;
  final int scholarships;
  final int trainings;
  final int ideas;

  const _SavedCompactSummary({
    required this.total,
    required this.opportunities,
    required this.scholarships,
    required this.trainings,
    required this.ideas,
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
                  Icons.bookmarks_outlined,
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
                      'Saved items',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StudentOpportunityHubPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Everything you saved, in one simple list.',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SavedMiniStat(
                label: 'Total',
                value: '$total',
                color: StudentOpportunityHubPalette.primary,
              ),
              _SavedMiniStat(
                label: 'Opportunities',
                value: '$opportunities',
                color: StudentOpportunityHubPalette.accent,
              ),
              _SavedMiniStat(
                label: 'Scholarships',
                value: '$scholarships',
                color: StudentOpportunityHubPalette.secondary,
              ),
              _SavedMiniStat(
                label: 'Trainings',
                value: '$trainings',
                color: const Color(0xFF6366F1),
              ),
              _SavedMiniStat(
                label: 'Ideas',
                value: '$ideas',
                color: InnovationHubPalette.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SavedMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: StudentOpportunityHubPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedOpportunityCard extends StatelessWidget {
  final SavedOpportunityModel item;
  final bool isOpening;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _SavedOpportunityCard({
    required this.item,
    required this.isOpening,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final accent = OpportunityType.color(item.type);
    final deadline = OpportunityMetadata.parseDateTimeLike(item.deadline);
    final isExpired = _isExpired(deadline);
    final isClosingSoon = _isClosingSoon(deadline);

    return _SavedListCard(
      accent: accent,
      leadingIcon: OpportunityType.icon(item.type),
      typeLabel: OpportunityType.label(item.type),
      savedLabel: _relativeSavedLabel(item.savedAt?.toDate()),
      title: item.title,
      subtitle: item.companyName,
      meta: [
        _SavedMetaChip(
          icon: Icons.location_on_outlined,
          label: item.location.trim().isEmpty
              ? 'Location not specified'
              : item.location.trim(),
        ),
        _SavedMetaChip(
          icon: isExpired ? Icons.event_busy_outlined : Icons.flag_outlined,
          label: _deadlineLabel(deadline, item.deadline),
          tone: _deadlineTone(deadline),
        ),
        if (isClosingSoon && !isExpired)
          const _SavedMetaChip(
            icon: Icons.local_fire_department_outlined,
            label: 'Closing soon',
            tone: StudentOpportunityHubPalette.accent,
          ),
      ],
      isOpening: isOpening,
      isRemoving: isRemoving,
      onOpen: onOpen,
      onRemove: onRemove,
    );
  }
}

class _SavedScholarshipCard extends StatelessWidget {
  final SavedScholarshipModel item;
  final bool isOpening;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _SavedScholarshipCard({
    required this.item,
    required this.isOpening,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final accent = StudentOpportunityHubPalette.secondary;
    final deadline = OpportunityMetadata.parseDateTimeLike(item.deadline);
    final fundingLabel = item.fundingType.trim().isEmpty
        ? 'Scholarship'
        : item.fundingType.trim();

    return _SavedListCard(
      accent: accent,
      leadingIcon: Icons.school_outlined,
      typeLabel: fundingLabel,
      savedLabel: _relativeSavedLabel(item.savedAt?.toDate()),
      title: item.title,
      subtitle: item.provider,
      meta: [
        _SavedMetaChip(
          icon: Icons.public_rounded,
          label: item.location.trim().isEmpty
              ? 'Destination not specified'
              : item.location.trim(),
        ),
        _SavedMetaChip(
          icon: Icons.event_available_outlined,
          label: _deadlineLabel(deadline, item.deadline),
          tone: _deadlineTone(deadline),
        ),
        if (item.level.trim().isNotEmpty)
          _SavedMetaChip(
            icon: Icons.school_outlined,
            label: item.level.trim(),
            tone: StudentOpportunityHubPalette.secondary,
          ),
      ],
      isOpening: isOpening,
      isRemoving: isRemoving,
      onOpen: onOpen,
      onRemove: onRemove,
    );
  }
}

class _SavedTrainingCard extends StatelessWidget {
  final TrainingModel item;
  final bool isOpening;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _SavedTrainingCard({
    required this.item,
    required this.isOpening,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6366F1);
    final typeLabel = item.type.trim().isEmpty
        ? 'Training'
        : item.type[0].toUpperCase() + item.type.substring(1);
    final summary = item.description.trim();

    return _SavedListCard(
      accent: accent,
      leadingIcon: Icons.menu_book_rounded,
      typeLabel: typeLabel,
      savedLabel: _relativeSavedLabel(null),
      title: item.title,
      subtitle: item.provider,
      summary: summary.isEmpty ? null : summary,
      meta: [
        if (item.level.trim().isNotEmpty)
          _SavedMetaChip(
            icon: Icons.signal_cellular_alt_rounded,
            label: item.level.trim(),
            tone: accent,
          ),
        if (item.duration.trim().isNotEmpty)
          _SavedMetaChip(
            icon: Icons.schedule_rounded,
            label: item.duration.trim(),
          ),
        if (item.domain.trim().isNotEmpty)
          _SavedMetaChip(
            icon: Icons.category_outlined,
            label: item.domain.trim(),
            tone: accent,
          ),
        if (item.language.trim().isNotEmpty)
          _SavedMetaChip(
            icon: Icons.language_rounded,
            label: item.language.trim(),
          ),
        if (item.isFree == true)
          const _SavedMetaChip(
            icon: Icons.money_off_rounded,
            label: 'Free',
            tone: Color(0xFF10B981),
          ),
        if (item.hasCertificate == true)
          const _SavedMetaChip(
            icon: Icons.verified_outlined,
            label: 'Certificate',
            tone: Color(0xFF6366F1),
          ),
      ],
      isOpening: isOpening,
      isRemoving: isRemoving,
      onOpen: onOpen,
      onRemove: onRemove,
    );
  }
}

class _SavedIdeaCard extends StatelessWidget {
  final SavedIdeaModel item;
  final bool isOpening;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _SavedIdeaCard({
    required this.item,
    required this.isOpening,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final accent = innovationCategoryColor(item.idea.displayCategory);
    final summary = item.idea.cardSummary.trim();

    return _SavedListCard(
      accent: accent,
      leadingIcon: innovationCategoryIcon(item.idea.displayCategory),
      typeLabel: item.idea.displayCategory,
      savedLabel: _relativeSavedLabel(item.savedAt?.toDate()),
      title: item.idea.title,
      subtitle: item.idea.creatorName,
      summary: summary.isEmpty ? null : summary,
      meta: [
        _SavedMetaChip(
          icon: Icons.timeline_outlined,
          label: item.idea.displayStage,
          tone: innovationStageColor(item.idea.displayStage),
        ),
        _SavedMetaChip(
          icon: Icons.people_outline_rounded,
          label: '${item.idea.interestedCount} interested',
          tone: StudentOpportunityHubPalette.secondary,
        ),
      ],
      isOpening: isOpening,
      isRemoving: isRemoving,
      onOpen: onOpen,
      onRemove: onRemove,
    );
  }
}

class _SavedListCard extends StatelessWidget {
  final Color accent;
  final IconData leadingIcon;
  final String typeLabel;
  final String savedLabel;
  final String title;
  final String subtitle;
  final String? summary;
  final List<Widget> meta;
  final bool isOpening;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _SavedListCard({
    required this.accent,
    required this.leadingIcon,
    required this.typeLabel,
    required this.savedLabel,
    required this.title,
    required this.subtitle,
    this.summary,
    required this.meta,
    required this.isOpening,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSummary = summary?.trim() ?? '';
    final isBusy = isOpening || isRemoving;

    return _SavedCardFrame(
      accent: accent,
      onTap: isBusy ? null : onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(leadingIcon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SavedLabelChip(
                      label: typeLabel,
                      tone: accent,
                      filled: true,
                    ),
                    _SavedLabelChip(
                      label: savedLabel,
                      icon: Icons.bookmark_added_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _SavedCardText.title,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _SavedCardText.subtitle,
                ),
                if (normalizedSummary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    normalizedSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.6,
                      height: 1.45,
                      color: StudentOpportunityHubPalette.textSecondary,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: meta),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isOpening
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          color: accent,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              _SavedTrailingButton(
                icon: isRemoving
                    ? Icons.hourglass_top_rounded
                    : Icons.bookmark_remove_outlined,
                tooltip: 'Remove',
                background: StudentOpportunityHubPalette.error.withValues(
                  alpha: 0.08,
                ),
                foreground: StudentOpportunityHubPalette.error,
                onTap: isBusy ? null : onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedCardFrame extends StatelessWidget {
  final Color accent;
  final Widget child;
  final VoidCallback? onTap;

  const _SavedCardFrame({
    required this.accent,
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class _SavedLabelChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color tone;
  final bool filled;

  const _SavedLabelChip({
    required this.label,
    this.icon,
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
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: 5),
          ],
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

class _SavedMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tone;

  const _SavedMetaChip({required this.icon, required this.label, this.tone});

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

class _SavedTrailingButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _SavedTrailingButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 17),
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

abstract final class _SavedCardText {
  static final TextStyle title = GoogleFonts.poppins(
    fontSize: 16,
    height: 1.18,
    fontWeight: FontWeight.w700,
    color: StudentOpportunityHubPalette.textPrimary,
  );

  static final TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 12.4,
    fontWeight: FontWeight.w600,
    color: StudentOpportunityHubPalette.textSecondary,
  );
}

enum _SavedHubItemKind { opportunity, scholarship, training, idea }

class _SavedHubItem {
  final _SavedHubItemKind kind;
  final SavedOpportunityModel? opportunity;
  final SavedScholarshipModel? scholarship;
  final TrainingModel? training;
  final SavedIdeaModel? idea;

  const _SavedHubItem._({
    required this.kind,
    this.opportunity,
    this.scholarship,
    this.training,
    this.idea,
  });

  factory _SavedHubItem.opportunity(SavedOpportunityModel value) {
    return _SavedHubItem._(
      kind: _SavedHubItemKind.opportunity,
      opportunity: value,
    );
  }

  factory _SavedHubItem.scholarship(SavedScholarshipModel value) {
    return _SavedHubItem._(
      kind: _SavedHubItemKind.scholarship,
      scholarship: value,
    );
  }

  factory _SavedHubItem.training(TrainingModel value) {
    return _SavedHubItem._(kind: _SavedHubItemKind.training, training: value);
  }

  factory _SavedHubItem.idea(SavedIdeaModel value) {
    return _SavedHubItem._(kind: _SavedHubItemKind.idea, idea: value);
  }

  String get id {
    switch (kind) {
      case _SavedHubItemKind.opportunity:
        return opportunity!.id;
      case _SavedHubItemKind.scholarship:
        return scholarship!.id;
      case _SavedHubItemKind.training:
        return training!.id;
      case _SavedHubItemKind.idea:
        return idea!.id;
    }
  }

  DateTime? get savedAt {
    switch (kind) {
      case _SavedHubItemKind.opportunity:
        return opportunity!.savedAt?.toDate();
      case _SavedHubItemKind.scholarship:
        return scholarship!.savedAt?.toDate();
      case _SavedHubItemKind.training:
        return training!.savedAt?.toDate();
      case _SavedHubItemKind.idea:
        return idea!.savedAt?.toDate();
    }
  }

  String get title {
    switch (kind) {
      case _SavedHubItemKind.opportunity:
        return opportunity!.title;
      case _SavedHubItemKind.scholarship:
        return scholarship!.title;
      case _SavedHubItemKind.training:
        return training!.title;
      case _SavedHubItemKind.idea:
        return idea!.idea.title;
    }
  }

  String get subtitle {
    switch (kind) {
      case _SavedHubItemKind.opportunity:
        return opportunity!.companyName;
      case _SavedHubItemKind.scholarship:
        return scholarship!.provider;
      case _SavedHubItemKind.training:
        return training!.provider;
      case _SavedHubItemKind.idea:
        return idea!.idea.creatorName;
    }
  }

  String get supporting {
    switch (kind) {
      case _SavedHubItemKind.opportunity:
        return opportunity!.location;
      case _SavedHubItemKind.scholarship:
        return scholarship!.location;
      case _SavedHubItemKind.training:
        return training!.description;
      case _SavedHubItemKind.idea:
        return idea!.idea.cardSummary;
    }
  }

  String get categoryLabel {
    switch (kind) {
      case _SavedHubItemKind.opportunity:
        return OpportunityType.label(opportunity!.type);
      case _SavedHubItemKind.scholarship:
        return 'Scholarship';
      case _SavedHubItemKind.training:
        return training!.type.isNotEmpty
            ? training!.type[0].toUpperCase() + training!.type.substring(1)
            : 'Training';
      case _SavedHubItemKind.idea:
        return idea!.idea.displayCategory;
    }
  }
}

String _relativeSavedLabel(DateTime? value) {
  if (value == null) {
    return 'Saved';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final difference = today.difference(target).inDays;

  if (difference <= 0) {
    return 'Saved today';
  }
  if (difference == 1) {
    return 'Saved yesterday';
  }
  if (difference < 7) {
    return 'Saved $difference days ago';
  }
  if (difference < 30) {
    final weeks = (difference / 7).ceil();
    return 'Saved $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  }

  return 'Saved ${DateFormat('MMM d').format(value)}';
}

bool _isClosingSoon(DateTime? deadline) {
  if (deadline == null) {
    return false;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(deadline.year, deadline.month, deadline.day);
  final difference = target.difference(today).inDays;
  return difference >= 0 && difference <= 7;
}

bool _isExpired(DateTime? deadline) {
  if (deadline == null) {
    return false;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(deadline.year, deadline.month, deadline.day);
  return target.isBefore(today);
}

String _deadlineLabel(DateTime? deadline, String fallback) {
  if (deadline == null) {
    final normalizedFallback = fallback.trim();
    if (normalizedFallback.isEmpty) {
      return 'No deadline shared';
    }
    return normalizedFallback;
  }

  final prefix = _isExpired(deadline) ? 'Closed' : 'Closes';
  return '$prefix ${DateFormat('MMM d').format(deadline)}';
}

Color? _deadlineTone(DateTime? deadline) {
  if (deadline == null) {
    return null;
  }

  if (_isExpired(deadline)) {
    return StudentOpportunityHubPalette.error;
  }
  if (_isClosingSoon(deadline)) {
    return StudentOpportunityHubPalette.accent;
  }
  return StudentOpportunityHubPalette.secondary;
}
