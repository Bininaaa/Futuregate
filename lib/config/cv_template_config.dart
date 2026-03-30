import 'package:flutter/material.dart';

class CvTemplateInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;

  const CvTemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}

class CvTemplateConfig {
  static const String classic = 'classic';
  static const String modern = 'modern';
  static const String minimal = 'minimal';
  static const String professional = 'professional';

  static const String defaultTemplate = classic;

  static const List<CvTemplateInfo> templates = [
    CvTemplateInfo(
      id: classic,
      name: 'Classic',
      description: 'Traditional single-column with clean sections',
      icon: Icons.article_outlined,
      accentColor: Color(0xFF2D3436),
    ),
    CvTemplateInfo(
      id: modern,
      name: 'Modern',
      description: 'Two-column layout with navy sidebar',
      icon: Icons.view_sidebar_outlined,
      accentColor: Color(0xFF1B2838),
    ),
    CvTemplateInfo(
      id: minimal,
      name: 'Minimal',
      description: 'Clean grayscale with generous whitespace',
      icon: Icons.text_snippet_outlined,
      accentColor: Color(0xFF555555),
    ),
    CvTemplateInfo(
      id: professional,
      name: 'Professional',
      description: 'Header band with two-column body',
      icon: Icons.workspace_premium_outlined,
      accentColor: Color(0xFF2C3E50),
    ),
  ];

  static CvTemplateInfo getTemplate(String id) {
    return templates.firstWhere(
      (t) => t.id == id,
      orElse: () => templates.first,
    );
  }

  static String resolveTemplateId(String templateId) {
    if (templateId.trim().isEmpty) return defaultTemplate;
    final valid = templates.any((t) => t.id == templateId);
    return valid ? templateId : defaultTemplate;
  }
}
