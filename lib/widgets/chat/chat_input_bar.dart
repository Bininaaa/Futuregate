import 'dart:typed_data';

import 'package:flutter/material.dart';

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

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isEditing;
  final PendingChatAttachment? pendingAttachment;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onCancelEdit;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onEmojiTap;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isEditing,
    required this.pendingAttachment,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.onCancelEdit,
    required this.onRemoveAttachment,
    required this.onEmojiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            gradient: ChatThemePalette.headerGradient,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
            boxShadow: ChatThemeStyles.softShadow(0.09),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing || pendingAttachment != null) ...[
                if (isEditing)
                  _StatusBanner(
                    icon: Icons.edit_outlined,
                    label: 'Editing message',
                    onClear: onCancelEdit,
                  ),
                if (isEditing && pendingAttachment != null)
                  const SizedBox(height: 10),
                if (pendingAttachment != null)
                  _AttachmentPreview(
                    attachment: pendingAttachment!,
                    onRemove: onRemoveAttachment,
                  ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Attach',
                    color: ChatThemePalette.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                            const Icon(
                              Icons.image_outlined,
                              color: ChatThemePalette.primary,
                            ),
                            const SizedBox(width: 10),
                            Text('Attach photo', style: ChatThemeStyles.body()),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'file',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              color: ChatThemePalette.secondary,
                            ),
                            const SizedBox(width: 10),
                            Text('Attach file', style: ChatThemeStyles.body()),
                          ],
                        ),
                      ),
                    ],
                    child: const _RoundIconButton(
                      icon: Icons.add_rounded,
                      color: ChatThemePalette.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: ChatThemePalette.border.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              style: ChatThemeStyles.body(),
                              decoration: InputDecoration(
                                hintText: isEditing
                                    ? 'Edit your message...'
                                    : 'Type your message...',
                                hintStyle: ChatThemeStyles.body(
                                  ChatThemePalette.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => onSend(),
                            ),
                          ),
                          IconButton(
                            onPressed: onEmojiTap,
                            splashRadius: 20,
                            icon: const Icon(
                              Icons.sentiment_satisfied_alt_outlined,
                              color: ChatThemePalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          ChatThemePalette.primaryDark,
                          ChatThemePalette.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: ChatThemeStyles.softShadow(0.12),
                    ),
                    child: IconButton(
                      onPressed: isSending ? null : onSend,
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ChatThemePalette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ChatThemePalette.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ChatThemePalette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: ChatThemeStyles.meta(
                ChatThemePalette.primary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: ChatThemePalette.canvasGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChatThemePalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: attachment.isImage
                  ? ChatThemePalette.secondary.withValues(alpha: 0.14)
                  : ChatThemePalette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              attachment.isImage
                  ? Icons.image_outlined
                  : Icons.insert_drive_file_outlined,
              color: attachment.isImage
                  ? ChatThemePalette.secondary
                  : ChatThemePalette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: ChatThemeStyles.cardTitle().copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    ChatFormatters.fileSizeLabel(attachment.fileSize),
                    attachment.isImage ? 'IMAGE' : 'FILE',
                  ].where((part) => part.trim().isNotEmpty).join(' - '),
                  style: ChatThemeStyles.meta(),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: ChatThemePalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _RoundIconButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Icon(icon, color: color),
    );
  }
}
