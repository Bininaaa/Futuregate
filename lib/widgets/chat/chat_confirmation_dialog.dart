import 'package:flutter/material.dart';

import 'chat_theme.dart';

Future<bool?> showChatConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) {
  final accentColor = destructive
      ? ChatThemePalette.error
      : ChatThemePalette.primary;

  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ChatThemePalette.surface, ChatThemePalette.surfaceMuted],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: ChatThemePalette.border),
            boxShadow: ChatThemeStyles.softShadow(0.12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.18),
                      accentColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ??
                      (destructive
                          ? Icons.delete_outline_rounded
                          : Icons.archive_outlined),
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: ChatThemeStyles.dialogTitle(),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      accentColor: accentColor,
                      filled: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? accentColor;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccentColor = accentColor ?? ChatThemePalette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: filled ? resolvedAccentColor : ChatThemePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? resolvedAccentColor : ChatThemePalette.border,
            ),
            boxShadow: filled ? ChatThemeStyles.softShadow(0.06) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: ChatThemeStyles.cardTitle(
                filled ? Colors.white : ChatThemePalette.textPrimary,
              ).copyWith(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
