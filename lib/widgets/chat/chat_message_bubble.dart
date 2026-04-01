import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/message_model.dart';
import '../../models/secure_document_link.dart';
import '../../models/user_model.dart';
import '../../services/document_access_service.dart';
import '../profile_avatar.dart';
import 'chat_formatters.dart';
import 'chat_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final String conversationId;
  final MessageModel message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showAvatar;
  final UserModel? otherUser;
  final String otherUserId;
  final String otherRole;
  final String fallbackName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatMessageBubble({
    super.key,
    required this.conversationId,
    required this.message,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.showAvatar,
    required this.otherUser,
    required this.otherUserId,
    required this.otherRole,
    required this.fallbackName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 12 : 4,
        bottom: isLastInGroup ? 8 : 2,
        left: 18,
        right: 18,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: showAvatar ? 1 : 0,
                  child: showAvatar
                      ? ProfileAvatar(
                          user: otherUser,
                          userId: otherUserId,
                          radius: 16,
                          fallbackName: fallbackName,
                          role: otherRole,
                        )
                      : const SizedBox(width: 32, height: 32),
                ),
              ),
            Flexible(
              child: GestureDetector(
                onLongPress: isMe && !message.isDeleted
                    ? () => _showActions(context)
                    : null,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 304),
                  padding: EdgeInsets.fromLTRB(
                    15,
                    message.hasAttachment ? 10 : 12,
                    15,
                    11,
                  ),
                  decoration: _bubbleDecoration(),
                  child: message.isDeleted
                      ? _DeletedMessageRow(isMe: isMe)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.isImageMessage)
                              _ImageAttachmentBubble(
                                conversationId: conversationId,
                                message: message,
                              ),
                            if (message.isFileMessage)
                              _FileAttachmentBubble(
                                conversationId: conversationId,
                                message: message,
                                isMe: isMe,
                              ),
                            if (message.text.trim().isNotEmpty) ...[
                              if (message.hasAttachment)
                                const SizedBox(height: 12),
                              Text(
                                message.text.trim(),
                                style: ChatThemeStyles.body(
                                  isMe
                                      ? Colors.white
                                      : ChatThemePalette.textPrimary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            _MessageFooter(message: message, isMe: isMe),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _bubbleDecoration() {
    if (message.isDeleted) {
      return BoxDecoration(
        color: isMe
            ? ChatThemePalette.primary.withValues(alpha: 0.56)
            : ChatThemePalette.border.withValues(alpha: 0.8),
        borderRadius: _bubbleRadius(),
      );
    }

    return BoxDecoration(
      gradient: isMe
          ? const LinearGradient(
              colors: [
                ChatThemePalette.primaryDark,
                ChatThemePalette.primary,
                Color(0xFF5B39FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FF), Color(0xFFF3F7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      color: null,
      borderRadius: _bubbleRadius(),
      border: Border.all(
        color: isMe
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE4EAF5),
      ),
      boxShadow: [
        BoxShadow(
          color: isMe
              ? ChatThemePalette.primary.withValues(alpha: 0.16)
              : const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: isMe ? 24 : 18,
          offset: const Offset(0, 11),
        ),
      ],
    );
  }

  BorderRadius _bubbleRadius() {
    const regular = Radius.circular(24);
    const tail = Radius.circular(10);

    if (isMe) {
      return BorderRadius.only(
        topLeft: regular,
        topRight: regular,
        bottomLeft: regular,
        bottomRight: isLastInGroup ? tail : regular,
      );
    }

    return BorderRadius.only(
      topLeft: regular,
      topRight: regular,
      bottomLeft: isLastInGroup ? tail : regular,
      bottomRight: regular,
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: ChatThemePalette.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isTextMessage)
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: ChatThemePalette.primary,
                    ),
                    title: Text(
                      'Edit message',
                      style: ChatThemeStyles.cardTitle(),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit?.call();
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: ChatThemePalette.error,
                  ),
                  title: Text(
                    'Delete for everyone',
                    style: ChatThemeStyles.cardTitle(ChatThemePalette.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeletedMessageRow extends StatelessWidget {
  final bool isMe;

  const _DeletedMessageRow({required this.isMe});

  @override
  Widget build(BuildContext context) {
    final color = isMe
        ? Colors.white.withValues(alpha: 0.84)
        : ChatThemePalette.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'This message was deleted',
            style: ChatThemeStyles.body(
              color,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _MessageFooter extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageFooter({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final metaColor = isMe
        ? Colors.white.withValues(alpha: 0.8)
        : ChatThemePalette.textSecondary;
    final isSeen = message.seenAt != null || message.isRead;
    final isDelivered = message.deliveredAt != null;
    final statusIcon = isSeen
        ? Icons.done_all_rounded
        : isDelivered
        ? Icons.done_all_rounded
        : Icons.done_rounded;
    final statusColor = isMe
        ? (isSeen ? Colors.white : Colors.white.withValues(alpha: 0.78))
        : metaColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Text(
            'edited',
            style: ChatThemeStyles.meta(
              metaColor,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        if (message.isEdited) const SizedBox(width: 4),
        Text(
          ChatFormatters.messageTime(message.sentAt),
          style: ChatThemeStyles.meta(metaColor),
        ),
        if (isMe) ...[
          const SizedBox(width: 6),
          Icon(statusIcon, size: 14, color: statusColor),
        ],
      ],
    );
  }
}

class _ImageAttachmentBubble extends StatefulWidget {
  final String conversationId;
  final MessageModel message;

  const _ImageAttachmentBubble({
    required this.conversationId,
    required this.message,
  });

  @override
  State<_ImageAttachmentBubble> createState() => _ImageAttachmentBubbleState();
}

class _ImageAttachmentBubbleState extends State<_ImageAttachmentBubble> {
  late Future<SecureDocumentLink> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = DocumentAccessService().getChatAttachmentDocument(
      conversationId: widget.conversationId,
      messageId: widget.message.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SecureDocumentLink>(
      future: _documentFuture,
      builder: (context, snapshot) {
        final document = snapshot.data;
        if (document == null) {
          return Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ChatThemePalette.background,
              borderRadius: BorderRadius.circular(22),
            ),
            child: snapshot.hasError
                ? const Icon(
                    Icons.broken_image_outlined,
                    color: ChatThemePalette.textSecondary,
                  )
                : const CircularProgressIndicator(),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ImagePreviewScreen(
                  imageUrl: document.viewUrl,
                  title: widget.message.fileName.trim().isEmpty
                      ? 'Photo'
                      : widget.message.fileName.trim(),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1.18,
              child: CachedNetworkImage(
                imageUrl: document.viewUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: ChatThemePalette.background,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: ChatThemePalette.background,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: ChatThemePalette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FileAttachmentBubble extends StatelessWidget {
  final String conversationId;
  final MessageModel message;
  final bool isMe;

  const _FileAttachmentBubble({
    required this.conversationId,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isMe
        ? Colors.white.withValues(alpha: 0.16)
        : ChatThemePalette.background;
    final borderColor = isMe
        ? Colors.white.withValues(alpha: 0.15)
        : ChatThemePalette.border;
    final iconBackground = isMe
        ? Colors.white.withValues(alpha: 0.18)
        : ChatThemePalette.primary.withValues(alpha: 0.08);
    final iconColor = isMe ? Colors.white : ChatThemePalette.primary;
    final titleColor = isMe ? Colors.white : ChatThemePalette.textPrimary;
    final metaColor = isMe
        ? Colors.white.withValues(alpha: 0.76)
        : ChatThemePalette.textSecondary;

    return InkWell(
      onTap: () => _openAttachment(context),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName.trim().isEmpty
                        ? 'Attachment'
                        : message.fileName.trim(),
                    style: ChatThemeStyles.cardTitle(
                      titleColor,
                    ).copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      ChatFormatters.fileSizeLabel(message.fileSize),
                      _fileTypeLabel(message.mimeType, message.fileName),
                    ].where((item) => item.trim().isNotEmpty).join(' - '),
                    style: ChatThemeStyles.meta(metaColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final document = await DocumentAccessService().getChatAttachmentDocument(
        conversationId: conversationId,
        messageId: message.id,
      );
      final uri = Uri.tryParse(document.viewUrl);
      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open this attachment.')),
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Could not open this attachment: $error')),
      );
    }
  }

  String _fileTypeLabel(String mimeType, String fileName) {
    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (normalizedMimeType.isNotEmpty) {
      if (normalizedMimeType.startsWith('image/')) {
        return 'IMAGE';
      }
      if (normalizedMimeType == 'application/pdf') {
        return 'PDF FILE';
      }
      if (normalizedMimeType.contains('word')) {
        return 'DOC FILE';
      }
      if (normalizedMimeType.contains('sheet') ||
          normalizedMimeType.contains('excel')) {
        return 'SPREADSHEET';
      }
    }

    final normalizedFileName = fileName.trim().toLowerCase();
    if (normalizedFileName.endsWith('.fig')) {
      return 'FIGMA FILE';
    }

    if (normalizedFileName.contains('.')) {
      return normalizedFileName.split('.').last.toUpperCase();
    }

    return 'FILE';
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _ImagePreviewScreen({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: ChatThemeStyles.cardTitle(Colors.white)),
      ),
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 3.5,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
