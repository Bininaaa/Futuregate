import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'chat_theme.dart';

class ChatSearchField extends StatefulWidget {
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
  State<ChatSearchField> createState() => _ChatSearchFieldState();
}

class _ChatSearchFieldState extends State<ChatSearchField> {
  late final FocusNode _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ChatSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFocusNode = oldWidget.focusNode ?? _internalFocusNode;
    final nextFocusNode = widget.focusNode ?? _internalFocusNode;
    if (oldFocusNode != nextFocusNode) {
      oldFocusNode.removeListener(_handleFocusChanged);
      nextFocusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        decoration: BoxDecoration(
          color: ChatThemePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _focusNode.hasFocus
                ? ChatThemePalette.primary
                : ChatThemePalette.border.withValues(alpha: 0.95),
            width: _focusNode.hasFocus ? 1.4 : 1,
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
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: ChatThemeStyles.body().copyWith(fontSize: 13),
                cursorColor: ChatThemePalette.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: ChatThemeStyles.body(
                    ChatThemePalette.textSecondary.withValues(alpha: 0.72),
                  ).copyWith(fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                if (value.text.trim().isEmpty) {
                  return const SizedBox(width: 12);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    tooltip: AppLocalizations.of(context)!.uiClearSearch,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    onPressed:
                        widget.onClear ??
                        () {
                          widget.controller.clear();
                          widget.onChanged?.call('');
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
