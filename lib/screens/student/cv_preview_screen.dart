import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../services/cv_pdf_service.dart';

class CvPreviewScreen extends StatefulWidget {
  final CvModel cv;

  const CvPreviewScreen({super.key, required this.cv});

  @override
  State<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends State<CvPreviewScreen> {
  static const Color strongBlue = Color(0xFF004E98);
  static const Color vibrantOrange = Color(0xFFFF6700);

  Future<Uint8List>? _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = CvPdfService.generatePdf(widget.cv);
  }

  Future<void> _exportAndUpload() async {
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    final error =
        await context.read<CvProvider>().exportCvAsPdf(studentId: uid);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV exported and saved successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _share(Uint8List bytes) async {
    final templateId =
        CvTemplateConfig.resolveTemplateId(widget.cv.templateId);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'cv_$templateId.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Preview CV',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
        actions: [
          FutureBuilder<Uint8List>(
            future: _pdfFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share PDF',
                onPressed: () => _share(snapshot.data!),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF Preview
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Generating PDF...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to generate PDF',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

          // Export button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _exportAndUpload,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      'Export & Save CV',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vibrantOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
