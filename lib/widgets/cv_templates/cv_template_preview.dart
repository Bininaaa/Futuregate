import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';

class CvTemplatePreview extends StatelessWidget {
  final CvModel cv;
  final String templateId;

  const CvTemplatePreview({
    super.key,
    required this.cv,
    required this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: Colors.white,
        child: AspectRatio(
          aspectRatio: 210 / 297,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(width: 210, height: 297, child: _buildPreview()),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (templateId) {
      case CvTemplateConfig.modern:
        return _ModernPreview(cv: cv);
      case CvTemplateConfig.minimal:
        return _MinimalPreview(cv: cv);
      case CvTemplateConfig.professional:
        return _ProfessionalPreview(cv: cv);
      case CvTemplateConfig.classic:
      default:
        return _ClassicPreview(cv: cv);
    }
  }
}

// ─── CLASSIC — Charcoal / Slate ───────────────────────────────────────────

class _ClassicPreview extends StatelessWidget {
  final CvModel cv;
  const _ClassicPreview({required this.cv});

  static const _dark = Color(0xFF2D3436);
  static const _muted = Color(0xFF636E72);
  static const _rule = Color(0xFFB2BEC3);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            [
              cv.email,
              cv.phone,
            ].where((s) => s.trim().isNotEmpty).join('  |  '),
            style: GoogleFonts.poppins(fontSize: 3.5, color: _muted),
          ),
          const SizedBox(height: 4),
          const Divider(color: _dark, thickness: 0.5, height: 2),
          const SizedBox(height: 5),
          if (cv.summary.trim().isNotEmpty) ...[
            _section('PROFILE'),
            _body(cv.summary),
            const SizedBox(height: 5),
          ],
          if (cv.experience.isNotEmpty) ...[
            _section('EXPERIENCE'),
            ...cv.experience
                .take(2)
                .map(
                  (exp) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exp['position'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 4,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                            Text(
                              exp['duration'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 3,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          exp['company'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 3,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 4),
          ],
          if (cv.education.isNotEmpty) ...[
            _section('EDUCATION'),
            ...cv.education
                .take(2)
                .map(
                  (edu) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              edu['degree'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 4,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                            Text(
                              edu['year'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 3,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          edu['institution'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 3,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (cv.skills.isNotEmpty) ...[
            const SizedBox(height: 4),
            _section('SKILLS'),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: cv.skills
                    .take(4)
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 0.5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _rule, width: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s,
                          style: GoogleFonts.poppins(fontSize: 3, color: _dark),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 4.5,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const Divider(color: _rule, thickness: 0.3, height: 2),
        ],
      ),
    );
  }

  Widget _body(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 3.2, color: _muted),
      ),
    );
  }
}

// ─── MODERN — Navy sidebar ────────────────────────────────────────────────

class _ModernPreview extends StatelessWidget {
  final CvModel cv;
  const _ModernPreview({required this.cv});

  static const _navy = Color(0xFF1B2838);
  static const _accent = Color(0xFF4A90A4);
  static const _slate = Color(0xFF5A6C7D);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 66,
          color: _navy,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
                style: GoogleFonts.poppins(
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 0.3, color: const Color(0xFF3D5468)),
              const SizedBox(height: 5),
              _sideLabel('CONTACT'),
              if (cv.email.isNotEmpty) _sideItem(cv.email),
              if (cv.phone.isNotEmpty) _sideItem(cv.phone),
              const SizedBox(height: 5),
              if (cv.skills.isNotEmpty) ...[
                _sideLabel('SKILLS'),
                ...cv.skills.take(4).map((s) => _sideItem(s)),
              ],
              const SizedBox(height: 5),
              if (cv.languages.isNotEmpty) ...[
                _sideLabel('LANGUAGES'),
                ...cv.languages.take(3).map((l) => _sideItem(l)),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cv.summary.trim().isNotEmpty) ...[
                  _mainSection('PROFILE'),
                  Text(
                    cv.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 3.2, color: _slate),
                  ),
                  const SizedBox(height: 6),
                ],
                if (cv.experience.isNotEmpty) ...[
                  _mainSection('EXPERIENCE'),
                  ...cv.experience
                      .take(2)
                      .map(
                        (exp) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 2.5,
                                height: 2.5,
                                margin: const EdgeInsets.only(
                                  top: 1.5,
                                  right: 3,
                                ),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _accent,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp['position'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${exp['company'] ?? ''} • ${exp['duration'] ?? ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 3,
                                        color: _slate,
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
                if (cv.education.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _mainSection('EDUCATION'),
                  ...cv.education
                      .take(2)
                      .map(
                        (edu) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 2.5,
                                height: 2.5,
                                margin: const EdgeInsets.only(
                                  top: 1.5,
                                  right: 3,
                                ),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _accent,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      edu['degree'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${edu['institution'] ?? ''} • ${edu['year'] ?? ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 3,
                                        color: _slate,
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
    );
  }

  Widget _sideLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 3.5,
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );
  }

  Widget _sideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 3, color: const Color(0xFFCCD6DD)),
      ),
    );
  }

  Widget _mainSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 5,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          Container(width: 12, height: 0.8, color: _accent),
        ],
      ),
    );
  }
}

