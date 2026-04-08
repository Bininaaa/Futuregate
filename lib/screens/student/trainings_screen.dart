import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/training_programs_widgets.dart';
import 'saved_trainings_screen.dart';

class TrainingsScreen extends StatefulWidget {
  final bool embedded;

  const TrainingsScreen({super.key, this.embedded = false});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchSectionKey = GlobalKey();

  String _searchText = '';
  String _selectedDomain = 'All';
  TrainingLayoutView _trainingLayoutView = TrainingLayoutView.grid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);

    Future.microtask(() async {
      if (!mounted) {
        return;
      }
      await _refreshData();
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
    if (nextValue == _searchText) {
      return;
    }

    setState(() {
      _searchText = nextValue;
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<TrainingProvider>();
    final uid = context.read<AuthProvider>().userModel?.uid;

    await provider.fetchTrainings();

    if (!mounted) {
      return;
    }

    if (uid != null && uid.isNotEmpty) {
      await provider.fetchSavedTrainings(uid);
    }
  }

  Future<void> _openLink(
    String link, {
    String emptyMessage = 'This training does not have a link yet.',
  }) async {
    if (link.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emptyMessage)));
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This training link is not valid.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We couldn\'t open this training link.')),
      );
    }
  }

  Future<void> _toggleSavedTraining(TrainingModel training) async {
    final auth = context.read<AuthProvider>().userModel;
    final userId = auth?.uid.trim() ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save resources'),
        ),
      );
      return;
    }

    final provider = context.read<TrainingProvider>();
    final wasSaved = provider.isTrainingSaved(training.id);
    final error = await provider.toggleSavedTraining(
      userId: userId,
      training: training,
    );

    if (!mounted) {
      return;
    }

    final normalizedError = error?.replaceFirst('Exception: ', '').trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          normalizedError == null || normalizedError.isEmpty
              ? wasSaved
                    ? 'Removed from saved resources'
                    : 'Resource saved'
              : normalizedError,
        ),
      ),
    );
  }

  Future<void> _focusSearchField() async {
    await _ensureVisible(_searchSectionKey);
    if (!mounted) {
      return;
    }
    _searchFocusNode.requestFocus();
  }

  Future<void> _ensureVisible(GlobalKey key) async {
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

  Future<void> _openSavedTrainings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SavedTrainingsScreen()));
  }

  Future<void> _showMenuSheet() async {
    final canPop = Navigator.of(context).canPop();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: OpportunityDashboardPalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                if (canPop)
                  _TrainingMenuTile(
                    icon: Icons.arrow_back_rounded,
                    title: 'Back',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).maybePop();
                    },
                  ),
                _TrainingMenuTile(
                  icon: Icons.bookmarks_outlined,
                  title: 'Saved resources',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openSavedTrainings();
                  },
                ),
                _TrainingMenuTile(
                  icon: Icons.refresh_rounded,
                  title: 'Refresh trainings',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _refreshData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TrainingModel> _sortedApprovedTrainings(List<TrainingModel> items) {
    final approved = items.where((item) => item.isApproved).toList();

    approved.sort((a, b) {
      final priorityDiff = _trainingPriorityScore(
        b,
      ).compareTo(_trainingPriorityScore(a));
      if (priorityDiff != 0) {
        return priorityDiff;
      }

      final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 0;
      final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 0;
      return bCreated.compareTo(aCreated);
    });

    return approved;
  }

  int _trainingPriorityScore(TrainingModel training) {
    var score = 0;

    if (training.isFeatured) {
      score += 120;
    }

    if (training.thumbnail.trim().isNotEmpty) {
      score += 18;
    }

    if (training.rating != null && training.rating! > 0) {
      score += 12;
    }

    if (training.providerLogo.trim().isNotEmpty) {
      score += 8;
    }

    if (training.duration.trim().isNotEmpty) {
      score += 6;
    }

    if (training.level.trim().isNotEmpty) {
      score += 6;
    }

    if (_looksCertified(training)) {
      score += 10;
    }

    switch (training.type.trim().toLowerCase()) {
      case 'course':
        score += 26;
        break;
      case 'training':
        score += 22;
        break;
      case 'video':
        score += 18;
        break;
      case 'book':
        score += 14;
        break;
      case 'file':
        score += 12;
        break;
      default:
        score += 8;
        break;
    }

    return score;
  }

  bool _matchesSearch(TrainingModel training) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final searchableValues = [
      training.title,
      training.provider,
      training.authors.join(' '),
      training.domain,
      training.description,
      training.level,
      training.duration,
      training.type,
      training.learnerCountLabel,
    ];

    return searchableValues.any((value) => value.toLowerCase().contains(query));
  }

  String _domainLabelFor(TrainingModel training) {
    final domain = training.domain.trim();
    return domain.isNotEmpty ? domain : 'General';
  }

  List<String> _availableDomains(List<TrainingModel> trainings) {
    final domains = trainings.map(_domainLabelFor).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (domains.isEmpty) {
      return const ['All'];
    }

    return ['All', ...domains];
  }

  bool _matchesDomain(TrainingModel training, String activeDomain) {
    return activeDomain == 'All' || _domainLabelFor(training) == activeDomain;
  }

  List<TrainingModel> _recommendedTrainings(List<TrainingModel> items) {
    if (items.isEmpty) {
      return const [];
    }

    final featured = items.where((item) => item.isFeatured).toList();
    final remaining = items.where((item) => !item.isFeatured).toList();
    final selected = <TrainingModel>[...featured.take(3)];

    final needed = 3 - selected.length;
    if (needed > 0) {
      selected.addAll(remaining.take(needed));
    }

    return selected;
  }

  TrainingModel? _findTrainingById(
    List<TrainingModel> trainings,
    String trainingId,
  ) {
    for (final training in trainings) {
      if (training.id == trainingId) {
        return training;
      }
    }

    return null;
  }

  TrainingCourseCardData _mapTrainingToCardData(TrainingModel training) {
    final accent = _accentFor(training);

    return TrainingCourseCardData(
      id: training.id,
      title: training.title.trim().isEmpty
          ? 'Training Program'
          : training.title.trim(),
      providerName: _providerName(training),
      providerLogoUrl: training.providerLogo.trim(),
      imageUrl: training.thumbnail.trim(),
      trainingType: training.type.trim(),
      durationLabel: _durationLabel(training),
      levelLabel: _levelLabel(training),
      ratingLabel: _ratingLabel(training),
      categoryLabel: _categoryLabel(training),
      accentColor: accent.primary,
      secondaryAccentColor: accent.secondary,
      fallbackIcon: _iconForTraining(training),
      badges: _badgesForTraining(training),
    );
  }

  _TrainingAccent _accentFor(TrainingModel training) {
    const accents = [
      _TrainingAccent(
        primary: OpportunityDashboardPalette.primary,
        secondary: OpportunityDashboardPalette.primaryDark,
      ),
      _TrainingAccent(
        primary: OpportunityDashboardPalette.secondary,
        secondary: OpportunityDashboardPalette.primary,
      ),
      _TrainingAccent(
        primary: OpportunityDashboardPalette.accent,
        secondary: OpportunityDashboardPalette.primaryDark,
      ),
      _TrainingAccent(
        primary: OpportunityDashboardPalette.primaryDark,
        secondary: OpportunityDashboardPalette.secondary,
      ),
      _TrainingAccent(
        primary: OpportunityDashboardPalette.warning,
        secondary: OpportunityDashboardPalette.accent,
      ),
    ];

    final seed = '${training.title}${training.provider}${training.type}';
    return accents[seed.hashCode.abs() % accents.length];
  }

  String _providerName(TrainingModel training) {
    final provider = training.provider.trim();
    if (provider.isNotEmpty) {
      return provider;
    }

    final authorText = training.authors.join(', ').trim();
    return authorText.isNotEmpty ? authorText : 'Training Provider';
  }

  String _durationLabel(TrainingModel training) {
    final duration = training.duration.trim();
    return duration.isNotEmpty ? duration : 'Flexible';
  }

  String _levelLabel(TrainingModel training) {
    final level = training.level.trim();
    return level.isNotEmpty ? _titleCase(level) : 'All levels';
  }

  String _categoryLabel(TrainingModel training) {
    final domain = training.domain.trim();
    if (domain.isNotEmpty) {
      return domain;
    }

    return switch (training.type.trim().toLowerCase()) {
      'course' => 'Career Course',
      'video' => 'Video Lesson',
      'book' => 'Reading Track',
      'file' => 'Guide & Toolkit',
      _ => 'Learning Path',
    };
  }

  String? _ratingLabel(TrainingModel training) {
    final rating = training.rating;
    if (rating == null || rating <= 0) {
      return null;
    }

    final learners = training.learnerCountLabel.trim();
    final base = rating.toStringAsFixed(1);
    return learners.isEmpty ? base : '$base ($learners)';
  }

  List<TrainingCourseBadgeData> _badgesForTraining(TrainingModel training) {
    final badges = <TrainingCourseBadgeData>[];

    if (training.isFree == true) {
      badges.add(
        const TrainingCourseBadgeData(
          label: 'FREE',
          backgroundColor: Color(0xFFDCFCE7),
          foregroundColor: OpportunityDashboardPalette.success,
        ),
      );
    }

    if (_looksCertified(training)) {
      badges.add(
        const TrainingCourseBadgeData(
          label: 'CERTIFIED',
          backgroundColor: Color(0xFFDBEAFE),
          foregroundColor: OpportunityDashboardPalette.primaryDark,
        ),
      );
    }

    if (badges.isEmpty && training.isFeatured) {
      badges.add(
        const TrainingCourseBadgeData(
          label: 'FEATURED',
          backgroundColor: Color(0xFFFFEDD5),
          foregroundColor: OpportunityDashboardPalette.accent,
        ),
      );
    }

    if (badges.isEmpty) {
      final type = training.type.trim().toLowerCase();
      switch (type) {
        case 'course':
          badges.add(
            const TrainingCourseBadgeData(
              label: 'COURSE',
              backgroundColor: Color(0xFFDBEAFE),
              foregroundColor: OpportunityDashboardPalette.primaryDark,
            ),
          );
          break;
        case 'video':
          badges.add(
            const TrainingCourseBadgeData(
              label: 'VIDEO',
              backgroundColor: Color(0xFFFEF3C7),
              foregroundColor: OpportunityDashboardPalette.warning,
            ),
          );
          break;
        case 'book':
          badges.add(
            const TrainingCourseBadgeData(
              label: 'BOOK',
              backgroundColor: Color(0xFFFCE7F3),
              foregroundColor: Color(0xFFBE185D),
            ),
          );
          break;
        case 'file':
          badges.add(
            const TrainingCourseBadgeData(
              label: 'GUIDE',
              backgroundColor: Color(0xFFEDE9FE),
              foregroundColor: OpportunityDashboardPalette.primary,
            ),
          );
          break;
        default:
          badges.add(
            const TrainingCourseBadgeData(
              label: 'PROGRAM',
              backgroundColor: Color(0xFFEDE9FE),
              foregroundColor: OpportunityDashboardPalette.primary,
            ),
          );
          break;
      }
    }

    return badges.take(2).toList();
  }

  bool _looksCertified(TrainingModel training) {
    if (training.hasCertificate == true) {
      return true;
    }

    final text = [
      training.title,
      training.description,
      training.domain,
    ].join(' ').toLowerCase();

    return text.contains('certificate') ||
        text.contains('certified') ||
        text.contains('certification');
  }

  IconData _iconForTraining(TrainingModel training) {
    switch (training.type.trim().toLowerCase()) {
      case 'course':
        return Icons.cast_for_education_outlined;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'file':
        return Icons.description_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  String _titleCase(String value) {
    if (value.trim().isEmpty) {
      return value;
    }

    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();
    final approvedTrainings = _sortedApprovedTrainings(provider.trainings);
    final availableDomains = _availableDomains(approvedTrainings);
    final activeDomain = availableDomains.contains(_selectedDomain)
        ? _selectedDomain
        : 'All';
    final domainFilteredTrainings = approvedTrainings
        .where((training) => _matchesDomain(training, activeDomain))
        .toList();
    final hasApprovedTrainings = approvedTrainings.isNotEmpty;
    final recommendedTrainings = _recommendedTrainings(approvedTrainings);
    final catalogTrainings = activeDomain == 'All'
        ? approvedTrainings
        : domainFilteredTrainings;
    final isSearching = _searchText.trim().isNotEmpty;
    final filteredTrainings = approvedTrainings.where(_matchesSearch).toList();

    final topCards = (isSearching ? filteredTrainings : recommendedTrainings)
        .map(_mapTrainingToCardData)
        .toList();
    final additionalCards =
        (!isSearching
                ? catalogTrainings.map(_mapTrainingToCardData)
                : const Iterable<TrainingCourseCardData>.empty())
            .toList();
    final sectionTitle = isSearching ? 'Search results' : 'Recommended for you';
    final showTopEmptyState =
        !hasApprovedTrainings || (isSearching && filteredTrainings.isEmpty);
    final showDomainEmptyState =
        hasApprovedTrainings &&
        !isSearching &&
        activeDomain != 'All' &&
        additionalCards.isEmpty;
    final emptySubtitle = !hasApprovedTrainings
        ? 'No training programs are available right now.'
        : isSearching
        ? 'Try a different search to find more training programs.'
        : activeDomain == 'All'
        ? 'No training programs are available right now.'
        : 'No training programs are available right now for $activeDomain.';

    Widget buildTrainingCard(TrainingCourseCardData card) {
      final training = _findTrainingById(approvedTrainings, card.id);
      if (training == null) {
        return const SizedBox.shrink();
      }

      void onTap() {
        _openLink(training.displayLink);
      }

      void onToggleSaved() {
        _toggleSavedTraining(training);
      }

      final isSaved = provider.isTrainingSaved(training.id);
      final isSaveBusy = provider.isTrainingBusy(training.id);

      final cardWidget = _trainingLayoutView == TrainingLayoutView.grid
          ? TrainingCourseCard(
              data: card,
              onTap: onTap,
              onStart: onTap,
              isSaved: isSaved,
              isSaveBusy: isSaveBusy,
              onToggleSaved: onToggleSaved,
            )
          : TrainingCourseListCard(
              data: card,
              onTap: onTap,
              onStart: onTap,
              isSaved: isSaved,
              isSaveBusy: isSaveBusy,
              onToggleSaved: onToggleSaved,
            );

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: cardWidget,
      );
    }

    if (provider.isLoading && provider.trainings.isEmpty) {
      final loadingScaffold = Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: !widget.embedded,
          child: const TrainingProgramsLoadingView(),
        ),
      );

      if (widget.embedded) {
        return loadingScaffold;
      }

      return AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            top: !widget.embedded,
            child: const TrainingProgramsLoadingView(),
          ),
        ),
      );
    }

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: !widget.embedded,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: OpportunityDashboardPalette.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    TrainingHeaderBar(
                      onMenuTap: _showMenuSheet,
                      onSearchTap: _focusSearchField,
                    ),
                    const SizedBox(height: 22),
                    const TrainingHeroIntro(),
                    const SizedBox(height: 18),
                    Container(
                      key: _searchSectionKey,
                      child: TrainingSearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onClear: _searchController.clear,
                      ),
                    ),
                    if (provider.isSavedLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (provider.savedErrorMessage != null) ...[
                      const SizedBox(height: 16),
                      TrainingInfoBanner(message: provider.savedErrorMessage!),
                    ],
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      TrainingInfoBanner(
                        message: provider.trainings.isEmpty
                            ? provider.errorMessage!
                            : '${provider.errorMessage!} Showing the training content currently available.',
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TrainingSectionTitle(title: sectionTitle),
                        ),
                        TrainingLayoutToggle(
                          view: _trainingLayoutView,
                          onChanged: (view) {
                            setState(() {
                              _trainingLayoutView = view;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (showTopEmptyState)
                      TrainingProgramsEmptyState(
                        title: 'No training programs match your search',
                        subtitle: emptySubtitle,
                      )
                    else
                      ...topCards.map(buildTrainingCard),
                    if (!isSearching && hasApprovedTrainings) ...[
                      const SizedBox(height: 6),
                      const BrowseMoreTopicsCard(),
                      const SizedBox(height: 10),
                      TrainingCatalogueSelector(
                        domains: availableDomains,
                        selectedDomain: activeDomain,
                        onSelected: (domain) {
                          setState(() {
                            _selectedDomain = domain;
                          });
                        },
                      ),
                      if (showDomainEmptyState) ...[
                        const SizedBox(height: 16),
                        TrainingProgramsEmptyState(
                          title: 'No training programs available in this topic',
                          subtitle: emptySubtitle,
                        ),
                      ] else if (additionalCards.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...additionalCards.map(buildTrainingCard),
                      ],
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return scaffold;
    }

    return AppShellBackground(child: scaffold);
  }
}

class _TrainingMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _TrainingMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: OpportunityDashboardPalette.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: OpportunityDashboardPalette.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: OpportunityDashboardPalette.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: OpportunityDashboardPalette.textSecondary,
      ),
    );
  }
}

class _TrainingAccent {
  final Color primary;
  final Color secondary;

  const _TrainingAccent({required this.primary, required this.secondary});
}
