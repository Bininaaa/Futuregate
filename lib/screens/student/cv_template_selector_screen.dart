import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';
import '../../widgets/cv_templates/cv_template_preview.dart';

class CvTemplateSelectorScreen extends StatefulWidget {
  final CvModel cv;
  final String currentTemplateId;

  const CvTemplateSelectorScreen({
    super.key,
    required this.cv,
    required this.currentTemplateId,
  });

  @override
  State<CvTemplateSelectorScreen> createState() =>
      _CvTemplateSelectorScreenState();
}

class _CvTemplateSelectorScreenState extends State<CvTemplateSelectorScreen> {
  late String _selectedId;

  static const Color strongBlue = Color(0xFF004E98);
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color softGray = Color(0xFFEBEBEB);

  @override
  void initState() {
    super.initState();
    _selectedId = CvTemplateConfig.resolveTemplateId(widget.currentTemplateId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Choose Template',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedId),
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: vibrantOrange,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: CvTemplateConfig.templates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.6,
          ),
          itemBuilder: (context, index) {
            final template = CvTemplateConfig.templates[index];
            final isSelected = template.id == _selectedId;

            return GestureDetector(
              onTap: () => setState(() => _selectedId = template.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? vibrantOrange : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? vibrantOrange.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Preview
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: CvTemplatePreview(
                          cv: widget.cv,
                          templateId: template.id,
                        ),
                      ),
                    ),
                    // Label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? vibrantOrange.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            template.icon,
                            size: 16,
                            color: isSelected ? vibrantOrange : strongBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              template.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? vibrantOrange : strongBlue,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: vibrantOrange,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
