import 'package:flutter/material.dart';

import 'chat_theme.dart';

class ChatActionSheetItem {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const ChatActionSheetItem({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });
}

class ChatActionSheet extends StatelessWidget {
  final List<ChatActionSheetItem> actions;

  const ChatActionSheet({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ChatThemePalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ChatThemePalette.border),
          boxShadow: ChatThemeStyles.softShadow(0.06),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map((action) => _ChatActionSheetRow(action: action))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ChatActionSheetRow extends StatelessWidget {
  final ChatActionSheetItem action;

  const _ChatActionSheetRow({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: action.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: ChatThemeStyles.actionLabel(
                    action.accentColor == ChatThemePalette.error
                        ? ChatThemePalette.error
                        : ChatThemePalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
