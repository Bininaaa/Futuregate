import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
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
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import 'create_idea_screen.dart';
import 'idea_details_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

enum _IdeaFilter { all, approved, pending, rejected, interested }

class ProjectIdeasScreen extends StatefulWidget {
  final bool embedded;

  const ProjectIdeasScreen({super.key, this.embedded = false});

  @override
  State<ProjectIdeasScreen> createState() => _ProjectIdeasScreenState();
}

class _ProjectIdeasScreenState extends State<ProjectIdeasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  IdeasHubSegment _segment = IdeasHubSegment.discover;
  _IdeaFilter _filter = _IdeaFilter.all;
  String _loadedUserId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUid = context.read<AuthProvider>().userModel?.uid ?? '';
    final provider = context.read<ProjectIdeaProvider>();
    if (currentUid.isNotEmpty && currentUid != _loadedUserId) {
      _loadedUserId = currentUid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        provider.fetchIdeas(currentUid);
      });
    } else if (currentUid.isEmpty &&
        _loadedUserId.isEmpty &&
        provider.approvedIdeas.isEmpty &&
        !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
    final discoverIdeas = _applyFilters(
      _searchIdeas(provider.approvedIdeas),
      isDiscover: true,
    );
    final myIdeas = _applyFilters(
      _searchIdeas(provider.myIdeas),
      isDiscover: false,
    );
    final categories = _buildCategoryList(provider);

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFab(),
      body: SafeArea(
        top: !widget.embedded,
        child: provider.isLoading && discoverIdeas.isEmpty && myIdeas.isEmpty
            ? const AppLoadingView(density: AppLoadingDensity.compact)
            : RefreshIndicator(
                color: InnovationHubPalette.primary,
                onRefresh: () => context.read<ProjectIdeaProvider>().fetchIdeas(
                  auth?.uid ?? _loadedUserId,
                ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    if (!widget.embedded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: _buildHeader(auth),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          widget.embedded ? 18 : 14,
                          20,
                          0,
                        ),
                        child: MyIdeasToggle(
                          selected: _segment,
                          onChanged: (value) {
                            setState(() {
                              _segment = value;
                              _filter = _IdeaFilter.all;
                            });
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _buildSearchBar(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: _buildCategoryChips(provider, categories),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _buildFilterChips(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
    );

    if (widget.embedded) {
      return scaffold;
    }

    return AppShellBackground(child: scaffold);
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
          icon: Icons.bookmark_outline_rounded,
          onTap: _openSavedIdeas,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: InnovationHubPalette.searchTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) => setState(() {}),
        style: InnovationHubTypography.body(
          color: InnovationHubPalette.textPrimary,
          size: 13.5,
        ),
        decoration: InputDecoration(
          hintText: 'Search ideas...',
          hintStyle: InnovationHubTypography.body(
            color: InnovationHubPalette.textSecondary.withValues(alpha: 0.82),
            size: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: InnovationHubPalette.primary,
            size: 20,
          ),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
    ProjectIdeaProvider provider,
    List<String> categories,
  ) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final category = categories[index];
          final selected = provider.filterDomain == category;
          return FilterChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              provider.setFilterDomain(selected ? null : category);
            },
            showCheckmark: false,
            selectedColor: InnovationHubPalette.primary,
            backgroundColor: InnovationHubPalette.chipTint,
            side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : InnovationHubPalette.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelStyle: InnovationHubTypography.label(
              color: selected ? Colors.white : InnovationHubPalette.textPrimary,
              size: 11.5,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final auth = context.read<AuthProvider>().userModel;
    final filters = _segment == IdeasHubSegment.discover
        ? <_IdeaFilter, String>{
            _IdeaFilter.all: 'All',
            if (auth != null) _IdeaFilter.interested: 'Interested',
          }
        : <_IdeaFilter, String>{
            _IdeaFilter.all: 'All',
            _IdeaFilter.approved: 'Approved',
            _IdeaFilter.pending: 'Pending',
            _IdeaFilter.rejected: 'Rejected',
          };

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final entry = filters.entries.elementAt(index);
          final selected = _filter == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _filter = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? InnovationHubPalette.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? InnovationHubPalette.primary.withValues(alpha: 0.3)
                      : InnovationHubPalette.border,
                ),
              ),
              child: Text(
                entry.value,
                style: InnovationHubTypography.label(
                  color: selected
                      ? InnovationHubPalette.primary
                      : InnovationHubPalette.textSecondary,
                  size: 11.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: InnovationHubPalette.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: InnovationHubPalette.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openCreateIdea,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  List<String> _buildCategoryList(ProjectIdeaProvider provider) {
    return <String>[
      ...innovationHubDefaultCategories,
      ...provider.availableDomains.where(
        (category) => !innovationHubDefaultCategories.contains(category),
      ),
    ];
  }

  List<ProjectIdeaModel> _searchIdeas(List<ProjectIdeaModel> source) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return source;

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

  List<ProjectIdeaModel> _applyFilters(
    List<ProjectIdeaModel> source, {
    required bool isDiscover,
  }) {
    if (_filter == _IdeaFilter.all) return source;

    if (isDiscover) {
      if (_filter == _IdeaFilter.interested) {
        return source
            .where((i) => i.isJoinedByCurrentUser)
            .toList(growable: false);
      }
      return source;
    }

    switch (_filter) {
      case _IdeaFilter.approved:
        return source
            .where((i) => i.status.toLowerCase() == 'approved')
            .toList(growable: false);
      case _IdeaFilter.pending:
        return source
            .where((i) => i.status.toLowerCase() == 'pending')
            .toList(growable: false);
      case _IdeaFilter.rejected:
        return source
            .where((i) => i.status.toLowerCase() == 'rejected')
            .toList(growable: false);
      case _IdeaFilter.interested:
        return source;
      case _IdeaFilter.all:
        return source;
    }
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
    if (idea.status.toLowerCase() != 'pending') return;

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
        builder: (_) => IdeaDetailsScreen(
          ideaId: idea.id,
          initialIdea: idea,
          showModerationStatus: _segment == IdeasHubSegment.mine,
        ),
      ),
    );
  }

  Future<void> _toggleSaveIdea(ProjectIdeaModel idea) async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) return;

    final error = await context.read<ProjectIdeaProvider>().toggleSave(
      idea,
      auth.uid,
    );

    if (error != null && mounted) {
      context.showAppSnackBar(
        error,
        title: AppLocalizations.of(context)!.uiUpdateUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _openSavedIdeas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SavedScreen(initialFilter: SavedScreenFilter.ideas),
      ),
    );
  }

  void _showManageTeamSheet(ProjectIdeaModel idea) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: BoxDecoration(
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
            Text(idea.title, style: InnovationHubTypography.section(size: 18)),
            const SizedBox(height: 8),
            IdeaMetricsRow(interestedCount: idea.interestedCount),
            if (idea.displayTeamNeeded.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Open Roles',
                style: InnovationHubTypography.label(
                  color: InnovationHubPalette.textSecondary,
                  size: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
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
                  size: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
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
      return _EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: AppLocalizations.of(context)!.uiNoIdeasMatchView,
        subtitle: AppLocalizations.of(context)!.uiTryDifferentFilter,
        ctaLabel: 'Create an idea',
        onTap: onCreateTap,
      );
    }

    return Column(
      children: ideas
          .map(
            (idea) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IdeaListCard(
                idea: idea,
                onTap: () => onIdeaTap(idea),
                showStatus: false,
                trailingAction: trailingActionBuilder?.call(idea),
              ),
            ),
          )
          .toList(),
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
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: isSaved
                      ? InnovationHubPalette.primary
                      : InnovationHubPalette.textSecondary,
                ),
        ),
      ),
    );
  }
}

