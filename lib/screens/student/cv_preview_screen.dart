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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CV exported and saved',
            style: SettingsFlowTheme.body(Colors.white),
          ),
          backgroundColor: SettingsFlowPalette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: SettingsFlowTheme.radius(12),
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: SettingsFlowPalette.error,
        ),
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: SettingsFlowPalette.textPrimary,
            ),
          ),
          title: Text('Preview', style: SettingsFlowTheme.appBarTitle()),
          actions: [
            FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: SettingsFlowPalette.textPrimary,
                  ),
                  tooltip: 'Share PDF',
                  onPressed: () => _share(snapshot.data!),
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
                          const CircularProgressIndicator(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: SettingsFlowPalette.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to generate PDF',
                              style: SettingsFlowTheme.sectionTitle(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              snapshot.error.toString(),
                              style: SettingsFlowTheme.caption(),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                  ? const Center(
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
