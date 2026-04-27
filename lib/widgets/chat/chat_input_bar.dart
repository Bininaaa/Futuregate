import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import 'chat_formatters.dart';
import 'chat_theme.dart';

class PendingChatAttachment {
  final String fileName;
  final String filePath;
  final Uint8List? bytes;
  final int fileSize;
  final String mimeType;
  final String messageType;

  const PendingChatAttachment({
    required this.fileName,
    this.filePath = '',
    this.bytes,
    this.fileSize = 0,
    this.mimeType = '',
    required this.messageType,
  });

  bool get isImage => messageType == 'image';
}

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isEditing;
  final bool isAiProcessing;
  final PendingChatAttachment? pendingAttachment;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onCancelEdit;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onEmojiTap;
  final bool showAiTools;
  final VoidCallback onAiFormalize;
  final VoidCallback onAiCorrect;
  final VoidCallback onAiTranslate;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isEditing,
    this.isAiProcessing = false,
    this.showAiTools = false,
    required this.pendingAttachment,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.onCancelEdit,
    required this.onRemoveAttachment,
    required this.onEmojiTap,
    required this.onAiFormalize,
    required this.onAiCorrect,
    required this.onAiTranslate,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final FocusNode _messageFocusNode = FocusNode();

  TextEditingController get controller => widget.controller;
  bool get isSending => widget.isSending;
  bool get isEditing => widget.isEditing;
  bool get isAiProcessing => widget.isAiProcessing;
  PendingChatAttachment? get pendingAttachment => widget.pendingAttachment;
  VoidCallback get onSend => widget.onSend;
  VoidCallback get onPickImage => widget.onPickImage;
  VoidCallback get onPickFile => widget.onPickFile;
  VoidCallback get onCancelEdit => widget.onCancelEdit;
  VoidCallback get onRemoveAttachment => widget.onRemoveAttachment;
  VoidCallback get onEmojiTap => widget.onEmojiTap;
  bool get showAiTools => widget.showAiTools;
  VoidCallback get onAiFormalize => widget.onAiFormalize;
  VoidCallback get onAiCorrect => widget.onAiCorrect;
  VoidCallback get onAiTranslate => widget.onAiTranslate;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _messageFocusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openSystemKeyboard() {
    _messageFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    onEmojiTap();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        border: Border(
          top: BorderSide(
            color: ChatThemePalette.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing || pendingAttachment != null) ...[
                if (isEditing)
                  _StatusBanner(
                    icon: Icons.edit_outlined,
                    label: AppLocalizations.of(context)!.uiEditingMessage,
                    onClear: onCancelEdit,
                  ),
                if (isEditing && pendingAttachment != null)
                  const SizedBox(height: 8),
                if (pendingAttachment != null)
                  _AttachmentPreview(
                    attachment: pendingAttachment!,
                    onRemove: onRemoveAttachment,
                  ),
                const SizedBox(height: 8),
              ],
              if (showAiTools) ...[
                if (isAiProcessing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AiProcessingIndicator(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        _AiChip(
                          icon: Icons.auto_awesome_outlined,
                          label: AppLocalizations.of(context)!.uiFormalize,
                          onTap: onAiFormalize,
                        ),
                        const SizedBox(width: 6),
                        _AiChip(
                          icon: Icons.spellcheck_rounded,
                          label: AppLocalizations.of(context)!.uiCorrect,
                          onTap: onAiCorrect,
                        ),
                        const SizedBox(width: 6),
                        _AiChip(
                          icon: Icons.translate_rounded,
                          label: AppLocalizations.of(context)!.uiTranslate,
                          onTap: onAiTranslate,
                        ),
                      ],
                    ),
                  ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    tooltip: AppLocalizations.of(context)!.uiAttach,
                    color: ChatThemePalette.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onSelected: (value) {
                      if (value == 'image') {
                        onPickImage();
                        return;
                      }
                      onPickFile();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'image',
                        child: Row(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: ChatThemePalette.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.uiPhoto,
                              style: ChatThemeStyles.body(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'file',
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              color: ChatThemePalette.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.uiFile,
                              style: ChatThemeStyles.body(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ChatThemePalette.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: ChatThemePalette.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: ChatThemePalette.surfaceMuted,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _messageFocusNode.hasFocus
                              ? ChatThemePalette.primary
                              : ChatThemePalette.border.withValues(alpha: 0.6),
                          width: _messageFocusNode.hasFocus ? 1.4 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: _messageFocusNode,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        style: ChatThemeStyles.body().copyWith(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: isEditing
                              ? 'Edit your message...'
                              : 'Message...',
                          hintStyle: ChatThemeStyles.body(
                            ChatThemePalette.textSecondary,
                          ).copyWith(fontSize: 13.5),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            12,
                            4,
                            12,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Emoji keyboard',
                            onPressed: _openSystemKeyboard,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            icon: Icon(
                              Icons.sentiment_satisfied_alt_outlined,
                              color: ChatThemePalette.textSecondary,
                              size: 22,
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 42,
                            minHeight: 38,
                          ),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: ChatThemePalette.fabGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ChatThemePalette.primary.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: isSending ? null : onSend,
                      padding: EdgeInsets.zero,
                      icon: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              isEditing
                                  ? Icons.check_rounded
                                  : Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onClear;

  const _StatusBanner({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatThemePalette.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ChatThemePalette.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: ChatThemeStyles.meta(ChatThemePalette.primary),
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(99),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: ChatThemePalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final PendingChatAttachment attachment;
  final VoidCallback onRemove;

  const _AttachmentPreview({required this.attachment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ChatThemePalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ChatThemePalette.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: attachment.isImage
                  ? ChatThemePalette.secondary.withValues(alpha: 0.12)
                  : ChatThemePalette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              attachment.isImage
                  ? Icons.image_outlined
                  : Icons.insert_drive_file_outlined,
              color: attachment.isImage
                  ? ChatThemePalette.secondary
                  : ChatThemePalette.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: ChatThemeStyles.cardTitle().copyWith(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    ChatFormatters.fileSizeLabel(attachment.fileSize),
                    attachment.isImage ? 'IMAGE' : 'FILE',
                  ].where((part) => part.trim().isNotEmpty).join(' - '),
                  style: ChatThemeStyles.meta().copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(99),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: ChatThemePalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AiChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ChatThemePalette.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ChatThemePalette.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: ChatThemePalette.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: ChatThemeStyles.meta(
                ChatThemePalette.primary,
              ).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiProcessingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatThemePalette.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ChatThemePalette.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI is processing...',
            style: ChatThemeStyles.meta(ChatThemePalette.primary),
          ),
        ],
      ),
    );
  }
}
