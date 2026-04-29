import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/training_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/training_provider.dart';
import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import 'admin_google_books_import_screen.dart';
import 'admin_youtube_import_screen.dart';

enum AdminLibrarySource { overview, googleBooks, youtube }

class AdminLibraryScreen extends StatefulWidget {
  final bool embedded;
  final AdminLibrarySource initialSource;

  const AdminLibraryScreen({
    super.key,
    this.embedded = false,
    this.initialSource = AdminLibrarySource.overview,
  });

  @override
  State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen>
    with SingleTickerProviderStateMixin {
  static const String _filterAll = 'all';
  static const String _filterFeatured = 'featured';
  static const String _filterHidden = 'hidden';
  static const String _filterBooks = 'books';
  static const String _filterVideos = 'videos';

  late final TabController _sourceController;
  final TextEditingController _searchController = TextEditingController();

  String _libraryFilter = _filterAll;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _sourceController = TabController(
      length: AdminLibrarySource.values.length,
      vsync: this,
      initialIndex: widget.initialSource.index,
    );
    Future.microtask(() async {
      if (!mounted) {
        return;
      }

      final provider = context.read<TrainingProvider>();
      if (provider.trainings.isEmpty && !provider.isLoading) {
        await provider.fetchTrainings();
      }
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ThemeData _buildScopedTheme(BuildContext context) {
    return Theme.of(context);
  }

  Future<void> _syncLibraryState() async {
    await Future.wait([
      context.read<TrainingProvider>().fetchTrainings(),
      context.read<AdminProvider>().loadModerationData(),
    ]);
  }

  void _selectSource(AdminLibrarySource source) {
    if (_sourceController.index == source.index) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _sourceController.animateTo(source.index);
  }

  Future<void> _openSourceWorkspace(AdminLibrarySource source) async {
    if (!widget.embedded) {
      _selectSource(source);
      return;
    }

    final Widget destination;
    switch (source) {
      case AdminLibrarySource.overview:
        return;
      case AdminLibrarySource.googleBooks:
        destination = const AdminGoogleBooksImportScreen();
        break;
      case AdminLibrarySource.youtube:
        destination = const AdminYoutubeImportScreen();
        break;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => destination));

    if (!mounted) {
      return;
    }

    await _syncLibraryState();
  }

  bool _matchesLibrarySearch(TrainingModel training) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final authorsText = training.authors.join(' ').toLowerCase();
    return training.title.toLowerCase().contains(query) ||
        training.provider.toLowerCase().contains(query) ||
        training.domain.toLowerCase().contains(query) ||
        training.level.toLowerCase().contains(query) ||
        training.source.toLowerCase().contains(query) ||
        training.type.toLowerCase().contains(query) ||
        authorsText.contains(query) ||
        training.language.toLowerCase().contains(query);
  }

  bool _matchesLibraryFilter(TrainingModel training, String filter) {
    switch (filter) {
      case _filterBooks:
        return training.type.trim().toLowerCase() == 'book';
      case _filterVideos:
        return training.type.trim().toLowerCase() == 'video';
      case _filterFeatured:
        return training.isFeatured;
      case _filterHidden:
        return training.isHidden;
      default:
        return true;
    }
  }

  String _libraryFilterTitle(String filter) {
    switch (filter) {
      case _filterBooks:
        return _l10n.uiBookLibrary;
      case _filterVideos:
        return _l10n.uiVideoLibrary;
      case _filterFeatured:
        return _l10n.uiFeaturedResources;
      case _filterHidden:
        return _l10n.uiHiddenResources;
      default:
        return _l10n.uiLibrary;
    }
  }

  String _libraryEmptyMessage(String filter) {
    switch (filter) {
      case _filterBooks:
        return _l10n.uiNoBooksMatchThisSearch;
      case _filterVideos:
        return _l10n.uiNoVideosMatchThisSearch;
      case _filterFeatured:
        return _l10n.uiNoFeaturedResourcesMatchThisSearch;
      case _filterHidden:
        return _l10n.uiNoHiddenResourcesMatchThisSearch;
      default:
        return _l10n.uiNoLibraryResourcesMatchThisSearch;
    }
  }

  String _joinCardSubtitleParts(Iterable<String> parts) {
    return parts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(' | ');
  }

  String _buildDateMetaLabel(String prefix, DateTime? value) {
    if (value == null) {
      return '';
    }
    return '$prefix ${DateFormat('MMM d').format(value.toLocal())}';
  }

  Color _resourceAccentColor(String type) {
    switch (type.trim().toLowerCase()) {
      case 'video':
        return AdminPalette.primary;
      case 'book':
        return AdminPalette.secondary;
      default:
        return AdminPalette.primary;
    }
  }

  IconData _resourceIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'video':
        return Icons.ondemand_video_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      default:
        return Icons.school_outlined;
    }
  }

  String _toggleFilterValue(
    String current,
    String next, {
    required String allValue,
  }) {
    return current == next ? allValue : next;
  }

  Future<void> _openExternalLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      context.showAppSnackBar(
        _l10n.uiThisResourceLinkIsInvalid,
        title: _l10n.uiLinkUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!mounted) {
      return;
    }
    if (!launched) {
      context.showAppSnackBar(
        _l10n.uiWeCouldNotOpenThisLinkRightNow,
        title: _l10n.uiLinkUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _toggleTrainingVisibility(TrainingModel training) async {
    final adminProvider = context.read<AdminProvider>();
    final error = await adminProvider.setTrainingHidden(
      training.id,
      !training.isHidden,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _l10n.updateUnavailableTitle,
        type: AppFeedbackType.error,
      );
      return;
    }

    await _syncLibraryState();
    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      training.isHidden
          ? _l10n.uiThisResourceIsVisibleAgain
          : _l10n.uiThisResourceWasHiddenYouCanRestoreItLater,
      title: training.isHidden
          ? _l10n.uiResourceVisible
          : _l10n.uiResourceHidden,
      type: training.isHidden
          ? AppFeedbackType.success
          : AppFeedbackType.removed,
      icon: training.isHidden ? null : Icons.visibility_off_outlined,
    );
  }

  Future<void> _showTrainingDetails(TrainingModel training) async {
    final accentColor = _resourceAccentColor(training.type);
    final providerLabel = DisplayText.capitalizeLeadingLabel(
      training.provider.isNotEmpty
          ? training.provider
          : _l10n.uiUnknownProvider,
    );
    final domainLabel = DisplayText.capitalizeLeadingLabel(training.domain);
    final levelLabel = DisplayText.capitalizeWords(training.level);
    final typeLabel = DisplayText.capitalizeWords(training.type);
    final sourceLabel = DisplayText.capitalizeWords(
      training.source.replaceAll('_', ' '),
    );
    final displayLink = training.displayLink.trim();
    final summary = training.description.trim();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Material(
                color: AdminPalette.background,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 14),
                    AdminSectionHeader(
                      eyebrow: _l10n.uiLibrary,
                      title: DisplayText.capitalizeWords(training.title),
                      subtitle: _joinCardSubtitleParts([
                        providerLabel,
                        if (domainLabel.isNotEmpty) domainLabel,
                        if (levelLabel.isNotEmpty) levelLabel,
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(typeLabel, accentColor),
                        if (!training.isApproved)
                          _buildBadge(
                            _l10n.uiPending,
                            AdminPalette.textSecondary,
                          ),
                        if (training.isFeatured)
                          _buildBadge(
                            _l10n.uiFeatured,
                            AdminPalette.textSecondary,
                          ),
                        if (training.isHidden)
                          _buildBadge(_l10n.uiHidden, Colors.blueGrey),
                        if (sourceLabel.isNotEmpty)
                          _buildBadge(sourceLabel, AdminPalette.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AdminSurface(
                      radius: 18,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Provider', providerLabel),
                          if (domainLabel.isNotEmpty)
                            _buildDetailRow('Domain', domainLabel),
                          if (levelLabel.isNotEmpty)
                            _buildDetailRow('Level', levelLabel),
                          if (training.language.trim().isNotEmpty)
                            _buildDetailRow(
                              'Language',
                              training.language.toUpperCase(),
                            ),
                          if (training.duration.trim().isNotEmpty)
                            _buildDetailRow('Duration', training.duration),
                          if (training.learnerCountLabel.trim().isNotEmpty)
                            _buildDetailRow(
                              'Learners',
                              training.learnerCountLabel.trim(),
                            ),
                          if (training.rating != null)
                            _buildDetailRow(
                              'Rating',
                              training.rating!.toStringAsFixed(1),
                            ),
                          if (training.hasCertificate == true)
                            _buildDetailRow('Certificate', 'Available'),
                        ],
                      ),
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AdminSurface(
                        radius: 18,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          summary,
                          style: AppTypography.product(
                            fontSize: 13,
                            height: 1.55,
                            color: AdminPalette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildResponsiveActionGroup([
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _toggleTrainingVisibility(training);
                        },
                        icon: Icon(
                          training.isHidden
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_outlined,
                          size: 16,
                        ),
                        label: Text(
                          training.isHidden ? _l10n.uiUnhide : _l10n.uiHide,
                        ),
                        style: _compactOutlinedFooterStyle(
                          training.isHidden
                              ? AdminPalette.success
                              : AdminPalette.textSecondary,
                        ),
                      ),
                      if (displayLink.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () => _openExternalLink(displayLink),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text(
                            AppLocalizations.of(context)!.uiOpenResource,
                          ),
                          style: _compactFilledFooterStyle(
                            AdminPalette.primary,
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab(TrainingProvider provider) {
    final adminProvider = context.watch<AdminProvider>();
    final allTrainings =
        provider.trainings.where(_matchesLibrarySearch).toList()
          ..sort((first, second) {
            if (first.isHidden != second.isHidden) {
              return first.isHidden ? 1 : -1;
            }
            if (first.isApproved != second.isApproved) {
              return first.isApproved ? 1 : -1;
            }
            if (first.isFeatured != second.isFeatured) {
              return first.isFeatured ? -1 : 1;
            }
            final firstTime = first.createdAt?.millisecondsSinceEpoch ?? 0;
            final secondTime = second.createdAt?.millisecondsSinceEpoch ?? 0;
            return secondTime.compareTo(firstTime);
          });
    final bookCount = allTrainings
        .where((training) => training.type.trim().toLowerCase() == 'book')
        .length;
    final videoCount = allTrainings
        .where((training) => training.type.trim().toLowerCase() == 'video')
        .length;
    final featuredCount = allTrainings
        .where((training) => training.isFeatured)
        .length;
    final hiddenCount = allTrainings
        .where((training) => training.isHidden)
        .length;
    final trainings = allTrainings
        .where((training) => _matchesLibraryFilter(training, _libraryFilter))
        .toList();
    final searchQuery = _searchController.text.trim();

    if (provider.isLoading && provider.trainings.isEmpty) {
      return const AppLoadingView(
        density: AppLoadingDensity.compact,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      );
    }

    if (provider.errorMessage != null && provider.trainings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: _l10n.uiLibraryUnavailable,
            message: provider.errorMessage!,
            action: FilledButton.icon(
              onPressed: () => _syncLibraryState(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.retryLabel),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AdminPalette.primary,
      onRefresh: _syncLibraryState,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AdminSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  eyebrow: _l10n.uiLibrary,
                  title:
                      '${_libraryFilterTitle(_libraryFilter)} (${trainings.length})',
                  subtitle: searchQuery.isEmpty
                      ? _l10n
                            .uiLibraryNowHoldsAllLearningResourcesSearchFilterReviewDetailsAndJumpIntoImportStudiosWhenYouNeedToAddMore
                      : _l10n.uiShowingFilteredResultsForSearchQuery(
                          searchQuery,
                        ),
                ),
                const SizedBox(height: 12),
                _buildSourceWorkspaceButtons(),
                const SizedBox(height: 12),
                AdminSearchField(
                  controller: _searchController,
                  hintText:
                      _l10n.uiSearchLibraryByTitleProviderDomainLevelOrSource,
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                _buildFilterChipRow([
                  AdminFilterChip(
                    label: _l10n.uiAll,
                    selected: _libraryFilter == _filterAll,
                    icon: Icons.grid_view_rounded,
                    badgeCount: allTrainings.length,
                    onTap: () => setState(() => _libraryFilter = _filterAll),
                    compact: true,
                  ),
                  AdminFilterChip(
                    label: _l10n.uiFeatured,
                    selected: _libraryFilter == _filterFeatured,
                    icon: Icons.workspace_premium_outlined,
                    badgeCount: featuredCount,
                    onTap: () => setState(() {
                      _libraryFilter = _toggleFilterValue(
                        _libraryFilter,
                        _filterFeatured,
                        allValue: _filterAll,
                      );
                    }),
                    compact: true,
                  ),
                  AdminFilterChip(
                    label: _l10n.uiHidden,
                    selected: _libraryFilter == _filterHidden,
                    icon: Icons.visibility_off_outlined,
                    badgeCount: hiddenCount,
                    onTap: () => setState(() {
                      _libraryFilter = _toggleFilterValue(
                        _libraryFilter,
                        _filterHidden,
                        allValue: _filterAll,
                      );
                    }),
                    compact: true,
                  ),
                ]),
                const SizedBox(height: 8),
                _buildFilterChipRow([
                  AdminFilterChip(
                    label: _l10n.uiBooks,
                    selected: _libraryFilter == _filterBooks,
                    icon: Icons.menu_book_rounded,
                    badgeCount: bookCount,
                    onTap: () => setState(() {
                      _libraryFilter = _toggleFilterValue(
                        _libraryFilter,
                        _filterBooks,
                        allValue: _filterAll,
                      );
                    }),
                    compact: true,
                  ),
                  AdminFilterChip(
                    label: _l10n.uiVideos,
                    selected: _libraryFilter == _filterVideos,
                    icon: Icons.ondemand_video_outlined,
                    badgeCount: videoCount,
                    onTap: () => setState(() {
                      _libraryFilter = _toggleFilterValue(
                        _libraryFilter,
                        _filterVideos,
                        allValue: _filterAll,
                      );
                    }),
                    compact: true,
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (trainings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AdminEmptyState(
                icon: Icons.search_off_outlined,
                title: _l10n.uiNoResultsInThisView,
                message: _libraryEmptyMessage(_libraryFilter),
              ),
            )
          else
            ...trainings.map(
              (training) => _buildResourceTile(
                training: training,
                isBusy: provider.isTrainingBusy(training.id),
                isVisibilityBusy: adminProvider.busyContentKeys.contains(
                  'training:${training.id}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceTile({
    required TrainingModel training,
    required bool isBusy,
    required bool isVisibilityBusy,
  }) {
    final accentColor = _resourceAccentColor(training.type);
    final providerLabel = DisplayText.capitalizeLeadingLabel(
      training.provider.isNotEmpty
          ? training.provider
          : _l10n.uiUnknownProvider,
    );
    final domainLabel = DisplayText.capitalizeLeadingLabel(training.domain);
    final levelLabel = DisplayText.capitalizeWords(training.level);
    final typeLabel = DisplayText.capitalizeWords(training.type);
    final statusLabel = training.isHidden
        ? _l10n.uiHidden
        : !training.isApproved
        ? _l10n.uiPending
        : training.isFeatured
        ? _l10n.uiFeatured
        : '';
    final badges = <_LibraryBadge>[
      _LibraryBadge(typeLabel, accentColor),
      if (statusLabel.isNotEmpty)
        _LibraryBadge(statusLabel, AdminPalette.textSecondary),
      if (levelLabel.trim().isNotEmpty)
        _LibraryBadge(levelLabel, AdminPalette.textSecondary),
    ].take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showTrainingDetails(training),
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: AdminPalette.border.withValues(alpha: 0.88),
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AdminPalette.primary.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _resourceIcon(training.type),
                          color: accentColor,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DisplayText.capitalizeWords(training.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AdminPalette.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _joinCardSubtitleParts([
                                providerLabel,
                                if (domainLabel.isNotEmpty) domainLabel,
                              ]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AdminPalette.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCompactCardAction(
                        icon: training.isHidden
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_outlined,
                        color: training.isHidden
                            ? AdminPalette.success
                            : AdminPalette.textSecondary,
                        onTap: isVisibilityBusy
                            ? null
                            : () => _toggleTrainingVisibility(training),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...badges.map(
                        (badge) => _buildBadge(badge.label, badge.color),
                      ),
                      _buildMetaBadge(
                        _joinCardSubtitleParts([
                          _buildDateMetaLabel(
                            'Added',
                            training.createdAt?.toDate(),
                          ),
                          if (training.learnerCountLabel.trim().isNotEmpty)
                            '${training.learnerCountLabel.trim()} learners',
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildResponsiveActionGroup([
                    OutlinedButton.icon(
                      onPressed: () => _showTrainingDetails(training),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(AppLocalizations.of(context)!.uiDetails),
                      style: _compactOutlinedFooterStyle(AdminPalette.primary),
                    ),
                    if (training.displayLink.trim().isNotEmpty)
                      FilledButton.icon(
                        onPressed: () =>
                            _openExternalLink(training.displayLink),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(
                          AppLocalizations.of(context)!.uiOpenResource,
                        ),
                        style: _compactFilledFooterStyle(AdminPalette.primary),
                      ),
                    if (training.isHidden)
                      OutlinedButton.icon(
                        onPressed: isBusy || isVisibilityBusy
                            ? null
                            : () => _toggleTrainingVisibility(training),
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: Text(_l10n.uiUnhide),
                        style: _compactOutlinedFooterStyle(
                          AdminPalette.success,
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipRow(List<Widget> chips) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildSourceWorkspaceButtons() {
    final googleBooksButton = FilledButton.icon(
      onPressed: () => _openSourceWorkspace(AdminLibrarySource.googleBooks),
      icon: const Icon(Icons.menu_book_rounded, size: 18),
      label: Text(_l10n.uiGoogleBooks),
      style: FilledButton.styleFrom(
        backgroundColor: AdminPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: AppTypography.product(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final youtubeButton = OutlinedButton.icon(
      onPressed: () => _openSourceWorkspace(AdminLibrarySource.youtube),
      icon: const Icon(Icons.ondemand_video_rounded, size: 18),
      label: Text(_l10n.uiYoutube),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminPalette.textSecondary,
        side: BorderSide(
          color: AdminPalette.textSecondary.withValues(alpha: 0.24),
        ),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: AppTypography.product(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              googleBooksButton,
              const SizedBox(height: 8),
              youtubeButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: googleBooksButton),
            const SizedBox(width: 8),
            Expanded(child: youtubeButton),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveActionGroup(List<Widget> buttons) {
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                buttons[index],
                if (index < buttons.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Wrap(spacing: 8, runSpacing: 8, children: buttons);
      },
    );
  }

  ButtonStyle _compactOutlinedFooterStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.24)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: AppTypography.product(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _compactFilledFooterStyle(Color color) {
    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: AppTypography.product(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCompactCardAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final effectiveColor = onTap == null ? AdminPalette.textMuted : color;

    return Material(
      color: effectiveColor.withValues(alpha: onTap == null ? 0.05 : 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16.5, color: effectiveColor),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 10.2,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildMetaBadge(String label) {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AdminPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 11.5,
              color: AdminPalette.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                normalized,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: 10.2,
                  fontWeight: FontWeight.w600,
                  color: AdminPalette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTypography.product(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              normalized,
              style: AppTypography.product(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AdminPalette.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scopedTheme = _buildScopedTheme(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TrainingProvider>();

    if (widget.embedded) {
      return Theme(data: scopedTheme, child: _buildOverviewTab(provider));
    }

    final trainings = provider.trainings;
    final featuredCount = trainings.where((item) => item.isFeatured).length;
    final bookCount = trainings
        .where((item) => item.type.trim().toLowerCase() == 'book')
        .length;
    final videoCount = trainings
        .where((item) => item.type.trim().toLowerCase() == 'video')
        .length;
    final content = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 12, 16, 10),
          child: AdminSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  eyebrow: l10n.uiLibrary,
                  title: l10n.uiLearningResources,
                  subtitle: l10n
                      .uiKeepBooksAndVideoResourcesInOneAdminFriendlyLibraryThenOpenTheSourceStudiosOnlyWhenYouNeedNewImports,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AdminPill(
                      label: l10n.libraryPillResourcesCount(trainings.length),
                      color: AdminPalette.primary,
                      icon: Icons.library_books_outlined,
                    ),
                    AdminPill(
                      label: l10n.libraryPillFeaturedCount(featuredCount),
                      color: AdminPalette.textSecondary,
                      icon: Icons.star_outline_rounded,
                    ),
                    AdminPill(
                      label: l10n.libraryPillBooksCount(bookCount),
                      color: AdminPalette.secondary,
                      icon: Icons.menu_book_rounded,
                    ),
                    AdminPill(
                      label: l10n.libraryPillVideosCount(videoCount),
                      color: AdminPalette.textSecondary,
                      icon: Icons.ondemand_video_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AdminPalette.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AdminPalette.border),
            ),
            child: TabBar(
              controller: _sourceController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: AdminPalette.textPrimary,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AdminPalette.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              tabs: [
                _LibraryTab(
                  icon: Icons.dashboard_outlined,
                  label: l10n.uiOverview,
                ),
                _LibraryTab(
                  icon: Icons.menu_book_rounded,
                  label: l10n.uiGoogleBooks,
                ),
                _LibraryTab(
                  icon: Icons.ondemand_video_rounded,
                  label: l10n.uiYoutube,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _sourceController,
            children: [
              _buildOverviewTab(provider),
              const AdminGoogleBooksImportScreen(embedded: true),
              const AdminYoutubeImportScreen(embedded: true),
            ],
          ),
        ),
      ],
    );

    return Theme(
      data: scopedTheme,
      child: Scaffold(
        backgroundColor: AdminPalette.background,
        appBar: AppBar(
          title: Text(l10n.uiLibrary),
          backgroundColor: AdminPalette.surface,
          foregroundColor: AdminPalette.textPrimary,
        ),
        body: AdminShellBackground(child: SafeArea(top: false, child: content)),
      ),
    );
  }
}

class _LibraryTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LibraryTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBadge {
  final String label;
  final Color color;

  const _LibraryBadge(this.label, this.color);
}
