import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/admin_palette.dart';
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
  String _level = 'licence';
  String _status = 'approved';

  bool get _isEditing => widget.initialIdea != null;

  @override
  void initState() {
    super.initState();
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
    _level = idea.level.trim().isEmpty ? 'licence' : idea.level;
    _status = idea.status == 'rejected' ? 'rejected' : 'approved';
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
    return AdminEditorScaffold(
      title: _isEditing ? 'Edit Admin Idea' : 'Publish Admin Idea',
      submitLabel: _isEditing ? 'Save Idea Changes' : 'Publish Idea',
      icon: Icons.lightbulb_outline_rounded,
      accentColor: Colors.amber.shade700,
      subtitle:
          'Add a platform-curated idea with a strong story, clear metadata, and the same polished structure users already recognize in the innovation feed.',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AdminEditorSection(
              title: 'Publishing',
              subtitle:
                  'Choose whether the idea is visible in discovery and whether it reads as a public collaboration opportunity.',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: 'Visible',
                          subtitle: 'Show this idea to users',
                          selected: _status == 'approved',
                          color: AdminPalette.success,
                          icon: Icons.visibility_outlined,
                          onTap: () => setState(() => _status = 'approved'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: 'Hidden',
                          subtitle: 'Keep it out of discovery',
                          selected: _status == 'rejected',
                          color: AdminPalette.danger,
                          icon: Icons.visibility_off_outlined,
                          onTap: () => setState(() => _status = 'rejected'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminEditorToggleCard(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                    title: 'Public collaboration allowed',
                    subtitle:
                        'When enabled, the idea reads like a public community opportunity instead of a hidden internal note.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Core Story',
              subtitle:
                  'Keep the headline and overview crisp so the idea reads strongly in both cards and full detail views.',
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
                    validator: adminRequiredMin('Description', min: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Metadata and collaboration',
              subtitle:
                  'These fields shape the filters, badges, and collaboration framing used throughout the app.',
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
                    items: const [
                      DropdownMenuItem(value: 'bac', child: Text('Bac')),
                      DropdownMenuItem(
                        value: 'licence',
                        child: Text('Licence'),
                      ),
                      DropdownMenuItem(value: 'master', child: Text('Master')),
                      DropdownMenuItem(
                        value: 'doctorat',
                        child: Text('Doctorat'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _level = value);
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
      'status': _status,
      'submittedBy': auth.uid,
      'submittedByName': auth.fullName.trim(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Admin idea updated successfully'
              : 'Admin idea published successfully',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }
}
