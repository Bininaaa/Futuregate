import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
      if (!mounted) {
        return;
      }
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
      if (uid == null) {
        return;
      }

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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                'Template changed to ${CvTemplateConfig.getTemplate(selectedId).name}.',
          ),
          backgroundColor: error == null
              ? SettingsFlowPalette.success
              : SettingsFlowPalette.error,
        ),
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
    final messenger = ScaffoldMessenger.of(context);

    if (cv == null || !cv.hasBuilderContent) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Add CV content first to generate a PDF.'),
          backgroundColor: SettingsFlowPalette.warning,
        ),
      );
      return;
    }

    final uid = _uid;
    if (uid == null) {
      return;
    }

    final error = await context.read<CvProvider>().exportCvAsPdf(
      studentId: uid,
    );

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Built CV exported successfully.'),
        backgroundColor: error == null
            ? SettingsFlowPalette.success
            : SettingsFlowPalette.error,
      ),
    );
  }

  Future<void> _uploadExistingCv() async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = _uid;
    if (uid == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    final file = result.files.single;
    final validationError = DocumentUploadValidator.validatePrimaryCv(
      fileName: file.name,
      sizeInBytes: file.size,
    );

    if (validationError != null) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: SettingsFlowPalette.error,
        ),
      );
      return;
    }

    final error = await context.read<CvProvider>().uploadCvFile(
      studentId: uid,
      filePath: file.path ?? '',
      fileName: file.name,
      fileBytes: file.bytes,
    );

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Primary CV uploaded successfully.'),
        backgroundColor: error == null
            ? SettingsFlowPalette.success
            : SettingsFlowPalette.error,
      ),
    );
  }

  Future<void> _togglePrimaryCvMode(CvModel cv) async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = _uid;
    if (uid == null) {
      return;
    }

    final newMode = cv.primaryCvMode == 'uploaded' ? 'builder_pdf' : 'uploaded';

    final error = await context.read<CvProvider>().setPrimaryCvMode(
      studentId: uid,
      primaryCvMode: newMode,
    );

    if (!mounted) {
      return;
    }

    final successMessage = newMode == 'uploaded'
        ? 'Applications now use your uploaded CV.'
        : 'Applications now use your built CV PDF.';

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error == null
            ? SettingsFlowPalette.success
            : SettingsFlowPalette.error,
      ),
    );
  }

  Future<void> _openSecureCv({
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getUserCvDocument(
        userId: uid,
        variant: variant,
      );

      if (requirePdf && !document.isPdf) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('This document is not a valid PDF file.'),
          ),
        );
        return;
      }

      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );

      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );

      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();
    final cv = cvProvider.cv;

    final sections = _buildSections(cv);
    final completeSections = sections
        .where((section) => section.complete)
        .length;
    final totalTrackableSections = sections
        .where((section) => section.trackInCompletion)
        .length;
    final completionRatio = totalTrackableSections == 0
        ? 0.0
        : completeSections / totalTrackableSections;
    final completionLabel = '${(completionRatio * 100).round()}%';

    return SettingsPageScaffold(
      title: 'CV Builder',
      actions: [
        IconButton(
          onPressed: _reload,
          icon: const Icon(
            Icons.refresh_rounded,
            color: SettingsFlowPalette.textPrimary,
          ),
        ),
      ],
      child: cvProvider.isLoading
          ? const Padding(
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
                SettingsPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 360;

                          return compact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Build a sharper student CV',
                                      style: SettingsFlowTheme.heroTitle(),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Track what is filled in, edit structured sections, and export a polished PDF when your profile is ready.',
                                      style: SettingsFlowTheme.caption(),
                                    ),
                                    const SizedBox(height: 14),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: _CompletionBadge(
                                        completionLabel: completionLabel,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Build a sharper student CV',
                                            style:
                                                SettingsFlowTheme.heroTitle(),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Track what is filled in, edit structured sections, and export a polished PDF when your profile is ready.',
                                            style: SettingsFlowTheme.caption(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _CompletionBadge(
                                      completionLabel: completionLabel,
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SettingsStatusPill(
                            label: cv?.templateId.trim().isNotEmpty == true
                                ? CvTemplateConfig.getTemplate(
                                    cv!.templateId,
                                  ).name
                                : 'No template selected',
                            color: SettingsFlowPalette.secondary,
                          ),
                          SettingsStatusPill(
                            label: cv?.hasUploadedCv == true
                                ? 'Primary PDF ready'
                                : 'Primary PDF missing',
                            color: cv?.hasUploadedCv == true
                                ? SettingsFlowPalette.success
                                : SettingsFlowPalette.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsButtonGroup(
                        children: [
                          SettingsPrimaryButton(
                            label: 'Edit CV',
                            icon: Icons.edit_outlined,
                            onPressed: _navigateToEdit,
                          ),
                          SettingsSecondaryButton(
                            label: 'Generate CV',
                            icon: Icons.picture_as_pdf_outlined,
                            onPressed: cvProvider.isExporting
                                ? null
                                : () => _generateCv(cv),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SettingsSecondaryButton(
                        label: 'Preview PDF',
                        icon: Icons.visibility_outlined,
                        onPressed: cv != null && cv.hasBuilderContent
                            ? () => _navigateToPreview(cv)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SettingsSectionHeading(
                  title: 'Builder Blocks',
                  subtitle:
                      'Every section below reflects the current CV data and stays connected to the existing editor.',
                ),
                const SizedBox(height: 10),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SettingsPanel(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 320;
                          final statusPill = SettingsStatusPill(
                            label: section.statusLabel,
                            color: section.complete
                                ? SettingsFlowPalette.success
                                : section.trackInCompletion
                                ? SettingsFlowPalette.warning
                                : SettingsFlowPalette.textSecondary,
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SettingsIconBox(
                                icon: section.icon,
                                color: section.color,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (compact) ...[
                                      Text(
                                        section.title,
                                        style: SettingsFlowTheme.cardTitle(),
                                      ),
                                      const SizedBox(height: 8),
                                      statusPill,
                                    ] else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              section.title,
                                              style:
                                                  SettingsFlowTheme.cardTitle(),
                                            ),
                                          ),
                                          statusPill,
                                        ],
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      section.description,
                                      style: SettingsFlowTheme.caption(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SettingsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SettingsSectionHeading(
                        title: 'Template & Export',
                        subtitle:
                            'Choose the layout you want recruiters to see and preview the output before sharing it.',
                      ),
                      const SizedBox(height: 12),
                      SettingsButtonGroup(
                        children: [
                          SettingsSecondaryButton(
                            label: 'Choose Template',
                            icon: Icons.style_outlined,
                            onPressed: cv != null && cv.hasBuilderContent
                                ? () => _navigateToTemplateSelector(cv)
                                : null,
                          ),
                          SettingsSecondaryButton(
                            label: 'Preview PDF',
                            icon: Icons.remove_red_eye_outlined,
                            onPressed: cv != null && cv.hasBuilderContent
                                ? () => _navigateToPreview(cv)
                                : null,
                          ),
                        ],
                      ),
                      if (cv != null &&
                          cv.hasBuilderContent &&
                          cv.templateId.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          height: 190,
                          decoration: BoxDecoration(
                            color: SettingsFlowPalette.background,
                            borderRadius: SettingsFlowTheme.radius(22),
                            border: Border.all(
                              color: SettingsFlowPalette.border,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: SettingsFlowTheme.radius(22),
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
                const SizedBox(height: 18),
                _PrimaryCvPanel(
                  cv: cv,
                  onUpload: _uploadExistingCv,
                  onViewPrimary: () =>
                      _openSecureCv(variant: 'primary', requirePdf: true),
                  onDownloadPrimary: () =>
                      _openSecureCv(variant: 'primary', download: true),
                  onViewBuilt: () =>
                      _openSecureCv(variant: 'built', requirePdf: true),
                  onDownloadBuilt: () =>
                      _openSecureCv(variant: 'built', download: true),
                  onToggleDefault:
                      cv != null && cv.hasUploadedCv && cv.hasExportedPdf
                      ? () => _togglePrimaryCvMode(cv)
                      : null,
                ),
              ],
            ),
    );
  }

  List<_CvSectionStatus> _buildSections(CvModel? cv) {
    return [
      _CvSectionStatus(
        title: 'Personal Info',
        description: cv == null || cv.fullName.trim().isEmpty
            ? 'Add your name, email, phone, and address to get started.'
            : '${cv.fullName} - ${[cv.email, cv.phone].where((value) => value.trim().isNotEmpty).join(' - ')}',
        icon: Icons.person_outline_rounded,
        color: SettingsFlowPalette.primary,
        complete:
            cv != null &&
            cv.fullName.trim().isNotEmpty &&
            cv.email.trim().isNotEmpty,
      ),
      _CvSectionStatus(
        title: 'Education',
        description: cv == null || cv.education.isEmpty
            ? 'No education added yet.'
            : '${cv.education.length} education entr${cv.education.length == 1 ? 'y' : 'ies'} ready.',
        icon: Icons.school_outlined,
        color: SettingsFlowPalette.secondary,
        complete: cv?.education.isNotEmpty == true,
      ),
      _CvSectionStatus(
        title: 'Experience',
        description: cv == null || cv.experience.isEmpty
            ? 'No experience added yet.'
            : '${cv.experience.length} experience entr${cv.experience.length == 1 ? 'y' : 'ies'} ready.',
        icon: Icons.work_outline_rounded,
        color: SettingsFlowPalette.accent,
        complete: cv?.experience.isNotEmpty == true,
      ),
      _CvSectionStatus(
        title: 'Skills',
        description: cv == null || cv.skills.isEmpty
            ? 'List your strongest skills for recruiters.'
            : '${cv.skills.length} skill${cv.skills.length == 1 ? '' : 's'} added.',
        icon: Icons.auto_awesome_outlined,
        color: SettingsFlowPalette.primaryDark,
        complete: cv?.skills.isNotEmpty == true,
      ),
      _CvSectionStatus(
        title: 'Languages',
        description: cv == null || cv.languages.isEmpty
            ? 'No languages added yet.'
            : '${cv.languages.length} language${cv.languages.length == 1 ? '' : 's'} added.',
        icon: Icons.translate_rounded,
        color: SettingsFlowPalette.success,
        complete: cv?.languages.isNotEmpty == true,
      ),
      const _CvSectionStatus(
        title: 'Certifications',
        description:
            'Dedicated certification entries are not connected to the current CV model yet, so this block is ready for future support.',
        icon: Icons.workspace_premium_outlined,
        color: SettingsFlowPalette.textSecondary,
        complete: false,
        trackInCompletion: false,
        statusLabelOverride: 'Soon',
      ),
    ];
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }

    return 'Could not open the document right now.';
  }
}

class _PrimaryCvPanel extends StatelessWidget {
  final CvModel? cv;
  final VoidCallback onUpload;
  final VoidCallback onViewPrimary;
  final VoidCallback onDownloadPrimary;
  final VoidCallback onViewBuilt;
  final VoidCallback onDownloadBuilt;
  final VoidCallback? onToggleDefault;

  const _PrimaryCvPanel({
    required this.cv,
    required this.onUpload,
    required this.onViewPrimary,
    required this.onDownloadPrimary,
    required this.onViewBuilt,
    required this.onDownloadBuilt,
    this.onToggleDefault,
  });

  @override
  Widget build(BuildContext context) {
    final uploadedAt = cv?.uploadedCvUploadedAt;
    final uploadedLabel = uploadedAt == null
        ? 'Not uploaded yet'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    final usesUploaded =
        cv != null && (cv!.primaryCvMode == 'uploaded' || !cv!.hasExportedPdf);

    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeading(
            title: 'Primary CV Access',
            subtitle:
                'Keep the original uploaded PDF available for applications, recruiters, and admin review.',
          ),
          const SizedBox(height: 12),
          SettingsListRow(
            icon: Icons.upload_file_outlined,
            iconColor: SettingsFlowPalette.primary,
            title: cv?.hasUploadedCv == true
                ? 'Uploaded Primary CV'
                : 'No Primary CV Uploaded',
            subtitle: cv?.hasUploadedCv == true
                ? '${cv!.uploadedCvDisplayName} - Uploaded $uploadedLabel'
                : 'Upload a PDF to keep a recruiter-ready primary file on hand.',
            onTap: onUpload,
            trailing: SettingsStatusPill(
              label: cv?.hasUploadedCv == true ? 'Ready' : 'Upload',
              color: cv?.hasUploadedCv == true
                  ? SettingsFlowPalette.success
                  : SettingsFlowPalette.warning,
            ),
          ),
          const SizedBox(height: 12),
          SettingsButtonGroup(
            children: [
              SettingsSecondaryButton(
                label: 'Upload Primary CV',
                icon: Icons.upload_outlined,
                onPressed: onUpload,
              ),
              SettingsSecondaryButton(
                label: 'View Primary CV',
                icon: Icons.visibility_outlined,
                onPressed: cv?.hasUploadedCv == true && cv!.isUploadedCvPdf
                    ? onViewPrimary
                    : null,
              ),
            ],
          ),
          if (cv?.hasUploadedCv == true) ...[
            const SizedBox(height: 12),
            SettingsSecondaryButton(
              label: 'Download Primary CV',
              icon: Icons.download_outlined,
              onPressed: onDownloadPrimary,
            ),
          ],
          if (cv?.hasExportedPdf == true) ...[
            const SizedBox(height: 16),
            SettingsListRow(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: SettingsFlowPalette.secondary,
              title: 'Built CV PDF',
              subtitle: 'Open or download the PDF exported from the builder.',
              trailing: SettingsStatusPill(
                label: usesUploaded ? 'Secondary' : 'Default',
                color: usesUploaded
                    ? SettingsFlowPalette.warning
                    : SettingsFlowPalette.success,
              ),
            ),
            const SizedBox(height: 12),
            SettingsButtonGroup(
              children: [
                SettingsSecondaryButton(
                  label: 'View Built CV',
                  icon: Icons.visibility_outlined,
                  onPressed: onViewBuilt,
                ),
                SettingsSecondaryButton(
                  label: 'Download Built CV',
                  icon: Icons.download_outlined,
                  onPressed: onDownloadBuilt,
                ),
              ],
            ),
          ],
          if (onToggleDefault != null) ...[
            const SizedBox(height: 14),
            SettingsPrimaryButton(
              label: usesUploaded
                  ? 'Use Built CV for Applications'
                  : 'Use Uploaded CV for Applications',
              icon: Icons.swap_horiz_rounded,
              onPressed: onToggleDefault,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final String completionLabel;

  const _CompletionBadge({required this.completionLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: SettingsFlowPalette.primaryGradient,
        borderRadius: SettingsFlowTheme.radius(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            completionLabel,
            style: SettingsFlowTheme.heroTitle(
              Colors.white,
            ).copyWith(fontSize: 22),
          ),
          Text(
            'Ready',
            style: SettingsFlowTheme.micro(
              Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _CvSectionStatus {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool complete;
  final bool trackInCompletion;
  final String? statusLabelOverride;

  const _CvSectionStatus({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.complete,
    this.trackInCompletion = true,
    this.statusLabelOverride,
  });

  String get statusLabel =>
      statusLabelOverride ??
      (complete
          ? 'Complete'
          : trackInCompletion
          ? 'Needs details'
          : 'Info');
}
