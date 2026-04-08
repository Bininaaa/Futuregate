import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/saved_scholarship_model.dart';
import '../../models/scholarship_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_scholarship_provider.dart';
import '../../providers/scholarship_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_workspace_shell.dart';
import 'scholarship_detail_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Palette alias for brevity
// ──────────────────────────────────────────────────────────────────────────────
typedef _P = OpportunityDashboardPalette;

class ScholarshipsScreen extends StatefulWidget {
  final bool embedded;

  const ScholarshipsScreen({super.key, this.embedded = false});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _activeFilterIndex = 0;

  static const List<String> _filters = [
    'All Scholarships',
    'Fully Funded',
    'Europe',
    'Asia',
    'Masters',
    'PhD',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<ScholarshipProvider>();
      if (provider.scholarships.isEmpty) {
        provider.fetchScholarships();
      }
      final userId = context.read<AuthProvider>().userModel?.uid.trim();
      if (userId != null && userId.isNotEmpty) {
        context.read<SavedScholarshipProvider>().fetchSavedScholarships(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering logic ──────────────────────────────────────────────────────
  List<ScholarshipModel> _applyFilters(List<ScholarshipModel> items) {
    var filtered = List<ScholarshipModel>.from(items);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.provider.toLowerCase().contains(q) ||
            (s.country ?? '').toLowerCase().contains(q) ||
            (s.city ?? '').toLowerCase().contains(q) ||
            (s.location ?? '').toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q);
      }).toList();
    }

    final filter = _filters[_activeFilterIndex];
    switch (filter) {
      case 'Fully Funded':
        filtered = filtered
            .where((s) => (s.fundingType ?? '').toLowerCase().contains('full'))
            .toList();
        break;
      case 'Europe':
        filtered = filtered
            .where((s) => _isInRegion(s, _europeCountries))
            .toList();
        break;
      case 'Asia':
        filtered = filtered
            .where((s) => _isInRegion(s, _asiaCountries))
            .toList();
        break;
      case 'Masters':
        filtered = filtered
            .where(
              (s) =>
                  (s.level ?? '').toLowerCase().contains('master') ||
                  (s.category ?? '').toLowerCase().contains('master'),
            )
            .toList();
        break;
      case 'PhD':
        filtered = filtered
            .where(
              (s) =>
                  (s.level ?? '').toLowerCase().contains('phd') ||
                  (s.level ?? '').toLowerCase().contains('doctor') ||
                  (s.category ?? '').toLowerCase().contains('phd'),
            )
            .toList();
        break;
    }

