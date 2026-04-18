import 'package:flutter/material.dart';

import 'chat_theme.dart';

class ChatSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry margin;

  const ChatSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.focusNode,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: ChatThemePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ChatThemePalette.border.withValues(alpha: 0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Icon(
              Icons.search_rounded,
              color: ChatThemePalette.textSecondary,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: ChatThemeStyles.body().copyWith(fontSize: 13),
                cursorColor: ChatThemePalette.primary,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: ChatThemeStyles.body(
                    ChatThemePalette.textSecondary.withValues(alpha: 0.72),
                  ).copyWith(fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.trim().isEmpty) {
                  return const SizedBox(width: 12);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    tooltip: 'Clear search',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    onPressed:
                        onClear ??
                        () {
                          controller.clear();
                          onChanged?.call('');
                        },
                    icon: Icon(
                      Icons.close_rounded,
                      color: ChatThemePalette.textSecondary,
                      size: 17,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
