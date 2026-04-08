import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../services/google_books_service.dart';
import '../../services/training_service.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';

class AdminGoogleBooksImportScreen extends StatefulWidget {
  const AdminGoogleBooksImportScreen({super.key});

  @override
  State<AdminGoogleBooksImportScreen> createState() =>
      _AdminGoogleBooksImportScreenState();
}

class _AdminGoogleBooksImportScreenState
    extends State<AdminGoogleBooksImportScreen> {
  final TextEditingController _searchController = TextEditingController();

  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final TrainingService _trainingService = TrainingService();

  bool _isSearching = false;
  bool _isImporting = false;
  bool _hasSearched = false;
  String? _searchError;
  String _importingBookId = '';

  List<TrainingModel> _results = [];

  String _selectedDomain = 'Informatique';
  String _selectedLevel = 'licence';
  String _selectedLanguage = 'fr';

  final List<String> _domains = const [
    'Informatique',
    'Mathematiques',
    'Medecine',
    'Droit',
    'Commerce',
    'Architecture',
    'Biologie',
    'Physique',
    'Chimie',
    'Langues',
  ];

  final List<String> _levels = const [
    'bac',
    'licence',
    'master',
    'doctorat',
    'general',
  ];

  final List<String> _languages = const ['fr', 'en', 'ar', ''];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) {
        return;
      }

      await context.read<TrainingProvider>().fetchTrainings();
    });
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
    });

    try {
      final results = await _googleBooksService.searchBooks(
        query: '$query $_selectedDomain',
        langRestrict: _selectedLanguage,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _searchError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message =
          'Something went wrong while searching books. Please try again.';
      setState(() {
        _results = [];
        _searchError = message;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _importBook(TrainingModel book) async {
    final adminId = context.read<AuthProvider>().userModel?.uid ?? '';

    if (adminId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin user not found')));
      return;
    }

    setState(() {
      _isImporting = true;
      _importingBookId = book.id;
    });

    try {
      await _trainingService.importGoogleBook(
        book: book,
        adminId: adminId,
        domain: _selectedDomain,
        level: _selectedLevel,
      );

      if (!mounted) {
        return;
      }

      await context.read<TrainingProvider>().fetchTrainings();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" imported successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importingBookId = '';
        });
      }
    }
  }

  Future<void> _toggleFeatured(TrainingModel training) async {
    final provider = context.read<TrainingProvider>();
    final error = await provider.updateFeaturedStatus(
      trainingId: training.id,
      isFeatured: !training.isFeatured,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            training.isFeatured
                ? 'Removed from featured resources'
                : 'Marked as featured',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _deleteTraining(TrainingModel training) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete resource'),
            content: Text(
              'Delete "${training.title}" from Firestore? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    final error = await context.read<TrainingProvider>().deleteTraining(
      training.id,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${training.title}" deleted')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _openLink(String link) async {
    if (link.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This result does not include an external link.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We couldn\'t open this link.')),
      );
    }
  }

  Widget _buildBookCover(TrainingModel book, {double width = 60}) {
    final height = width * 1.5;

    if (book.thumbnail.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.menu_book_rounded),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: book.thumbnail,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget _buildTrainingThumbnail(TrainingModel training) {
    final isVideo = training.type == 'video';
    final width = isVideo ? 96.0 : 56.0;
    final height = isVideo ? 54.0 : 84.0;
    final placeholderIcon = isVideo
        ? Icons.play_circle_outline_rounded
        : Icons.menu_book_rounded;

    if (training.thumbnail.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(placeholderIcon),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: training.thumbnail,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AdminSurface(
        child: Column(
          children: [
            const AdminSectionHeader(
              eyebrow: 'Google Books',
              title: 'Import Books',
              subtitle:
                  'Search by topic, domain, level, and language before publishing a curated resource into the library.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books, for example: algorithms',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDomain,
                    decoration: const InputDecoration(
                      labelText: 'Domain',
                      border: OutlineInputBorder(),
                    ),
                    items: _domains
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedDomain = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                    ),
                    items: _levels
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedLevel = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: _languages
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.isEmpty ? 'Any' : item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchBooks,
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? 'Searching...' : 'Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _results.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AdminPalette.primary),
        ),
      );
    }

    if (!_hasSearched) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AdminEmptyState(
          icon: Icons.menu_book_rounded,
          title: 'Start with a Google Books search',
          message:
              'Use a topic, domain, or language filter to bring in curated books for review.',
        ),
      );
    }

    if (_searchError != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AdminEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Search failed',
          message: _searchError!,
          action: FilledButton.icon(
            onPressed: _searchBooks,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AdminEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No books match this search',
          message:
              'Try a broader query or change the language and domain filters before searching again.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final book = _results[index];
          final isImportingBook = _importingBookId == book.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSearchResultCard(
              book: book,
              isImportingBook: isImportingBook,
            ),
          );
        }, childCount: _results.length),
      ),
    );
  }

  Widget _buildManageTab(TrainingProvider provider) {
    final books = provider.trainings
        .where((training) => training.source == 'google_books')
        .toList();

    if (provider.isLoading && books.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AdminPalette.primary),
      );
    }

    if (provider.errorMessage != null && books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Book library unavailable',
            message: provider.errorMessage!,
            action: FilledButton.icon(
              onPressed: provider.fetchTrainings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchTrainings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(
                  eyebrow: 'Library',
                  title: 'Manage Imported Books',
                  subtitle:
                      'This workspace is dedicated to Google Books imports, so book curation stays focused.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AdminPill(
                      label: '${books.length} imported books',
                      color: AdminPalette.info,
                      icon: Icons.menu_book_rounded,
                    ),
                    AdminPill(
                      label:
                          '${books.where((book) => book.isFeatured).length} featured',
                      color: AdminPalette.accent,
                      icon: Icons.star_rounded,
                    ),
                    AdminPill(
                      label: provider.isLoading ? 'Syncing' : 'Synced',
                      color: provider.isLoading
                          ? AdminPalette.warning
                          : AdminPalette.success,
                      icon: provider.isLoading
                          ? Icons.sync_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (books.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: AdminEmptyState(
                icon: Icons.menu_book_rounded,
                title: 'No books imported yet',
                message:
                    'Import a few Google Books results first, then manage featuring, opening, and deleting from here.',
              ),
            )
          else
            ...books.map((training) {
              final isBusy = provider.isTrainingBusy(training.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildManageResourceCard(
                  training: training,
                  isBusy: isBusy,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard({
    required TrainingModel book,
    required bool isImportingBook,
  }) {
    return AdminSurface(
      radius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookCover(book),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  book.authors.isNotEmpty
                      ? book.authors.join(', ')
                      : book.provider,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                if (book.description.trim().isNotEmpty)
                  Text(
                    book.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const AdminPill(label: 'BOOK', color: AdminPalette.info),
                    if (book.language.trim().isNotEmpty)
                      AdminPill(
                        label: book.language.toUpperCase(),
                        color: AdminPalette.success,
                      ),
                    if (book.domain.trim().isNotEmpty)
                      AdminPill(
                        label: book.domain,
                        color: AdminPalette.activity,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isImporting ? null : () => _importBook(book),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminPalette.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isImportingBook ? 'Importing...' : 'Import'),
          ),
        ],
      ),
    );
  }

  Widget _buildManageResourceCard({
    required TrainingModel training,
    required bool isBusy,
  }) {
    return AdminSurface(
      radius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrainingThumbnail(training),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        training.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isBusy)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  training.authors.isNotEmpty
                      ? training.authors.join(', ')
                      : training.provider,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AdminChip(
                      label: training.type.toUpperCase(),
                      color: AdminPalette.info,
                    ),
                    if (training.domain.trim().isNotEmpty)
                      _AdminChip(
                        label: training.domain,
                        color: AdminPalette.activity,
                      ),
                    if (training.isFeatured)
                      _AdminChip(
                        label: 'featured',
                        color: Colors.amber.shade800,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _toggleFeatured(training),
                      icon: Icon(
                        training.isFeatured
                            ? Icons.star_outline_rounded
                            : Icons.star_rounded,
                      ),
                      label: Text(
                        training.isFeatured ? 'Unfeature' : 'Feature',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isBusy || training.displayLink.trim().isEmpty
                          ? null
                          : () => _openLink(training.displayLink),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _deleteTraining(training),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminPalette.danger,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AdminPalette.background,
        appBar: AppBar(
          title: const Text('Import Google Books'),
          backgroundColor: Colors.white,
          foregroundColor: AdminPalette.textPrimary,
          bottom: const TabBar(
            labelColor: AdminPalette.primary,
            indicatorColor: AdminPalette.primary,
            tabs: [
              Tab(text: 'Search'),
              Tab(text: 'Manage'),
            ],
          ),
        ),
        body: AdminShellBackground(
          child: TabBarView(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: AdminSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AdminSectionHeader(
                              eyebrow: 'Studio',
                              title: 'Book Import Workspace',
                              subtitle:
                                  'Search and import books in one continuous flow instead of working inside separate fixed windows.',
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                AdminPill(
                                  label: '${_results.length} results',
                                  color: AdminPalette.info,
                                  icon: Icons.manage_search_rounded,
                                ),
                                AdminPill(
                                  label: _selectedDomain,
                                  color: AdminPalette.activity,
                                ),
                                AdminPill(
                                  label: _selectedLanguage.isEmpty
                                      ? 'Any language'
                                      : _selectedLanguage.toUpperCase(),
                                  color: AdminPalette.success,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildSearchForm()),
                  _buildSearchResults(),
                ],
              ),
              _buildManageTab(provider),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AdminChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
