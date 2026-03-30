import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
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
  static const Color strongBlue = Color(0xFF004E98);
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);
  final DocumentAccessService _documentAccessService = DocumentAccessService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<CvProvider>().loadCv(uid);
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

      // Save CV with the new template ID
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

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Template changed to ${CvTemplateConfig.getTemplate(selectedId).name}',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    }
  }

  Future<void> _navigateToPreview(CvModel cv) async {
    final exported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CvPreviewScreen(cv: cv)),
    );
    if (exported == true) _reload();
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

    final file = result.files.single;
    final validationError = DocumentUploadValidator.validatePrimaryCv(
      fileName: file.name,
      sizeInBytes: file.size,
    );

    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validationError)));
      }
      return;
    }

    if (!mounted) return;

    final error = await context.read<CvProvider>().uploadCvFile(
      studentId: uid,
      filePath: file.path ?? '',
      fileName: file.name,
      fileBytes: file.bytes,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV uploaded successfully')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
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

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newMode == 'uploaded'
                ? 'Using uploaded CV as primary'
                : 'Using builder CV as primary',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openSecureCv({
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final uid = _uid;
    if (uid == null) return;

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
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();
    final cv = cvProvider.cv;

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'My CV',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
      ),
      body: cvProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(cv),
                const SizedBox(height: 16),
                _buildBuiltCvSection(cv),
                const SizedBox(height: 16),
                _buildPrimaryCvSection(cv),
                const SizedBox(height: 16),
                _buildApplicationDefaultCard(cv),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildStatusCard(CvModel? cv) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (cv == null || (!cv.hasBuilderContent && !cv.hasUploadedCv)) {
      statusText =
          'No CV yet — get started by editing your content or uploading a file';
      statusIcon = Icons.info_outline;
      statusColor = mediumBlue;
    } else if (cv.hasBuilderContent && cv.hasUploadedCv) {
      statusText =
          'Hybrid CV — you have both builder content and an uploaded file';
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else if (cv.hasBuilderContent) {
      statusText = cv.templateId.trim().isNotEmpty
          ? 'Builder CV with ${CvTemplateConfig.getTemplate(cv.templateId).name} template'
          : 'Builder CV — choose a template to preview and export';
      statusIcon = Icons.description_outlined;
      statusColor = strongBlue;
    } else {
      statusText = 'Uploaded CV: ${cv.uploadedFileName}';
      statusIcon = Icons.upload_file;
      statusColor = strongBlue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: strongBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuiltCvSection(CvModel? cv) {
    final hasBuilderContent = cv?.hasBuilderContent ?? false;
    final hasExportedPdf = cv?.hasExportedPdf ?? false;
    final templateName = cv != null && cv.templateId.trim().isNotEmpty
        ? CvTemplateConfig.getTemplate(cv.templateId).name
        : 'No template selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Built CV',
          subtitle: 'Your structured profile CV and exported PDF.',
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasBuilderContent
                    ? 'Template: $templateName'
                    : 'No built CV content yet',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: strongBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasBuilderContent
                    ? hasExportedPdf
                          ? 'Your built CV is ready and exported as a PDF.'
                          : 'Your built CV content is ready. Export it to generate the PDF recruiters can open.'
                    : 'Add your details to create a professional built CV and export it as PDF.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.5,
                  color: mediumBlue,
                ),
              ),
              const SizedBox(height: 14),
              _buildActionCard(
                icon: Icons.edit_note,
                title: 'Edit CV Content',
                subtitle: hasBuilderContent
                    ? 'Update your information, education, and experience'
                    : 'Fill in your information to get started',
                onTap: _navigateToEdit,
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                icon: Icons.style_outlined,
                title: 'Choose Template',
                subtitle: templateName,
                onTap: () {
                  if (cv == null || !cv.hasBuilderContent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in your CV content first'),
                      ),
                    );
                    return;
                  }
                  _navigateToTemplateSelector(cv);
                },
                enabled: hasBuilderContent,
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Preview & Export PDF',
                subtitle: hasExportedPdf
                    ? 'Refresh or review the built CV PDF'
                    : 'Generate a PDF from your built CV',
                onTap: () {
                  if (cv == null || !cv.hasBuilderContent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in your CV content first'),
                      ),
                    );
                    return;
                  }
                  _navigateToPreview(cv);
                },
                enabled: hasBuilderContent,
              ),
              if (hasExportedPdf) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildDocumentButton(
                        label: 'View Built CV',
                        icon: Icons.visibility_outlined,
                        color: strongBlue,
                        onPressed: () =>
                            _openSecureCv(variant: 'built', requirePdf: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDocumentButton(
                        label: 'Download Built CV',
                        icon: Icons.download_outlined,
                        color: vibrantOrange,
                        onPressed: () =>
                            _openSecureCv(variant: 'built', download: true),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (cv != null &&
            cv.hasBuilderContent &&
            cv.templateId.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildTemplatePreviewCard(cv),
        ],
      ],
    );
  }

  Widget _buildPrimaryCvSection(CvModel? cv) {
    final hasPrimaryCv = cv?.hasUploadedCv ?? false;
    final uploadedAt = cv?.uploadedCvUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Primary CV',
          subtitle:
              'The uploaded PDF file recruiters and admins can review directly.',
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: hasPrimaryCv
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv!.uploadedCvDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: strongBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploaded: $uploadedAtLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: mediumBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!cv.isUploadedCvPdf)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'This uploaded file is not a valid PDF. Please replace it with a PDF so it can be viewed by recruiters and admins.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.5,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDocumentButton(
                            label: 'View Primary CV',
                            icon: Icons.visibility_outlined,
                            color: strongBlue,
                            onPressed: cv.isUploadedCvPdf
                                ? () => _openSecureCv(
                                    variant: 'primary',
                                    requirePdf: true,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDocumentButton(
                            label: 'Download Primary CV',
                            icon: Icons.download_outlined,
                            color: vibrantOrange,
                            onPressed: () => _openSecureCv(
                              variant: 'primary',
                              download: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildActionCard(
                      icon: Icons.upload_file,
                      title: 'Replace Primary CV',
                      subtitle: 'Upload a newer PDF version of your primary CV',
                      onTap: _uploadExistingCv,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No primary CV uploaded yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: strongBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload a PDF CV so companies and admins can view the original file directly.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: mediumBlue,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildActionCard(
                      icon: Icons.upload_file,
                      title: 'Upload Primary CV',
                      subtitle: 'Upload your main CV as a PDF file',
                      onTap: _uploadExistingCv,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildApplicationDefaultCard(CvModel? cv) {
    if (cv == null || (!cv.hasUploadedCv && !cv.hasExportedPdf)) {
      return const SizedBox.shrink();
    }

    final usesUploadedCv = cv.primaryCvMode == 'uploaded' && cv.hasUploadedCv;
    final activeLabel = usesUploadedCv || !cv.hasExportedPdf
        ? 'Applications currently use: Primary CV'
        : 'Applications currently use: Built CV PDF';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Default',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            activeLabel,
            style: GoogleFonts.poppins(fontSize: 12, color: mediumBlue),
          ),
          if (cv.hasUploadedCv && cv.hasExportedPdf) ...[
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.swap_horiz,
              title: 'Switch Primary CV',
              subtitle: usesUploadedCv
                  ? 'Currently using the uploaded PDF'
                  : 'Currently using the built CV PDF',
              onTap: () => _togglePrimaryCvMode(cv),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: strongBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: mediumBlue),
        ),
      ],
    );
  }

  Widget _buildTemplatePreviewCard(CvModel cv) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  CvTemplateConfig.getTemplate(cv.templateId).icon,
                  color: strongBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${CvTemplateConfig.getTemplate(cv.templateId).name} Template',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: strongBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: softGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CvTemplatePreview(cv: cv, templateId: cv.templateId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? strongBlue : Colors.grey, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? strongBlue : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: enabled
                          ? strongBlue.withValues(alpha: 0.6)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: enabled
                  ? strongBlue.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    return 'Could not open the document right now.';
  }
}
