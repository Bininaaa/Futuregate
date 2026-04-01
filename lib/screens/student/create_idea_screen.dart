import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';

class CreateIdeaScreen extends StatefulWidget {
  final ProjectIdeaModel? idea;
  final bool isEditMode;

  const CreateIdeaScreen({super.key, this.idea, this.isEditMode = false});

  @override
  State<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends State<CreateIdeaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _taglineController;
  late final TextEditingController _overviewController;
  late final TextEditingController _problemController;
  late final TextEditingController _solutionController;
  late final TextEditingController _audienceController;
  late final TextEditingController _resourcesController;
  late final TextEditingController _benefitsController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _attachmentUrlController;
  late final TextEditingController _customSkillsController;
  late final TextEditingController _customRolesController;

  late String _selectedCategory;
  late String _selectedStage;
  late String _selectedLevel;
  late bool _isPublic;
  late Set<String> _selectedSkills;
  late Set<String> _selectedRoles;

  bool get _isLocked =>
      widget.isEditMode &&
      (widget.idea?.status.toLowerCase() ?? '') != 'pending';

  @override
  void initState() {
    super.initState();
    final idea = widget.idea;
    _titleController = TextEditingController(text: idea?.title ?? '');
    _taglineController = TextEditingController(text: idea?.tagline ?? '');
    _overviewController = TextEditingController(
      text: idea?.description ?? idea?.shortDescription ?? '',
    );
    _problemController = TextEditingController(
      text: idea?.problemStatement ?? '',
    );
    _solutionController = TextEditingController(text: idea?.solution ?? '');
    _audienceController = TextEditingController(
      text: idea?.targetAudience ?? '',
    );
    _resourcesController = TextEditingController(
      text: idea?.resourcesNeeded ?? '',
    );
    _benefitsController = TextEditingController(text: idea?.benefits ?? '');
    _imageUrlController = TextEditingController(text: idea?.imageUrl ?? '');
    _attachmentUrlController = TextEditingController(
      text: idea?.attachmentUrl ?? '',
    );
    _customSkillsController = TextEditingController();
    _customRolesController = TextEditingController();
    _selectedCategory = (idea?.displayCategory ?? '').trim().isNotEmpty
        ? idea!.displayCategory
        : innovationHubDefaultCategories.first;
    _selectedStage = (idea?.displayStage ?? '').trim().isNotEmpty
        ? idea!.displayStage
        : innovationHubStageOptions.first;
    _selectedLevel = (idea?.level ?? '').trim().isNotEmpty
        ? idea!.level
        : 'licence';
    _isPublic = idea?.isPublic ?? true;
    _selectedSkills = {...?idea?.displaySkills};
    _selectedRoles = {...?idea?.displayTeamNeeded};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _overviewController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _audienceController.dispose();
    _resourcesController.dispose();
    _benefitsController.dispose();
    _imageUrlController.dispose();
    _attachmentUrlController.dispose();
    _customSkillsController.dispose();
    _customRolesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLocked) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final provider = context.read<ProjectIdeaProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) {
      return;
    }

    _commitCustomEntries();

    final category = _selectedCategory.trim();
    final stage = _selectedStage.trim();
    final skills = _selectedSkills.toList(growable: false);
    final roles = _selectedRoles.toList(growable: false);
    final description = _overviewController.text.trim();
    final tagline = _taglineController.text.trim();

    final error = widget.isEditMode && widget.idea != null
        ? await provider.updateProjectIdea(
            id: widget.idea!.id,
            title: _titleController.text.trim(),
            description: description,
            domain: category,
            level: _selectedLevel,
            tools: skills.join(', '),
            submittedBy: currentUser.uid,
            tagline: tagline,
            shortDescription: tagline.isNotEmpty ? tagline : description,
            category: category,
            tags: skills.take(3).toList(growable: false),
            stage: stage,
            skillsNeeded: skills,
            teamNeeded: roles,
            targetAudience: _audienceController.text.trim(),
            problemStatement: _problemController.text.trim(),
            solution: _solutionController.text.trim(),
            resourcesNeeded: _resourcesController.text.trim(),
            benefits: _benefitsController.text.trim(),
            imageUrl: _imageUrlController.text.trim(),
            attachmentUrl: _attachmentUrlController.text.trim(),
            isPublic: _isPublic,
          )
        : await provider.submitProjectIdea(
            title: _titleController.text.trim(),
            description: description,
            domain: category,
            level: _selectedLevel,
            tools: skills.join(', '),
            submittedBy: currentUser.uid,
            tagline: tagline,
            shortDescription: tagline.isNotEmpty ? tagline : description,
            category: category,
            tags: skills.take(3).toList(growable: false),
            stage: stage,
            skillsNeeded: skills,
            teamNeeded: roles,
            targetAudience: _audienceController.text.trim(),
            problemStatement: _problemController.text.trim(),
            solution: _solutionController.text.trim(),
            resourcesNeeded: _resourcesController.text.trim(),
            benefits: _benefitsController.text.trim(),
            imageUrl: _imageUrlController.text.trim(),
            attachmentUrl: _attachmentUrlController.text.trim(),
            isPublic: _isPublic,
          );

    if (!mounted) {
      return;
    }

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Idea updated successfully.'
                : 'Idea submitted successfully.',
          ),
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _commitCustomEntries() {
    for (final skill in _customSkillsController.text.split(',')) {
      final trimmed = skill.trim();
      if (trimmed.isNotEmpty) {
        _selectedSkills.add(trimmed);
      }
    }
    _customSkillsController.clear();

    for (final role in _customRolesController.text.split(',')) {
      final trimmed = role.trim();
      if (trimmed.isNotEmpty) {
        _selectedRoles.add(trimmed);
      }
    }
    _customRolesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();

    return Scaffold(
      backgroundColor: InnovationHubPalette.background,
      appBar: AppBar(
        backgroundColor: InnovationHubPalette.background,
        foregroundColor: InnovationHubPalette.textPrimary,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.isEditMode ? 'Edit Idea' : 'Create Idea',
          style: InnovationHubTypography.section(size: 20),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: InnovationHubPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: InnovationHubPalette.border),
            boxShadow: InnovationHubPalette.softShadow(0.06),
          ),
          child: provider.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: CircularProgressIndicator()),
                )
              : ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InnovationHubPalette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _isLocked
                        ? 'Editing locked after review'
                        : widget.isEditMode
                        ? 'Save Changes'
                        : 'Publish Idea',
                    style: InnovationHubTypography.label(
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isLocked,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _buildHeroCard(),
              if (_isLocked) ...[
                const SizedBox(height: 16),
                _buildLockNotice(),
              ],
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Core Idea',
                subtitle:
                    'Shape the concept and make the first impression feel sharp.',
                child: Column(
                  children: [
                    _StyledField(
                      controller: _titleController,
                      label: 'Idea Title',
                      hint: 'AI-powered campus wellbeing assistant',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _taglineController,
                      label: 'Short Tagline',
                      hint: 'A smarter way for students to find support fast.',
                    ),
                    const SizedBox(height: 18),
                    _buildChoiceGroup(
                      title: 'Category',
                      values: innovationHubDefaultCategories,
                      selected: _selectedCategory,
                      onSelected: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildChoiceGroup(
                      title: 'Stage',
                      values: innovationHubStageOptions,
                      selected: _selectedStage,
                      onSelected: (value) {
                        setState(() => _selectedStage = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      dropdownColor: InnovationHubPalette.surface,
                      decoration: _inputDecoration(
                        label: 'Best suited for',
                        hint: 'Select student level',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'bac', child: Text('Bachelor')),
                        DropdownMenuItem(
                          value: 'licence',
                          child: Text('Licence'),
                        ),
                        DropdownMenuItem(
                          value: 'master',
                          child: Text('Master'),
                        ),
                        DropdownMenuItem(
                          value: 'doctorat',
                          child: Text('Doctorate'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLevel = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Idea Story',
                subtitle:
                    'Give students and future collaborators a clear reason to care.',
                child: Column(
                  children: [
                    _StyledField(
                      controller: _overviewController,
                      label: 'Idea Overview',
                      hint:
                          'Describe the concept, what it does, and how it comes to life.',
                      validator: _requiredValidator,
                      minLines: 4,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _problemController,
                      label: 'Problem Statement',
                      hint: 'What student challenge does this idea solve?',
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _solutionController,
                      label: 'Solution',
                      hint:
                          'Explain the proposed solution and why it stands out.',
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _audienceController,
                      label: 'Target Audience',
                      hint: 'Students, clubs, mentors, campuses...',
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _benefitsController,
                      label: 'Benefits / Impact',
                      hint: 'Why does this idea matter right now?',
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Team Setup',
                subtitle:
                    'Show who you need to turn the concept into something real.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SelectionWrap(
                      title: 'Team Needed',
                      suggestions: innovationHubRoleOptions,
                      selectedValues: _selectedRoles,
                      onToggle: (value) {
                        setState(() {
                          if (_selectedRoles.contains(value)) {
                            _selectedRoles.remove(value);
                          } else {
                            _selectedRoles.add(value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _StyledField(
                      controller: _customRolesController,
                      label: 'Add custom roles',
                      hint: 'Mentor, Community Lead, Data Analyst',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    _SelectionWrap(
                      title: 'Skills Needed',
                      suggestions: innovationHubSkillSuggestions,
                      selectedValues: _selectedSkills,
                      onToggle: (value) {
                        setState(() {
                          if (_selectedSkills.contains(value)) {
                            _selectedSkills.remove(value);
                          } else {
                            _selectedSkills.add(value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _StyledField(
                      controller: _customSkillsController,
                      label: 'Add custom skills',
                      hint: 'Firebase, UX Research, Fundraising',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _resourcesController,
                      label: 'Resources / Needs',
                      hint:
                          'Prototype support, mentor feedback, pilot testers...',
                      minLines: 3,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Visuals & Links',
                subtitle:
                    'Optional now, but structured so richer upload flows can slot in cleanly later.',
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: InnovationHubPalette.cardTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: InnovationHubPalette.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: InnovationHubPalette.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add a cover visual or deck link',
                                  style: InnovationHubTypography.label(
                                    color: InnovationHubPalette.textPrimary,
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use URLs for now so the idea stays publishable even if native uploads are not configured yet.',
                                  style: InnovationHubTypography.body(
                                    size: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _imageUrlController,
                      label: 'Image URL',
                      hint: 'https://...',
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _attachmentUrlController,
                      label: 'Attachment / Deck Link',
                      hint: 'Figma, Notion, pitch deck, demo link...',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: InnovationHubPalette.cardTint,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: InnovationHubPalette.border),
                      ),
                      child: SwitchListTile.adaptive(
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() => _isPublic = value);
                        },
                        activeThumbColor: InnovationHubPalette.primary,
                        activeTrackColor: InnovationHubPalette.primary
                            .withValues(alpha: 0.3),
                        title: Text(
                          'Ready for public discovery',
                          style: InnovationHubTypography.label(
                            color: InnovationHubPalette.textPrimary,
                            size: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Approved ideas appear in Discover. Pending ideas still stay visible in My Ideas.',
                          style: InnovationHubTypography.body(size: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: InnovationHubPalette.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: InnovationHubPalette.primary.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            widget.isEditMode
                ? 'Refine your idea'
                : 'Launch your next breakthrough',
            style: InnovationHubTypography.title(color: Colors.white, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            'Build an idea profile that feels ready for collaborators, feedback, and student momentum.',
            style: InnovationHubTypography.body(
              color: Colors.white.withValues(alpha: 0.86),
              size: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InnovationHubPalette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: InnovationHubPalette.warning.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: InnovationHubPalette.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Only pending ideas can be edited. This idea has already moved past review, so the form is shown in locked mode.',
              style: InnovationHubTypography.body(
                color: InnovationHubPalette.textPrimary,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceGroup({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: InnovationHubTypography.label(
            color: InnovationHubPalette.textPrimary,
            size: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                  selectedColor: InnovationHubPalette.primary,
                  backgroundColor: InnovationHubPalette.cardTint,
                  side: BorderSide(
                    color: selected == value
                        ? Colors.transparent
                        : InnovationHubPalette.border,
                  ),
                  labelStyle: InnovationHubTypography.label(
                    color: selected == value
                        ? Colors.white
                        : InnovationHubPalette.textPrimary,
                    size: 12.5,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: InnovationHubTypography.body(
        color: InnovationHubPalette.textSecondary,
      ),
      hintStyle: InnovationHubTypography.body(
        color: InnovationHubPalette.textSecondary.withValues(alpha: 0.8),
      ),
      filled: true,
      fillColor: InnovationHubPalette.cardTint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: InnovationHubPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: InnovationHubPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: InnovationHubPalette.primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: InnovationHubPalette.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: InnovationHubPalette.error,
          width: 1.4,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: InnovationHubTypography.section(size: 18)),
          const SizedBox(height: 8),
          Text(subtitle, style: InnovationHubTypography.body(size: 13.5)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CreateIdeaScreenState>();
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: InnovationHubTypography.body(
        color: InnovationHubPalette.textPrimary,
      ),
      decoration: state?._inputDecoration(label: label, hint: hint),
    );
  }
}

class _SelectionWrap extends StatelessWidget {
  final String title;
  final List<String> suggestions;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  const _SelectionWrap({
    required this.title,
    required this.suggestions,
    required this.selectedValues,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: InnovationHubTypography.label(
            color: InnovationHubPalette.textPrimary,
            size: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: selectedValues.contains(value),
                  onSelected: (_) => onToggle(value),
                  selectedColor: InnovationHubPalette.primary.withValues(
                    alpha: 0.14,
                  ),
                  backgroundColor: InnovationHubPalette.cardTint,
                  side: BorderSide(
                    color: selectedValues.contains(value)
                        ? InnovationHubPalette.primary.withValues(alpha: 0.24)
                        : InnovationHubPalette.border,
                  ),
                  labelStyle: InnovationHubTypography.label(
                    color: selectedValues.contains(value)
                        ? InnovationHubPalette.primary
                        : InnovationHubPalette.textPrimary,
                    size: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  showCheckmark: false,
                ),
              )
              .toList(),
        ),
        if (selectedValues.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedValues
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: InnovationHubPalette.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: InnovationHubTypography.label(
                            color: InnovationHubPalette.primary,
                            size: 11.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onToggle(value),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: InnovationHubPalette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