// ─── MINIMAL — Pure grayscale ─────────────────────────────────────────────

class _MinimalPreview extends StatelessWidget {
  final CvModel cv;
  const _MinimalPreview({required this.cv});

  static const _dark = Color(0xFF333333);
  static const _med = Color(0xFF777777);
  static const _light = Color(0xFFBBBBBB);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: _dark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            [
              cv.email,
              cv.phone,
            ].where((s) => s.trim().isNotEmpty).join('   •   '),
            style: GoogleFonts.poppins(fontSize: 3.2, color: _med),
          ),
          const SizedBox(height: 5),
          Divider(color: _light, thickness: 0.3, height: 2),
          const SizedBox(height: 5),
          if (cv.summary.trim().isNotEmpty) ...[
            Text(
              cv.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 3.2, color: _med),
            ),
            const SizedBox(height: 5),
            Divider(color: _light, thickness: 0.3, height: 2),
            const SizedBox(height: 5),
          ],
          if (cv.experience.isNotEmpty) ...[
            _section('Experience'),
            ...cv.experience
                .take(2)
                .map(
                  (exp) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp['position'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 4,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                            Text(
                              exp['company'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 3,
                                color: _med,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          exp['duration'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 3,
                            color: _light,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 4),
          ],
          if (cv.education.isNotEmpty) ...[
            _section('Education'),
            ...cv.education
                .take(2)
                .map(
                  (edu) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              edu['degree'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 4,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                            Text(
                              edu['institution'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 3,
                                color: _med,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          edu['year'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 3,
                            color: _light,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (cv.skills.isNotEmpty) ...[
            const SizedBox(height: 4),
            _section('Skills'),
            Text(
              cv.skills.take(5).join(',  '),
              style: GoogleFonts.poppins(fontSize: 3.2, color: _med),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 4.5,
          fontWeight: FontWeight.w600,
          color: _dark,
        ),
      ),
    );
  }
}

// ─── PROFESSIONAL — Slate header / Muted blue ─────────────────────────────

class _ProfessionalPreview extends StatelessWidget {
  final CvModel cv;
  const _ProfessionalPreview({required this.cv});

  static const _header = Color(0xFF2C3E50);
  static const _accent = Color(0xFF5B8C9E);
  static const _muted = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _header,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cv.fullName.isNotEmpty ? cv.fullName : 'Your Name',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                [
                  cv.email,
                  cv.phone,
                ].where((s) => s.trim().isNotEmpty).join('   |   '),
                style: GoogleFonts.poppins(
                  fontSize: 3,
                  color: const Color(0xFFBDC3C7),
                ),
              ),
            ],
          ),
        ),
        if (cv.summary.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            color: const Color(0xFFF7F8FA),
            child: Text(
              cv.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 3.2, color: _muted),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cv.experience.isNotEmpty) ...[
                          _colTitle('EXPERIENCE'),
                          ...cv.experience
                              .take(2)
                              .map(
                                (exp) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exp['position'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 4,
                                          fontWeight: FontWeight.w600,
                                          color: _header,
                                        ),
                                      ),
                                      Text(
                                        '${exp['company'] ?? ''} • ${exp['duration'] ?? ''}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 3,
                                          color: _muted,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cv.education.isNotEmpty) ...[
                          _colTitle('EDUCATION'),
                          ...cv.education
                              .take(2)
                              .map(
                                (edu) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        edu['degree'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 4,
                                          fontWeight: FontWeight.w600,
                                          color: _header,
                                        ),
                                      ),
                                      Text(
                                        '${edu['institution'] ?? ''} • ${edu['year'] ?? ''}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 3,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          const SizedBox(height: 4),
                        ],
                        if (cv.skills.isNotEmpty) ...[
                          _colTitle('SKILLS'),
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: cv.skills
                                .take(4)
                                .map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s,
                                      style: GoogleFonts.poppins(
                                        fontSize: 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
    );
  }

  Widget _colTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 4.5,
              fontWeight: FontWeight.w700,
              color: _header,
            ),
          ),
          Container(width: 10, height: 0.6, color: _accent),
        ],
      ),
    );
  }
}
