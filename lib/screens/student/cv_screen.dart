import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';
import '../../services/document_access_service.dart';
import '../../utils/document_upload_validator.dart';
import '../../widgets/cv_templates/cv_template_preview.dart';
import '../../widgets/shared/app_directional.dart';
import '../../widgets/shared/app_feedback.dart';
import 'cv_edit_screen.dart';
import 'cv_preview_screen.dart';
import 'cv_template_selector_screen.dart';

class CvScreen extends StatefulWidget {
  const CvScreen({super.key});

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  final DocumentAccessService _documentAccessService = DocumentAccessService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        await context.read<CvProvider>().loadCv(uid);
      }
    });
  }

  String? get _uid => context.read<AuthProvider>().userModel?.uid;

  Future<void> _reload() async {
    final uid = _uid;
    if (uid != null && mounted) {
      await context.read<CvProvider>().loadCv(uid);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CvEditScreen()),
    );
    await _reload();

    if (result == 'pick_template' && mounted) {
      final cv = context.read<CvProvider>().cv;
      if (cv != null && cv.hasBuilderContent) {
        _navigateToTemplateSelector(cv);
      }
    }
  }

  Future<void> _navigateToTemplateSelector(CvModel cv) async {
    final selectedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CvTemplateSelectorScreen(cv: cv, currentTemplateId: cv.templateId),
      ),
    );

    if (selectedId != null && selectedId != cv.templateId && mounted) {
      final uid = _uid;
      if (uid == null) return;

      final error = await context.read<CvProvider>().saveCv(
        studentId: uid,
        fullName: cv.fullName,
        email: cv.email,
        phone: cv.phone,
        address: cv.address,
        summary: cv.summary,
        education: cv.education,
        experience: cv.experience,
        skills: cv.skills,
        languages: cv.languages,
        templateId: selectedId,
      );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      context.showAppSnackBar(
        error ??
            l10n.studentCvTemplateUpdatedTo(
              CvTemplateConfig.getTemplate(selectedId).name,
            ),
        title: error == null
            ? l10n.studentCvTemplateUpdatedTitle
            : l10n.studentCvTemplateUpdateUnavailable,
        type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
      );
    }
  }

  Future<void> _navigateToPreview(CvModel cv) async {
    final exported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CvPreviewScreen(cv: cv)),
    );
    if (exported == true) {
      await _reload();
    }
  }

  Future<void> _generateCv(CvModel? cv) async {
    if (cv == null || !cv.hasBuilderContent) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.studentCvAddDetailsBeforeSaving,
        title: AppLocalizations.of(context)!.uiContentNeeded,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final uid = _uid;
    if (uid == null) return;

    final error = await context.read<CvProvider>().exportCvAsPdf(
      studentId: uid,
    );

    if (!mounted) return;

    context.showAppSnackBar(
      error ?? AppLocalizations.of(context)!.studentCvPdfSavedToMyCv,
      title: error == null
          ? AppLocalizations.of(context)!.uiExportComplete
          : AppLocalizations.of(context)!.uiSaveUnavailable,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _uploadExistingCv() async {
    final uid = _uid;
    if (uid == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final file = result.files.single;
    final validationError = DocumentUploadValidator.validatePrimaryCv(
      fileName: file.name,
      sizeInBytes: file.size,
    );

    if (validationError != null) {
      if (!mounted) return;
      context.showAppSnackBar(
        validationError,
        title: AppLocalizations.of(context)!.uiUploadUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final error = await context.read<CvProvider>().uploadCvFile(
      studentId: uid,
      filePath: file.path ?? '',
      fileName: file.name,
      fileBytes: file.bytes,
    );

    if (!mounted) return;

    context.showAppSnackBar(
      error ?? AppLocalizations.of(context)!.studentCvFileUploaded,
      title: error == null
          ? AppLocalizations.of(context)!.uiUploadComplete
          : AppLocalizations.of(context)!.uiUploadUnavailable,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _togglePrimaryCvMode(CvModel cv) async {
    await _setPrimaryCvMode(
      cv,
      cv.primaryCvMode == 'uploaded' ? 'builder_pdf' : 'uploaded',
    );
  }

  Future<void> _setPrimaryCvMode(CvModel cv, String newMode) async {
    final uid = _uid;
    if (uid == null || cv.primaryCvMode == newMode) return;

    final error = await context.read<CvProvider>().setPrimaryCvMode(
      studentId: uid,
      primaryCvMode: newMode,
    );

    if (!mounted) return;

    final successMessage = newMode == 'uploaded'
        ? AppLocalizations.of(context)!.studentCvUsingUploaded
        : AppLocalizations.of(context)!.studentCvUsingBuilt;

    context.showAppSnackBar(
      error ?? successMessage,
      title: error == null
          ? AppLocalizations.of(context)!.studentPrimaryCvUpdated
          : AppLocalizations.of(context)!.uiUpdateUnavailable,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _removeUploadedCv(CvModel cv) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.studentRemoveUploadedCvTitle),
          content: Text(
            l10n.studentRemoveUploadedCvMessage(cv.uploadedCvDisplayName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: SettingsFlowPalette.error,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.removeLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final uid = _uid;
    if (uid == null) return;

    final error = await context.read<CvProvider>().removeUploadedCv(
      studentId: uid,
    );

    if (!mounted) return;

    context.showAppSnackBar(
      error ?? l10n.studentUploadedCvRemoved,
      title: error == null
          ? l10n.studentCvRemovedTitle
          : l10n.uiRemoveUnavailable,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _resetBuiltCv(CvModel cv) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.studentResetBuiltCvTitle),
          content: Text(
            cv.hasUploadedCv
                ? l10n.studentResetBuiltCvWithUploadedMessage
                : l10n.studentResetBuiltCvMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: SettingsFlowPalette.error,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.studentReset),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final uid = _uid;
    if (uid == null) return;

    final error = await context.read<CvProvider>().resetBuiltCv(studentId: uid);

    if (!mounted) return;

    context.showAppSnackBar(
      error ?? l10n.studentBuiltCvResetMessage,
      title: error == null
          ? l10n.studentBuiltCvResetTitle
          : l10n.uiResetUnavailable,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _openSecureCv({
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final document = await _documentAccessService.getUserCvDocument(
        userId: uid,
        variant: variant,
      );
      if (!mounted) return;

      if (requirePdf && !document.isPdf) {
        context.showAppSnackBar(
          AppLocalizations.of(context)!.studentFileNotValidPdfYet,
          title: AppLocalizations.of(context)!.uiPreviewUnavailable,
          type: AppFeedbackType.warning,
        );
        return;
      }

      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );

      if (uri == null) throw Exception('File unavailable.');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );

      if (!mounted) return;
      if (!launched) {
        context.showAppSnackBar(
          AppLocalizations.of(context)!.studentCouldNotOpenDocumentNow,
          title: AppLocalizations.of(context)!.uiOpenUnavailable,
          type: AppFeedbackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        _documentErrorMessage(e, AppLocalizations.of(context)!),
        title: AppLocalizations.of(context)!.uiDocumentUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _openActiveCv(CvModel cv, {bool download = false}) async {
    if (_isUploadedActive(cv)) {
      await _openSecureCv(
        variant: 'primary',
        download: download,
        requirePdf: !download,
      );
      return;
    }

    if (_isBuiltActive(cv)) {
      await _openSecureCv(
        variant: 'built',
        download: download,
        requirePdf: !download,
      );
      return;
    }

    if (cv.hasBuilderContent && !download) {
      await _navigateToPreview(cv);
    }
  }

  bool _isUploadedActive(CvModel cv) {
    return cv.hasUploadedCv &&
        (cv.primaryCvMode == 'uploaded' || !cv.hasExportedPdf);
  }

  bool _isBuiltActive(CvModel cv) {
    return cv.hasExportedPdf &&
        (cv.primaryCvMode != 'uploaded' || !cv.hasUploadedCv);
  }

  bool _hasApplicationReadyCv(CvModel? cv) {
    return cv != null && (cv.hasUploadedCv || cv.hasExportedPdf);
  }

  List<_ReadinessItem> _readinessItems(CvModel? cv, AppLocalizations l10n) {
    final hasContact =
        cv?.fullName.trim().isNotEmpty == true &&
        cv?.email.trim().isNotEmpty == true;
    final hasBuilderContent = cv?.hasBuilderContent == true;

    return [
      _ReadinessItem(
        icon: Icons.badge_outlined,
        title: l10n.studentCvContactInfo,
        subtitle: hasContact
            ? l10n.studentCvNameEmailReady
            : l10n.studentCvAddNameEmail,
        isComplete: hasContact,
      ),
      _ReadinessItem(
        icon: Icons.subject_rounded,
        title: l10n.uiSummary,
        subtitle: cv?.summary.trim().isNotEmpty == true
            ? l10n.studentCvProfileIntroReady
            : l10n.studentCvWriteProfile,
        isComplete: cv?.summary.trim().isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.school_outlined,
        title: l10n.uiEducation,
        subtitle: cv?.education.isNotEmpty == true
            ? l10n.studentCvEducationSaved(cv!.education.length)
            : l10n.studentCvAddEducation,
        isComplete: cv?.education.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.work_outline_rounded,
        title: l10n.studentCvExperienceProjects,
        subtitle: cv?.experience.isNotEmpty == true
            ? l10n.studentCvExperienceSaved(cv!.experience.length)
            : l10n.studentCvAddExperience,
        isComplete: cv?.experience.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.auto_awesome_outlined,
        title: l10n.uiSkills,
        subtitle: cv?.skills.isNotEmpty == true
            ? l10n.studentCvSkillsListed(cv!.skills.length)
            : l10n.studentCvListSkills,
        isComplete: cv?.skills.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.translate_outlined,
        title: l10n.uiLanguages,
        subtitle: cv?.languages.isNotEmpty == true
            ? l10n.studentCvLanguagesListed(cv!.languages.length)
            : l10n.studentCvAddLanguages,
        isComplete: cv?.languages.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.dashboard_customize_outlined,
        title: l10n.uiTemplate,
        subtitle: cv?.templateId.trim().isNotEmpty == true
            ? l10n.studentCvTemplateSelected(
                CvTemplateConfig.getTemplate(cv!.templateId).name,
              )
            : hasBuilderContent
            ? l10n.studentCvClassicDefault
            : l10n.studentCvBuildBeforeStyle,
        isComplete: cv?.templateId.trim().isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.verified_outlined,
        title: l10n.studentCvApplicationFile,
        subtitle: _hasApplicationReadyCv(cv)
            ? l10n.studentCvPdfReadyApplications
            : hasBuilderContent
            ? l10n.studentCvSaveBuilderAsPdf
            : l10n.studentCvBuildOrUploadFile,
        isComplete: _hasApplicationReadyCv(cv),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();
    final cv = cvProvider.cv;

    return SettingsPageScaffold(
      title: AppLocalizations.of(context)!.uiCvStudio,
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.studentRefreshCv,
          onPressed: _reload,
          icon: Icon(
            Icons.refresh_rounded,
            color: SettingsFlowPalette.textPrimary,
          ),
        ),
      ],
      child: cvProvider.isLoading
          ? Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                child: CircularProgressIndicator(
                  color: SettingsFlowPalette.primary,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActiveCvPanel(cv, cvProvider),
                const SizedBox(height: 16),
                cv != null && _isUploadedActive(cv)
                    ? _buildUploadedCvStatusPanel(cv)
                    : _buildReadinessPanel(cv),
                const SizedBox(height: 16),
                _buildBuilderPanel(cv, cvProvider),
                const SizedBox(height: 24),
                _buildDocumentsSection(cv),
              ],
            ),
    );
  }

  Widget _buildActiveCvPanel(CvModel? cv, CvProvider cvProvider) {
    final ready = _hasApplicationReadyCv(cv);
    final hasDraft = cv?.hasBuilderContent == true && !ready;
    final l10n = AppLocalizations.of(context)!;
    final title = _activeCvTitle(cv, l10n);
    final subtitle = _activeCvSubtitle(cv, l10n);
    final statusLabel = ready
        ? l10n.studentReady
        : (hasDraft ? l10n.studentDraft : l10n.studentEmpty);
    final statusColor = ready
        ? SettingsFlowPalette.success
        : (hasDraft ? SettingsFlowPalette.warning : SettingsFlowPalette.error);

    return SettingsPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: ready
                    ? Icons.verified_user_outlined
                    : Icons.assignment_outlined,
                color: ready
                    ? SettingsFlowPalette.success
                    : SettingsFlowPalette.primary,
                boxSize: 46,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studentCompaniesWillSee,
                      style: SettingsFlowTheme.micro(
                        SettingsFlowPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: SettingsFlowTheme.heroTitle()),
                    const SizedBox(height: 6),
                    Text(subtitle, style: SettingsFlowTheme.caption()),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SettingsStatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 18),
          _buildActiveActions(cv, cvProvider),
          if (cv != null && cv.hasUploadedCv && cv.hasExportedPdf) ...[
            const SizedBox(height: 10),
            SettingsSecondaryButton(
              label: cv.primaryCvMode == 'uploaded'
                  ? l10n.studentUseBuiltCvInstead
                  : l10n.studentUseUploadedCvInstead,
              icon: Icons.swap_horiz_rounded,
              onPressed: () => _togglePrimaryCvMode(cv),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveActions(CvModel? cv, CvProvider cvProvider) {
    if (cv == null ||
        (!cv.hasBuilderContent && !cv.hasUploadedCv && !cv.hasExportedPdf)) {
      return SettingsButtonGroup(
        children: [
          SettingsPrimaryButton(
            label: AppLocalizations.of(context)!.uiActionBuildCv,
            icon: Icons.edit_rounded,
            onPressed: _navigateToEdit,
          ),
          SettingsSecondaryButton(
            label: AppLocalizations.of(context)!.studentUploadPdf,
            icon: Icons.upload_file_rounded,
            onPressed: _uploadExistingCv,
          ),
        ],
      );
    }

    if (_hasApplicationReadyCv(cv)) {
      return SettingsButtonGroup(
        children: [
          SettingsPrimaryButton(
            label: AppLocalizations.of(context)!.studentViewActiveCv,
            icon: Icons.visibility_outlined,
            onPressed: () => _openActiveCv(cv),
          ),
          SettingsSecondaryButton(
            label: AppLocalizations.of(context)!.uiDownload,
            icon: Icons.download_rounded,
            onPressed: () => _openActiveCv(cv, download: true),
          ),
        ],
      );
    }

    return SettingsButtonGroup(
      children: [
        SettingsPrimaryButton(
          label: cvProvider.isExporting
              ? AppLocalizations.of(context)!.studentSavingEllipsis
              : AppLocalizations.of(context)!.studentSaveAsPdf,
          icon: Icons.picture_as_pdf_rounded,
          onPressed: cvProvider.isExporting ? null : () => _generateCv(cv),
        ),
        SettingsSecondaryButton(
          label: AppLocalizations.of(context)!.uiPreview,
          icon: Icons.visibility_outlined,
          onPressed: cv.hasBuilderContent ? () => _navigateToPreview(cv) : null,
        ),
      ],
    );
  }

  Widget _buildReadinessPanel(CvModel? cv) {
    final l10n = AppLocalizations.of(context)!;
    final items = _readinessItems(cv, l10n);
    final completed = items.where((item) => item.isComplete).length;
    final progress = completed / items.length;

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
                      l10n.studentCvReadiness,
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.studentCvEssentialsComplete(completed, items.length),
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              SettingsStatusPill(
                label: '${(progress * 100).round()}%',
                color: progress >= 0.75
                    ? SettingsFlowPalette.success
                    : SettingsFlowPalette.primary,
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
          const SizedBox(height: 12),
          for (final item in items) _ReadinessRow(item: item),
        ],
      ),
    );
  }

  Widget _buildUploadedCvStatusPanel(CvModel cv) {
    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: Icons.picture_as_pdf_outlined,
                color: SettingsFlowPalette.secondary,
                boxSize: 42,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.studentUploadedPdfActive,
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.studentUploadedCvActiveMessage(
                        cv.uploadedCvDisplayName,
                      ),
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SettingsStatusPill(
                label: cv.isUploadedCvPdf
                    ? 'PDF'
                    : AppLocalizations.of(context)!.uiFile,
                color: SettingsFlowPalette.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ReadinessRow(
            item: _ReadinessItem(
              icon: Icons.upload_file_rounded,
              title: AppLocalizations.of(context)!.studentFileUploaded,
              subtitle: _uploadedDateLabel(cv, AppLocalizations.of(context)!),
              isComplete: true,
            ),
          ),
          _ReadinessRow(
            item: _ReadinessItem(
              icon: Icons.verified_outlined,
              title: AppLocalizations.of(context)!.studentApplicationReady,
              subtitle: cv.isUploadedCvPdf
                  ? AppLocalizations.of(context)!.studentUploadedPdfReadyAttach
                  : AppLocalizations.of(
                      context,
                    )!.studentUploadedFileSavedPreviewLimited,
              isComplete: cv.hasUploadedCv,
            ),
          ),
          const SizedBox(height: 8),
          SettingsButtonGroup(
            children: [
              SettingsSecondaryButton(
                label: AppLocalizations.of(context)!.studentReplacePdf,
                icon: Icons.upload_file_rounded,
                onPressed: _uploadExistingCv,
              ),
              SettingsSecondaryButton(
                label: AppLocalizations.of(context)!.studentBuildInstead,
                icon: Icons.edit_rounded,
                onPressed: cv.hasExportedPdf
                    ? () => _setPrimaryCvMode(cv, 'builder_pdf')
                    : _navigateToEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuilderPanel(CvModel? cv, CvProvider cvProvider) {
    final hasContent = cv?.hasBuilderContent == true;
    final selectedTemplateId = hasContent
        ? CvTemplateConfig.resolveTemplateId(cv!.templateId)
        : CvTemplateConfig.defaultTemplate;
    final templateName = CvTemplateConfig.getTemplate(selectedTemplateId).name;
    final l10n = AppLocalizations.of(context)!;

    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studentStructuredCvBuilder,
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasContent
                          ? l10n.studentTemplateEditSavePdf(templateName)
                          : l10n.studentCreatePolishedCv,
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              SettingsStatusPill(
                label: cv?.hasExportedPdf == true
                    ? l10n.uiExportComplete
                    : (hasContent ? l10n.studentDraft : l10n.studentNotStarted),
                color: cv?.hasExportedPdf == true
                    ? SettingsFlowPalette.success
                    : (hasContent
                          ? SettingsFlowPalette.warning
                          : SettingsFlowPalette.textSecondary),
              ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: 14),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: SettingsFlowPalette.background,
                borderRadius: SettingsFlowTheme.radius(18),
                border: Border.all(color: SettingsFlowPalette.border),
              ),
              child: ClipRRect(
                borderRadius: SettingsFlowTheme.radius(18),
                child: CvTemplatePreview(
                  cv: cv!,
                  templateId: selectedTemplateId,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SettingsButtonGroup(
            children: [
              SettingsPrimaryButton(
                label: hasContent
                    ? l10n.studentEditBuilder
                    : l10n.studentStartBuilder,
                icon: Icons.edit_rounded,
                onPressed: _navigateToEdit,
              ),
              SettingsSecondaryButton(
                label: l10n.uiTemplate,
                icon: Icons.dashboard_customize_outlined,
                onPressed: hasContent
                    ? () => _navigateToTemplateSelector(cv!)
                    : null,
              ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: 10),
            SettingsButtonGroup(
              children: [
                SettingsSecondaryButton(
                  label: AppLocalizations.of(context)!.uiPreview,
                  icon: Icons.visibility_outlined,
                  onPressed: () => _navigateToPreview(cv!),
                ),
                SettingsPrimaryButton(
                  label: cvProvider.isExporting
                      ? l10n.studentSavingEllipsis
                      : l10n.studentSavePdf,
                  icon: Icons.picture_as_pdf_rounded,
                  onPressed: cvProvider.isExporting
                      ? null
                      : () => _generateCv(cv),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(CvModel? cv) {
    final hasFiles = cv != null && (cv.hasUploadedCv || cv.hasExportedPdf);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeading(
          title: AppLocalizations.of(context)!.studentApplicationFiles,
          subtitle: AppLocalizations.of(
            context,
          )!.studentApplicationFilesSubtitle,
        ),
        const SizedBox(height: 10),
        if (!hasFiles)
          SettingsListRow(
            icon: Icons.upload_file_rounded,
            iconColor: SettingsFlowPalette.secondary,
            title: AppLocalizations.of(context)!.studentUploadPdfCv,
            subtitle: AppLocalizations.of(
              context,
            )!.studentUseExistingPdfWhileBuilding,
            onTap: _uploadExistingCv,
            trailing: SettingsStatusPill(
              label: AppLocalizations.of(context)!.uploadLabel,
              color: SettingsFlowPalette.secondary,
            ),
          )
        else ...[
          if (cv.hasUploadedCv)
            _CvDocumentCard(
              icon: Icons.upload_file_rounded,
              iconColor: SettingsFlowPalette.secondary,
              title: AppLocalizations.of(context)!.uiUploadedCv,
              subtitle:
                  '${cv.uploadedCvDisplayName} - ${_uploadedDateLabel(cv, AppLocalizations.of(context)!)}',
              isActive: _isUploadedActive(cv),
              onView: cv.isUploadedCvPdf
                  ? () => _openSecureCv(variant: 'primary', requirePdf: true)
                  : null,
              onDownload: () =>
                  _openSecureCv(variant: 'primary', download: true),
              onMakeActive: _isUploadedActive(cv)
                  ? null
                  : () => _setPrimaryCvMode(cv, 'uploaded'),
              onRemove: () => _removeUploadedCv(cv),
            ),
          if (cv.hasUploadedCv && cv.hasExportedPdf) const SizedBox(height: 10),
          if (cv.hasExportedPdf)
            _CvDocumentCard(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: SettingsFlowPalette.primary,
              title: AppLocalizations.of(context)!.studentBuiltCvPdf,
              subtitle:
                  '${cv.exportedPdfFileName} - ${CvTemplateConfig.getTemplate(CvTemplateConfig.resolveTemplateId(cv.templateId)).name}',
              isActive: _isBuiltActive(cv),
              onView: () => _openSecureCv(variant: 'built', requirePdf: true),
              onDownload: () => _openSecureCv(variant: 'built', download: true),
              onMakeActive: _isBuiltActive(cv)
                  ? null
                  : () => _setPrimaryCvMode(cv, 'builder_pdf'),
              onRemove: () => _resetBuiltCv(cv),
            ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.add_rounded,
            iconColor: SettingsFlowPalette.secondary,
            title: cv.hasUploadedCv
                ? AppLocalizations.of(context)!.studentReplaceUploadedPdf
                : AppLocalizations.of(context)!.studentUploadPdfCv,
            subtitle: AppLocalizations.of(context)!.studentAttachNewPdf,
            compact: true,
            onTap: _uploadExistingCv,
          ),
        ],
      ],
    );
  }

  String _activeCvTitle(CvModel? cv, AppLocalizations l10n) {
    if (cv == null) return l10n.studentNoActiveCvYet;
    if (_isBuiltActive(cv)) return l10n.studentBuiltCvPdf;
    if (_isUploadedActive(cv)) return l10n.studentUploadedPdf;
    if (cv.hasBuilderContent) return l10n.studentBuilderDraft;
    return l10n.studentNoActiveCvYet;
  }

  String _activeCvSubtitle(CvModel? cv, AppLocalizations l10n) {
    if (cv == null) {
      return l10n.studentCvStartApplyingFaster;
    }

    if (_isBuiltActive(cv)) {
      return l10n.studentSavedBuilderPdfReady;
    }

    if (_isUploadedActive(cv)) {
      return l10n.studentUploadedFileUsedApplications;
    }

    if (cv.hasBuilderContent) {
      return l10n.studentPreviewDraftSavePdf;
    }

    return l10n.studentCvStartApplyingFaster;
  }

  String _uploadedDateLabel(CvModel cv, AppLocalizations l10n) {
    final uploadedAt = cv.uploadedCvUploadedAt;
    if (uploadedAt == null) return l10n.studentUploadedRecently;
    return l10n.studentUploadedDate(
      DateFormat('MMM d, yyyy').format(uploadedAt.toDate()),
    );
  }

  String _documentErrorMessage(Object error, AppLocalizations l10n) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return l10n.uiPermissionDeniedWhileOpeningTheDocument;
    }
    if (message.contains('404') || message.contains('not found')) {
      return l10n.uiTheRequestedDocumentIsNoLongerAvailable;
    }
    return l10n.studentCouldNotOpenDocumentNow;
  }
}

class _ReadinessItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;

  const _ReadinessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
  });
}

class _ReadinessRow extends StatelessWidget {
  final _ReadinessItem item;

  const _ReadinessRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isComplete
        ? SettingsFlowPalette.success
        : SettingsFlowPalette.textSecondary;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.studentReadinessSemantic(
        item.title,
        item.isComplete ? l10n.studentComplete : l10n.studentIncomplete,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: item.isComplete ? 0.12 : 0.08),
                borderRadius: SettingsFlowTheme.radius(12),
              ),
              child: Icon(
                item.isComplete ? Icons.check_rounded : item.icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: SettingsFlowTheme.cardTitle()),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: SettingsFlowTheme.caption()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvDocumentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onMakeActive;
  final VoidCallback? onRemove;

  const _CvDocumentCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.onView,
    this.onDownload,
    this.onMakeActive,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SettingsFlowTheme.cardTitle()),
                    const SizedBox(height: 3),
                    Text(subtitle, style: SettingsFlowTheme.caption()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SettingsStatusPill(
                label: isActive
                    ? AppLocalizations.of(context)!.uiActive
                    : AppLocalizations.of(context)!.studentAvailable,
                color: isActive
                    ? SettingsFlowPalette.success
                    : SettingsFlowPalette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocumentActionButton(
                label: AppLocalizations.of(context)!.uiView,
                icon: Icons.visibility_outlined,
                onPressed: onView,
              ),
              _DocumentActionButton(
                label: AppLocalizations.of(context)!.uiDownload,
                icon: Icons.download_outlined,
                onPressed: onDownload,
              ),
              if (onMakeActive != null)
                _DocumentActionButton(
                  label: AppLocalizations.of(context)!.studentMakeActive,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: onMakeActive,
                  color: SettingsFlowPalette.success,
                ),
              _DocumentActionButton(
                label: AppLocalizations.of(context)!.removeLabel,
                icon: Icons.delete_outline_rounded,
                onPressed: onRemove,
                color: SettingsFlowPalette.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const _DocumentActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? SettingsFlowPalette.textPrimary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        foregroundColor: effectiveColor,
        disabledForegroundColor: SettingsFlowPalette.textSecondary.withValues(
          alpha: 0.45,
        ),
        side: BorderSide(
          color: onPressed == null
              ? SettingsFlowPalette.border
              : effectiveColor.withValues(alpha: 0.28),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: SettingsFlowTheme.radius(14),
        ),
      ),
      child: AppInlineIconLabel(
        icon: icon,
        iconSize: 16,
        iconColor: effectiveColor,
        gap: 7,
        label: Text(label, style: SettingsFlowTheme.micro(effectiveColor)),
      ),
    );
  }
}
