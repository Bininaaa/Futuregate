import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/cv_template_config.dart';
import '../models/cv_model.dart';

class CvPdfService {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    if (_regular != null && _bold != null) return;
    final regularData = await rootBundle.load(
      'assets/fonts/Poppins-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }

  static pw.TextStyle _style({
    double fontSize = 10,
    bool bold = false,
    PdfColor? color,
    double? lineSpacing,
  }) {
    return pw.TextStyle(
      font: bold ? _bold : _regular,
      fontBold: _bold,
      fontSize: fontSize,
      color: color ?? PdfColors.black,
      lineSpacing: lineSpacing,
    );
  }

  static Future<Uint8List> generatePdf(CvModel cv) async {
    await _loadFonts();
    final templateId = CvTemplateConfig.resolveTemplateId(cv.templateId);
    switch (templateId) {
      case CvTemplateConfig.modern:
        return _buildModernPdf(cv);
      case CvTemplateConfig.minimal:
        return _buildMinimalPdf(cv);
      case CvTemplateConfig.professional:
        return _buildProfessionalPdf(cv);
      case CvTemplateConfig.classic:
      default:
        return _buildClassicPdf(cv);
    }
  }

  // ─── CLASSIC — Charcoal / Slate / White ────────────────────────────────
  // Traditional single-column. Clean horizontal rules. Dark charcoal headers.

  static const _classicDark = PdfColor.fromInt(0xFF2D3436);
  static const _classicMuted = PdfColor.fromInt(0xFF636E72);
  static const _classicRule = PdfColor.fromInt(0xFFB2BEC3);

  static Future<Uint8List> _buildClassicPdf(CvModel cv) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(44),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
              style: _style(fontSize: 22, bold: true, color: _classicDark),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              [
                cv.email,
                cv.phone,
                cv.address,
              ].where((s) => s.trim().isNotEmpty).join('   |   '),
              style: _style(fontSize: 9, color: _classicMuted),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: _classicDark, thickness: 1.2),
          pw.SizedBox(height: 14),
          if (cv.summary.trim().isNotEmpty) ...[
            _classicSection('PROFILE'),
            pw.Text(
              cv.summary,
              style: _style(
                fontSize: 9.5,
                color: _classicMuted,
                lineSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 16),
          ],
          if (cv.experience.isNotEmpty) ...[
            _classicSection('EXPERIENCE'),
            ...cv.experience.map(
              (exp) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          exp['position'] ?? '',
                          style: _style(
                            fontSize: 10.5,
                            bold: true,
                            color: _classicDark,
                          ),
                        ),
                        pw.Text(
                          exp['duration'] ?? '',
                          style: _style(fontSize: 9, color: _classicMuted),
                        ),
                      ],
                    ),
                    pw.Text(
                      exp['company'] ?? '',
                      style: _style(fontSize: 9, color: _classicMuted),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.education.isNotEmpty) ...[
            _classicSection('EDUCATION'),
            ...cv.education.map(
              (edu) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          edu['degree'] ?? '',
                          style: _style(
                            fontSize: 10.5,
                            bold: true,
                            color: _classicDark,
                          ),
                        ),
                        pw.Text(
                          edu['year'] ?? '',
                          style: _style(fontSize: 9, color: _classicMuted),
                        ),
                      ],
                    ),
                    pw.Text(
                      edu['institution'] ?? '',
                      style: _style(fontSize: 9, color: _classicMuted),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.skills.isNotEmpty) ...[
            _classicSection('SKILLS'),
            pw.Wrap(
              spacing: 8,
              runSpacing: 5,
              children: cv.skills
                  .map(
                    (s) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _classicRule),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        s,
                        style: _style(fontSize: 8.5, color: _classicDark),
                      ),
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.languages.isNotEmpty) ...[
            _classicSection('LANGUAGES'),
            pw.Wrap(
              spacing: 14,
              runSpacing: 4,
              children: cv.languages
                  .map(
                    (l) => pw.Text(
                      l,
                      style: _style(fontSize: 9.5, color: _classicDark),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _classicSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: _style(fontSize: 11, bold: true, color: _classicDark),
          ),
          pw.SizedBox(height: 2),
          pw.Divider(color: _classicRule, thickness: 0.6),
        ],
      ),
    );
  }

  // ─── MODERN — Navy sidebar / White body ────────────────────────────────
  // Two-column: dark navy sidebar with contact/skills, white main area.

  static const _modernNavy = PdfColor.fromInt(0xFF1B2838);
  static const _modernSlate = PdfColor.fromInt(0xFF5A6C7D);
  static const _modernAccent = PdfColor.fromInt(0xFF4A90A4);

  static Future<Uint8List> _buildModernPdf(CvModel cv) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sidebar
            pw.Container(
              width: 185,
              height: double.infinity,
              color: _modernNavy,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 30,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
                    style: _style(
                      fontSize: 17,
                      bold: true,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    height: 0.5,
                    color: const PdfColor.fromInt(0xFF3D5468),
                  ),
                  pw.SizedBox(height: 16),
                  _modernSideLabel('CONTACT'),
                  if (cv.email.isNotEmpty) _modernSideItem(cv.email),
                  if (cv.phone.isNotEmpty) _modernSideItem(cv.phone),
                  if (cv.address.isNotEmpty) _modernSideItem(cv.address),
                  pw.SizedBox(height: 16),
                  if (cv.skills.isNotEmpty) ...[
                    _modernSideLabel('SKILLS'),
                    ...cv.skills.map((s) => _modernSideItem(s)),
                    pw.SizedBox(height: 16),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    _modernSideLabel('LANGUAGES'),
                    ...cv.languages.map((l) => _modernSideItem(l)),
                  ],
                ],
              ),
            ),
            // Main content
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (cv.summary.trim().isNotEmpty) ...[
                      _modernMainSection('PROFILE'),
                      pw.Text(
                        cv.summary,
                        style: _style(
                          fontSize: 9.5,
                          color: _modernSlate,
                          lineSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                    if (cv.experience.isNotEmpty) ...[
                      _modernMainSection('EXPERIENCE'),
                      ...cv.experience.map(
                        (exp) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 5,
                                height: 5,
                                margin: const pw.EdgeInsets.only(
                                  top: 4,
                                  right: 10,
                                ),
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  color: _modernAccent,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      exp['position'] ?? '',
                                      style: _style(fontSize: 10.5, bold: true),
                                    ),
                                    pw.Text(
                                      '${exp['company'] ?? ''}${(exp['duration'] ?? '').toString().isNotEmpty ? '  •  ${exp['duration']}' : ''}',
                                      style: _style(
                                        fontSize: 9,
                                        color: _modernSlate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 18),
                    ],
                    if (cv.education.isNotEmpty) ...[
                      _modernMainSection('EDUCATION'),
                      ...cv.education.map(
                        (edu) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 5,
                                height: 5,
                                margin: const pw.EdgeInsets.only(
                                  top: 4,
                                  right: 10,
                                ),
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  color: _modernAccent,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      edu['degree'] ?? '',
                                      style: _style(fontSize: 10.5, bold: true),
                                    ),
                                    pw.Text(
                                      '${edu['institution'] ?? ''}${(edu['year'] ?? '').toString().isNotEmpty ? '  •  ${edu['year']}' : ''}',
                                      style: _style(
                                        fontSize: 9,
                                        color: _modernSlate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _modernSideLabel(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: _style(fontSize: 9, bold: true, color: _modernAccent),
      ),
    );
  }

  static pw.Widget _modernSideItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        text,
        style: _style(fontSize: 8.5, color: const PdfColor.fromInt(0xFFCCD6DD)),
      ),
    );
  }

  static pw.Widget _modernMainSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: _style(fontSize: 12, bold: true, color: _modernNavy),
          ),
          pw.SizedBox(height: 3),
          pw.Container(width: 28, height: 2, color: _modernAccent),
        ],
      ),
    );
  }

  // ─── MINIMAL — Pure grayscale / maximum whitespace ─────────────────────

  static const _minDark = PdfColor.fromInt(0xFF333333);
  static const _minMed = PdfColor.fromInt(0xFF777777);
  static const _minLight = PdfColor.fromInt(0xFFBBBBBB);

  static Future<Uint8List> _buildMinimalPdf(CvModel cv) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 52, vertical: 48),
        build: (context) => [
          pw.Text(
            cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
            style: _style(fontSize: 26, color: _minDark),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            [
              cv.email,
              cv.phone,
              cv.address,
            ].where((s) => s.trim().isNotEmpty).join('   •   '),
            style: _style(fontSize: 9, color: _minMed),
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: _minLight, thickness: 0.5),
          pw.SizedBox(height: 18),
          if (cv.summary.trim().isNotEmpty) ...[
            pw.Text(
              cv.summary,
              style: _style(fontSize: 9.5, color: _minMed, lineSpacing: 2.5),
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: _minLight, thickness: 0.5),
            pw.SizedBox(height: 18),
          ],
          if (cv.experience.isNotEmpty) ...[
            _minSection('Experience'),
            ...cv.experience.map(
              (exp) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          exp['position'] ?? '',
                          style: _style(
                            fontSize: 10.5,
                            bold: true,
                            color: _minDark,
                          ),
                        ),
                        pw.Text(
                          exp['duration'] ?? '',
                          style: _style(fontSize: 9, color: _minLight),
                        ),
                      ],
                    ),
                    pw.Text(
                      exp['company'] ?? '',
                      style: _style(fontSize: 9, color: _minMed),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.education.isNotEmpty) ...[
            _minSection('Education'),
            ...cv.education.map(
              (edu) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          edu['degree'] ?? '',
                          style: _style(
                            fontSize: 10.5,
                            bold: true,
                            color: _minDark,
                          ),
                        ),
                        pw.Text(
                          edu['year'] ?? '',
                          style: _style(fontSize: 9, color: _minLight),
                        ),
                      ],
                    ),
                    pw.Text(
                      edu['institution'] ?? '',
                      style: _style(fontSize: 9, color: _minMed),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.skills.isNotEmpty) ...[
            _minSection('Skills'),
            pw.Text(
              cv.skills.join(',   '),
              style: _style(fontSize: 9.5, color: _minMed),
            ),
            pw.SizedBox(height: 14),
          ],
          if (cv.languages.isNotEmpty) ...[
            _minSection('Languages'),
            pw.Text(
              cv.languages.join(',   '),
              style: _style(fontSize: 9.5, color: _minMed),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _minSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: _style(fontSize: 11, bold: true, color: _minDark),
      ),
    );
  }

  // ─── PROFESSIONAL — Slate header / Muted blue accents ──────────────────
  // Full-width slate header, two-column body, tag pills.

  static const _proHeader = PdfColor.fromInt(0xFF2C3E50);
  static const _proAccent = PdfColor.fromInt(0xFF5B8C9E);
  static const _proMuted = PdfColor.fromInt(0xFF7F8C8D);
  static const _proBg = PdfColor.fromInt(0xFFF7F8FA);

  static Future<Uint8List> _buildProfessionalPdf(CvModel cv) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header band
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 44,
                vertical: 30,
              ),
              color: _proHeader,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
                    style: _style(
                      fontSize: 22,
                      bold: true,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    [
                      cv.email,
                      cv.phone,
                      cv.address,
                    ].where((s) => s.trim().isNotEmpty).join('   |   '),
                    style: _style(
                      fontSize: 9,
                      color: const PdfColor.fromInt(0xFFBDC3C7),
                    ),
                  ),
                ],
              ),
            ),
            // Summary bar
            if (cv.summary.trim().isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 14,
                ),
                color: _proBg,
                child: pw.Text(
                  cv.summary,
                  style: _style(
                    fontSize: 9.5,
                    color: _proMuted,
                    lineSpacing: 2,
                  ),
                ),
              ),
            // Two-column body
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 22,
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left — Experience
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 18),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (cv.experience.isNotEmpty) ...[
                              _proSection('EXPERIENCE'),
                              ...cv.experience.map(
                                (exp) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 12),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        exp['position'] ?? '',
                                        style: _style(
                                          fontSize: 10.5,
                                          bold: true,
                                          color: _proHeader,
                                        ),
                                      ),
                                      pw.Text(
                                        '${exp['company'] ?? ''}${(exp['duration'] ?? '').toString().isNotEmpty ? '  •  ${exp['duration']}' : ''}',
                                        style: _style(
                                          fontSize: 9,
                                          color: _proMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Right — Education, Skills, Languages
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 18),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (cv.education.isNotEmpty) ...[
                              _proSection('EDUCATION'),
                              ...cv.education.map(
                                (edu) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 12),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        edu['degree'] ?? '',
                                        style: _style(
                                          fontSize: 10.5,
                                          bold: true,
                                          color: _proHeader,
                                        ),
                                      ),
                                      pw.Text(
                                        '${edu['institution'] ?? ''}${(edu['year'] ?? '').toString().isNotEmpty ? '  •  ${edu['year']}' : ''}',
                                        style: _style(
                                          fontSize: 9,
                                          color: _proMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 14),
                            ],
                            if (cv.skills.isNotEmpty) ...[
                              _proSection('SKILLS'),
                              pw.Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: cv.skills
                                    .map(
                                      (s) => pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 3,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          color: _proAccent,
                                          borderRadius:
                                              pw.BorderRadius.circular(10),
                                        ),
                                        child: pw.Text(
                                          s,
                                          style: _style(
                                            fontSize: 8,
                                            color: PdfColors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              pw.SizedBox(height: 14),
                            ],
                            if (cv.languages.isNotEmpty) ...[
                              _proSection('LANGUAGES'),
                              ...cv.languages.map(
                                (l) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 4),
                                  child: pw.Text(
                                    l,
                                    style: _style(
                                      fontSize: 9.5,
                                      color: _proHeader,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _proSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: _style(fontSize: 11, bold: true, color: _proHeader),
          ),
          pw.SizedBox(height: 3),
          pw.Container(width: 26, height: 2, color: _proAccent),
        ],
      ),
    );
  }
}
