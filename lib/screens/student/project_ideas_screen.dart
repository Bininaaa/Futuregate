import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../services/project_idea_service.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/ideas/idea_cards.dart';
import '../../widgets/ideas/idea_metrics_row.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';
import '../../widgets/ideas/my_ideas_toggle.dart';
import '../../widgets/profile_avatar.dart';
import 'create_idea_screen.dart';
import 'idea_details_screen.dart';
import 'profile_screen.dart';

class ProjectIdeasScreen extends StatefulWidget {
  const ProjectIdeasScreen({super.key});

  @override
  State<ProjectIdeasScreen> createState() => _ProjectIdeasScreenState();
}

class _ProjectIdeasScreenState extends State<ProjectIdeasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  IdeasHubSegment _segment = IdeasHubSegment.discover;
  String _loadedUserId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUid = context.read<AuthProvider>().userModel?.uid ?? '';
    final provider = context.read<ProjectIdeaProvider>();
    if (currentUid.isNotEmpty && currentUid != _loadedUserId) {
      _loadedUserId = currentUid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        provider.fetchIdeas(currentUid);
      });
    } else if (currentUid.isEmpty &&
        _loadedUserId.isEmpty &&
        provider.approvedIdeas.isEmpty &&
        !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        provider.fetchApprovedIdeas();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().userModel;
    final provider = context.watch<ProjectIdeaProvider>();
    final discoverIdeas = _filterIdeas(provider.approvedIdeas);
    final myIdeas = _filterIdeas(provider.myIdeas);
    final categories = _buildCategoryList(provider);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildFab(),
        body: SafeArea(
          child: provider.isLoading && discoverIdeas.isEmpty && myIdeas.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: InnovationHubPalette.primary,
                  onRefresh: () => context
                      .read<ProjectIdeaProvider>()
                      .fetchIdeas(auth?.uid ?? _loadedUserId),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: _buildHeader(auth),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                          child: _buildHero(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: MyIdeasToggle(
                            selected: _segment,
                            onChanged: (value) {
                              setState(() => _segment = value);
                            },
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: _buildSearchBar(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _buildCategoryChips(provider, categories),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            child: _segment == IdeasHubSegment.discover
                                ? _DiscoverIdeasSection(
                                    key: const ValueKey<String>('discover'),
                                    ideas: discoverIdeas,
                                    onIdeaTap: _openIdeaDetails,
                                    onCreateTap: _openCreateIdea,
                                    trailingActionBuilder: auth == null
                                        ? null
                                        : (idea) => _IdeaSaveButton(
                                            isSaved: idea.isSavedByCurrentUser,
                                            isBusy: provider.isInteractionBusy(
                                              idea.id,
                                              ProjectIdeaInteractionType.save,
                                            ),
                                            onTap: () => _toggleSaveIdea(idea),
                                          ),
                                  )
                                : _MyIdeasSection(
                                    key: const ValueKey<String>('mine'),
                                    ideas: myIdeas,
                                    totalSparks: provider.totalMyIdeaSparks,
                                    totalInterested:
                                        provider.totalMyIdeaInterested,
                                    onCreateTap: _openCreateIdea,
                                    onIdeaTap: _openIdeaDetails,
                                    onEditTap: _openEditIdea,
                                    onManageTeamTap: _showManageTeamSheet,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? auth) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: ProfileAvatar(user: auth, radius: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Innovation Hub',
            style: InnovationHubTypography.section(
              size: 20,
              color: InnovationHubPalette.primary,
            ),
          ),
        ),
        _HeaderActionButton(
          icon: Icons.search_rounded,
          onTap: () => _searchFocusNode.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildHero() {
    final isDiscover = _segment == IdeasHubSegment.discover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDiscover ? 'Discover Ideas' : 'Build Your Ideas',
          style: InnovationHubTypography.title(size: 33),
        ),
        const SizedBox(height: 10),
        Text(
          isDiscover
              ? 'Explore the next generation of student-led breakthroughs.'
              : 'Track the concepts you are shaping and the collaborators they attract.',
          style: InnovationHubTypography.body(size: 15),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: InnovationHubPalette.searchTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) => setState(() {}),
        style: InnovationHubTypography.body(
          color: InnovationHubPalette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search innovation...',
          hintStyle: InnovationHubTypography.body(
            color: InnovationHubPalette.textSecondary.withValues(alpha: 0.82),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: InnovationHubPalette.primary,
          ),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
    ProjectIdeaProvider provider,
    List<String> categories,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(category),
                  selected: provider.filterDomain == category,
                  onSelected: (_) {
                    provider.setFilterDomain(
                      provider.filterDomain == category ? null : category,
                    );
                  },
                  showCheckmark: false,
                  selectedColor: InnovationHubPalette.primary,
                  backgroundColor: InnovationHubPalette.chipTint,
                  side: BorderSide(
                    color: provider.filterDomain == category
                        ? Colors.transparent
                        : InnovationHubPalette.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelStyle: InnovationHubTypography.label(
                    color: provider.filterDomain == category
                        ? Colors.white
                        : InnovationHubPalette.textPrimary,
                    size: 12.5,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: InnovationHubPalette.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: InnovationHubPalette.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openCreateIdea,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  List<String> _buildCategoryList(ProjectIdeaProvider provider) {
    final categories = <String>[
      ...innovationHubDefaultCategories,
      ...provider.availableDomains.where(
        (category) => !innovationHubDefaultCategories.contains(category),
      ),
    ];
    return categories;
  }

  List<ProjectIdeaModel> _filterIdeas(List<ProjectIdeaModel> source) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }

    return source
        .where((idea) {
          final haystack = <String>[
            idea.title,
            idea.tagline,
            idea.description,
            idea.displayCategory,
            idea.displayStage,
            idea.problemStatement,
            idea.solution,
            idea.targetAudience,
            idea.resourcesNeeded,
            ...idea.tags,
            ...idea.displaySkills,
            ...idea.displayTeamNeeded,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openCreateIdea() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateIdeaScreen()),
    );
    if (result == true && mounted) {
      final uid = context.read<AuthProvider>().userModel?.uid ?? _loadedUserId;
      context.read<ProjectIdeaProvider>().fetchIdeas(uid);
    }
  }

  Future<void> _openEditIdea(ProjectIdeaModel idea) async {
    if (idea.status.toLowerCase() != 'pending') {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateIdeaScreen(idea: idea, isEditMode: true),
      ),
    );
    if (result == true && mounted) {
      final uid = context.read<AuthProvider>().userModel?.uid ?? _loadedUserId;
      context.read<ProjectIdeaProvider>().fetchIdeas(uid);
    }
  }

  void _openIdeaDetails(ProjectIdeaModel idea) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IdeaDetailsScreen(ideaId: idea.id, initialIdea: idea),
      ),
    );
  }

  Future<void> _toggleSaveIdea(ProjectIdeaModel idea) async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) {
      return;
    }

    final error = await context.read<ProjectIdeaProvider>().toggleSave(
      idea,
      auth.uid,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showManageTeamSheet(ProjectIdeaModel idea) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: InnovationHubPalette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: InnovationHubPalette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(idea.title, style: InnovationHubTypography.section(size: 20)),
            const SizedBox(height: 8),
            IdeaMetricsRow(
              sparksCount: idea.sparksCount,
              interestedCount: idea.interestedCount,
            ),
            if (idea.displayTeamNeeded.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Open Roles',
                style: InnovationHubTypography.label(
                  color: InnovationHubPalette.textSecondary,
                  size: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: idea.displayTeamNeeded
                    .map((role) => _SheetChip(label: role))
                    .toList(),
              ),
            ],
            if (idea.displaySkills.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Skills',
                style: InnovationHubTypography.label(
                  color: InnovationHubPalette.textSecondary,
                  size: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: idea.displaySkills
                    .map((skill) => _SheetChip(label: skill))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiscoverIdeasSection extends StatelessWidget {
  final List<ProjectIdeaModel> ideas;
  final ValueChanged<ProjectIdeaModel> onIdeaTap;
  final VoidCallback onCreateTap;
  final Widget Function(ProjectIdeaModel idea)? trailingActionBuilder;

  const _DiscoverIdeasSection({
    super.key,
    required this.ideas,
    required this.onIdeaTap,
    required this.onCreateTap,
    this.trailingActionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) {
      return _PremiumEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No ideas match your search',
        subtitle:
            'Try a different keyword or create a new concept to kick the hub forward.',
        ctaLabel: 'Create an idea',
        onTap: onCreateTap,
      );
    }

    final featuredIdea = ideas.length > 2 ? ideas[2] : ideas.first;
    final cards = ideas.where((idea) => idea.id != featuredIdea.id).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = (constraints.maxWidth - 12) / 2;
        final widgets = <Widget>[];

        for (var i = 0; i < cards.length; i++) {
          if (i == 2) {
            widgets.add(
              SizedBox(
                width: constraints.maxWidth,
                child: FeaturedIdeaCard(
                  idea: featuredIdea,
                  onTap: () => onIdeaTap(featuredIdea),
                  trailingAction: trailingActionBuilder?.call(featuredIdea),
                ),
              ),
            );
          }

          widgets.add(
            SizedBox(
              width: compactWidth,
              child: IdeaCard(
                idea: cards[i],
                onTap: () => onIdeaTap(cards[i]),
                trailingAction: trailingActionBuilder?.call(cards[i]),
              ),
            ),
          );
        }

        if (cards.length <= 2) {
          widgets.insert(
            widgets.length,
            SizedBox(
              width: constraints.maxWidth,
              child: FeaturedIdeaCard(
                idea: featuredIdea,
                onTap: () => onIdeaTap(featuredIdea),
                trailingAction: trailingActionBuilder?.call(featuredIdea),
              ),
            ),
          );
        }

        return Wrap(spacing: 12, runSpacing: 12, children: widgets);
      },
    );
  }
}

class _IdeaSaveButton extends StatelessWidget {
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;

  const _IdeaSaveButton({
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isSaved
                ? InnovationHubPalette.primary.withValues(alpha: 0.12)
                : InnovationHubPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSaved
                  ? InnovationHubPalette.primary.withValues(alpha: 0.18)
                  : InnovationHubPalette.border,
            ),
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 18,
                    color: isSaved
                        ? InnovationHubPalette.primary
                        : InnovationHubPalette.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _MyIdeasSection extends StatelessWidget {
  final List<ProjectIdeaModel> ideas;
  final int totalSparks;
  final int totalInterested;
  final VoidCallback onCreateTap;
  final ValueChanged<ProjectIdeaModel> onIdeaTap;
  final ValueChanged<ProjectIdeaModel> onEditTap;
  final ValueChanged<ProjectIdeaModel> onManageTeamTap;

  const _MyIdeasSection({
    super.key,
    required this.ideas,
    required this.totalSparks,
    required this.totalInterested,
    required this.onCreateTap,
    required this.onIdeaTap,
    required this.onEditTap,
    required this.onManageTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) {
      return _PremiumEmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Your idea board is still empty',
        subtitle:
            'Start your first concept and turn it into something teammates can rally around.',
        ctaLabel: 'Create your first idea',
        onTap: onCreateTap,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Total Ideas', value: '${ideas.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(label: 'Total Sparks', value: '$totalSparks'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Active Collaborators',
                value: '$totalInterested',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ideas.map(
          (idea) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IdeaWorkspaceCard(
              idea: idea,
              onView: () => onIdeaTap(idea),
              onEdit: idea.status.toLowerCase() == 'pending'
                  ? () => onEditTap(idea)
                  : null,
              onManageTeam: () => onManageTeamTap(idea),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _PremiumEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.05),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: InnovationHubPalette.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: InnovationHubTypography.section(size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: InnovationHubTypography.body(size: 14),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: InnovationHubPalette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text(
              ctaLabel,
              style: InnovationHubTypography.label(
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: InnovationHubPalette.textPrimary),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: InnovationHubTypography.section(size: 20)),
          const SizedBox(height: 6),
          Text(label, style: InnovationHubTypography.body(size: 12.5)),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;

  const _SheetChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: InnovationHubPalette.cardTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(
          color: InnovationHubPalette.textPrimary,
          size: 11.5,
        ),
      ),
    );
  }
}
