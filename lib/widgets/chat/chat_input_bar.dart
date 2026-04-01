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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ChatThemePalette.border.withValues(alpha: 0.5)),
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
                    label: 'Editing message',
                    onClear: onCancelEdit,
                  ),
                if (isEditing && pendingAttachment != null) const SizedBox(height: 8),
                if (pendingAttachment != null)
                  _AttachmentPreview(
                    attachment: pendingAttachment!,
                    onRemove: onRemoveAttachment,
                  ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Attach',
                    color: ChatThemePalette.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                            const Icon(Icons.image_outlined, color: ChatThemePalette.primary, size: 20),
                            const SizedBox(width: 10),
                            Text('Photo', style: ChatThemeStyles.body()),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'file',
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file_rounded, color: ChatThemePalette.secondary, size: 20),
                            const SizedBox(width: 10),
                            Text('File', style: ChatThemeStyles.body()),
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
                      child: const Icon(Icons.add_rounded, color: ChatThemePalette.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: ChatThemePalette.border.withValues(alpha: 0.6),
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
                              style: ChatThemeStyles.body().copyWith(fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: isEditing ? 'Edit your message...' : 'Message...',
                                hintStyle: ChatThemeStyles.body(ChatThemePalette.textSecondary).copyWith(fontSize: 13.5),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => onSend(),
                            ),
                          ),
                          GestureDetector(
                            onTap: onEmojiTap,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.sentiment_satisfied_alt_outlined,
                                color: ChatThemePalette.textSecondary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
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
                          color: ChatThemePalette.primary.withValues(alpha: 0.25),
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
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(
                              isEditing ? Icons.check_rounded : Icons.send_rounded,
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
              style: ChatThemeStyles.meta(ChatThemePalette.primary).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 16, color: ChatThemePalette.primary),
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
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChatThemePalette.border.withValues(alpha: 0.5)),
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
              attachment.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
              color: attachment.isImage ? ChatThemePalette.secondary : ChatThemePalette.primary,
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
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 16, color: ChatThemePalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
