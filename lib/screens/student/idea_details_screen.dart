import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/project_idea_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_translation_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../services/opportunity_translation_service.dart';
import '../../services/project_idea_service.dart';
import '../../utils/display_text.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/ideas/project_idea_cover_image.dart';
import '../../widgets/ideas/idea_metrics_row.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/content_translation_widgets.dart';
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

  AppContentTheme get _theme => AppContentTheme.futureGate(
    accent: InnovationHubPalette.primary,
    accentDark: InnovationHubPalette.primaryDark,
    accentSoft: InnovationHubPalette.cardTint,
    secondary: InnovationHubPalette.secondary,
    heroGradient: InnovationHubPalette.primaryGradient,
    typography: AppContentTypography.innovation,
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();
    final translationProvider = context.watch<OpportunityTranslationProvider>();
    final auth = context.watch<AuthProvider>().userModel;
    final baseIdea = provider.findIdeaById(ideaId) ?? initialIdea;
    if (baseIdea != null) {
      _ensureTranslation(context, baseIdea);
    }
    final hasTranslation =
        baseIdea != null && _hasTranslation(baseIdea, translationProvider);
    final showingTranslated =
        baseIdea != null &&
        translationProvider.isShowingTranslatedContent(
          contentType: ContentTranslationType.idea,
          contentId: baseIdea.id,
        );
    final idea = baseIdea == null
        ? null
        : _displayIdea(baseIdea, translationProvider);
    final isOwner = auth?.uid == idea?.submittedBy;

    if (idea == null) {
      return AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: Text(
              AppLocalizations.of(context)!.ideaNotAvailable,
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
            AppLocalizations.of(context)!.ideaHubTitle,
            style: _theme.section(size: 18, weight: FontWeight.w700),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: idea.isSavedByCurrentUser
                  ? AppLocalizations.of(context)!.ideaUnsaveTooltip
                  : AppLocalizations.of(context)!.ideaSaveTooltip,
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
              tooltip: AppLocalizations.of(context)!.uiShareIdea,
              onPressed: () => _shareIdea(context, idea),
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
                              ? AppLocalizations.of(context)!.ideaEditLabel
                              : AppLocalizations.of(context)!.ideaManageLabel)
                        : (idea.isJoinedByCurrentUser
                              ? AppLocalizations.of(
                                  context,
                                )!.ideaInterestedLabel
                              : AppLocalizations.of(
                                  context,
                                )!.ideaImInterestedLabel),
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
                          label: isOwner
                              ? AppLocalizations.of(
                                  context,
                                )!.ideaManageTeamLabel
                              : AppLocalizations.of(
                                  context,
                                )!.ideaContactCreator,
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
                              ? AppLocalizations.of(context)!.ideaShareLabel
                              : (idea.isSavedByCurrentUser
                                    ? AppLocalizations.of(
                                        context,
                                      )!.ideaSavedLabel
                                    : AppLocalizations.of(
                                        context,
                                      )!.ideaSaveLabel),
                          icon: isOwner
                              ? Icons.ios_share_rounded
                              : idea.isSavedByCurrentUser
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          onPressed: () {
                            if (isOwner) {
                              _shareIdea(context, idea);
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
              media: ProjectIdeaCoverImage(
                imageUrl: idea.imageUrl,
                ideaId: idea.id,
                height: 168,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholderColor: _theme.surfaceMuted,
                iconColor: _theme.textMuted,
              ),
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
                  label: innovationCategoryLabel(context, idea.displayCategory),
                  icon: innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                ),
                AppBadgeData(
                  label: innovationStageLabel(context, idea.displayStage),
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
                    label: academicLevelDisplayLabel(context, idea.level),
                    icon: Icons.school_outlined,
                    color: _theme.secondary,
                  ),
                AppBadgeData(
                  label: innovationVisibilityLabel(context, idea.isPublic),
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
                    label: AppLocalizations.of(context)!.uiCreator,
                    value: idea.creatorName,
                    icon: Icons.person_outline_rounded,
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: AppLocalizations.of(context)!.uiLastUpdated,
                    value: idea.lastUpdatedLabel,
                    icon: Icons.update_rounded,
                  ),
                  if (idea.createdAt != null)
                    AppMetaRow(
                      theme: _theme,
                      label: AppLocalizations.of(context)!.uiPosted,
                      value: DateFormat(
                        'MMM d, yyyy',
                      ).format(idea.createdAt!.toDate()),
                      icon: Icons.event_outlined,
                    ),
                ],
              ),
            ),
            if (baseIdea != null &&
                (translationProvider.statusForContent(
                          contentType: ContentTranslationType.idea,
                          contentId: baseIdea.id,
                        ) ==
                        TranslationStatus.loading ||
                    hasTranslation)) ...<Widget>[
              const SizedBox(height: 12),
              ContentTranslationBanner(
                isTranslating:
                    translationProvider.statusForContent(
                      contentType: ContentTranslationType.idea,
                      contentId: baseIdea.id,
                    ) ==
                    TranslationStatus.loading,
                hasTranslation: hasTranslation,
                showingTranslated: showingTranslated,
                originalLanguage: baseIdea.originalLanguage,
                onToggle: () => translationProvider.toggleTranslatedContent(
                  contentType: ContentTranslationType.idea,
                  contentId: baseIdea.id,
                ),
                accentColor: _theme.accent,
                surfaceColor: _theme.surface,
                borderColor: _theme.border,
                titleColor: _theme.textPrimary,
                subtitleColor: _theme.textSecondary,
              ),
            ],
            const SizedBox(height: 16),
            AppInfoTileGrid(
              theme: _theme,
              items: <AppInfoTileData>[
                AppInfoTileData(
                  label: AppLocalizations.of(context)!.uiStage,
                  value: innovationStageLabel(context, idea.displayStage),
                  icon: Icons.timeline_outlined,
                  color: stageColor,
                ),
                if (showModerationStatus)
                  AppInfoTileData(
                    label: AppLocalizations.of(context)!.uiStatus,
                    value: idea.statusLabel,
                    icon: Icons.flag_outlined,
                    color: statusColor,
                  ),
                AppInfoTileData(
                  label: AppLocalizations.of(context)!.uiCategory,
                  value: innovationCategoryLabel(context, idea.displayCategory),
                  icon: innovationCategoryIcon(idea.displayCategory),
                  color: categoryColor,
                ),
                AppInfoTileData(
                  label: AppLocalizations.of(context)!.uiLevel,
                  value: idea.level.trim().isNotEmpty
                      ? academicLevelDisplayLabel(context, idea.level)
                      : '',
                  icon: Icons.school_outlined,
                ),
                AppInfoTileData(
                  label: AppLocalizations.of(context)!.uiInterested,
                  value: '${idea.interestedCount}',
                  icon: Icons.groups_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: AppLocalizations.of(context)!.uiOverview,
              icon: Icons.auto_awesome_rounded,
              child: Text(
                DisplayText.capitalizeDisplayValue(idea.overviewText),
                style: _theme.body(color: _theme.textPrimary),
              ),
            ),
            if (idea.description.trim().isNotEmpty &&
                idea.description.trim() !=
                    idea.overviewText.trim()) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: AppLocalizations.of(context)!.uiFullDescription,
                icon: Icons.description_outlined,
                child: Text(
                  DisplayText.capitalizeDisplayValue(idea.description),
                  style: _theme.body(color: _theme.textPrimary),
                ),
              ),
            ],
            if (idea.problemText.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: AppLocalizations.of(context)!.uiProblemStatement,
                icon: Icons.help_outline_rounded,
                child: Text(
                  DisplayText.capitalizeDisplayValue(idea.problemText),
                  style: _theme.body(color: _theme.textPrimary),
                ),
              ),
            ],
            if (idea.solutionText.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: AppLocalizations.of(context)!.uiProposedSolution,
                icon: Icons.rocket_launch_outlined,
                child: Text(
                  DisplayText.capitalizeDisplayValue(idea.solutionText),
                  style: _theme.body(color: _theme.textPrimary),
                ),
              ),
            ],
            if (idea.targetAudience.trim().isNotEmpty ||
                idea.impactText.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: AppLocalizations.of(context)!.uiAudienceAndImpact,
                icon: Icons.groups_2_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (idea.targetAudience.trim().isNotEmpty)
                      AppMetaRow(
                        theme: _theme,
                        label: AppLocalizations.of(context)!.uiTargetAudience,
                        value: idea.targetAudience,
                      ),
                    if (idea.impactText.trim().isNotEmpty)
                      AppMetaRow(
                        theme: _theme,
                        label: AppLocalizations.of(
                          context,
                        )!.uiBenefitsAndImpact,
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
                title: AppLocalizations.of(context)!.uiCollaborationNeeds,
                icon: Icons.diversity_3_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (idea.displayTeamNeeded.isNotEmpty)
                      _TagBlock(
                        theme: _theme,
                        title: AppLocalizations.of(context)!.uiTeamNeeded,
                        values: idea.displayTeamNeeded,
                      ),
                    if (idea.displaySkills.isNotEmpty) ...<Widget>[
                      if (idea.displayTeamNeeded.isNotEmpty)
                        const SizedBox(height: 14),
                      _TagBlock(
                        theme: _theme,
                        title: AppLocalizations.of(context)!.uiSkillsNeeded,
                        values: idea.displaySkills,
                      ),
                    ],
                    if (idea.tools.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      AppMetaRow(
                        theme: _theme,
                        label: AppLocalizations.of(context)!.uiToolsAndStack,
                        value: idea.tools,
                      ),
                    ],
                    if (idea.resourcesNeeded.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      AppMetaRow(
                        theme: _theme,
                        label: AppLocalizations.of(context)!.uiResourcesOrNeeds,
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
                title: AppLocalizations.of(context)!.uiReferencesAndLinks,
                icon: Icons.attach_file_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppMetaRow(
                      theme: _theme,
                      label: AppLocalizations.of(context)!.uiAttachment,
                      value: idea.attachmentUrl,
                      icon: Icons.link_rounded,
                    ),
                    const SizedBox(height: 8),
                    AppPrimaryButton(
                      theme: _theme,
                      label: AppLocalizations.of(context)!.uiOpenAttachment,
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
                title: AppLocalizations.of(context)!.uiTags,
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

  void _ensureTranslation(BuildContext context, ProjectIdeaModel idea) {
    final originalLanguage = idea.originalLanguage.trim();
    if (originalLanguage.isEmpty) {
      return;
    }

    final currentLocale = Localizations.localeOf(context).languageCode;
    if (currentLocale == originalLanguage) {
      return;
    }

    final provider = context.read<OpportunityTranslationProvider>();
    final status = provider.statusForContent(
      contentType: ContentTranslationType.idea,
      contentId: idea.id,
    );
    if (status == TranslationStatus.loading ||
        status == TranslationStatus.ready) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      context.read<OpportunityTranslationProvider>().ensureContentTranslation(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        fields: <String, String>{
          'title': idea.title,
          'tagline': idea.tagline,
          'shortDescription': idea.shortDescription,
          'description': idea.description,
          'targetAudience': idea.targetAudience,
          'problemStatement': idea.problemStatement,
          'solution': idea.solution,
          'resourcesNeeded': idea.resourcesNeeded,
          'benefits': idea.benefits,
        },
        currentLocale: currentLocale,
        originalLocale: originalLanguage,
      );
    });
  }

  bool _hasTranslation(
    ProjectIdeaModel idea,
    OpportunityTranslationProvider provider,
  ) {
    return provider.statusForContent(
              contentType: ContentTranslationType.idea,
              contentId: idea.id,
            ) ==
            TranslationStatus.ready &&
        provider.translationForContent(
              contentType: ContentTranslationType.idea,
              contentId: idea.id,
            ) !=
            null;
  }

  ProjectIdeaModel _displayIdea(
    ProjectIdeaModel idea,
    OpportunityTranslationProvider provider,
  ) {
    final hasTranslation = _hasTranslation(idea, provider);
    final showingTranslated = provider.isShowingTranslatedContent(
      contentType: ContentTranslationType.idea,
      contentId: idea.id,
    );
    if (!hasTranslation || !showingTranslated) {
      return idea;
    }

    return idea.copyWith(
      title: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'title',
        originalValue: idea.title,
      ),
      tagline: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'tagline',
        originalValue: idea.tagline,
      ),
      shortDescription: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'shortDescription',
        originalValue: idea.shortDescription,
      ),
      description: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'description',
        originalValue: idea.description,
      ),
      targetAudience: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'targetAudience',
        originalValue: idea.targetAudience,
      ),
      problemStatement: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'problemStatement',
        originalValue: idea.problemStatement,
      ),
      solution: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'solution',
        originalValue: idea.solution,
      ),
      resourcesNeeded: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'resourcesNeeded',
        originalValue: idea.resourcesNeeded,
      ),
      benefits: provider.resolvedField(
        contentType: ContentTranslationType.idea,
        contentId: idea.id,
        field: 'benefits',
        originalValue: idea.benefits,
      ),
    );
  }

  void _shareIdea(BuildContext context, ProjectIdeaModel idea) {
    SharePlus.instance.share(
      ShareParams(
        text:
            '${idea.title}\n\n${idea.overviewText}\n\n${AppLocalizations.of(context)!.ideaSharedFromHub}',
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
        title: AppLocalizations.of(context)!.uiUpdateUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  void _openCreatorProfile(BuildContext context, ProjectIdeaModel idea) {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) {
      context.showAppSnackBar(
        'Sign in to contact the creator.',
        title: AppLocalizations.of(context)!.uiLoginRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (idea.submittedBy.trim().isEmpty) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.ideaNotAvailable,
        title: 'Contact unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

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
        AppLocalizations.of(context)!.uiCouldNotOpenThatLink,
        title: AppLocalizations.of(context)!.uiOpenUnavailable,
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
        decoration: BoxDecoration(
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
              Text(
                AppLocalizations.of(context)!.uiManageTeam,
                style: _theme.section(size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(
                  context,
                )!.uiTrackTheRolesYouNeedAndTheInterestBuildingAround,
                style: _theme.body(size: 13.5),
              ),
              const SizedBox(height: 18),
              AppDetailSection(
                theme: _theme,
                title: AppLocalizations.of(context)!.uiInterestSnapshot,
                icon: Icons.groups_rounded,
                child: IdeaMetricsRow(interestedCount: idea.interestedCount),
              ),
              if (idea.displayTeamNeeded.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                AppDetailSection(
                  theme: _theme,
                  title: AppLocalizations.of(context)!.uiOpenRoles,
                  icon: Icons.badge_outlined,
                  child: _TagBlock(
                    theme: _theme,
                    title: AppLocalizations.of(context)!.uiRoles,
                    values: idea.displayTeamNeeded,
                  ),
                ),
              ],
              if (idea.displaySkills.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                AppDetailSection(
                  theme: _theme,
                  title: AppLocalizations.of(context)!.uiKeySkills,
                  icon: Icons.auto_fix_high_outlined,
                  child: _TagBlock(
                    theme: _theme,
                    title: AppLocalizations.of(context)!.uiSkills,
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
