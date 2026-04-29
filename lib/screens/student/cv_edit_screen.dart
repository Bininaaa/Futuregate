import 'dart:async';

import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';
import '../../widgets/shared/app_directional.dart';
import '../../widgets/shared/app_feedback.dart';

class CvEditScreen extends StatefulWidget {
  const CvEditScreen({super.key});

  @override
  State<CvEditScreen> createState() => _CvEditScreenState();
}

class _CvEditScreenState extends State<CvEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillInputController = TextEditingController();
  final _languageInputController = TextEditingController();
  final _personalKey = GlobalKey();
  final _summaryKey = GlobalKey();
  final _educationKey = GlobalKey();
  final _experienceKey = GlobalKey();
  final _skillsKey = GlobalKey();
  final _languagesKey = GlobalKey();

  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _experience = [];
  List<String> _skills = [];
  List<String> _languages = [];

  bool _initialized = false;
  bool _isHydrating = false;
  bool _isAutosaving = false;
  bool _hasPendingAutosave = false;
  bool _saveAgainAfterCurrent = false;
  bool _hasExistingCv = false;
  bool _allowPop = false;
  String _templateId = '';
  String? _lastSavedSignature;
  String? _autosaveError;
  Timer? _autosaveDebounce;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_handleFormChanged);
    _emailController.addListener(_handleFormChanged);
    _phoneController.addListener(_handleFormChanged);
    _addressController.addListener(_handleFormChanged);
    _summaryController.addListener(_handleFormChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final cv = context.read<CvProvider>().cv;
      final user = context.read<AuthProvider>().userModel;

      _isHydrating = true;
      if (cv != null) {
        _hasExistingCv = true;
        _templateId = cv.templateId;
        _fullNameController.text = cv.fullName;
        _emailController.text = cv.email;
        _phoneController.text = cv.phone;
        _addressController.text = cv.address;
        _summaryController.text = cv.summary;
        _skills = List.from(cv.skills);
        _languages = List.from(cv.languages);
        _education = List.from(cv.education);
        _experience = List.from(cv.experience);
      } else if (user != null) {
        _fullNameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
      }

      _lastSavedSignature = _snapshotSignature();
      _isHydrating = false;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    _fullNameController.removeListener(_handleFormChanged);
    _emailController.removeListener(_handleFormChanged);
    _phoneController.removeListener(_handleFormChanged);
    _addressController.removeListener(_handleFormChanged);
    _summaryController.removeListener(_handleFormChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _skillInputController.dispose();
    _languageInputController.dispose();
    super.dispose();
  }

  void _handleFormChanged() {
    if (!mounted || _isHydrating) return;
    setState(() {});
    _scheduleAutosave();
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: SettingsFlowPalette.textSecondary)
          : null,
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
    );
  }

  String _snapshotSignature() {
    String encodeMapList(List<Map<String, dynamic>> items) {
      return items
          .map(
            (item) => [
              item['degree'],
              item['institution'],
              item['year'],
              item['position'],
              item['company'],
              item['duration'],
            ].map((value) => (value ?? '').toString().trim()).join('|'),
          )
          .join('||');
    }

    return [
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _addressController.text.trim(),
      _summaryController.text.trim(),
      encodeMapList(_education),
      encodeMapList(_experience),
      _skills.map((value) => value.trim()).join('|'),
      _languages.map((value) => value.trim()).join('|'),
      _templateId.trim(),
    ].join('###');
  }

  bool _hasAnyCvContent() {
    return _fullNameController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _summaryController.text.trim().isNotEmpty ||
        _education.isNotEmpty ||
        _experience.isNotEmpty ||
        _skills.isNotEmpty ||
        _languages.isNotEmpty;
  }

  void _scheduleAutosave({bool immediate = false}) {
    if (!_initialized || _isHydrating) return;

    final signature = _snapshotSignature();
    if (signature == _lastSavedSignature) {
      if (_hasPendingAutosave && mounted) {
        setState(() => _hasPendingAutosave = false);
      }
      return;
    }

    if (!_hasAnyCvContent() && !_hasExistingCv) {
      return;
    }

    _autosaveDebounce?.cancel();
    if (mounted) {
      setState(() {
        _hasPendingAutosave = true;
        _autosaveError = null;
      });
    }

    if (immediate) {
      unawaited(_performAutosave());
      return;
    }

    _autosaveDebounce = Timer(
      const Duration(milliseconds: 750),
      _performAutosave,
    );
  }

  Future<void> _performAutosave() async {
    _autosaveDebounce?.cancel();

    if (_isAutosaving) {
      _saveAgainAfterCurrent = true;
      return;
    }

    final signature = _snapshotSignature();
    if (signature == _lastSavedSignature ||
        (!_hasAnyCvContent() && !_hasExistingCv)) {
      if (mounted) {
        setState(() => _hasPendingAutosave = false);
      }
      return;
    }

    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    if (mounted) {
      setState(() {
        _isAutosaving = true;
        _hasPendingAutosave = false;
        _autosaveError = null;
      });
    }

    final error = await context.read<CvProvider>().saveCv(
      studentId: uid,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      summary: _summaryController.text.trim(),
      education: _education,
      experience: _experience,
      skills: _skills,
      languages: _languages,
      templateId: _templateId,
    );

    if (!mounted) return;

    if (error == null) {
      _hasExistingCv = true;
      _lastSavedSignature = signature;
      setState(() => _isAutosaving = false);

      if (_saveAgainAfterCurrent || _snapshotSignature() != signature) {
        _saveAgainAfterCurrent = false;
        _scheduleAutosave(immediate: true);
      }
      return;
    }

    setState(() {
      _isAutosaving = false;
      _autosaveError = error;
      _hasPendingAutosave = true;
    });

    context.showAppSnackBar(
      error,
      title: AppLocalizations.of(context)!.uiSaveUnavailable,
      type: AppFeedbackType.error,
    );
  }

  Future<void> _flushAutosave() async {
    _autosaveDebounce?.cancel();
    while (_isAutosaving && mounted) {
      _saveAgainAfterCurrent = true;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    await _performAutosave();
  }

  Future<void> _handleLeave() async {
    if (_allowPop) return;
    await _flushAutosave();
    if (!mounted) return;
    _allowPop = true;
    Navigator.of(context).pop();
  }

  String _autosaveStatusLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_autosaveError != null) return l10n.studentSaveFailed;
    if (_isAutosaving) return l10n.studentSavingEllipsis;
    if (_hasPendingAutosave) return l10n.studentUnsaved;
    return l10n.uiSaved;
  }

  Color _autosaveStatusColor() {
    if (_autosaveError != null) return SettingsFlowPalette.error;
    if (_isAutosaving || _hasPendingAutosave) {
      return SettingsFlowPalette.warning;
    }
    return SettingsFlowPalette.success;
  }

  List<_BuilderGuideStep> _builderGuideSteps() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _BuilderGuideStep(
        key: _personalKey,
        label: l10n.uiBasicInformation,
        icon: Icons.badge_outlined,
        isComplete:
            _fullNameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty,
      ),
      _BuilderGuideStep(
        key: _summaryKey,
        label: l10n.uiSummary,
        icon: Icons.subject_rounded,
        isComplete: _summaryController.text.trim().isNotEmpty,
      ),
      _BuilderGuideStep(
        key: _educationKey,
        label: l10n.uiEducation,
        icon: Icons.school_outlined,
        isComplete: _education.isNotEmpty,
      ),
      _BuilderGuideStep(
        key: _experienceKey,
        label: l10n.uiExperience,
        icon: Icons.work_outline,
        isComplete: _experience.isNotEmpty,
      ),
      _BuilderGuideStep(
        key: _skillsKey,
        label: l10n.uiSkills,
        icon: Icons.auto_awesome_outlined,
        isComplete: _skills.isNotEmpty,
      ),
      _BuilderGuideStep(
        key: _languagesKey,
        label: l10n.uiLanguages,
        icon: Icons.translate_outlined,
        isComplete: _languages.isNotEmpty,
      ),
    ];
  }

  void _scrollToSection(GlobalKey key) {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildBuilderGuide() {
    final steps = _builderGuideSteps();
    final completed = steps.where((step) => step.isComplete).length;
    final progress = completed / steps.length;

    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.studentCvBuilderSteps,
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.studentCvSectionsComplete(completed, steps.length),
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              SettingsStatusPill(
                label: _autosaveStatusLabel(),
                color: _autosaveStatusColor(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: SettingsFlowTheme.radius(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: SettingsFlowPalette.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.75
                    ? SettingsFlowPalette.success
                    : SettingsFlowPalette.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: steps
                .map(
                  (step) => _BuilderStepChip(
                    step: step,
                    onPressed: () => _scrollToSection(step.key),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Skills / Languages ──────────────────────────────────────────────────

  void _addSkill() {
    final text = _skillInputController.text.trim();
    if (text.isEmpty) return;
    var changed = false;
    setState(() {
      for (final item
          in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        if (!_skills.contains(item)) {
          _skills.add(item);
          changed = true;
        }
      }
      _skillInputController.clear();
    });
    if (changed) _scheduleAutosave();
  }

  void _addLanguage() {
    final text = _languageInputController.text.trim();
    if (text.isEmpty) return;
    var changed = false;
    setState(() {
      for (final item
          in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        if (!_languages.contains(item)) {
          _languages.add(item);
          changed = true;
        }
      }
      _languageInputController.clear();
    });
    if (changed) _scheduleAutosave();
  }

  void _removeSkill(int index) {
    setState(() => _skills.removeAt(index));
    _scheduleAutosave();
  }

  void _removeLanguage(int index) {
    setState(() => _languages.removeAt(index));
    _scheduleAutosave();
  }

  void _removeEducation(int index) {
    setState(() => _education.removeAt(index));
    _scheduleAutosave();
  }

  void _removeExperience(int index) {
    setState(() => _experience.removeAt(index));
    _scheduleAutosave();
  }

  // ── Education CRUD ──────────────────────────────────────────────────────

  void _addOrEditEducation({int? editIndex}) {
    final isEdit = editIndex != null;
    final degreeCtrl = TextEditingController(
      text: isEdit ? (_education[editIndex]['degree'] ?? '') : '',
    );
    final institutionCtrl = TextEditingController(
      text: isEdit ? (_education[editIndex]['institution'] ?? '') : '',
    );
    final yearCtrl = TextEditingController(
      text: isEdit ? (_education[editIndex]['year'] ?? '') : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsFlowPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit
                  ? AppLocalizations.of(context)!.studentEditEducation
                  : AppLocalizations.of(context)!.studentAddEducationTitle,
              style: SettingsFlowTheme.sectionTitle(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: degreeCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: AppLocalizations.of(context)!.uiDegree,
                prefixIcon: Icons.school_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: institutionCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: AppLocalizations.of(context)!.uiInstitution,
                prefixIcon: Icons.business_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: AppLocalizations.of(context)!.uiYear,
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: isEdit
                  ? AppLocalizations.of(context)!.studentUpdate
                  : AppLocalizations.of(context)!.uiAdd,
              onPressed: () {
                if (degreeCtrl.text.trim().isEmpty) return;
                setState(() {
                  final entry = {
                    'degree': degreeCtrl.text.trim(),
                    'institution': institutionCtrl.text.trim(),
                    'year': yearCtrl.text.trim(),
                  };
                  if (isEdit) {
                    _education[editIndex] = entry;
                  } else {
                    _education.add(entry);
                  }
                });
                _scheduleAutosave();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Experience CRUD ─────────────────────────────────────────────────────

  void _addOrEditExperience({int? editIndex}) {
    final isEdit = editIndex != null;
    final positionCtrl = TextEditingController(
      text: isEdit ? (_experience[editIndex]['position'] ?? '') : '',
    );
    final companyCtrl = TextEditingController(
      text: isEdit ? (_experience[editIndex]['company'] ?? '') : '',
    );
    final durationCtrl = TextEditingController(
      text: isEdit ? (_experience[editIndex]['duration'] ?? '') : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsFlowPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit
                  ? AppLocalizations.of(context)!.studentEditExperience
                  : AppLocalizations.of(context)!.studentAddExperienceTitle,
              style: SettingsFlowTheme.sectionTitle(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: positionCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: AppLocalizations.of(context)!.uiPosition,
                prefixIcon: Icons.work_outline,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: AppLocalizations.of(context)!.uiCompany,
                prefixIcon: Icons.business_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: AppLocalizations.of(context)!.uiDuration,
                hint: AppLocalizations.of(context)!.studentDateRangeHint,
                prefixIcon: Icons.date_range_outlined,
              ),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: isEdit
                  ? AppLocalizations.of(context)!.studentUpdate
                  : AppLocalizations.of(context)!.uiAdd,
              onPressed: () {
                if (positionCtrl.text.trim().isEmpty) return;
                setState(() {
                  final entry = {
                    'position': positionCtrl.text.trim(),
                    'company': companyCtrl.text.trim(),
                    'duration': durationCtrl.text.trim(),
                  };
                  if (isEdit) {
                    _experience[editIndex] = entry;
                  } else {
                    _experience.add(entry);
                  }
                });
                _scheduleAutosave();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleLeave();
      },
      child: SettingsPageScaffold(
        title: AppLocalizations.of(context)!.uiEditCv,
        leading: IconButton(
          onPressed: _handleLeave,
          icon: AppDirectionalIcon(
            Icons.arrow_back_ios_new_rounded,
            color: SettingsFlowPalette.textPrimary,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBuilderGuide(),
              const SizedBox(height: 24),

              // ── Personal Information ──
              KeyedSubtree(
                key: _personalKey,
                child: SettingsSectionHeading(
                  title: AppLocalizations.of(context)!.uiPersonalInformation,
                ),
              ),
              const SizedBox(height: 10),
              SettingsPanel(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      style: SettingsFlowTheme.body(),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.uiFullName,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: SettingsFlowTheme.body(),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.uiEmail,
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: SettingsFlowTheme.body(),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.uiPhone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      style: SettingsFlowTheme.body(),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.fullStreetAddress],
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.uiAddress,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Professional Summary ──
              KeyedSubtree(
                key: _summaryKey,
                child: SettingsSectionHeading(
                  title: AppLocalizations.of(context)!.uiProfessionalSummary,
                ),
              ),
              const SizedBox(height: 10),
              SettingsPanel(
                child: TextFormField(
                  controller: _summaryController,
                  style: SettingsFlowTheme.body(),
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration(
                    label: AppLocalizations.of(context)!.uiBriefSummary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Education ──
              KeyedSubtree(
                key: _educationKey,
                child: SettingsSectionHeading(
                  title: AppLocalizations.of(context)!.uiEducation,
                  trailing: _addChip(onTap: () => _addOrEditEducation()),
                ),
              ),
              const SizedBox(height: 10),
              if (_education.isEmpty)
                _emptyState(
                  AppLocalizations.of(context)!.studentAddYourEducation,
                  Icons.school_outlined,
                )
              else
                ..._education.asMap().entries.map((entry) {
                  final i = entry.key;
                  final edu = entry.value;
                  return _itemCard(
                    title: edu['degree'] ?? '',
                    subtitle:
                        '${edu['institution'] ?? ''}${(edu['year'] ?? '').toString().isNotEmpty ? '  •  ${edu['year']}' : ''}',
                    icon: Icons.school_outlined,
                    onEdit: () => _addOrEditEducation(editIndex: i),
                    onDelete: () => _removeEducation(i),
                  );
                }),

              const SizedBox(height: 24),

              // ── Experience ──
              KeyedSubtree(
                key: _experienceKey,
                child: SettingsSectionHeading(
                  title: AppLocalizations.of(context)!.uiExperience,
                  trailing: _addChip(onTap: () => _addOrEditExperience()),
                ),
              ),
              const SizedBox(height: 10),
              if (_experience.isEmpty)
                _emptyState(
                  AppLocalizations.of(context)!.studentAddYourExperience,
                  Icons.work_outline,
                )
              else
                ..._experience.asMap().entries.map((entry) {
                  final i = entry.key;
                  final exp = entry.value;
                  return _itemCard(
                    title: exp['position'] ?? '',
                    subtitle:
                        '${exp['company'] ?? ''}${(exp['duration'] ?? '').toString().isNotEmpty ? '  •  ${exp['duration']}' : ''}',
                    icon: Icons.work_outline,
                    onEdit: () => _addOrEditExperience(editIndex: i),
                    onDelete: () => _removeExperience(i),
                  );
                }),

              const SizedBox(height: 24),

              // ── Skills ──
              KeyedSubtree(
                key: _skillsKey,
                child: SettingsSectionHeading(
                  title: AppLocalizations.of(context)!.uiSkills,
                ),
              ),
              const SizedBox(height: 10),
              SettingsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_skills.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills.asMap().entries.map((entry) {
                          return _chip(
                            entry.value,
                            () => _removeSkill(entry.key),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _skillInputController,
                      style: SettingsFlowTheme.body(),
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.uiAddSkill,
                        hint: AppLocalizations.of(
                          context,
                        )!.studentTypeAndPressEnter,
                        prefixIcon: Icons.auto_awesome_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: SettingsFlowPalette.primary,
                          ),
                          onPressed: _addSkill,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Languages ──
              KeyedSubtree(
                key: _languagesKey,
                child: SettingsSectionHeading(
                  title: AppLocalizations.of(context)!.uiLanguages,
                ),
              ),
              const SizedBox(height: 10),
              SettingsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_languages.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _languages.asMap().entries.map((entry) {
                          return _chip(
                            entry.value,
                            () => _removeLanguage(entry.key),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _languageInputController,
                      style: SettingsFlowTheme.body(),
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.uiAddALanguage,
                        hint: AppLocalizations.of(
                          context,
                        )!.studentTypeAndPressEnter,
                        prefixIcon: Icons.translate_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: SettingsFlowPalette.primary,
                          ),
                          onPressed: _addLanguage,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addLanguage(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  _isAutosaving
                      ? AppLocalizations.of(context)!.studentSavingChanges
                      : AppLocalizations.of(
                          context,
                        )!.studentChangesSaveAutomatically,
                  style: SettingsFlowTheme.caption(
                    _autosaveError == null
                        ? SettingsFlowPalette.textSecondary
                        : SettingsFlowPalette.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────

  Widget _addChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
          borderRadius: SettingsFlowTheme.radius(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: SettingsFlowPalette.primary,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.uiAdd,
              style: SettingsFlowTheme.micro(SettingsFlowPalette.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onDelete) {
    final maxChipWidth = (MediaQuery.sizeOf(context).width - 112)
        .clamp(140.0, 360.0)
        .toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
          borderRadius: SettingsFlowTheme.radius(10),
          border: Border.all(
            color: SettingsFlowPalette.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _itemCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SettingsPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SettingsIconBox(icon: icon, color: SettingsFlowPalette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SettingsFlowTheme.cardTitle()),
                  if (subtitle.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: SettingsFlowTheme.caption()),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: SettingsFlowPalette.textSecondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: SettingsFlowPalette.error.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.surface,
        borderRadius: SettingsFlowTheme.radius(20),
        border: Border.all(color: SettingsFlowPalette.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: SettingsFlowPalette.textSecondary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          Text(text, style: SettingsFlowTheme.caption()),
        ],
      ),
    );
  }
}

class _BuilderGuideStep {
  final GlobalKey key;
  final String label;
  final IconData icon;
  final bool isComplete;

  const _BuilderGuideStep({
    required this.key,
    required this.label,
    required this.icon,
    required this.isComplete,
  });
}

class _BuilderStepChip extends StatelessWidget {
  final _BuilderGuideStep step;
  final VoidCallback onPressed;

  const _BuilderStepChip({required this.step, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = step.isComplete
        ? SettingsFlowPalette.success
        : SettingsFlowPalette.primary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ActionChip(
        avatar: Icon(
          step.isComplete ? Icons.check_rounded : step.icon,
          size: 16,
          color: color,
        ),
        label: Text(step.label, style: SettingsFlowTheme.micro(color)),
        onPressed: onPressed,
        backgroundColor: color.withValues(alpha: 0.09),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
        shape: StadiumBorder(side: BorderSide.none),
      ),
    );
  }
}
