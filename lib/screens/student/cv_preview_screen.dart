import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';
import '../../services/cv_pdf_service.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/student/student_workspace_shell.dart';

class CvPreviewScreen extends StatefulWidget {
  final CvModel cv;

  const CvPreviewScreen({super.key, required this.cv});

  @override
  State<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends State<CvPreviewScreen> {
  Future<Uint8List>? _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = CvPdfService.generatePdf(widget.cv);
  }

  Future<void> _exportAndUpload() async {
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    final error = await context.read<CvProvider>().exportCvAsPdf(
      studentId: uid,
    );

    if (!mounted) return;

    if (error == null) {
      context.showAppSnackBar(
        'Your CV PDF has been exported and saved.',
        title: 'Export complete',
        type: AppFeedbackType.success,
      );
      Navigator.pop(context, true);
    } else {
      context.showAppSnackBar(
        error,
        title: 'Export unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _share(Uint8List bytes) async {
    final templateId = CvTemplateConfig.resolveTemplateId(widget.cv.templateId);
    await Printing.sharePdf(bytes: bytes, filename: 'cv_$templateId.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudentWorkspaceAppBar(
          title: 'CV Preview',
          subtitle: 'Review the final layout before you export or share it.',
          icon: Icons.picture_as_pdf_rounded,
          showBackButton: true,
          onBack: () => Navigator.maybePop(context),
          actions: [
            FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return StudentWorkspaceActionButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Share PDF',
                  onTap: () => _share(snapshot.data!),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _pdfFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: SettingsFlowPalette.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Generating PDF...',
                            style: SettingsFlowTheme.caption(),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: AppEmptyStateNotice(
                          type: AppFeedbackType.error,
                          icon: Icons.picture_as_pdf_rounded,
                          title: 'Preview unavailable',
                          message:
                              'We couldn\'t generate this PDF preview right now. ${snapshot.error}',
                          accentColor: SettingsFlowPalette.error,
                        ),
                      ),
                    );
                  }

                  return PdfPreview(
                    build: (_) => snapshot.data!,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: false,
                    allowSharing: false,
                    pdfFileName: 'cv_preview.pdf',
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SettingsFlowPalette.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: cvProvider.isExporting
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                          color: SettingsFlowPalette.primary,
                        ),
                      ),
                    )
                  : SettingsPrimaryButton(
                      label: 'Export & Save CV',
                      icon: Icons.cloud_upload_outlined,
                      onPressed: _exportAndUpload,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
