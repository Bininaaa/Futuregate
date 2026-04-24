import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/message_model.dart';
import '../../models/secure_document_link.dart';
import '../../models/user_model.dart';
import '../../services/document_access_service.dart';
import '../profile_avatar.dart';
import '../shared/app_feedback.dart';
import 'chat_action_sheet.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = (screenWidth * 0.72).clamp(200.0, 420.0);

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 10 : 3,
        bottom: isLastInGroup ? 6 : 2,
        left: 14,
        right: 14,
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
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: showAvatar ? 1 : 0,
                  child: showAvatar
                      ? ProfileAvatar(
                          user: otherUser,
                          userId: otherUserId,
                          radius: 15,
                          fallbackName: fallbackName,
                          role: otherRole,
                        )
                      : const SizedBox(width: 30, height: 30),
                ),
              ),
            Flexible(
              child: GestureDetector(
                onLongPress: isMe && !message.isDeleted
                    ? () => _showActions(context)
                    : null,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: EdgeInsets.fromLTRB(
                    14,
                    message.hasAttachment ? 8 : 10,
                    14,
                    8,
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
                                const SizedBox(height: 10),
                              Text(
                                message.text.trim(),
                                style: ChatThemeStyles.body(
                                  isMe
                                      ? Colors.white
                                      : ChatThemePalette.textPrimary,
                                ).copyWith(fontSize: 13.5, height: 1.45),
                              ),
                            ],
                            const SizedBox(height: 5),
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
            ? ChatThemePalette.primary.withValues(alpha: 0.45)
            : ChatThemePalette.border.withValues(alpha: 0.6),
        borderRadius: _bubbleRadius(),
      );
    }

    return BoxDecoration(
      gradient: isMe
          ? LinearGradient(
              colors: [
                ChatThemePalette.primaryDark,
                ChatThemePalette.primary,
                Color(0xFF5B39FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: isMe ? null : ChatThemePalette.surfaceElevated,
      borderRadius: _bubbleRadius(),
      border: Border.all(
        color: isMe
            ? Colors.white.withValues(alpha: 0.06)
            : ChatThemePalette.border.withValues(alpha: 0.92),
      ),
      boxShadow: [
        BoxShadow(
          color: isMe
              ? ChatThemePalette.primary.withValues(alpha: 0.12)
              : ChatThemePalette.primary.withValues(alpha: 0.04),
          blurRadius: isMe ? 18 : 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  BorderRadius _bubbleRadius() {
    const regular = Radius.circular(20);
    const tail = Radius.circular(6);

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
        return ChatActionSheet(
          actions: [
            if (message.isTextMessage)
              ChatActionSheetItem(
                icon: Icons.edit_outlined,
                label: AppLocalizations.of(context)!.uiEditMessage,
                accentColor: ChatThemePalette.primary,
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            ChatActionSheetItem(
              icon: Icons.delete_outline_rounded,
              label: AppLocalizations.of(context)!.uiDeleteForEveryone,
              accentColor: ChatThemePalette.error,
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
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
        ? Colors.white.withValues(alpha: 0.78)
        : ChatThemePalette.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'This message was deleted',
            style: ChatThemeStyles.body(
              color,
            ).copyWith(fontStyle: FontStyle.italic, fontSize: 12.5),
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
        ? Colors.white.withValues(alpha: 0.72)
        : ChatThemePalette.textSecondary;
    final isSeen = message.seenAt != null || message.isRead;
    final isDelivered = message.deliveredAt != null;
    final statusIcon = isSeen
        ? Icons.done_all_rounded
        : isDelivered
        ? Icons.done_all_rounded
        : Icons.done_rounded;
    final statusColor = isMe
        ? (isSeen ? Colors.white : Colors.white.withValues(alpha: 0.68))
        : metaColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Text(
            'edited',
            style: ChatThemeStyles.meta(
              metaColor,
            ).copyWith(fontStyle: FontStyle.italic, fontSize: 10),
          ),
        if (message.isEdited) const SizedBox(width: 3),
        Text(
          ChatFormatters.messageTime(message.sentAt),
          style: ChatThemeStyles.meta(metaColor).copyWith(fontSize: 10),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(statusIcon, size: 13, color: statusColor),
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
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ChatThemePalette.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: snapshot.hasError
                ? Icon(
                    Icons.broken_image_outlined,
                    color: ChatThemePalette.textSecondary,
                  )
                : const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ImagePreviewScreen(
                  imageUrl: document.viewUrl,
                  downloadUrl: document.downloadUrl,
                  title: widget.message.fileName.trim().isEmpty
                      ? 'Photo'
                      : widget.message.fileName.trim(),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: document.viewUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: ChatThemePalette.background,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: ChatThemePalette.background,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: ChatThemePalette.textSecondary,
                      ),
                    ),
                  ),
                ],
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
        ? Colors.white.withValues(alpha: 0.14)
        : ChatThemePalette.background;
    final borderColor = isMe
        ? Colors.white.withValues(alpha: 0.12)
        : ChatThemePalette.border;
    final iconBackground = isMe
        ? Colors.white.withValues(alpha: 0.16)
        : ChatThemePalette.primary.withValues(alpha: 0.08);
    final iconColor = isMe ? Colors.white : ChatThemePalette.primary;
    final titleColor = isMe ? Colors.white : ChatThemePalette.textPrimary;
    final metaColor = isMe
        ? Colors.white.withValues(alpha: 0.7)
        : ChatThemePalette.textSecondary;

    return InkWell(
      onTap: () => _openAttachment(context),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
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
                    ).copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      ChatFormatters.fileSizeLabel(message.fileSize),
                      _fileTypeLabel(message.mimeType, message.fileName),
                    ].where((item) => item.trim().isNotEmpty).join(' - '),
                    style: ChatThemeStyles.meta(
                      metaColor,
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AttachmentDownloadButton(
              foregroundColor: iconColor,
              backgroundColor: iconBackground,
              borderColor: borderColor,
              onTap: () => _openAttachment(context, download: true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(
    BuildContext context, {
    bool download = false,
  }) async {
    try {
      final document = await DocumentAccessService().getChatAttachmentDocument(
        conversationId: conversationId,
        messageId: message.id,
      );
      if (!context.mounted) {
        return;
      }
      await _launchAttachment(context, document: document, download: download);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      context.showAppSnackBar(
        download
            ? 'We couldn\'t download this attachment. $error'
            : 'We couldn\'t open this attachment. $error',
        title: AppLocalizations.of(context)!.uiAttachmentUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  String _fileTypeLabel(String mimeType, String fileName) {
    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (normalizedMimeType.isNotEmpty) {
      if (normalizedMimeType.startsWith('image/')) return 'IMAGE';
      if (normalizedMimeType == 'application/pdf') return 'PDF FILE';
      if (normalizedMimeType.contains('word')) return 'DOC FILE';
      if (normalizedMimeType.contains('sheet') ||
          normalizedMimeType.contains('excel')) {
        return 'SPREADSHEET';
      }
    }

    final normalizedFileName = fileName.trim().toLowerCase();
    if (normalizedFileName.endsWith('.fig')) return 'FIGMA FILE';
    if (normalizedFileName.contains('.')) {
      return normalizedFileName.split('.').last.toUpperCase();
    }
    return 'FILE';
  }
}

class _AttachmentDownloadButton extends StatelessWidget {
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _AttachmentDownloadButton({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.uiDownloadA479,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.download_rounded,
              color: foregroundColor,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchAttachment(
  BuildContext context, {
  required SecureDocumentLink document,
  required bool download,
}) {
  final url = download && document.downloadUrl.trim().isNotEmpty
      ? document.downloadUrl
      : document.viewUrl;
  return _launchAttachmentUrl(context, url, download: download);
}

Future<void> _launchAttachmentUrl(
  BuildContext context,
  String url, {
  required bool download,
}) async {
  try {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      throw Exception('File unavailable.');
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched && context.mounted) {
      context.showAppSnackBar(
        download
            ? 'We couldn\'t download this attachment.'
            : 'We couldn\'t open this attachment.',
        title: AppLocalizations.of(context)!.uiAttachmentUnavailable,
        type: AppFeedbackType.error,
      );
    }
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    context.showAppSnackBar(
      download
          ? 'We couldn\'t download this attachment. $error'
          : 'We couldn\'t open this attachment. $error',
      title: AppLocalizations.of(context)!.uiAttachmentUnavailable,
      type: AppFeedbackType.error,
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String downloadUrl;
  final String title;

  const _ImagePreviewScreen({
    required this.imageUrl,
    required this.downloadUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = ChatThemePalette.secondary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: actionColor,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_rounded, color: actionColor),
        ),
        title: Text(title, style: ChatThemeStyles.cardTitle(Colors.white)),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.uiDownloadA479,
            onPressed: () =>
                _launchAttachmentUrl(context, downloadUrl, download: true),
            icon: Icon(Icons.download_rounded, color: actionColor),
          ),
        ],
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
