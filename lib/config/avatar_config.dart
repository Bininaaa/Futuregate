import 'package:flutter/material.dart';

class AvatarDefinition {
  final String id;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AvatarDefinition({
    required this.id,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}

class AvatarConfig {
  AvatarConfig._();

  static const List<AvatarDefinition> avatars = [
    AvatarDefinition(
      id: 'avatar_1',
      icon: Icons.person_outline_rounded,
      backgroundColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1565C0),
    ),
    AvatarDefinition(
      id: 'avatar_2',
      icon: Icons.school_outlined,
      backgroundColor: Color(0xFFFCE4EC),
      iconColor: Color(0xFFC62828),
    ),
    AvatarDefinition(
      id: 'avatar_3',
      icon: Icons.code_rounded,
      backgroundColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
    ),
    AvatarDefinition(
      id: 'avatar_4',
      icon: Icons.architecture_rounded,
      backgroundColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
    ),
    AvatarDefinition(
      id: 'avatar_5',
      icon: Icons.science_outlined,
      backgroundColor: Color(0xFFF3E5F5),
      iconColor: Color(0xFF6A1B9A),
    ),
    AvatarDefinition(
      id: 'avatar_6',
      icon: Icons.insights_rounded,
      backgroundColor: Color(0xFFE0F7FA),
      iconColor: Color(0xFF00838F),
    ),
    AvatarDefinition(
      id: 'avatar_7',
      icon: Icons.auto_awesome_outlined,
      backgroundColor: Color(0xFFFFF8E1),
      iconColor: Color(0xFFF9A825),
    ),
    AvatarDefinition(
      id: 'avatar_8',
      icon: Icons.workspace_premium_outlined,
      backgroundColor: Color(0xFFEFEBE9),
      iconColor: Color(0xFF4E342E),
    ),
  ];

  static AvatarDefinition? getById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return avatars.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
