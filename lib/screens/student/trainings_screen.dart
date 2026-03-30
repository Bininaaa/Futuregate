import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../widgets/training_resource_card.dart';
import 'saved_trainings_screen.dart';

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'all';
  String _selectedDomain = 'All';
  String _searchText = '';

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

  void _handleSearchChanged() {
    final nextValue = _searchController.text;
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

  Future<void> _toggleSaved(TrainingModel training) async {
    final authProvider = context.read<AuthProvider>();
    final trainingProvider = context.read<TrainingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final uid = authProvider.userModel?.uid;

    if (uid == null || uid.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save resources'),
        ),
      );
      return;
    }

    final wasSaved = trainingProvider.isTrainingSaved(training.id);
    final error = await trainingProvider.toggleSavedTraining(
      userId: uid,
      training: training,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? 'Removed from saved resources' : 'Resource saved',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  List<String> _availableDomains(List<TrainingModel> allItems) {
    final domains =
        allItems
            .where((item) => item.isApproved && item.domain.trim().isNotEmpty)
            .map((item) => item.domain.trim())
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['All', ...domains];
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
    ];

    return searchableValues.any((value) => value.toLowerCase().contains(query));
  }

  List<TrainingModel> _filteredItems(
    List<TrainingModel> allItems,
    String activeDomain,
  ) {
    return allItems.where((item) {
      if (!item.isApproved) {
        return false;
      }

      if (_selectedFilter != 'all' && item.type != _selectedFilter) {
        return false;
      }

      if (activeDomain != 'All' && item.domain.trim() != activeDomain) {
        return false;
      }

      return _matchesSearch(item);
    }).toList();
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title, provider, authors, domain...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(
    TrainingProvider provider,
    List<TrainingModel> featuredItems,
  ) {
    if (featuredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final uid = context.read<AuthProvider>().userModel?.uid ?? '';
    final featuredHeight = featuredItems.any((item) => item.type == 'video')
        ? 300.0
        : 210.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured Resources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Highlighted books, videos, and materials recommended for students.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: featuredHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featuredItems.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final training = featuredItems[index];
                final isSaved = provider.isTrainingSaved(training.id);
                final isBusy = provider.isTrainingBusy(training.id);

                return Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeaturedMediaPreview(training),
                      if (training.type == 'video') const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              training.type.toUpperCase(),
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (uid.isNotEmpty)
                            isBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    onPressed: () => _toggleSaved(training),
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline_rounded,
                                      color: isSaved
                                          ? const Color(0xFFFF8C00)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        training.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        training.authors.isNotEmpty
                            ? training.authors.join(', ')
                            : training.provider,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (training.domain.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          training.domain,
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openLink(training.displayLink),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open Resource'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMediaPreview(TrainingModel training) {
    if (training.type != 'video') {
      return const SizedBox.shrink();
    }

    if (training.thumbnail.trim().isEmpty) {
      return Container(
        height: 96,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.play_circle_outline_rounded, size: 42),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: training.thumbnail,
        height: 96,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 96,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 96,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget _buildFiltersSection(List<String> domains, String activeDomain) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('book', 'Books'),
                const SizedBox(width: 8),
                _buildFilterChip('training', 'Trainings'),
                const SizedBox(width: 8),
                _buildFilterChip('course', 'Courses'),
                const SizedBox(width: 8),
                _buildFilterChip('video', 'Videos'),
                const SizedBox(width: 8),
                _buildFilterChip('file', 'Files'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('training-domain-$activeDomain-${domains.length}'),
            initialValue: activeDomain,
            decoration: InputDecoration(
              labelText: 'Domain',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: domains
                .map(
                  (domain) => DropdownMenuItem<String>(
                    value: domain,
                    child: Text(domain),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                hasFilters
                    ? 'No resources match your current filters'
                    : 'No training resources found',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();
    final domains = _availableDomains(provider.trainings);
    final activeDomain = domains.contains(_selectedDomain)
        ? _selectedDomain
        : 'All';
    final items = _filteredItems(provider.trainings, activeDomain);
    final featuredItems = items.where((item) => item.isFeatured).toList();
    final hasFilters =
        _selectedFilter != 'all' ||
        activeDomain != 'All' ||
        _searchText.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        actions: [
          IconButton(
            tooltip: 'Saved resources',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedTrainingsScreen()),
              );
            },
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: provider.isLoading && provider.trainings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && provider.trainings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchSection()),
                  if (provider.isSavedLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _buildFeaturedSection(provider, featuredItems),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFiltersSection(domains, activeDomain),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Text(
                        '${items.length} resource${items.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    _buildEmptyState(hasFilters)
                  else
                    SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final training = items[index];
                        return TrainingResourceCard(
                          training: training,
                          isSaved: provider.isTrainingSaved(training.id),
                          isSaveBusy: provider.isTrainingBusy(training.id),
                          onOpen: () => _openLink(training.displayLink),
                          onToggleSaved: () => _toggleSaved(training),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
    );
  }
}
