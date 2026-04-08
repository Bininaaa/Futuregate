import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../services/file_storage_service.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_workspace_shell.dart';

class CreateIdeaScreen extends StatefulWidget {
  final ProjectIdeaModel? idea;
  final bool isEditMode;
  final bool isAdmin;

  const CreateIdeaScreen({
    super.key,
    this.idea,
    this.isEditMode = false,
    this.isAdmin = false,
  });

  @override
  State<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends State<CreateIdeaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  late final TextEditingController _titleController;
  late final TextEditingController _taglineController;
  late final TextEditingController _overviewController;
  late final TextEditingController _problemController;
  late final TextEditingController _solutionController;
  late final TextEditingController _audienceController;
  late final TextEditingController _resourcesController;
  late final TextEditingController _benefitsController;
  late final TextEditingController _attachmentUrlController;
  late final TextEditingController _customSkillsController;
  late final TextEditingController _customRolesController;

  late String _selectedCategory;
  late String _selectedStage;
  late String _selectedLevel;
  late bool _isPublic;
  late Set<String> _selectedSkills;
  late Set<String> _selectedRoles;
  late String _imageUrl;
  late String _uploadedImageName;
  bool _isUploadingImage = false;
  late String _adminStatus;

  bool get _isLocked =>
      !widget.isAdmin &&
      widget.isEditMode &&
      (widget.idea?.status.toLowerCase() ?? '') != 'pending';

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
    _imageUrl = (idea?.imageUrl ?? '').trim();
    _uploadedImageName = _deriveImageLabel(_imageUrl);
    _adminStatus = idea != null
        ? (idea.status == 'rejected' ? 'rejected' : 'approved')
        : 'approved';
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
    _attachmentUrlController.dispose();
    _customSkillsController.dispose();
    _customRolesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLocked) {
      return;
    }
    if (_isUploadingImage) {
      context.showAppSnackBar(
        'Please wait for the cover image upload to finish.',
        title: 'Upload in progress',
        type: AppFeedbackType.warning,
      );
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

    final String? error;

    if (widget.isAdmin) {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'tagline': tagline,
        'shortDescription': tagline.isNotEmpty ? tagline : description,
        'description': description,
        'domain': category,
        'level': _selectedLevel,
        'category': category,
        'stage': stage,
        'tools': skills.join(', '),
        'tags': skills.take(3).toList(growable: false),
        'skillsNeeded': skills,
        'teamNeeded': roles,
        'targetAudience': _audienceController.text.trim(),
        'problemStatement': _problemController.text.trim(),
        'solution': _solutionController.text.trim(),
        'resourcesNeeded': _resourcesController.text.trim(),
        'benefits': _benefitsController.text.trim(),
        'imageUrl': _imageUrl.trim(),
        'attachmentUrl': _attachmentUrlController.text.trim(),
        'isPublic': _isPublic,
        'status': _adminStatus,
        'submittedBy': currentUser.uid,
        'submittedByName': currentUser.fullName.trim(),
        'authorAvatar': currentUser.profileImage.trim(),
        'authorPhotoType': (currentUser.photoType ?? '').trim(),
        'authorAvatarId': (currentUser.avatarId ?? '').trim(),
      };

      final adminProvider = context.read<AdminProvider>();
      error = widget.isEditMode && widget.idea != null
          ? await adminProvider.updateAdminProjectIdea(widget.idea!.id, payload)
          : await adminProvider.createAdminProjectIdea(payload);
    } else if (widget.isEditMode && widget.idea != null) {
      error = await provider.updateProjectIdea(
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
        imageUrl: _imageUrl.trim(),
        attachmentUrl: _attachmentUrlController.text.trim(),
        isPublic: _isPublic,
      );
    } else {
      error = await provider.submitProjectIdea(
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
        imageUrl: _imageUrl.trim(),
        attachmentUrl: _attachmentUrlController.text.trim(),
        isPublic: _isPublic,
      );
    }

    if (!mounted) {
      return;
    }

    if (error == null) {
      context.showAppSnackBar(
        widget.isEditMode
            ? 'Idea updated successfully.'
            : widget.isAdmin
            ? 'Idea published successfully.'
            : 'Idea submitted successfully.',
        title: widget.isEditMode
            ? 'Idea updated'
            : widget.isAdmin
            ? 'Idea published'
            : 'Idea submitted',
        type: AppFeedbackType.success,
      );
      Navigator.pop(context, true);
      return;
    }

    context.showAppSnackBar(
      error,
      title: 'Submission unavailable',
      type: AppFeedbackType.error,
    );
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

  Future<void> _pickAndUploadImage() async {
    if (_isLocked ||
        _isUploadingImage ||
        context.read<ProjectIdeaProvider>().isLoading) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      context.showAppSnackBar(
        'Choose an image smaller than 5 MB.',
        title: 'Upload unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      context.showAppSnackBar(
        'Please sign in again to upload images.',
        title: 'Login required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final upload = await _storageService.uploadProjectIdeaImage(
        userId: currentUser.uid,
        fileName: file.name,
        filePath: file.path ?? '',
        fileBytes: file.bytes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _imageUrl = upload.fileUrl.trim();
        _uploadedImageName = upload.fileName.trim();
        _isUploadingImage = false;
      });

      context.showAppSnackBar(
        'Cover image uploaded successfully.',
        title: 'Upload complete',
        type: AppFeedbackType.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isUploadingImage = false);
      context.showAppSnackBar(
        _formatUploadError(error),
        title: 'Upload unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = '';
      _uploadedImageName = '';
    });
  }

  String _formatUploadError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Image upload failed. Please try again.';
    }
    return message;
  }

  String _deriveImageLabel(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.pathSegments.isEmpty) {
      return 'Current cover image';
    }

    return Uri.decodeComponent(uri.pathSegments.last);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudentWorkspaceAppBar(
          title: widget.isEditMode
              ? 'Edit Idea'
              : widget.isAdmin
              ? 'Publish Idea'
              : 'Create Idea',
          subtitle: widget.isEditMode
              ? 'Refine the concept, details, and team signals before updating.'
              : 'Shape your idea clearly so it feels strong the moment it is submitted.',
          icon: widget.isEditMode
              ? Icons.edit_rounded
              : Icons.lightbulb_rounded,
          showBackButton: true,
          onBack: () => Navigator.maybePop(context),
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
                : AppPrimaryButton(
                    theme: _theme,
                    label: _isUploadingImage
                        ? 'Uploading cover image...'
                        : _isLocked
                        ? 'Editing locked after review'
                        : widget.isEditMode
                        ? 'Save Changes'
                        : widget.isAdmin
                        ? 'Publish Idea'
                        : 'Submit Idea',
                    onPressed: _isUploadingImage ? null : _submit,
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
                if (widget.isAdmin) ...[
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Publish',
                    subtitle:
                        'Keep visibility decisions in the same structured publishing area used across content flows.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AdminChoiceCard(
                                label: 'Visible',
                                subtitle: 'Show in discovery',
                                selected: _adminStatus == 'approved',
                                icon: Icons.visibility_outlined,
                                onTap: () =>
                                    setState(() => _adminStatus = 'approved'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AdminChoiceCard(
                                label: 'Hidden',
                                subtitle: 'Keep out of discovery',
                                selected: _adminStatus == 'rejected',
                                icon: Icons.visibility_off_outlined,
                                onTap: () =>
                                    setState(() => _adminStatus = 'rejected'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Idea Basics',
                  subtitle:
                      'Set the core headline, category, and stage so the idea reads clearly from the start.',
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
                        hint:
                            'A smarter way for students to find support fast.',
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
                      AppFormDropdownField<String>(
                        theme: _theme,
                        value: _selectedLevel,
                        label: 'Best suited for',
                        hint: 'Select student level',
                        items: const [
                          DropdownMenuItem(
                            value: 'bac',
                            child: Text('Bachelor'),
                          ),
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
                  title: 'Idea Description',
                  subtitle:
                      'Explain the concept, the problem behind it, and the solution you want collaborators to understand.',
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
                  title: 'Collaboration',
                  subtitle:
                      'Show the roles, skills, and resources that will help this idea move forward.',
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
                  title: 'Optional Extras',
                  subtitle:
                      'Add the supporting materials, visibility settings, and attachments that make the post feel complete.',
                  child: Column(
                    children: [
                      _buildImageUploadCard(),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _attachmentUrlController,
                        label: 'Deck / Demo Link',
                        hint: 'Figma, Notion, pitch deck, landing page...',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: InnovationHubPalette.cardTint,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: InnovationHubPalette.border,
                          ),
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
      ),
    );
  }

  Widget _buildImageUploadCard() {
    final hasImage = _imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            InnovationHubPalette.cardTint,
            InnovationHubPalette.searchTint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InnovationHubPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: InnovationHubPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: InnovationHubPalette.primary.withValues(
                        alpha: 0.16,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.image_outlined, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasImage ? 'Cover image ready' : 'Upload a cover image',
                      style: InnovationHubTypography.label(
                        color: InnovationHubPalette.textPrimary,
                        size: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasImage
                          ? 'Your idea now has a visual header that will show across Discover, My Ideas, and the details view.'
                          : 'Choose a JPG, PNG, or WebP image to make the idea feel polished from the first glance.',
                      style: InnovationHubTypography.body(size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 170,
                  alignment: Alignment.center,
                  color: Colors.white,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: InnovationHubPalette.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: InnovationHubPalette.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: InnovationHubPalette.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _uploadedImageName.isNotEmpty
                          ? _uploadedImageName
                          : 'Cover image uploaded',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InnovationHubTypography.body(
                        color: InnovationHubPalette.textPrimary,
                        size: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: InnovationHubPalette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: InnovationHubPalette.secondary.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: InnovationHubPalette.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A strong visual makes the featured cards and detail hero feel much more alive.',
                      style: InnovationHubTypography.body(
                        color: InnovationHubPalette.textPrimary,
                        size: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InnovationHubPalette.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: InnovationHubPalette.primary
                        .withValues(alpha: 0.36),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          hasImage
                              ? Icons.refresh_rounded
                              : Icons.file_upload_outlined,
                        ),
                  label: Text(
                    _isUploadingImage
                        ? 'Uploading...'
                        : hasImage
                        ? 'Change image'
                        : 'Upload image',
                    style: InnovationHubTypography.label(
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isUploadingImage ? null : _removeImage,
                  child: Text(
                    'Remove',
                    style: InnovationHubTypography.label(
                      color: InnovationHubPalette.error,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Best results: 16:9 cover, under 5 MB.',
            style: InnovationHubTypography.body(size: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return AppFormHeaderCard(
      theme: _theme,
      icon: widget.isEditMode ? Icons.edit_rounded : Icons.lightbulb_outline,
      title: widget.isEditMode
          ? 'Refine your idea'
          : widget.isAdmin
          ? 'Publish an idea'
          : 'Launch your next breakthrough',
      subtitle: widget.isAdmin
          ? 'Add a platform-curated idea with a strong story, clear metadata, and a predictable posting structure.'
          : 'Build an idea profile that feels ready for collaborators, feedback, and student momentum.',
      badges: <AppBadgeData>[
        AppBadgeData(
          label: _selectedCategory,
          icon: innovationCategoryIcon(_selectedCategory),
          color: _theme.accent,
        ),
        AppBadgeData(
          label: _selectedStage,
          icon: Icons.timeline_rounded,
          color: innovationStageColor(_selectedStage),
        ),
      ],
      footer: Row(
        children: <Widget>[
          Expanded(
            child: AppMetaRow(
              theme: _theme,
              label: 'Visibility',
              value: _isPublic ? 'Public-ready' : 'Private draft',
              icon: _isPublic
                  ? Icons.public_rounded
                  : Icons.lock_outline_rounded,
            ),
          ),
          Expanded(
            child: AppMetaRow(
              theme: _theme,
              label: 'Focus',
              value: academicLevelLabel(_selectedLevel),
              icon: Icons.school_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockNotice() {
    return AppInfoHint(
      theme: _theme,
      icon: Icons.lock_outline_rounded,
      title: 'Editing locked',
      message:
          'Only pending ideas can be edited. This idea has already moved past review, so the form is shown in locked mode.',
    );
  }

  Widget _buildChoiceGroup({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return AppChoiceWrap(
      theme: _theme,
      title: title,
      values: values,
      selectedValue: selected,
      onSelected: onSelected,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
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
    return AppFormSectionCard(
      theme: context.findAncestorStateOfType<_CreateIdeaScreenState>()!._theme,
      title: title,
      subtitle: subtitle,
      child: child,
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
    return AppFormField(
      theme: state!._theme,
      controller: controller,
      label: label,
      hint: hint,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
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
    final state = context.findAncestorStateOfType<_CreateIdeaScreenState>();
    return AppChipSelector(
      theme: state!._theme,
      title: title,
      suggestions: suggestions,
      selectedValues: selectedValues,
      onToggle: onToggle,
    );
  }
}

class _AdminChoiceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminChoiceCard({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CreateIdeaScreenState>();
    return AppChoiceCard(
      theme: state!._theme,
      label: label,
      subtitle: subtitle,
      selected: selected,
      icon: icon,
      onTap: onTap,
    );
  }
}
