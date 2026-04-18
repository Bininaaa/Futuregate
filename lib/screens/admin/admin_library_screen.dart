import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/training_model.dart';
import '../../providers/training_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
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
  late final TabController _sourceController;

  @override
  void initState() {
    super.initState();
    _sourceController = TabController(
      length: AdminLibrarySource.values.length,
      vsync: this,
      initialIndex: widget.initialSource.index,
    );
    Future.microtask(() {
      if (!mounted) {
        return;
      }

      final provider = context.read<TrainingProvider>();
      if (provider.trainings.isEmpty && !provider.isLoading) {
        provider.fetchTrainings();
      }
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  void _selectSource(AdminLibrarySource source) {
    if (_sourceController.index == source.index) {
      return;
    }
    _sourceController.animateTo(source.index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TrainingProvider>();
    final trainings = provider.trainings;
    final featuredCount = trainings.where((item) => item.isFeatured).length;
    final googleBooksCount = trainings
        .where((item) => item.source == 'google_books')
        .length;
    final youtubeCount = trainings
        .where((item) => item.source == 'youtube')
        .length;
    final content = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 12, 16, 10),
          child: AdminHeroCard(
            title: 'Resource Studio for Admin Curation',
            subtitle:
                'Import trusted learning resources, keep featured content fresh, and turn external sources into a clean admin-managed library.',
            icon: Icons.auto_awesome_mosaic_rounded,
            accentColor: AdminPalette.secondary,
            stats: [
              AdminHeroStat(label: 'Resources', value: '${trainings.length}'),
              AdminHeroStat(label: 'Featured', value: '$featuredCount'),
              AdminHeroStat(label: 'Books', value: '$googleBooksCount'),
              AdminHeroStat(label: 'Videos', value: '$youtubeCount'),
            ],
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
                color: AdminPalette.secondary,
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
              _LibraryOverviewTab(
                trainings: trainings,
                isLoading: provider.isLoading,
                errorMessage: provider.errorMessage,
                googleBooksCount: googleBooksCount,
                youtubeCount: youtubeCount,
                featuredCount: featuredCount,
                onRefresh: provider.fetchTrainings,
                onOpenGoogleBooks: () =>
                    _selectSource(AdminLibrarySource.googleBooks),
                onOpenYoutube: () => _selectSource(AdminLibrarySource.youtube),
              ),
              const AdminGoogleBooksImportScreen(embedded: true),
              const AdminYoutubeImportScreen(embedded: true),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: AppBar(
        title: Text(l10n.uiLibrary),
        backgroundColor: AdminPalette.surface,
        foregroundColor: AdminPalette.textPrimary,
      ),
      body: AdminShellBackground(child: SafeArea(top: false, child: content)),
    );
  }
}

class _LibraryOverviewTab extends StatelessWidget {
  final List<TrainingModel> trainings;
  final bool isLoading;
  final String? errorMessage;
  final int googleBooksCount;
  final int youtubeCount;
  final int featuredCount;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenGoogleBooks;
  final VoidCallback onOpenYoutube;

  const _LibraryOverviewTab({
    required this.trainings,
    required this.isLoading,
    required this.errorMessage,
    required this.googleBooksCount,
    required this.youtubeCount,
    required this.featuredCount,
    required this.onRefresh,
    required this.onOpenGoogleBooks,
    required this.onOpenYoutube,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AdminPalette.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const AdminSectionHeader(
            eyebrow: 'Sources',
            title: 'Import Pipelines',
            subtitle:
                'Each source keeps its own search workflow and management tools, but they now live under one embedded library destination.',
          ),
          const SizedBox(height: 12),
          _LibraryCard(
            title: 'Google Books Import',
            subtitle:
                'Find books by domain, level, and language, then import them into the training library with admin metadata.',
            icon: Icons.menu_book_rounded,
            accentColor: AdminPalette.info,
            stats: [
              _LibraryStat(label: 'Imported', value: '$googleBooksCount'),
              _LibraryStat(label: 'Source', value: 'Google Books'),
            ],
            chips: [
              AdminPill(
                label: 'Books',
                color: AdminPalette.info,
                icon: Icons.book_outlined,
              ),
              AdminPill(
                label: 'Language Filters',
                color: AdminPalette.secondary,
              ),
            ],
            onOpen: onOpenGoogleBooks,
          ),
          const SizedBox(height: 12),
          _LibraryCard(
            title: 'YouTube Import',
            subtitle:
                'Search educational videos, review metadata, and publish curated training content from YouTube into the admin library.',
            icon: Icons.ondemand_video_rounded,
            accentColor: AdminPalette.danger,
            stats: [
              _LibraryStat(label: 'Imported', value: '$youtubeCount'),
              _LibraryStat(label: 'Source', value: 'YouTube'),
            ],
            chips: [
              AdminPill(
                label: 'Video Lessons',
                color: AdminPalette.danger,
                icon: Icons.play_circle_outline_rounded,
              ),
              AdminPill(label: 'Quick Curation', color: AdminPalette.accent),
            ],
            onOpen: onOpenYoutube,
          ),
          const SizedBox(height: 18),
          const AdminSectionHeader(
            eyebrow: 'Health',
            title: 'Library Overview',
            subtitle:
                'A quick pulse on imported resources so admins can curate instead of guessing.',
          ),
          const SizedBox(height: 12),
          AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AdminPill(
                      label: '$featuredCount featured resources',
                      color: AdminPalette.accent,
                      icon: Icons.star_rounded,
                    ),
                    AdminPill(
                      label:
                          '${trainings.where((item) => item.source == 'internal').length} internal items',
                      color: AdminPalette.secondary,
                      icon: Icons.inventory_2_outlined,
                    ),
                    AdminPill(
                      label: isLoading
                          ? 'Refreshing library'
                          : 'Library synced',
                      color: isLoading
                          ? AdminPalette.warning
                          : AdminPalette.success,
                      icon: isLoading
                          ? Icons.sync_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? _libraryHealthMessage(trainings),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: errorMessage == null
                        ? AdminPalette.textSecondary
                        : AdminPalette.danger,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppLocalizations.of(context)!.uiRetrySync),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _libraryHealthMessage(List<TrainingModel> trainings) {
    if (trainings.isEmpty) {
      return 'No resources have been imported yet. Import books or video lessons to start curating material for students.';
    }

    return 'The library currently mixes imported and internal resources. Use the source studios above whenever you want to add or refine curated content without leaving the admin area.';
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
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<_LibraryStat> stats;
  final List<Widget> chips;
  final VoidCallback onOpen;

  const _LibraryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.stats,
    required this.chips,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: AdminPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: chips),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats
                .map(
                  (stat) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AdminPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdminPalette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.value,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stat.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AdminPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(AppLocalizations.of(context)!.uiOpenStudio),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryStat {
  final String label;
  final String value;

  const _LibraryStat({required this.label, required this.value});
}