class _MyIdeasSection extends StatelessWidget {
  final List<ProjectIdeaModel> ideas;
  final int totalInterested;
  final VoidCallback onCreateTap;
  final ValueChanged<ProjectIdeaModel> onIdeaTap;
  final ValueChanged<ProjectIdeaModel> onEditTap;
  final ValueChanged<ProjectIdeaModel> onManageTeamTap;

  const _MyIdeasSection({
    super.key,
    required this.ideas,
    required this.totalInterested,
    required this.onCreateTap,
    required this.onIdeaTap,
    required this.onEditTap,
    required this.onManageTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) {
      return _EmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: AppLocalizations.of(context)!.uiNoIdeasYet,
        subtitle: AppLocalizations.of(context)!.uiCreateFirstIdea,
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
              child: _StatCard(label: AppLocalizations.of(context)!.uiIdeas, value: '${ideas.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(label: AppLocalizations.of(context)!.uiInterested, value: '$totalInterested'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...ideas.map(
          (idea) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _EmptyState({
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: InnovationHubPalette.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: InnovationHubTypography.section(size: 17),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: InnovationHubTypography.body(size: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: InnovationHubPalette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(
              ctaLabel,
              style: InnovationHubTypography.label(
                color: Colors.white,
                size: 12.5,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: InnovationHubPalette.textPrimary, size: 20),
        visualDensity: VisualDensity.compact,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: InnovationHubTypography.section(size: 20)),
          const SizedBox(height: 4),
          Text(label, style: InnovationHubTypography.body(size: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: InnovationHubPalette.cardTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(
          color: InnovationHubPalette.textPrimary,
          size: 11,
        ),
      ),
    );
  }
}
