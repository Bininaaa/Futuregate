import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = message.sentAt != null
        ? DateFormat.Hm().format(message.sentAt!.toDate())
        : '';

    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFFFF6700).withValues(alpha: 0.3)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 14,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                'This message was deleted',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: isMe ? () => _showActions(context) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFF6700) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isEdited) ...[
                    Text(
                      'edited',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF004E98)),
              title: Text(AppLocalizations.of(context)!.editMessageLabel, style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(ctx);
                onEdit?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Delete for everyone',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
