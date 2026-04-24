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
    final uid = _uid;
    if (uid == null) return;

    final newMode = cv.primaryCvMode == 'uploaded' ? 'builder_pdf' : 'uploaded';

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

  int _completedCount(CvModel? cv) {
    if (cv == null) return 0;
    int count = 0;
    if (cv.fullName.trim().isNotEmpty && cv.email.trim().isNotEmpty) count++;
    if (cv.education.isNotEmpty) count++;
    if (cv.experience.isNotEmpty) count++;
    if (cv.skills.isNotEmpty) count++;
    if (cv.languages.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();
    final cv = cvProvider.cv;
    final completed = _completedCount(cv);
    const total = 5;
    final progress = completed / total;

    return SettingsPageScaffold(
      title: AppLocalizations.of(context)!.uiMyCv,
      actions: [
        IconButton(
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
                // ── Progress Card ──
                SettingsPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: SettingsFlowPalette.border,
                              valueColor: AlwaysStoppedAnimation(
                                SettingsFlowPalette.primary,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Text(
                                '${(progress * 100).round()}%',
                                style: SettingsFlowTheme.sectionTitle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cv?.fullName.trim().isNotEmpty == true
                            ? cv!.fullName
                            : 'Start building your CV',
                        style: SettingsFlowTheme.heroTitle(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed of $total sections complete',
                        style: SettingsFlowTheme.caption(),
                      ),
                      const SizedBox(height: 20),
                      SettingsPrimaryButton(
                        label: cv?.hasBuilderContent == true
                            ? 'Edit Your CV'
                            : 'Start Building',
                        icon: Icons.edit_rounded,
                        onPressed: _navigateToEdit,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Template ──
                SettingsPanel(
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
                                  'Template',
                                  style: SettingsFlowTheme.sectionTitle(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cv != null && cv.templateId.trim().isNotEmpty
                                      ? CvTemplateConfig.getTemplate(
                                          cv.templateId,
                                        ).name
                                      : cv?.hasBuilderContent == true
                                      ? 'None selected'
                                      : 'Add content first',
                                  style: SettingsFlowTheme.caption(),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: cv != null && cv.hasBuilderContent
                                ? () => _navigateToTemplateSelector(cv)
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: SettingsFlowPalette.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: SettingsFlowTheme.radius(12),
                              ),
                            ),
                            child: Text(
                              'Change',
                              style: SettingsFlowTheme.body(
                                SettingsFlowPalette.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cv != null &&
                          cv.hasBuilderContent &&
                          cv.templateId.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: SettingsFlowPalette.background,
                            borderRadius: SettingsFlowTheme.radius(18),
                            border: Border.all(
                              color: SettingsFlowPalette.border,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: SettingsFlowTheme.radius(18),
                            child: CvTemplatePreview(
                              cv: cv,
                              templateId: cv.templateId,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Preview & Export ──
                SettingsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview & Save',
                        style: SettingsFlowTheme.sectionTitle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a polished PDF and keep it in My CV.',
                        style: SettingsFlowTheme.caption(),
                      ),
                      const SizedBox(height: 14),
                      SettingsButtonGroup(
                        children: [
                          SettingsSecondaryButton(
                            label: AppLocalizations.of(context)!.uiPreview,
                            icon: Icons.visibility_outlined,
                            onPressed: cv != null && cv.hasBuilderContent
                                ? () => _navigateToPreview(cv)
                                : null,
                          ),
                          SettingsPrimaryButton(
                            label: cvProvider.isExporting
                                ? 'Saving...'
                                : 'Save PDF to My CV',
                            icon: Icons.picture_as_pdf_rounded,
                            onPressed: cvProvider.isExporting
                                ? null
                                : () => _generateCv(cv),
                          ),
                        ],
                      ),
                      if (cv?.hasBuilderContent == true &&
                          cv?.hasExportedPdf != true) ...[
                        const SizedBox(height: 12),
                        SettingsListRow(
                          icon: Icons.delete_sweep_outlined,
                          iconColor: SettingsFlowPalette.error,
                          title: 'Reset built CV',
                          subtitle:
                              'Delete built details and start again. Uploaded CV stays.',
                          destructive: true,
                          compact: true,
                          onTap: () => _resetBuiltCv(cv!),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(child: Divider(color: SettingsFlowPalette.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or upload your own',
                        style: SettingsFlowTheme.caption(),
                      ),
                    ),
                    Expanded(child: Divider(color: SettingsFlowPalette.border)),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Upload ──
                SettingsListRow(
                  icon: Icons.upload_file_rounded,
                  iconColor: SettingsFlowPalette.secondary,
                  title: cv?.hasUploadedCv == true
                      ? cv!.uploadedCvDisplayName
                      : 'Upload a PDF',
                  subtitle: cv?.hasUploadedCv == true
                      ? 'Uploaded ${cv!.uploadedCvUploadedAt != null ? DateFormat('MMM d, yyyy').format(cv.uploadedCvUploadedAt!.toDate()) : 'recently'}'
                      : 'Use your existing CV file',
                  onTap: _uploadExistingCv,
                  trailing: SettingsStatusPill(
                    label: cv?.hasUploadedCv == true ? 'Ready' : 'Upload',
                    color: cv?.hasUploadedCv == true
                        ? SettingsFlowPalette.success
                        : SettingsFlowPalette.textSecondary,
                  ),
                ),

                // ── Your Files ──
                if (cv != null && (cv.hasUploadedCv || cv.hasExportedPdf)) ...[
                  const SizedBox(height: 20),
                  SettingsPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Files',
                          style: SettingsFlowTheme.sectionTitle(),
                        ),
                        const SizedBox(height: 14),
                        if (cv.hasUploadedCv)
                          _FileRow(
                            icon: Icons.upload_file_rounded,
                            label: AppLocalizations.of(context)!.uiUploadedCv,
                            isActive:
                                cv.primaryCvMode == 'uploaded' ||
                                !cv.hasExportedPdf,
                            onView: cv.isUploadedCvPdf
                                ? () => _openSecureCv(
                                    variant: 'primary',
                                    requirePdf: true,
                                  )
                                : null,
                            onDownload: () => _openSecureCv(
                              variant: 'primary',
                              download: true,
                            ),
                            onRemove: () => _removeUploadedCv(cv),
                          ),
                        if (cv.hasUploadedCv && cv.hasExportedPdf)
                          Divider(
                            color: SettingsFlowPalette.border,
                            height: 24,
                          ),
                        if (cv.hasExportedPdf)
                          _FileRow(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'Built CV',
                            isActive:
                                cv.primaryCvMode != 'uploaded' ||
                                !cv.hasUploadedCv,
                            onView: () => _openSecureCv(
                              variant: 'built',
                              requirePdf: true,
                            ),
                            onDownload: () =>
                                _openSecureCv(variant: 'built', download: true),
                            onRemove: () => _resetBuiltCv(cv),
                          ),
                        if (cv.hasUploadedCv && cv.hasExportedPdf) ...[
                          const SizedBox(height: 14),
                          SettingsSecondaryButton(
                            label: cv.primaryCvMode == 'uploaded'
                                ? 'Switch to built CV'
                                : 'Switch to uploaded CV',
                            icon: Icons.swap_horiz_rounded,
                            onPressed: () => _togglePrimaryCvMode(cv),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
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

class _FileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onRemove;

  const _FileRow({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onView,
    this.onDownload,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SettingsFlowPalette.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: SettingsFlowTheme.body())),
        if (isActive)
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: SettingsStatusPill(
              label: 'Active',
              color: SettingsFlowPalette.success,
            ),
          ),
        if (onView != null)
          GestureDetector(
            onTap: onView,
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.visibility_outlined,
                size: 18,
                color: SettingsFlowPalette.textSecondary,
              ),
            ),
          ),
        if (onDownload != null)
          GestureDetector(
            onTap: onDownload,
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.download_outlined,
                size: 18,
                color: SettingsFlowPalette.textSecondary,
              ),
            ),
          ),
        if (onRemove != null)
          Tooltip(
            message: AppLocalizations.of(context)!.removeLabel,
            child: GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: SettingsFlowPalette.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
