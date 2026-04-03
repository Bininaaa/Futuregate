import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/training_model.dart';
import '../../providers/training_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import 'admin_google_books_import_screen.dart';
import 'admin_youtube_import_screen.dart';

class AdminLibraryScreen extends StatefulWidget {
  const AdminLibraryScreen({super.key});

  @override
  State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();
    final trainings = provider.trainings;
    final featuredCount = trainings.where((item) => item.isFeatured).length;
    final googleBooksCount = trainings
        .where((item) => item.source == 'google_books')
        .length;
    final youtubeCount = trainings
        .where((item) => item.source == 'youtube')
        .length;

    return RefreshIndicator(
      color: AdminPalette.primary,
      onRefresh: provider.fetchTrainings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminHeroCard(
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
            const SizedBox(height: 18),
            const AdminSectionHeader(
              eyebrow: 'Sources',
              title: 'Import Pipelines',
              subtitle:
                  'Each source keeps its own search workflow and management tools, but they now live under one library destination.',
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
                const _LibraryStat(label: 'Source', value: 'Google Books'),
              ],
              chips: const [
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
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminGoogleBooksImportScreen(),
                  ),
                );
              },
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
                const _LibraryStat(label: 'Source', value: 'YouTube'),
              ],
              chips: const [
                AdminPill(
                  label: 'Video Lessons',
                  color: AdminPalette.danger,
                  icon: Icons.play_circle_outline_rounded,
                ),
                AdminPill(label: 'Quick Curation', color: AdminPalette.accent),
              ],
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminYoutubeImportScreen(),
                  ),
                );
              },
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
                        label: provider.isLoading
                            ? 'Refreshing library'
                            : 'Library synced',
                        color: provider.isLoading
                            ? AdminPalette.warning
                            : AdminPalette.success,
                        icon: provider.isLoading
                            ? Icons.sync_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? _libraryHealthMessage(trainings),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: provider.errorMessage == null
                          ? AdminPalette.textSecondary
                          : AdminPalette.danger,
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: provider.fetchTrainings,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry sync'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _libraryHealthMessage(List<TrainingModel> trainings) {
    if (trainings.isEmpty) {
      return 'No resources have been imported yet. Start with books or video lessons, then feature the strongest material for students.';
    }

    return 'The library currently mixes imported and internal resources. Use the source studios above whenever you want to add or refine curated content without leaving the admin area.';
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
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
                          style: const TextStyle(
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
            label: const Text('Open Studio'),
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
