import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import '../chat/user_profile_preview_screen.dart';
import 'create_idea_screen.dart';

class IdeaDetailsScreen extends StatelessWidget {
  final String ideaId;
  final ProjectIdeaModel? initialIdea;
  final bool showModerationStatus;

  const IdeaDetailsScreen({
    super.key,
    required this.ideaId,
    this.initialIdea,
    this.showModerationStatus = false,
  });

  AppContentTheme get _theme => const AppContentTheme(
    accent: InnovationHubPalette.primary,
    accentDark: InnovationHubPalette.primaryDark,
    accentSoft: InnovationHubPalette.cardTint,
    secondary: InnovationHubPalette.secondary,
    background: InnovationHubPalette.background,
    surface: InnovationHubPalette.surface,
    surfaceMuted: InnovationHubPalette.cardTint,
    border: InnovationHubPalette.border,
    textPrimary: InnovationHubPalette.textPrimary,
    textSecondary: InnovationHubPalette.textSecondary,
    textMuted: InnovationHubPalette.textSecondary,
    success: InnovationHubPalette.success,
    warning: InnovationHubPalette.warning,
    error: InnovationHubPalette.error,
    heroGradient: InnovationHubPalette.primaryGradient,
    typography: AppContentTypography.innovation,
  );

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
              style: _theme.body(color: _theme.textPrimary),
            ),
          ),
        ),
      );
    }

    final categoryColor = innovationCategoryColor(idea.displayCategory);
    final stageColor = innovationStageColor(idea.displayStage);
    final statusColor = innovationStatusColor(idea.status);
    final hasAttachment = idea.attachmentUrl.trim().isNotEmpty;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: _theme.textPrimary,
          elevation: 0,
          title: Text(
            'Innovation Hub',
            style: _theme.section(size: 18, weight: FontWeight.w700),
          ),
          actions: <Widget>[
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
              onPressed: () => _shareIdea(idea),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _theme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _theme.border),
                boxShadow: _theme.shadow(0.04),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppPrimaryButton(
                    theme: _theme,
                    label: isOwner
                        ? (idea.status.toLowerCase() == 'pending'
                              ? 'Edit Idea'
                              : 'Manage This Idea')
                        : (idea.isJoinedByCurrentUser
                              ? 'Interested'
                              : "I'm Interested"),
                    icon: isOwner
                        ? Icons.edit_rounded
                        : idea.isJoinedByCurrentUser
                        ? Icons.check_circle_rounded
                        : Icons.people_outline_rounded,
                    onPressed: () {
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
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppSecondaryButton(
                          theme: _theme,
                          label: isOwner ? 'Manage Team' : 'Contact Creator',
                          icon: isOwner
                              ? Icons.groups_rounded
                              : Icons.person_outline_rounded,
                          onPressed: () {
                            if (isOwner) {
                              _showManageTeamSheet(context, idea);
                              return;
                            }
                            _openCreatorProfile(context, idea);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppSecondaryButton(
                          theme: _theme,
                          label: isOwner
                              ? 'Share Idea'
                              : (idea.isSavedByCurrentUser
                                    ? 'Saved'
                                    : 'Save Idea'),
                          icon: isOwner
                              ? Icons.ios_share_rounded
                              : idea.isSavedByCurrentUser
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          onPressed: () {
                            if (isOwner) {
                              _shareIdea(idea);
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
          children: <Widget>[
            AppDetailHeroCard(
              theme: _theme,
              icon: innovationCategoryIcon(idea.displayCategory),
              title: idea.title,
              subtitle: idea.tagline.trim().isNotEmpty
                  ? idea.tagline
                  : idea.creatorHeadline,
              summary: idea.overviewText,
              imageUrl: idea.imageUrl,
              leading: ProfileAvatar(
                userId: idea.submittedBy,
                photoType: idea.authorPhotoType,
                avatarId: idea.authorAvatarId,
                photoUrl: idea.authorAvatarUrl,
                fallbackName: idea.creatorName,
                radius: 24,
              ),
              badges: <AppBadgeData>[
                AppBadgeData(
                  label: idea.displayCategory,
                  icon: innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                ),
                AppBadgeData(
                  label: idea.displayStage,
                  icon: Icons.timeline_outlined,
                  color: stageColor,
                ),
                if (showModerationStatus)
                  AppBadgeData(
                    label: idea.statusLabel,
                    icon: Icons.flag_outlined,
                    color: statusColor,
                  ),
                if (idea.level.trim().isNotEmpty)
                  AppBadgeData(
                    label: academicLevelLabel(idea.level),
                    icon: Icons.school_outlined,
                    color: _theme.secondary,
                  ),
                AppBadgeData(
                  label: idea.isPublic ? 'Public' : 'Private',
                  icon: idea.isPublic
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                ),
              ],
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppMetaRow(
                    theme: _theme,
                    label: 'Creator',
                    value: idea.creatorName,
                    icon: Icons.person_outline_rounded,
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Last updated',
                    value: idea.lastUpdatedLabel,
                    icon: Icons.update_rounded,
                  ),
                  if (idea.createdAt != null)
                    AppMetaRow(
                      theme: _theme,
                      label: 'Posted',
                      value: DateFormat(
                        'MMM d, yyyy',
                      ).format(idea.createdAt!.toDate()),
                      icon: Icons.event_outlined,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppInfoTileGrid(
              theme: _theme,
              items: <AppInfoTileData>[
                AppInfoTileData(
                  label: 'Stage',
                  value: idea.displayStage,
                  icon: Icons.timeline_outlined,
                  color: stageColor,
                ),
                if (showModerationStatus)
                  AppInfoTileData(
                    label: 'Status',
                    value: idea.statusLabel,
                    icon: Icons.flag_outlined,
                    color: statusColor,
                  ),
                AppInfoTileData(
                  label: 'Category',
                  value: idea.displayCategory,
                  icon: innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                ),
                AppInfoTileData(
                  label: 'Level',
                  value: idea.level.trim().isNotEmpty
                      ? academicLevelLabel(idea.level)
                      : '',
                  icon: Icons.school_outlined,
                ),
                AppInfoTileData(
                  label: 'Sparks',
                  value: '${idea.sparksCount}',
                  icon: Icons.bolt_rounded,
                  emphasize: true,
                ),
                AppInfoTileData(
                  label: 'Interested',
                  value: '${idea.interestedCount}',
                  icon: Icons.groups_rounded,
                ),
                AppInfoTileData(
                  label: 'Views',
                  value: '${idea.viewsCount}',
                  icon: Icons.remove_red_eye_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Overview',
              icon: Icons.auto_awesome_rounded,
              child: Text(
                idea.overviewText,
                style: _theme.body(color: _theme.textPrimary),
              ),
            ),
            if (idea.description.trim().isNotEmpty &&
                idea.description.trim() !=
                    idea.overviewText.trim()) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Full Description',
                icon: Icons.description_outlined,
                child: Text(
                  idea.description,
                  style: _theme.body(color: _theme.textPrimary),
                ),
              ),
            ],
            if (idea.problemText.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Problem Statement',
                icon: Icons.help_outline_rounded,
                child: Text(
                  idea.problemText,
                  style: _theme.body(color: _theme.textPrimary),
                ),
              ),
            ],
            if (idea.solutionText.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Proposed Solution',
                icon: Icons.rocket_launch_outlined,
                child: Text(
                  idea.solutionText,
                  style: _theme.body(color: _theme.textPrimary),
                ),
              ),
            ],
            if (idea.targetAudience.trim().isNotEmpty ||
                idea.impactText.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Audience And Impact',
                icon: Icons.groups_2_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (idea.targetAudience.trim().isNotEmpty)
                      AppMetaRow(
                        theme: _theme,
                        label: 'Target audience',
                        value: idea.targetAudience,
                      ),
                    if (idea.impactText.trim().isNotEmpty)
                      AppMetaRow(
                        theme: _theme,
                        label: 'Benefits and impact',
                        value: idea.impactText,
                      ),
                  ],
                ),
              ),
            ],
            if (idea.displayTeamNeeded.isNotEmpty ||
                idea.displaySkills.isNotEmpty ||
                idea.tools.trim().isNotEmpty ||
                idea.resourcesNeeded.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Collaboration Needs',
                icon: Icons.diversity_3_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (idea.displayTeamNeeded.isNotEmpty)
                      _TagBlock(
                        theme: _theme,
                        title: 'Team needed',
                        values: idea.displayTeamNeeded,
                      ),
                    if (idea.displaySkills.isNotEmpty) ...<Widget>[
                      if (idea.displayTeamNeeded.isNotEmpty)
                        const SizedBox(height: 14),
                      _TagBlock(
                        theme: _theme,
                        title: 'Skills needed',
                        values: idea.displaySkills,
                      ),
                    ],
                    if (idea.tools.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      AppMetaRow(
                        theme: _theme,
                        label: 'Tools and stack',
                        value: idea.tools,
                      ),
                    ],
                    if (idea.resourcesNeeded.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      AppMetaRow(
                        theme: _theme,
                        label: 'Resources or needs',
                        value: idea.resourcesNeeded,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (hasAttachment) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'References And Links',
                icon: Icons.attach_file_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppMetaRow(
                      theme: _theme,
                      label: 'Attachment',
                      value: idea.attachmentUrl,
                      icon: Icons.link_rounded,
                    ),
                    const SizedBox(height: 8),
                    AppPrimaryButton(
                      theme: _theme,
                      label: 'Open Attachment',
                      icon: Icons.open_in_new_rounded,
                      onPressed: () =>
                          _openExternalLink(context, idea.attachmentUrl),
                    ),
                  ],
                ),
              ),
            ],
            if (idea.tags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Tags',
                icon: Icons.local_offer_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: idea.tags
                      .map(
                        (tag) => AppTagChip(
                          theme: _theme,
                          badge: AppBadgeData(label: tag),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareIdea(ProjectIdeaModel idea) {
    SharePlus.instance.share(
      ShareParams(
        text:
            '${idea.title}\n\n${idea.overviewText}\n\nShared from Innovation Hub',
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
      context.showAppSnackBar(
        error,
        title: 'Update unavailable',
        type: AppFeedbackType.error,
      );
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
      context.showAppSnackBar(
        'Could not open that link.',
        title: 'Open unavailable',
        type: AppFeedbackType.error,
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
      MaterialPageRoute(
        builder: (_) => CreateIdeaScreen(idea: idea, isEditMode: true),
      ),
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
            children: <Widget>[
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
              Text('Manage Team', style: _theme.section(size: 20)),
              const SizedBox(height: 8),
              Text(
                'Track the roles you need and the interest building around this idea.',
                style: _theme.body(size: 13.5),
              ),
              const SizedBox(height: 18),
              AppDetailSection(
                theme: _theme,
                title: 'Interest Snapshot',
                icon: Icons.groups_rounded,
                child: IdeaMetricsRow(interestedCount: idea.interestedCount),
              ),
              if (idea.displayTeamNeeded.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                AppDetailSection(
                  theme: _theme,
                  title: 'Open Roles',
                  icon: Icons.badge_outlined,
                  child: _TagBlock(
                    theme: _theme,
                    title: 'Roles',
                    values: idea.displayTeamNeeded,
                  ),
                ),
              ],
              if (idea.displaySkills.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                AppDetailSection(
                  theme: _theme,
                  title: 'Key Skills',
                  icon: Icons.auto_fix_high_outlined,
                  child: _TagBlock(
                    theme: _theme,
                    title: 'Skills',
                    values: idea.displaySkills,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TagBlock extends StatelessWidget {
  final AppContentTheme theme;
  final String title;
  final List<String> values;

  const _TagBlock({
    required this.theme,
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.label(size: 12.5, color: theme.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => AppTagChip(
                  theme: theme,
                  badge: AppBadgeData(label: value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
