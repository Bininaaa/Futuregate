import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../services/google_books_service.dart';
import '../../services/training_service.dart';

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
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

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
        const SnackBar(content: Text('No link available for this item')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link')));
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
    final orange = const Color(0xFFFF8C00);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
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
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
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
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
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
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final strongPurple = const Color(0xFF2D1B4E);

    if (_results.isEmpty) {
      return const Center(child: Text('No Google Books results yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final book = _results[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: strongPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.authors.isNotEmpty
                            ? book.authors.join(', ')
                            : book.provider,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (book.description.trim().isNotEmpty)
                        Text(
                          book.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'BOOK',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (book.language.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                book.language.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isImporting ? null : () => _importBook(book),
                  child: const Text('Import'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManageTab(TrainingProvider provider) {
    if (provider.isLoading && provider.trainings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.trainings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.fetchTrainings(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.trainings.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.fetchTrainings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No imported resources found yet')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchTrainings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.trainings.length,
        itemBuilder: (context, index) {
          final training = provider.trainings[index];
          final isBusy = provider.isTrainingBusy(training.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          training.authors.isNotEmpty
                              ? training.authors.join(', ')
                              : training.provider,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AdminChip(
                              label: training.type.toUpperCase(),
                              color: Colors.blue,
                            ),
                            if (training.source.trim().isNotEmpty)
                              _AdminChip(
                                label: training.source.replaceAll('_', ' '),
                                color: Colors.teal,
                              ),
                            if (training.domain.trim().isNotEmpty)
                              _AdminChip(
                                label: training.domain,
                                color: Colors.deepPurple,
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
                              onPressed:
                                  isBusy || training.displayLink.trim().isEmpty
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
                                foregroundColor: Colors.red,
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
            ),
          );
        },
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
        appBar: AppBar(
          title: const Text('Import Google Books'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Search'),
              Tab(text: 'Manage'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                _buildSearchForm(),
                Expanded(child: _buildSearchResults()),
              ],
            ),
            _buildManageTab(provider),
          ],
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
