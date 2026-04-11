import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../../widgets/training_programs_widgets.dart';
import 'saved_screen.dart';

class TrainingsScreen extends StatefulWidget {
  final bool embedded;

  const TrainingsScreen({super.key, this.embedded = false});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  String _selectedDomain = 'All';
  TrainingLayoutView _trainingLayoutView = TrainingLayoutView.grid;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) {
        return;
      }
      await _refreshData();
    });
  }

  @override
  void dispose() {
    super.dispose();
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
      context.showAppSnackBar(
        emptyMessage,
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      context.showAppSnackBar(
        'This training link is not valid.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      context.showAppSnackBar(
        'We couldn\'t open this training link right now.',
        title: 'Open unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _toggleSavedTraining(TrainingModel training) async {
    final auth = context.read<AuthProvider>().userModel;
    final userId = auth?.uid.trim() ?? '';
    if (userId.isEmpty) {
      context.showAppSnackBar(
        'Sign in to save training resources for later.',
        title: 'Login required',
        type: AppFeedbackType.warning,
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
    context.showAppSnackBar(
      normalizedError == null || normalizedError.isEmpty
          ? wasSaved
                ? 'Removed from saved resources'
                : 'Resource saved'
          : normalizedError,
      title: normalizedError == null || normalizedError.isEmpty
          ? 'Saved items updated'
          : 'Update unavailable',
      type: normalizedError == null || normalizedError.isEmpty
          ? AppFeedbackType.success
          : AppFeedbackType.error,
    );
  }

  Future<void> _openSavedTrainings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const SavedScreen(initialFilter: SavedScreenFilter.trainings),
      ),
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

  PreferredSizeWidget? _buildStandaloneAppBar() {
    if (widget.embedded) {
      return null;
    }

    return StudentWorkspaceAppBar(
      title: 'Training',
      subtitle: 'Courses, books, and certifications that sharpen your journey.',
      icon: Icons.cast_for_education_rounded,
      showBackButton: true,
      onBack: () => Navigator.maybePop(context),
      actions: [
        StudentWorkspaceActionButton(
          icon: Icons.bookmark_outline_rounded,
          tooltip: 'Saved resources',
          onTap: _openSavedTrainings,
        ),
      ],
    );
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

  List<String> _profileRecommendationKeywords({
    required String fieldOfStudy,
    required String researchDomain,
  }) {
    final keywords = <String>{};

    for (final value in <String>[fieldOfStudy, researchDomain]) {
      final normalized = value.trim().toLowerCase();
      if (normalized.length >= 3) {
        keywords.add(normalized);
      }

      for (final part in normalized.split(RegExp(r'[^a-z0-9]+'))) {
        if (part.length >= 4) {
          keywords.add(part);
        }
      }
    }

    return keywords.toList(growable: false);
  }

  bool _matchesRecommendationProfile(
    TrainingModel training,
    List<String> profileKeywords,
  ) {
    if (profileKeywords.isEmpty) {
      return false;
    }

    final searchableText = [
      training.domain,
      training.title,
      training.description,
      training.provider,
    ].join(' ').toLowerCase();

    return profileKeywords.any(searchableText.contains);
  }

  List<TrainingModel> _recommendedTrainings(
    List<TrainingModel> items, {
    List<String> profileKeywords = const <String>[],
  }) {
    if (items.isEmpty) {
      return const [];
    }

    final selected = <TrainingModel>[];

    void addCandidates(Iterable<TrainingModel> candidates) {
      for (final training in candidates) {
        if (selected.any((item) => item.id == training.id)) {
          continue;
        }

        selected.add(training);
        if (selected.length == 2) {
          return;
        }
      }
    }

    addCandidates(
      items.where(
        (training) =>
            _matchesRecommendationProfile(training, profileKeywords),
      ),
    );
    addCandidates(items.where((training) => training.isFeatured));
    addCandidates(items);

    return selected.take(2).toList(growable: false);
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
    final currentUser = context.watch<AuthProvider>().userModel;
    final provider = context.watch<TrainingProvider>();
    final approvedTrainings = _sortedApprovedTrainings(provider.trainings);
    final availableDomains = _availableDomains(approvedTrainings);
    final profileKeywords = _profileRecommendationKeywords(
      fieldOfStudy: currentUser?.fieldOfStudy ?? '',
      researchDomain: currentUser?.researchDomain ?? '',
    );
    final activeDomain = availableDomains.contains(_selectedDomain)
        ? _selectedDomain
        : 'All';
    final domainFilteredTrainings = approvedTrainings
        .where((training) => _matchesDomain(training, activeDomain))
        .toList();
    final hasApprovedTrainings = approvedTrainings.isNotEmpty;
    final recommendedTrainings = _recommendedTrainings(
      approvedTrainings,
      profileKeywords: profileKeywords,
    );
    final catalogTrainings = domainFilteredTrainings;

    final topCards = recommendedTrainings.map(_mapTrainingToCardData).toList();
    final additionalCards = catalogTrainings
        .map(_mapTrainingToCardData)
        .toList();
    final sectionTitle = 'Recommended for you';
    final showTopEmptyState = !hasApprovedTrainings;
    final showDomainEmptyState =
        hasApprovedTrainings &&
        activeDomain != 'All' &&
        domainFilteredTrainings.isEmpty;
    final emptySubtitle = !hasApprovedTrainings || activeDomain == 'All'
        ? 'No training programs are available right now.'
        : 'No training programs are available right now for $activeDomain.';

    Widget buildTrainingCard(
      TrainingCourseCardData card, {
      TrainingLayoutView layoutView = TrainingLayoutView.grid,
    }) {
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

      final cardWidget = layoutView == TrainingLayoutView.grid
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
        appBar: _buildStandaloneAppBar(),
        body: SafeArea(top: false, child: const TrainingProgramsLoadingView()),
      );

      if (widget.embedded) {
        return loadingScaffold;
      }

      return AppShellBackground(child: loadingScaffold);
    }

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildStandaloneAppBar(),
      body: SafeArea(
        top: false,
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
                    const TrainingHeroIntro(),
                    const SizedBox(height: 18),
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
                    TrainingSectionTitle(title: sectionTitle),
                    const SizedBox(height: 12),
                    if (showTopEmptyState)
                      TrainingProgramsEmptyState(
                        title: 'No training programs available right now',
                        subtitle: emptySubtitle,
                      )
                    else
                      ...topCards.map(buildTrainingCard),
                    if (hasApprovedTrainings) ...[
                      const SizedBox(height: 10),
                      TrainingCatalogueSelector(
                        domains: availableDomains,
                        selectedDomain: activeDomain,
                        headerTrailing: TrainingLayoutToggle(
                          view: _trainingLayoutView,
                          onChanged: (view) {
                            setState(() {
                              _trainingLayoutView = view;
                            });
                          },
                        ),
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
                        ...additionalCards.map(
                          (card) => buildTrainingCard(
                            card,
                            layoutView: _trainingLayoutView,
                          ),
                        ),
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

class _TrainingAccent {
  final Color primary;
  final Color secondary;

  const _TrainingAccent({required this.primary, required this.secondary});
}
