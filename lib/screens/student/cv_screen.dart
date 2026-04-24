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

      context.showAppSnackBar(
        error ??
            'Template updated to ${CvTemplateConfig.getTemplate(selectedId).name}.',
        title: error == null
            ? 'Template updated'
            : 'Template update unavailable',
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
        'Add your CV details before saving a PDF.',
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
      error ?? 'Your CV PDF was saved to My CV.',
      title: error == null ? 'PDF saved' : 'Save unavailable',
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
      error ?? 'Your CV file has been uploaded.',
      title: error == null ? 'Upload complete' : 'Upload unavailable',
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
        ? 'Now using your uploaded CV.'
        : 'Now using your built CV.';

    context.showAppSnackBar(
      error ?? successMessage,
      title: error == null ? 'Primary CV updated' : 'Update unavailable',
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _removeUploadedCv(CvModel cv) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove uploaded CV?'),
          content: Text(
            'This removes ${cv.uploadedCvDisplayName} from your CV studio. Your built CV content stays available.',
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
      error ?? 'Uploaded CV removed.',
      title: error == null ? 'CV removed' : l10n.uiRemoveUnavailable,
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  Future<void> _resetBuiltCv(CvModel cv) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset built CV?'),
          content: Text(
            cv.hasUploadedCv
                ? 'This deletes your built CV details and saved PDF. Your uploaded CV stays available.'
                : 'This deletes your built CV details and saved PDF.',
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
              child: const Text('Reset'),
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
      error ?? 'Built CV reset.',
      title: error == null ? 'Built CV reset' : 'Reset unavailable',
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
          'This file is not a valid PDF yet.',
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
          'We couldn\'t open the document right now.',
          title: AppLocalizations.of(context)!.uiOpenUnavailable,
          type: AppFeedbackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        _documentErrorMessage(e),
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

  List<_ReadinessItem> _readinessItems(CvModel? cv) {
    final hasContact =
        cv?.fullName.trim().isNotEmpty == true &&
        cv?.email.trim().isNotEmpty == true;
    final hasBuilderContent = cv?.hasBuilderContent == true;

    return [
      _ReadinessItem(
        icon: Icons.badge_outlined,
        title: 'Contact info',
        subtitle: hasContact
            ? 'Name and email are ready.'
            : 'Add your name and email.',
        isComplete: hasContact,
      ),
      _ReadinessItem(
        icon: Icons.subject_rounded,
        title: 'Summary',
        subtitle: cv?.summary.trim().isNotEmpty == true
            ? 'Your profile has a short introduction.'
            : 'Write a short professional profile.',
        isComplete: cv?.summary.trim().isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.school_outlined,
        title: 'Education',
        subtitle: cv?.education.isNotEmpty == true
            ? '${cv!.education.length} education item saved.'
            : 'Add your latest degree or training.',
        isComplete: cv?.education.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.work_outline_rounded,
        title: 'Experience or projects',
        subtitle: cv?.experience.isNotEmpty == true
            ? '${cv!.experience.length} experience item saved.'
            : 'Add internships, work, or project experience.',
        isComplete: cv?.experience.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.auto_awesome_outlined,
        title: 'Skills',
        subtitle: cv?.skills.isNotEmpty == true
            ? '${cv!.skills.length} skills listed.'
            : 'List your strongest skills.',
        isComplete: cv?.skills.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.translate_outlined,
        title: 'Languages',
        subtitle: cv?.languages.isNotEmpty == true
            ? '${cv!.languages.length} languages listed.'
            : 'Add languages recruiters should know.',
        isComplete: cv?.languages.isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.dashboard_customize_outlined,
        title: 'Template',
        subtitle: cv?.templateId.trim().isNotEmpty == true
            ? '${CvTemplateConfig.getTemplate(cv!.templateId).name} selected.'
            : hasBuilderContent
            ? 'Classic will be used unless you choose another style.'
            : 'Build your CV before choosing a style.',
        isComplete: cv?.templateId.trim().isNotEmpty == true,
      ),
      _ReadinessItem(
        icon: Icons.verified_outlined,
        title: 'Application file',
        subtitle: _hasApplicationReadyCv(cv)
            ? 'A PDF is ready for applications.'
            : hasBuilderContent
            ? 'Save the builder as a PDF.'
            : 'Build or upload a CV file.',
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
          tooltip: 'Refresh CV',
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
                _buildReadinessPanel(cv),
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
    final title = _activeCvTitle(cv);
    final subtitle = _activeCvSubtitle(cv);
    final statusLabel = ready ? 'Ready' : (hasDraft ? 'Draft' : 'Empty');
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
                      'Companies will see',
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
                  ? 'Use built CV instead'
                  : 'Use uploaded CV instead',
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
            label: 'Build CV',
            icon: Icons.edit_rounded,
            onPressed: _navigateToEdit,
          ),
          SettingsSecondaryButton(
            label: 'Upload PDF',
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
            label: 'View active CV',
            icon: Icons.visibility_outlined,
            onPressed: () => _openActiveCv(cv),
          ),
          SettingsSecondaryButton(
            label: 'Download',
            icon: Icons.download_rounded,
            onPressed: () => _openActiveCv(cv, download: true),
          ),
        ],
      );
    }

    return SettingsButtonGroup(
      children: [
        SettingsPrimaryButton(
          label: cvProvider.isExporting ? 'Saving...' : 'Save as PDF',
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
    final items = _readinessItems(cv);
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
                      'CV readiness',
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completed of ${items.length} essentials complete',
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

  Widget _buildBuilderPanel(CvModel? cv, CvProvider cvProvider) {
    final hasContent = cv?.hasBuilderContent == true;
    final selectedTemplateId = hasContent
        ? CvTemplateConfig.resolveTemplateId(cv!.templateId)
        : CvTemplateConfig.defaultTemplate;
    final templateName = CvTemplateConfig.getTemplate(selectedTemplateId).name;

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
                      'Structured CV builder',
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasContent
                          ? '$templateName template. Edit details, preview, then save the PDF.'
                          : 'Create a polished CV from structured profile details.',
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              SettingsStatusPill(
                label: cv?.hasExportedPdf == true
                    ? 'PDF saved'
                    : (hasContent ? 'Draft' : 'Not started'),
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
                label: hasContent ? 'Edit builder' : 'Start builder',
                icon: Icons.edit_rounded,
                onPressed: _navigateToEdit,
              ),
              SettingsSecondaryButton(
                label: 'Template',
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
                  label: cvProvider.isExporting ? 'Saving...' : 'Save PDF',
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
          title: 'Application files',
          subtitle: 'Choose the document recruiters receive when you apply.',
        ),
        const SizedBox(height: 10),
        if (!hasFiles)
          SettingsListRow(
            icon: Icons.upload_file_rounded,
            iconColor: SettingsFlowPalette.secondary,
            title: 'Upload a PDF CV',
            subtitle: 'Use an existing file while you build a structured CV.',
            onTap: _uploadExistingCv,
            trailing: SettingsStatusPill(
              label: 'Upload',
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
                  '${cv.uploadedCvDisplayName} - ${_uploadedDateLabel(cv)}',
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
              title: 'Built CV PDF',
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
            title: cv.hasUploadedCv ? 'Replace uploaded PDF' : 'Upload PDF CV',
            subtitle: 'Attach a new PDF file from your device.',
            compact: true,
            onTap: _uploadExistingCv,
          ),
        ],
      ],
    );
  }

  String _activeCvTitle(CvModel? cv) {
    if (cv == null) return 'No active CV yet';
    if (_isBuiltActive(cv)) return 'Built CV PDF';
    if (_isUploadedActive(cv)) return 'Uploaded PDF';
    if (cv.hasBuilderContent) return 'Builder draft';
    return 'No active CV yet';
  }

  String _activeCvSubtitle(CvModel? cv) {
    if (cv == null) {
      return 'Build a structured CV or upload a PDF to start applying faster.';
    }

    if (_isBuiltActive(cv)) {
      return 'Your saved builder PDF is ready for applications.';
    }

    if (_isUploadedActive(cv)) {
      return 'Your uploaded file is currently used for applications.';
    }

    if (cv.hasBuilderContent) {
      return 'Preview the draft, then save it as a PDF before applying.';
    }

    return 'Build a structured CV or upload a PDF to start applying faster.';
  }

  String _uploadedDateLabel(CvModel cv) {
    final uploadedAt = cv.uploadedCvUploadedAt;
    if (uploadedAt == null) return 'uploaded recently';
    return 'uploaded ${DateFormat('MMM d, yyyy').format(uploadedAt.toDate())}';
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }
    return 'We couldn\'t open the document right now.';
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

    return Semantics(
      label: '${item.title}, ${item.isComplete ? 'complete' : 'incomplete'}',
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
                label: isActive ? 'Active' : 'Available',
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
                label: 'View',
                icon: Icons.visibility_outlined,
                onPressed: onView,
              ),
              _DocumentActionButton(
                label: 'Download',
                icon: Icons.download_outlined,
                onPressed: onDownload,
              ),
              if (onMakeActive != null)
                _DocumentActionButton(
                  label: 'Make active',
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

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: SettingsFlowTheme.micro(effectiveColor)),
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
    );
  }
}
