import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../services/file_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_controller.dart';
import '../../utils/content_language.dart';
import '../settings/settings_flow_theme.dart';
import '../settings/settings_flow_widgets.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/ideas/project_idea_cover_image.dart';
import '../../widgets/ideas/innovation_hub_theme.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';

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
  late final TextEditingController _categoryController;
  late final TextEditingController _stageController;

  late String _selectedCategory;
  late String _selectedStage;
  late String _selectedLevel;
  late String _originalLanguage;
  late bool _isPublic;
  late bool _adminIsHidden;
  late Set<String> _selectedSkills;
  late Set<String> _selectedRoles;
  late String _imageUrl;
  late String _uploadedImageName;
  bool _isUploadingImage = false;
  late String _adminStatus;

  bool get _shouldResubmitAfterEdit =>
      !widget.isAdmin &&
      widget.isEditMode &&
      (widget.idea?.shouldResubmitAfterEdit ?? false);

  bool get _isLocked =>
      !widget.isAdmin &&
      widget.isEditMode &&
      !(widget.idea?.canOwnerEdit ?? false);

  AppContentTheme get _theme => AppContentTheme.futureGate(
    accent: InnovationHubPalette.primary,
    accentDark: InnovationHubPalette.primaryDark,
    accentSoft: InnovationHubPalette.cardTint,
    secondary: InnovationHubPalette.secondary,
    heroGradient: InnovationHubPalette.primaryGradient,
    typography: AppContentTypography.product,
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
    _originalLanguage = ContentLanguage.normalizeCode(
      idea?.originalLanguage,
      fallback: ContentLanguage.normalizeCode(
        LocaleController.activeLanguageCode,
        fallback: 'fr',
      ),
    );
    _isPublic = idea?.isPublic ?? true;
    _adminIsHidden =
        (idea?.isHidden ?? false) ||
        (widget.isAdmin && idea?.status == 'rejected');
    _selectedSkills = {...?idea?.displaySkills};
    _selectedRoles = {...?idea?.displayTeamNeeded};
    _categoryController = TextEditingController(text: _selectedCategory);
    _stageController = TextEditingController(text: _selectedStage);
    _imageUrl = (idea?.imageUrl ?? '').trim();
    _uploadedImageName = _deriveImageLabel(_imageUrl);
    _adminStatus = idea?.status == 'pending' ? 'pending' : 'approved';
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
    _categoryController.dispose();
    _stageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLocked) {
      return;
    }
    if (_isUploadingImage) {
      context.showAppSnackBar(
        'Please wait for the cover image upload to finish.',
        title: AppLocalizations.of(context)!.uiUploadInProgress,
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
    final shouldResubmit = _shouldResubmitAfterEdit;

    final String? error;

    if (widget.isAdmin) {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'tagline': tagline,
        'shortDescription': tagline.isNotEmpty ? tagline : description,
        'description': description,
        'domain': category,
        'level': _selectedLevel,
        'originalLanguage': _originalLanguage,
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
        'isHidden': _adminIsHidden,
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
        originalLanguage: _originalLanguage,
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
        status: shouldResubmit ? 'pending' : null,
        isHidden: shouldResubmit ? false : null,
      );
    } else {
      error = await provider.submitProjectIdea(
        title: _titleController.text.trim(),
        description: description,
        domain: category,
        level: _selectedLevel,
        originalLanguage: _originalLanguage,
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
      final l10n = AppLocalizations.of(context)!;
      context.showAppSnackBar(
        _shouldResubmitAfterEdit
            ? l10n.studentIdeaResubmittedSuccess
            : widget.isEditMode
            ? l10n.ideaUpdatedMessage
            : widget.isAdmin
            ? l10n.ideaPublishedMessage
            : l10n.ideaSubmittedMessage,
        title: _shouldResubmitAfterEdit
            ? l10n.studentIdeaResubmittedTitle
            : widget.isEditMode
            ? l10n.ideaUpdatedTitle
            : widget.isAdmin
            ? l10n.ideaPublishedTitle
            : l10n.ideaSubmittedTitle,
        type: AppFeedbackType.success,
      );
      Navigator.pop(context, true);
      return;
    }

    context.showAppSnackBar(
      error,
      title: AppLocalizations.of(context)!.uiSubmissionUnavailable,
      type: AppFeedbackType.error,
    );
  }

  void _commitCustomEntries() {
    _addEntriesToSet(
      controller: _customSkillsController,
      values: _selectedSkills,
    );
    _addEntriesToSet(
      controller: _customRolesController,
      values: _selectedRoles,
    );
  }

  void _addEntriesToSet({
    required TextEditingController controller,
    required Set<String> values,
  }) {
    for (final rawValue in controller.text.split(',')) {
      final trimmed = rawValue.trim();
      if (trimmed.isNotEmpty) {
        values.add(trimmed);
      }
    }
    controller.clear();
  }

  void _addCustomSkills() {
    setState(() {
      _addEntriesToSet(
        controller: _customSkillsController,
        values: _selectedSkills,
      );
    });
  }

  void _addCustomRoles() {
    setState(() {
      _addEntriesToSet(
        controller: _customRolesController,
        values: _selectedRoles,
      );
    });
  }

  Future<void> _pickCategory() async {
    final value = await _showOptionPicker(
      title: AppLocalizations.of(context)!.uiSelectCategory,
      options: innovationHubDefaultCategories,
      currentValue: _selectedCategory,
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() {
      _selectedCategory = value;
      _categoryController.text = value;
    });
  }

  Future<void> _pickStage() async {
    final value = await _showOptionPicker(
      title: AppLocalizations.of(context)!.uiSelectStage,
      options: innovationHubStageOptions,
      currentValue: _selectedStage,
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() {
      _selectedStage = value;
      _stageController.text = value;
    });
  }

  Future<String?> _showOptionPicker({
    required String title,
    required List<String> options,
    required String currentValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.current.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SettingsFlowPalette.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: SettingsFlowTheme.sectionTitle()),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.chooseOneOptionLabel,
                    style: SettingsFlowTheme.caption(),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == currentValue;
                        return InkWell(
                          borderRadius: SettingsFlowTheme.radius(18),
                          onTap: () => Navigator.of(context).pop(option),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SettingsFlowPalette.primary.withValues(
                                      alpha: 0.08,
                                    )
                                  : SettingsFlowPalette.surface,
                              borderRadius: SettingsFlowTheme.radius(18),
                              border: Border.all(
                                color: isSelected
                                    ? SettingsFlowPalette.primary.withValues(
                                        alpha: 0.18,
                                      )
                                    : SettingsFlowPalette.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: SettingsFlowTheme.body(
                                      isSelected
                                          ? SettingsFlowPalette.primary
                                          : SettingsFlowPalette.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: SettingsFlowPalette.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _cvStyleInputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: SettingsFlowPalette.textSecondary,
      ),
      suffixIcon: suffixIcon,
      labelStyle: SettingsFlowTheme.caption(),
      hintStyle: SettingsFlowTheme.caption(
        SettingsFlowPalette.textSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: SettingsFlowPalette.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SettingsFlowPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SettingsFlowPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SettingsFlowPalette.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SettingsFlowPalette.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SettingsFlowPalette.error, width: 1.5),
      ),
    );
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
        AppLocalizations.of(context)!.ideaUploadSizeMessage,
        title: AppLocalizations.of(context)!.uiUploadUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.loginRequiredUploadMessage,
        title: AppLocalizations.of(context)!.uiLoginRequired,
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
        AppLocalizations.of(context)!.studentIdeaCoverUploadedSuccess,
        title: AppLocalizations.of(context)!.uiUploadComplete,
        type: AppFeedbackType.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isUploadingImage = false);
      context.showAppSnackBar(
        _formatUploadError(error),
        title: AppLocalizations.of(context)!.uiUploadUnavailable,
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
      return AppLocalizations.of(context)!.studentIdeaImageUploadFailed;
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

  String get _screenTitle => widget.isEditMode
      ? AppLocalizations.of(context)!.uiEditIdea
      : widget.isAdmin
      ? AppLocalizations.of(context)!.studentPublishIdeaButton
      : AppLocalizations.of(context)!.studentCreateIdeaTitle;

  PreferredSizeWidget _buildSettingsStyleAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: SettingsFlowPalette.textPrimary,
        ),
      ),
      title: Text(_screenTitle, style: SettingsFlowTheme.appBarTitle()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();
    final l10n = AppLocalizations.of(context)!;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildSettingsStyleAppBar(),
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
                        ? l10n.studentUploadingCoverImage
                        : _isLocked
                        ? l10n.studentEditingLockedAfterReview
                        : _shouldResubmitAfterEdit
                        ? l10n.studentPublishAgain
                        : widget.isEditMode
                        ? l10n.saveChangesLabel
                        : widget.isAdmin
                        ? l10n.studentPublishIdeaButton
                        : l10n.studentSubmitIdea,
                    onPressed: _isUploadingImage ? null : _submit,
                  ),
          ),
        ),
        body: AbsorbPointer(
          absorbing: _isLocked,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    title: AppLocalizations.of(context)!.uiPublish,
                    subtitle: l10n
                        .uiKeepVisibilityDecisionsInTheSameStructuredPublishingAreaUsed,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AdminChoiceCard(
                                label: AppLocalizations.of(context)!.uiVisible,
                                subtitle: AppLocalizations.of(
                                  context,
                                )!.uiShowInDiscovery,
                                selected: !_adminIsHidden,
                                icon: Icons.visibility_outlined,
                                onTap: () => setState(() {
                                  _adminIsHidden = false;
                                  _adminStatus = 'approved';
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AdminChoiceCard(
                                label: AppLocalizations.of(
                                  context,
                                )!.uiHiddenLabel,
                                subtitle: AppLocalizations.of(
                                  context,
                                )!.uiKeepOutOfDiscovery,
                                selected: _adminIsHidden,
                                icon: Icons.visibility_off_outlined,
                                onTap: () => setState(() {
                                  _adminIsHidden = true;
                                  _adminStatus = 'approved';
                                }),
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
                  title: AppLocalizations.of(context)!.uiIdeaBasics,
                  subtitle: l10n.uiSetTheCoreHeadlineCategoryAndStageSoTheIdea,
                  child: Column(
                    children: [
                      _StyledField(
                        controller: _titleController,
                        label: AppLocalizations.of(context)!.uiIdeaTitle,
                        hint: l10n.studentIdeaTitleHint,
                        helper: l10n.studentIdeaTitleHelper,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _taglineController,
                        label: AppLocalizations.of(context)!.uiShortTagline,
                        hint: l10n.studentIdeaTaglineHint,
                        helper: l10n.studentIdeaTaglineHelper,
                      ),
                      const SizedBox(height: 18),
                      _CvSingleSelectField(
                        title: AppLocalizations.of(context)!.uiCategory,
                        controller: _categoryController,
                        fieldLabel: l10n.studentChooseCategory,
                        hint: l10n.studentPickIdeaCategory,
                        prefixIcon: Icons.category_outlined,
                        onTap: _pickCategory,
                      ),
                      const SizedBox(height: 18),
                      _CvSingleSelectField(
                        title: AppLocalizations.of(context)!.uiStage,
                        controller: _stageController,
                        fieldLabel: l10n.studentChooseStage,
                        hint: l10n.studentPickCurrentStage,
                        prefixIcon: Icons.timeline_rounded,
                        onTap: _pickStage,
                      ),
                      const SizedBox(height: 18),
                      AppFormDropdownField<String>(
                        theme: _theme,
                        value: _selectedLevel,
                        label: AppLocalizations.of(context)!.uiBestSuitedFor,
                        hint: l10n.studentSelectStudentLevel,
                        items: [
                          DropdownMenuItem(
                            value: 'bac',
                            child: Text(
                              AppLocalizations.of(context)!.uiBachelor,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'licence',
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.academicLevelLicence,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'master',
                            child: Text(
                              AppLocalizations.of(context)!.academicLevelMaster,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'doctorat',
                            child: Text(
                              AppLocalizations.of(context)!.uiDoctorate,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      AppFormDropdownField<String>(
                        theme: _theme,
                        value: _originalLanguage,
                        label: AppLocalizations.of(
                          context,
                        )!.originalLanguageFieldLabel,
                        hint: AppLocalizations.of(
                          context,
                        )!.originalLanguageFieldHint,
                        items: [
                          DropdownMenuItem(
                            value: 'fr',
                            child: Text(
                              AppLocalizations.of(context)!.languageFrench,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(
                              AppLocalizations.of(context)!.languageEnglish,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text(
                              AppLocalizations.of(context)!.languageArabic,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _originalLanguage = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: AppLocalizations.of(context)!.uiIdeaDescription,
                  subtitle: l10n.studentIdeaDescriptionSubtitle,
                  child: Column(
                    children: [
                      _StyledField(
                        controller: _overviewController,
                        label: AppLocalizations.of(context)!.uiIdeaOverview,
                        hint: l10n.studentIdeaOverviewHint,
                        helper: l10n.studentIdeaOverviewHelper,
                        minLength: 60,
                        validator: _descriptionValidator,
                        minLines: 4,
                        maxLines: 6,
                      ),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _problemController,
                        label: AppLocalizations.of(context)!.uiProblemStatement,
                        hint: l10n.studentIdeaProblemHint,
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _solutionController,
                        label: AppLocalizations.of(context)!.uiSolution,
                        hint: l10n.studentIdeaSolutionHint,
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _audienceController,
                        label: AppLocalizations.of(context)!.uiTargetAudience,
                        hint: l10n.studentIdeaAudienceHint,
                      ),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _benefitsController,
                        label: AppLocalizations.of(
                          context,
                        )!.uiBenefitsAndImpact,
                        hint: l10n.studentIdeaBenefitsHint,
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: AppLocalizations.of(context)!.uiCollaboration,
                  subtitle:
                      l10n.uiShowTheRolesSkillsAndResourcesThatWillHelpThis,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectionWrap(
                        title: AppLocalizations.of(context)!.uiTeamNeeded,
                        selectedValues: _selectedRoles,
                        controller: _customRolesController,
                        fieldLabel: l10n.studentAddRole,
                        hint: l10n.studentAddRoleHint,
                        helper: l10n.studentAddRoleHelper,
                        prefixIcon: Icons.groups_2_outlined,
                        onSubmitted: _addCustomRoles,
                        onDelete: (value) {
                          setState(() => _selectedRoles.remove(value));
                        },
                      ),
                      const SizedBox(height: 18),
                      _SelectionWrap(
                        title: AppLocalizations.of(context)!.uiSkillsNeeded,
                        selectedValues: _selectedSkills,
                        controller: _customSkillsController,
                        fieldLabel: l10n.uiAddASkill,
                        hint: l10n.studentAddSkillHint,
                        helper: l10n.studentAddSkillHelper,
                        prefixIcon: Icons.auto_awesome_outlined,
                        onSubmitted: _addCustomSkills,
                        onDelete: (value) {
                          setState(() => _selectedSkills.remove(value));
                        },
                      ),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _resourcesController,
                        label: AppLocalizations.of(context)!.uiResourcesNeeds,
                        hint: l10n.studentResourcesHint,
                        helper: l10n.studentResourcesHelper,
                        minLines: 3,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: AppLocalizations.of(context)!.uiOptionalExtras,
                  subtitle: l10n
                      .uiAddTheSupportingMaterialsVisibilitySettingsAndAttachmentsThatMake,
                  child: Column(
                    children: [
                      _buildImageUploadCard(),
                      const SizedBox(height: 14),
                      _StyledField(
                        controller: _attachmentUrlController,
                        label: AppLocalizations.of(context)!.uiDeckDemoLink,
                        hint: l10n.deckDemoLinkHint,
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
        gradient: LinearGradient(
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
                      hasImage
                          ? AppLocalizations.of(context)!.coverImageReadyTitle
                          : AppLocalizations.of(context)!.uploadCoverImageTitle,
                      style: _theme.label(
                        color: InnovationHubPalette.textPrimary,
                        size: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasImage
                          ? AppLocalizations.of(
                              context,
                            )!.coverImageReadySubtitle
                          : AppLocalizations.of(
                              context,
                            )!.uploadCoverImageSubtitle,
                      style: _theme.body(size: 12.5),
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
              child: ProjectIdeaCoverImage(
                imageUrl: _imageUrl,
                ideaId: widget.idea?.id ?? '',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholderColor: AppColors.current.surfaceMuted,
                iconColor: InnovationHubPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.current.surfaceElevated.withValues(
                  alpha: AppColors.isDark ? 0.96 : 0.82,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: InnovationHubPalette.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: InnovationHubPalette.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _uploadedImageName.isNotEmpty
                          ? _uploadedImageName
                          : AppLocalizations.of(
                              context,
                            )!.coverImageUploadedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _theme.body(
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
                color: AppColors.current.surfaceElevated.withValues(
                  alpha: AppColors.isDark ? 0.96 : 0.74,
                ),
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
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: InnovationHubPalette.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.strongVisualHint,
                      style: _theme.body(
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
                        ? AppLocalizations.of(context)!.studentUploadingEllipsis
                        : hasImage
                        ? AppLocalizations.of(context)!.changeImageLabel
                        : AppLocalizations.of(context)!.uploadImageLabel,
                    style: _theme.label(color: Colors.white, size: 13),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isUploadingImage ? null : _removeImage,
                  child: Text(
                    AppLocalizations.of(context)!.removeLabel,
                    style: _theme.label(
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
            AppLocalizations.of(context)!.bestResultsImageHint,
            style: _theme.body(size: 12.5),
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
          ? (_shouldResubmitAfterEdit
                ? AppLocalizations.of(context)!.studentRefineAndPublishAgain
                : AppLocalizations.of(context)!.refineIdeaTitle)
          : widget.isAdmin
          ? AppLocalizations.of(context)!.publishIdeaTitle
          : AppLocalizations.of(context)!.launchBreakthroughTitle,
      subtitle: widget.isAdmin
          ? AppLocalizations.of(context)!.studentAdminPublishIdeaSubtitle
          : _shouldResubmitAfterEdit
          ? AppLocalizations.of(context)!.studentResubmitIdeaSubtitle
          : AppLocalizations.of(context)!.studentIdeaHeroSubtitle,
    );
  }

  Widget _buildLockNotice() {
    return AppInfoHint(
      theme: _theme,
      icon: Icons.lock_outline_rounded,
      title: AppLocalizations.of(context)!.uiEditingLocked,
      message: AppLocalizations.of(context)!.studentIdeaLockNotice,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.validationFieldRequired;
    }
    return null;
  }

  String? _descriptionValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return AppLocalizations.of(context)!.validationFieldRequired;
    }
    if (text.length < 60) {
      return AppLocalizations.of(context)!.studentPleaseAddMoreDetail;
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
  final String? helper;
  final int minLines;
  final int maxLines;
  final int? minLength;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.helper,
    this.minLines = 1,
    this.maxLines = 1,
    this.minLength,
    this.validator,
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
      minLength: minLength,
      helperText: helper,
    );
  }
}

class _CvSingleSelectField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String fieldLabel;
  final String hint;
  final IconData prefixIcon;
  final VoidCallback onTap;

  const _CvSingleSelectField({
    required this.title,
    required this.controller,
    required this.fieldLabel,
    required this.hint,
    required this.prefixIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CreateIdeaScreenState>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SettingsFlowTheme.sectionTitle()),
        const SizedBox(height: 10),
        SettingsPanel(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: SettingsFlowTheme.body(),
            decoration: state._cvStyleInputDecoration(
              label: fieldLabel,
              hint: hint,
              prefixIcon: prefixIcon,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: SettingsFlowPalette.primary,
                ),
                onPressed: onTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionWrap extends StatelessWidget {
  final String title;
  final Set<String> selectedValues;
  final TextEditingController controller;
  final String fieldLabel;
  final String hint;
  final String? helper;
  final IconData prefixIcon;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onDelete;

  const _SelectionWrap({
    required this.title,
    required this.selectedValues,
    required this.controller,
    required this.fieldLabel,
    required this.hint,
    this.helper,
    required this.prefixIcon,
    required this.onSubmitted,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CreateIdeaScreenState>()!;
    final helperText = helper?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SettingsFlowTheme.sectionTitle()),
        const SizedBox(height: 10),
        SettingsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedValues.isNotEmpty) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedValues
                          .map(
                            (value) => _CvValueChip(
                              label: value,
                              maxWidth: constraints.maxWidth,
                              onDelete: () => onDelete(value),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: controller,
                style: SettingsFlowTheme.body(),
                decoration: state._cvStyleInputDecoration(
                  label: fieldLabel,
                  hint: hint,
                  prefixIcon: prefixIcon,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: SettingsFlowPalette.primary,
                    ),
                    onPressed: onSubmitted,
                  ),
                ),
                onFieldSubmitted: (_) => onSubmitted(),
              ),
            ],
          ),
        ),
        if (helperText != null && helperText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: SettingsFlowTheme.caption(SettingsFlowPalette.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _CvValueChip extends StatelessWidget {
  final String label;
  final double maxWidth;
  final VoidCallback onDelete;

  const _CvValueChip({
    required this.label,
    required this.maxWidth,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
          borderRadius: SettingsFlowTheme.radius(10),
          border: Border.all(
            color: SettingsFlowPalette.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: SettingsFlowTheme.caption(SettingsFlowPalette.primary),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: SettingsFlowPalette.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
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