    return filtered;
  }

  bool _isInRegion(ScholarshipModel s, Set<String> regionCountries) {
    final loc = '${s.country ?? ''} ${s.city ?? ''} ${s.location ?? ''}'
        .toLowerCase();
    return regionCountries.any((c) => loc.contains(c));
  }

  static const _europeCountries = {
    'germany',
    'france',
    'uk',
    'united kingdom',
    'britain',
    'netherlands',
    'sweden',
    'norway',
    'denmark',
    'finland',
    'italy',
    'spain',
    'austria',
    'switzerland',
    'belgium',
    'ireland',
    'poland',
    'czech',
    'portugal',
    'hungary',
    'romania',
    'greece',
    'europe',
  };

  static const _asiaCountries = {
    'japan',
    'china',
    'korea',
    'india',
    'singapore',
    'malaysia',
    'thailand',
    'indonesia',
    'vietnam',
    'philippines',
    'taiwan',
    'hong kong',
    'pakistan',
    'bangladesh',
    'sri lanka',
    'turkey',
    'asia',
  };

  // ── Pick featured scholarship from real data ─────────────────────────────
  ScholarshipModel? _pickFeatured(List<ScholarshipModel> all) {
    if (all.isEmpty) return null;
    final nonOxford = all.where((s) => !_isOxfordScholarship(s)).toList();
    final candidates = nonOxford.isNotEmpty ? nonOxford : all;

    for (final s in candidates) {
      if (s.imageUrl?.isNotEmpty ?? false) return s;
    }
    return candidates.first;
  }

  bool _isOxfordScholarship(ScholarshipModel scholarship) {
    final searchableText = [
      scholarship.title,
      scholarship.provider,
      scholarship.location,
      scholarship.city,
      scholarship.country,
    ].whereType<String>().join(' ').toLowerCase();

    return searchableText.contains('oxford');
  }

  Future<void> _toggleSavedScholarship(ScholarshipModel scholarship) async {
    final userId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    if (userId.isEmpty) {
      return;
    }

    final provider = context.read<SavedScholarshipProvider>();
    SavedScholarshipModel? existing;
    for (final item in provider.savedScholarships) {
      if (item.scholarshipId == scholarship.id) {
        existing = item;
        break;
      }
    }

    final locationParts = <String>[
      scholarship.city?.trim() ?? '',
      scholarship.country?.trim() ?? '',
      scholarship.location?.trim() ?? '',
    ].where((value) => value.isNotEmpty).toList(growable: false);

    final error = existing != null
        ? await provider.unsaveScholarship(existing.id, userId)
        : await provider.saveScholarship(
            studentId: userId,
            scholarshipId: scholarship.id,
            title: scholarship.title,
            provider: scholarship.provider,
            deadline: scholarship.deadline,
            location: locationParts.isEmpty
                ? 'Location not specified'
                : locationParts.join(', '),
            fundingType: scholarship.fundingType?.trim() ?? '',
            level: scholarship.level?.trim() ?? '',
          );

    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      error ??
          (existing != null
              ? 'This scholarship was removed from your saved list.'
              : 'This scholarship has been saved.'),
      title: error == null ? 'Saved items updated' : 'Update unavailable',
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScholarshipProvider>();
    final savedProvider = context.watch<SavedScholarshipProvider>();
    final savedIds = savedProvider.savedScholarships
        .map((item) => item.scholarshipId)
        .toSet();
    final filtered = _applyFilters(provider.scholarships);
    final featured = _pickFeatured(filtered);

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.embedded
          ? null
          : StudentWorkspaceAppBar(
              title: 'Scholarships',
              subtitle:
                  'Curated funding paths, deadlines, and global study options.',
              icon: Icons.school_rounded,
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: _P.primary))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeroSection()),
                  if (featured != null)
                    SliverToBoxAdapter(
                      child: _buildHeroVisualCard(
                        featured,
                        isSaved: savedIds.contains(featured.id),
                        isSaving: savedProvider.isLoading,
                        onToggleSaved: () => _toggleSavedScholarship(featured),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  SliverToBoxAdapter(child: _buildCurationHeader()),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ScholarshipCard(
                              scholarship: filtered[index],
                              cardIndex: index,
                              isSaved: savedIds.contains(filtered[index].id),
                              isBusy: savedProvider.isLoading,
                              onToggleSaved: () =>
                                  _toggleSavedScholarship(filtered[index]),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],
              ),
      ),
    );

    if (widget.embedded) {
      return scaffold;
    }

    return AppShellBackground(child: scaffold);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. TOP HEADER BAR
  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // 2. HERO SECTION (label + title + subtitle)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE NOW',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              color: _P.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Featured\nScholarship',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: _P.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A quick highlight picked from the scholarships '
            'currently available below.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: _P.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. HERO VISUAL CARD — uses real data only
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroVisualCard(
    ScholarshipModel featured, {
    required bool isSaved,
    required bool isSaving,
    required VoidCallback onToggleSaved,
  }) {
    final heroTitle = featured.title.isNotEmpty
        ? featured.title
        : featured.provider;
    final heroProvider = featured.provider;
    final heroLocation = _buildLocationText(featured);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => _openDetail(context, featured),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _P.primaryDark.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (featured.imageUrl != null && featured.imageUrl!.isNotEmpty)
                  Image.network(
                    featured.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => _buildHeroGradientFallback(),
                  )
                else
                  _buildHeroGradientFallback(),

                // Dark overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),

                // Featured badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: isSaving ? null : onToggleSaved,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Center(
                            child: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _P.secondary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'FEATURED',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom-left text
                Positioned(
                  left: 14,
                  bottom: 12,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (heroProvider.isNotEmpty) ...[
                        Text(
                          heroProvider,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        heroTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (heroLocation != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                heroLocation,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroGradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B22F6), Color(0xFF1E40AF), Color(0xFF14B8A6)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.school_rounded,
              size: 42,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
          style: GoogleFonts.poppins(fontSize: 12, color: _P.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search university or country...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: _P.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _P.textSecondary,
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isActive = index == _activeFilterIndex;
            return GestureDetector(
              onTap: () => setState(() => _activeFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _P.primary
                      : _P.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(15),
                  border: isActive
                      ? null
                      : Border.all(
                          color: _P.primary.withValues(alpha: 0.12),
                          width: 1,
                        ),
                ),
                child: Text(
                  _filters[index],
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : _P.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. CURATION SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCurationHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BROWSE',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: _P.secondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Available\nScholarships',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: _P.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.embedded)
            GestureDetector(
              onTap: _openScholarshipCatalog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all scholarships',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _P.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: _P.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _P.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 26,
              color: _P.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No scholarships match your search',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _P.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filters\nto explore more scholarships.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: _P.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  String? _buildLocationText(ScholarshipModel? s) {
    if (s == null) return null;
    final parts = <String>[];
    if (s.city != null && s.city!.isNotEmpty) parts.add(s.city!);
    if (s.country != null && s.country!.isNotEmpty) parts.add(s.country!);
    if (parts.isEmpty && s.location != null && s.location!.isNotEmpty) {
      return s.location!;
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  void _openDetail(BuildContext context, ScholarshipModel scholarship) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScholarshipDetailScreen(scholarship: scholarship),
      ),
    );
  }

  void _openScholarshipCatalog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScholarshipsScreen()),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCHOLARSHIP CARD WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ScholarshipCard extends StatelessWidget {
  final ScholarshipModel scholarship;
  final int cardIndex;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onToggleSaved;

  const _ScholarshipCard({
    required this.scholarship,
    required this.cardIndex,
    required this.isSaved,
    required this.isBusy,
    required this.onToggleSaved,
  });

  static const _gradients = [
    [Color(0xFF3B22F6), Color(0xFF1E40AF)],
    [Color(0xFF0F172A), Color(0xFF1E293B)],
    [Color(0xFF14B8A6), Color(0xFF0D9488)],
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
  ];

  @override
  Widget build(BuildContext context) {
    final hasImage =
        scholarship.imageUrl != null && scholarship.imageUrl!.isNotEmpty;
    final gradientColors = _gradients[cardIndex % _gradients.length];
    final locationText = _locationText();
    final fundingBadge = _fundingBadgeText();
    final tagText = _tagText();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScholarshipDetailScreen(scholarship: scholarship),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── A. Image / visual block ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 128,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        scholarship.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            _buildGradientBlock(gradientColors),
                      )
                    else
                      _buildGradientBlock(gradientColors),

                    // Subtle bottom fade
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── B. Status badge ──
                    if (fundingBadge != null)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeColor(fundingBadge),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            fundingBadge,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: GestureDetector(
                        onTap: isBusy ? null : onToggleSaved,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: isBusy
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _P.primary.withValues(alpha: 0.9),
                                    ),
                                  )
                                : Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    size: 18,
                                    color: isSaved
                                        ? _P.primary
                                        : _P.textPrimary,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Card body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── C. Location row ──
                  if (locationText != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: _P.textSecondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            locationText.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.7,
                              color: _P.textSecondary.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // ── D. Title ──
                  Text(
                    scholarship.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: _P.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ── E. Description ──
                  if (scholarship.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      scholarship.description,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                        color: _P.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // ── F. Tag pill ──
                  if (tagText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _P.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagText.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.45,
                          color: _P.secondary,
                        ),
                      ),
                    ),
                  ],

                  // ── G. Action button ──
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ScholarshipDetailScreen(scholarship: scholarship),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: _P.primary.withValues(alpha: 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Explore Scholarship',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _P.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBlock(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            bottom: -25,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -15,
            top: -15,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.school_rounded,
              size: 34,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  String? _locationText() {
    final parts = <String>[];
    if (scholarship.city != null && scholarship.city!.isNotEmpty) {
      parts.add(scholarship.city!);
    }
    if (scholarship.country != null && scholarship.country!.isNotEmpty) {
      parts.add(scholarship.country!);
    }
    if (parts.isEmpty &&
        scholarship.location != null &&
        scholarship.location!.isNotEmpty) {
      return scholarship.location!;
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? _fundingBadgeText() {
    final ft = scholarship.fundingType;
    if (ft == null || ft.isEmpty) return null;
    final lower = ft.toLowerCase();
    if (lower.contains('full')) return 'FULLY FUNDED';
    if (lower.contains('partial')) return 'PARTIALLY FUNDED';
    if (lower.contains('merit')) return 'MERIT-BASED';
    if (lower.contains('prestige')) return 'PRESTIGE';
    return ft.toUpperCase();
  }

  String? _tagText() {
    if (scholarship.level != null && scholarship.level!.isNotEmpty) {
      return scholarship.level;
    }
    if (scholarship.category != null && scholarship.category!.isNotEmpty) {
      return scholarship.category;
    }
    if (scholarship.tags.isNotEmpty) {
      return scholarship.tags.first;
    }
    return null;
  }

  Color _badgeColor(String badge) {
    final lower = badge.toLowerCase();
    if (lower.contains('full')) return _P.success.withValues(alpha: 0.85);
    if (lower.contains('partial')) return _P.warning.withValues(alpha: 0.85);
    if (lower.contains('merit')) return _P.accent.withValues(alpha: 0.85);
    if (lower.contains('prestige')) {
      return _P.primaryDark.withValues(alpha: 0.85);
    }
    return _P.primary.withValues(alpha: 0.85);
  }
}
