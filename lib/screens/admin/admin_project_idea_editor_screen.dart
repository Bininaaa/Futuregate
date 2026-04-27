import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/locale_controller.dart';
import '../../utils/admin_identity.dart';
import '../../utils/admin_palette.dart';
import '../../utils/content_language.dart';
import '../../widgets/shared/app_feedback.dart';
import 'admin_editor_widgets.dart';

class AdminProjectIdeaEditorScreen extends StatefulWidget {
  final ProjectIdeaModel? initialIdea;

  const AdminProjectIdeaEditorScreen({super.key, this.initialIdea});

  @override
  State<AdminProjectIdeaEditorScreen> createState() =>
      _AdminProjectIdeaEditorScreenState();
}

class _AdminProjectIdeaEditorScreenState
    extends State<AdminProjectIdeaEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _taglineController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _domainController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _toolsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _teamController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _resourcesController = TextEditingController();
  final _benefitsController = TextEditingController();

  bool _isSubmitting = false;
  bool _isPublic = true;
  bool _isHidden = false;
  String _level = 'licence';
  String _status = 'approved';
  String _originalLanguage = 'fr';

  bool get _isEditing => widget.initialIdea != null;

  @override
  void initState() {
    super.initState();
    _originalLanguage = ContentLanguage.normalizeCode(
      LocaleController.activeLanguageCode,
      fallback: 'fr',
    );
    final idea = widget.initialIdea;
    if (idea == null) return;

    _titleController.text = idea.title;
    _taglineController.text = idea.tagline;
    _shortDescriptionController.text = idea.shortDescription;
    _domainController.text = idea.domain;
    _categoryController.text = idea.category;
    _stageController.text = idea.stage;
    _descriptionController.text = idea.description;
    _toolsController.text = idea.tools;
    _tagsController.text = adminJoinList(idea.tags);
    _skillsController.text = adminJoinList(idea.skillsNeeded);
    _teamController.text = adminJoinList(idea.teamNeeded);
    _targetAudienceController.text = idea.targetAudience;
    _problemController.text = idea.problemStatement;
    _solutionController.text = idea.solution;
    _resourcesController.text = idea.resourcesNeeded;
    _benefitsController.text = idea.benefits;
    _isPublic = idea.isPublic;
    _isHidden = idea.isHidden || idea.status == 'rejected';
    _level = idea.level.trim().isEmpty ? 'licence' : idea.level;
    _status = idea.status == 'pending' ? 'pending' : 'approved';
    _originalLanguage = ContentLanguage.normalizeCode(
      idea.originalLanguage,
      fallback: _originalLanguage,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _shortDescriptionController.dispose();
    _domainController.dispose();
    _categoryController.dispose();
    _stageController.dispose();
    _descriptionController.dispose();
    _toolsController.dispose();
    _tagsController.dispose();
    _skillsController.dispose();
    _teamController.dispose();
    _targetAudienceController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _resourcesController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminEditorScaffold(
      title: _isEditing ? l10n.uiEditIdea : l10n.publishIdeaTitle,
      submitLabel: _isEditing ? l10n.saveIdeaChangesLabel : l10n.publishLabel,
      icon: Icons.lightbulb_outline_rounded,
      accentColor: AdminPalette.warning,
      subtitle: l10n.uiAddAPlatformCuratedIdeaWithAStrongStoryClear,
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            AdminEditorSection(
              title: l10n.publishingSectionTitle,
              subtitle:
                  l10n.uiChooseWhetherTheIdeaIsVisibleInDiscoveryAndWhether,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: 'Visible',
                          subtitle: 'Show this idea to users',
                          selected: !_isHidden,
                          color: AdminPalette.success,
                          icon: Icons.visibility_outlined,
                          onTap: () => setState(() {
                            _isHidden = false;
                            _status = 'approved';
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: 'Hidden',
                          subtitle: 'Keep it out of discovery',
                          selected: _isHidden,
                          color: AdminPalette.danger,
                          icon: Icons.visibility_off_outlined,
                          onTap: () => setState(() {
                            _isHidden = true;
                            _status = 'approved';
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminEditorToggleCard(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                    title: l10n.uiPublicCollaborationAllowed,
                    subtitle:
                        'When enabled, the idea reads like a public community opportunity instead of a hidden internal note.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: l10n.uiCoreStory,
              subtitle: l10n.uiKeepTheHeadlineAndOverviewCrispSoTheIdeaReads,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _titleController,
                    label: 'Idea title',
                    hint: 'e.g. Campus Innovation Partner Program',
                    validator: adminRequiredMin('Title', min: 4),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _taglineController,
                    label: 'Tagline',
                    hint: 'Short hook for the hero section',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _shortDescriptionController,
                    label: 'Short description',
                    hint: 'A tight one-paragraph summary',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _descriptionController,
                    label: 'Full description',
                    hint: 'Describe the idea clearly and with enough depth',
                    maxLines: 6,
                    minLength: 60,
                    helperText:
                        'Describe the problem, solution, audience, and expected impact.',
                    validator: adminRequiredMin('Description', min: 60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: l10n.uiMetadataAndCollaboration,
              subtitle: l10n
                  .uiTheseFieldsShapeTheFiltersBadgesAndCollaborationFramingUsed,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _domainController,
                    label: 'Domain',
                    hint: 'e.g. EdTech, AI, Sustainability',
                    validator: adminRequiredMin('Domain'),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorDropdown<String>(
                    value: _level,
                    label: 'Academic level',
                    items: [
                      DropdownMenuItem(value: 'bac', child: Text(l10n.uiBac)),
                      DropdownMenuItem(
                        value: 'licence',
                        child: Text(l10n.academicLevelLicence),
                      ),
                      DropdownMenuItem(
                        value: 'master',
                        child: Text(l10n.academicLevelMaster),
                      ),
                      DropdownMenuItem(
                        value: 'doctorat',
                        child: Text(l10n.academicLevelDoctorat),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _level = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  AdminEditorDropdown<String>(
                    value: _originalLanguage,
                    label: l10n.originalLanguageFieldLabel,
                    items: [
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(l10n.languageFrench),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.languageEnglish),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(l10n.languageArabic),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _originalLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _categoryController,
                    label: 'Category',
                    hint: 'e.g. Innovation, Startup, Research',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _stageController,
                    label: 'Stage',
                    hint: 'e.g. Concept, Prototype, Pilot',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _toolsController,
                    label: 'Tools or stack',
                    hint: 'e.g. Flutter, Firebase, Figma',
                    validator: adminRequiredMin('Tools'),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _tagsController,
                    label: 'Tags',
                    hint: 'Comma-separated tags',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _skillsController,
                    label: 'Skills needed',
                    hint: 'Comma-separated skills',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _teamController,
                    label: 'Team roles needed',
                    hint: 'Comma-separated roles',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _targetAudienceController,
                    label: 'Target audience',
                    hint: 'Who benefits most from this idea?',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _problemController,
                    label: 'Problem statement',
                    hint: 'What challenge does this solve?',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _solutionController,
                    label: 'Solution',
                    hint: 'How does the idea solve the problem?',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _resourcesController,
                    label: 'Resources needed',
                    hint: 'What support, partners, or assets are required?',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _benefitsController,
                    label: 'Benefits or impact',
                    hint: 'What outcomes make this valuable?',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) return;

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'shortDescription': _shortDescriptionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'domain': _domainController.text.trim(),
      'level': _level,
      'originalLanguage': _originalLanguage,
      'category': _categoryController.text.trim(),
      'stage': _stageController.text.trim(),
      'tools': _toolsController.text.trim(),
      'tags': adminSplitCsv(_tagsController.text),
      'skillsNeeded': adminSplitCsv(_skillsController.text),
      'teamNeeded': adminSplitCsv(_teamController.text),
      'targetAudience': _targetAudienceController.text.trim(),
      'problemStatement': _problemController.text.trim(),
      'solution': _solutionController.text.trim(),
      'resourcesNeeded': _resourcesController.text.trim(),
      'benefits': _benefitsController.text.trim(),
      'isPublic': _isPublic,
      'isHidden': _isHidden,
      'status': _status,
      'submittedBy': auth.uid,
      'submittedByName': AdminIdentity.publicName,
      'authorAvatar': auth.profileImage.trim(),
      'authorPhotoType': (auth.photoType ?? '').trim(),
      'authorAvatarId': (auth.avatarId ?? '').trim(),
    };

    final provider = context.read<AdminProvider>();
    final error = _isEditing
        ? await provider.updateAdminProjectIdea(widget.initialIdea!.id, payload)
        : await provider.createAdminProjectIdea(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _isEditing ? 'Update unavailable' : 'Publish unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      _isEditing
          ? 'Admin idea updated successfully.'
          : 'Admin idea published successfully.',
      title: _isEditing ? 'Idea updated' : 'Idea published',
      type: AppFeedbackType.success,
    );
    Navigator.of(context).pop(true);
  }
}
