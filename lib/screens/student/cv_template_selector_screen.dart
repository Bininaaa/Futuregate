import 'package:flutter/material.dart';

import '../../config/cv_template_config.dart';
import '../../models/cv_model.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../widgets/app_shell_background.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedId = CvTemplateConfig.resolveTemplateId(widget.currentTemplateId);
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            'Choose Template',
            style: SettingsFlowTheme.appBarTitle(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedId),
              child: Text(
                'Apply',
                style: SettingsFlowTheme.body(SettingsFlowPalette.primary),
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
                    color: SettingsFlowPalette.surface,
                    borderRadius: SettingsFlowTheme.radius(18),
                    border: Border.all(
                      color: isSelected
                          ? SettingsFlowPalette.primary
                          : SettingsFlowPalette.border,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? SettingsFlowPalette.primary.withValues(
                                alpha: 0.12,
                              )
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(isSelected ? 15.5 : 17),
                          ),
                          child: CvTemplatePreview(
                            cv: widget.cv,
                            templateId: template.id,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SettingsFlowPalette.primary.withValues(
                                  alpha: 0.06,
                                )
                              : SettingsFlowPalette.surface,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(isSelected ? 15.5 : 17),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              template.icon,
                              size: 16,
                              color: isSelected
                                  ? SettingsFlowPalette.primary
                                  : SettingsFlowPalette.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                template.name,
                                style: SettingsFlowTheme.cardTitle(
                                  isSelected
                                      ? SettingsFlowPalette.primary
                                      : SettingsFlowPalette.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: SettingsFlowPalette.primary,
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
      ),
    );
  }
}
