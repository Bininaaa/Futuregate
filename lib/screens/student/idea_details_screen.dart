import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/project_idea_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../services/project_idea_service.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/ideas/idea_metrics_row.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../chat/user_profile_preview_screen.dart';
import 'edit_project_idea_screen.dart';

class IdeaDetailsScreen extends StatelessWidget {
  final String ideaId;
  final ProjectIdeaModel? initialIdea;

  const IdeaDetailsScreen({super.key, required this.ideaId, this.initialIdea});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();
    final auth = context.watch<AuthProvider>().userModel;
    final idea = provider.findIdeaById(ideaId) ?? initialIdea;
    final isOwner = auth?.uid == idea?.submittedBy;

    if (idea == null) {
      return AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: Text(
              'This idea is no longer available.',
              style: InnovationHubTypography.body(
                color: InnovationHubPalette.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: InnovationHubPalette.textPrimary,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Innovation Hub',
            style: InnovationHubTypography.section(size: 18),
          ),
          actions: [
            IconButton(
              tooltip: idea.isSavedByCurrentUser ? 'Unsave idea' : 'Save idea',
              onPressed: auth == null
                  ? null
                  : () => _toggleInteraction(
                      context,
                      idea,
                      ProjectIdeaInteractionType.save,
                    ),
              icon: Icon(
                idea.isSavedByCurrentUser
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Share idea',
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      '${idea.title}\n\n${idea.overviewText}\n\nShared from Innovation Hub',
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _DetailsBottomActions(
            idea: idea,
            isOwner: isOwner,
            onPrimaryTap: () {
              if (isOwner) {
                _openEdit(context, idea);
                return;
              }
              _toggleInteraction(
                context,
                idea,
                ProjectIdeaInteractionType.interest,
              );
            },
            onSecondaryTap: () {
              if (isOwner) {
                _showManageTeamSheet(context, idea);
                return;
              }
              _openCreatorProfile(context, idea);
            },
            onTertiaryTap: () {
              if (isOwner) {
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${idea.title}\n\n${idea.overviewText}\n\nShared from Innovation Hub',
                  ),
                );
                return;
              }
              _toggleInteraction(
                context,
                idea,
                ProjectIdeaInteractionType.save,
              );
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildHeroCard(context, idea),
            const SizedBox(height: 14),
            if (idea.overviewText.trim().isNotEmpty)
              _IdeaSectionCard(
                title: 'Idea Overview',
                icon: Icons.auto_awesome_rounded,
                child: Text(
                  idea.overviewText,
                  style: InnovationHubTypography.body(
                    color: InnovationHubPalette.textPrimary,
                  ),
                ),
              ),
            if (idea.problemText.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdeaSectionCard(
                title: 'What problem it solves',
                icon: Icons.help_outline_rounded,
                child: Text(
                  idea.problemText,
                  style: InnovationHubTypography.body(
                    color: InnovationHubPalette.textPrimary,
                  ),
                ),
              ),
            ],
            if (idea.solutionText.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdeaSectionCard(
                title: 'Proposed solution',
                icon: Icons.rocket_launch_outlined,
                child: Text(
                  idea.solutionText,
                  style: InnovationHubTypography.body(
                    color: InnovationHubPalette.textPrimary,
                  ),
                ),
              ),
            ],
            if (idea.targetAudience.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdeaSectionCard(
                title: 'Target Users',
                icon: Icons.groups_2_outlined,
                child: Text(
                  idea.targetAudience,
                  style: InnovationHubTypography.body(
                    color: InnovationHubPalette.textPrimary,
                  ),
                ),
              ),
            ],
            if (idea.displayTeamNeeded.isNotEmpty ||
                idea.displaySkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdeaSectionCard(
                title: 'Team / Roles Needed',
                icon: Icons.diversity_3_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (idea.displayTeamNeeded.isNotEmpty)
                      _TagWrap(label: 'Roles', values: idea.displayTeamNeeded),
                    if (idea.displayTeamNeeded.isNotEmpty &&
                        idea.displaySkills.isNotEmpty)
                      const SizedBox(height: 14),
                    if (idea.displaySkills.isNotEmpty)
                      _TagWrap(label: 'Skills', values: idea.displaySkills),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _IdeaSectionCard(
              title: 'Progress / Stage',
              icon: Icons.timeline_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniInfoBadge(
                        label: idea.displayStage,
                        color: innovationStageColor(idea.displayStage),
                      ),
                      _MiniInfoBadge(
                        label: idea.statusLabel,
                        color: innovationStatusColor(idea.status),
                      ),
                      if (idea.level.trim().isNotEmpty)
                        _MiniInfoBadge(
                          label: academicLevelLabel(idea.level),
                          color: InnovationHubPalette.secondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    idea.lastUpdatedLabel,
                    style: InnovationHubTypography.body(size: 13),
                  ),
                ],
              ),
            ),
            if (idea.resourcesNeeded.trim().isNotEmpty ||
                idea.attachmentUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdeaSectionCard(
                title: 'Resources / Needs',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (idea.resourcesNeeded.trim().isNotEmpty)
                      Text(
                        idea.resourcesNeeded,
                        style: InnovationHubTypography.body(
                          color: InnovationHubPalette.textPrimary,
                        ),
                      ),
                    if (idea.attachmentUrl.trim().isNotEmpty) ...[
                      if (idea.resourcesNeeded.trim().isNotEmpty)
                        const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openExternalLink(context, idea.attachmentUrl),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InnovationHubPalette.primary,
                          side: const BorderSide(
                            color: InnovationHubPalette.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open Attachment'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (idea.impactText.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdeaSectionCard(
                title: 'Benefits / Impact',
                icon: Icons.volunteer_activism_outlined,
                child: Text(
                  idea.impactText,
                  style: InnovationHubTypography.body(
                    color: InnovationHubPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ProjectIdeaModel idea) {
    final categoryColor = innovationCategoryColor(idea.displayCategory);
    final provider = context.watch<ProjectIdeaProvider>();
    final auth = context.watch<AuthProvider>().userModel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                ),
              ),
              const Spacer(),
              _MiniInfoBadge(
                label: idea.displayStage,
                color: innovationStageColor(idea.displayStage),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(idea.title, style: InnovationHubTypography.title(size: 26)),
          if (idea.tagline.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(idea.tagline, style: InnovationHubTypography.body(size: 14)),
          ],
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _openCreatorProfile(context, idea),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ProfileAvatar(
                    userId: idea.submittedBy,
                    photoType: idea.authorPhotoType,
                    avatarId: idea.authorAvatarId,
                    photoUrl: idea.authorAvatarUrl,
                    fallbackName: idea.creatorName,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.creatorName,
                          style: InnovationHubTypography.label(
                            color: InnovationHubPalette.textPrimary,
                            size: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          idea.creatorHeadline,
                          style: InnovationHubTypography.body(size: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: InnovationHubPalette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfoBadge(label: idea.displayCategory, color: categoryColor),
              if (idea.isPublic)
                const _MiniInfoBadge(
                  label: 'Public',
                  color: InnovationHubPalette.secondary,
                ),
            ],
          ),
          if (idea.imageUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                idea.imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 170,
                  color: InnovationHubPalette.cardTint,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: InnovationHubPalette.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          IdeaMetricsRow(interestedCount: idea.interestedCount),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auth == null ||
                      provider.isInteractionBusy(
                        idea.id,
                        ProjectIdeaInteractionType.interest,
                      )
                  ? null
                  : () => _toggleInteraction(
                      context,
                      idea,
                      ProjectIdeaInteractionType.interest,
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: idea.isJoinedByCurrentUser
                    ? InnovationHubPalette.primary
                    : InnovationHubPalette.textPrimary,
                side: BorderSide(
                  color: idea.isJoinedByCurrentUser
                      ? InnovationHubPalette.primary.withValues(alpha: 0.25)
                      : InnovationHubPalette.border,
                ),
                backgroundColor: idea.isJoinedByCurrentUser
                    ? InnovationHubPalette.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                idea.isJoinedByCurrentUser
                    ? Icons.check_circle_rounded
                    : Icons.people_outline_rounded,
                size: 20,
              ),
              label: Text(
                idea.isJoinedByCurrentUser ? 'Interested' : "I'm Interested",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleInteraction(
    BuildContext context,
    ProjectIdeaModel idea,
    ProjectIdeaInteractionType type,
  ) async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) {
      return;
    }

    final provider = context.read<ProjectIdeaProvider>();
    String? error;
    switch (type) {
      case ProjectIdeaInteractionType.spark:
        error = await provider.toggleSpark(idea, auth.uid);
        break;
      case ProjectIdeaInteractionType.interest:
        error = await provider.toggleInterest(idea, auth.uid);
        break;
      case ProjectIdeaInteractionType.save:
        error = await provider.toggleSave(idea, auth.uid);
        break;
    }

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _openCreatorProfile(BuildContext context, ProjectIdeaModel idea) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePreviewScreen(
          userId: idea.submittedBy,
          fallbackName: idea.creatorName,
          fallbackRole: 'student',
          fallbackHeadline: idea.creatorHeadline,
          fallbackAbout: idea.overviewText,
          contextLabel: idea.title,
        ),
      ),
    );
  }

  Future<void> _openExternalLink(BuildContext context, String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  void _openEdit(BuildContext context, ProjectIdeaModel idea) {
    if (idea.status.toLowerCase() != 'pending') {
      _showManageTeamSheet(context, idea);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProjectIdeaScreen(idea: idea)),
    );
  }

  void _showManageTeamSheet(BuildContext context, ProjectIdeaModel idea) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: InnovationHubPalette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 18),
              Text(
                'Manage Team',
                style: InnovationHubTypography.section(size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Track the roles you need and the interest building around this idea.',
                style: InnovationHubTypography.body(size: 13.5),
              ),
              const SizedBox(height: 18),
              _IdeaSectionCard(
                title: 'Interest Snapshot',
                icon: Icons.groups_rounded,
                child: IdeaMetricsRow(
                  interestedCount: idea.interestedCount,
                ),
              ),
              if (idea.displayTeamNeeded.isNotEmpty) ...[
                const SizedBox(height: 14),
                _IdeaSectionCard(
                  title: 'Open Roles',
                  icon: Icons.badge_outlined,
                  child: _TagWrap(
                    label: 'Roles',
                    values: idea.displayTeamNeeded,
                  ),
                ),
              ],
              if (idea.displaySkills.isNotEmpty) ...[
                const SizedBox(height: 14),
                _IdeaSectionCard(
                  title: 'Key Skills',
                  icon: Icons.auto_fix_high_outlined,
                  child: _TagWrap(label: 'Skills', values: idea.displaySkills),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsBottomActions extends StatelessWidget {
  final ProjectIdeaModel idea;
  final bool isOwner;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final VoidCallback onTertiaryTap;

  const _DetailsBottomActions({
    required this.idea,
    required this.isOwner,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.onTertiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.06),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: InnovationHubPalette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isOwner
                    ? (idea.status.toLowerCase() == 'pending'
                          ? 'Edit Idea'
                          : 'Manage This Idea')
                    : (idea.isJoinedByCurrentUser
                          ? 'Interested'
                          : "I'm Interested"),
                style: InnovationHubTypography.label(
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondaryTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: InnovationHubPalette.textPrimary,
                    side: const BorderSide(color: InnovationHubPalette.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isOwner ? 'Manage Team' : 'Contact Creator',
                    style: InnovationHubTypography.label(
                      color: InnovationHubPalette.textPrimary,
                      size: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onTertiaryTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: InnovationHubPalette.textPrimary,
                    side: const BorderSide(color: InnovationHubPalette.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isOwner
                        ? 'Share Idea'
                        : (idea.isSavedByCurrentUser ? 'Saved' : 'Save Idea'),
                    style: InnovationHubTypography.label(
                      color: InnovationHubPalette.textPrimary,
                      size: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdeaSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _IdeaSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: InnovationHubPalette.cardTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: InnovationHubPalette.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: InnovationHubTypography.section(size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  final String label;
  final List<String> values;

  const _TagWrap({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InnovationHubTypography.label(
            color: InnovationHubPalette.textSecondary,
            size: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: InnovationHubPalette.cardTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    value,
                    style: InnovationHubTypography.label(
                      color: InnovationHubPalette.textPrimary,
                      size: 11.5,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MiniInfoBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniInfoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: InnovationHubTypography.label(color: color, size: 11.5),
      ),
    );
  }
}
