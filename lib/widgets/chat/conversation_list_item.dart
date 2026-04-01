import 'package:flutter/material.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../services/public_profile_service.dart';
import '../profile_avatar.dart';
import 'chat_formatters.dart';
import 'chat_theme.dart';

class ConversationListItem extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final int unreadCount;
  final bool isMuted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onOpenProfile;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.unreadCount,
    this.isMuted = false,
    required this.onTap,
    this.onLongPress,
    required this.onOpenProfile,
  });

  @override
  State<ConversationListItem> createState() => _ConversationListItemState();
}

class _ConversationListItemState extends State<ConversationListItem> {
  Future<UserModel?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfileFuture();
  }

  @override
  void didUpdateWidget(covariant ConversationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id ||
        oldWidget.currentUserId != widget.currentUserId) {
      _refreshProfileFuture();
    }
  }

  void _refreshProfileFuture() {
    if (widget.conversation.isGroup) {
      _profileFuture = null;
      return;
    }

    _profileFuture = PublicProfileService.instance.fetchPublicProfile(
      widget.conversation.otherParticipantId(widget.currentUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final unreadCount = widget.unreadCount;
    final hasUnread = unreadCount > 0;
    final displayName = conversation.displayNameFor(widget.currentUserId);
    final isMuted = widget.isMuted;

    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final subtitle = conversation.listPreviewText;

        return InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: ChatThemePalette.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: hasUnread
                    ? ChatThemePalette.primary.withValues(alpha: 0.18)
                    : ChatThemePalette.border,
              ),
              boxShadow: ChatThemeStyles.softShadow(hasUnread ? 0.09 : 0.05),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 58,
                  decoration: BoxDecoration(
                    color: hasUnread
                        ? ChatThemePalette.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: widget.onOpenProfile,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ConversationAvatar(
                        conversation: conversation,
                        currentUserId: widget.currentUserId,
                        profile: profile,
                        fallbackName: displayName,
                      ),
                      if (profile?.isOnline ?? false)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: ChatThemePalette.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: ChatThemeStyles.cardTitle().copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMuted)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 14,
                                color: ChatThemePalette.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (conversation.contextLabel.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          conversation.contextLabel.trim(),
                          style: ChatThemeStyles.meta(
                            ChatThemePalette.primary.withValues(alpha: 0.88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style:
                            ChatThemeStyles.body(
                              hasUnread
                                  ? ChatThemePalette.textPrimary
                                  : ChatThemePalette.textSecondary,
                            ).copyWith(
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ChatFormatters.inboxTimestamp(
                        conversation.lastMessageTime,
                      ),
                      style:
                          ChatThemeStyles.meta(
                            hasUnread
                                ? ChatThemePalette.primary
                                : ChatThemePalette.textSecondary,
                          ).copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 10),
                    if (hasUnread)
                      Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          gradient: ChatThemePalette.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: ChatThemeStyles.meta(
                              Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 22),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final UserModel? profile;
  final String fallbackName;

  const _ConversationAvatar({
    required this.conversation,
    required this.currentUserId,
    required this.profile,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation.isGroup) {
      final initials = fallbackName
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .take(2)
          .map((part) => part.trim()[0].toUpperCase())
          .join();

      return CircleAvatar(
        radius: 28,
        backgroundColor: ChatThemePalette.primary.withValues(alpha: 0.12),
        child: Text(
          initials.isEmpty ? 'G' : initials,
          style: ChatThemeStyles.cardTitle(
            ChatThemePalette.primary,
          ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
    }

    return ProfileAvatar(
      user: profile,
      userId: conversation.otherParticipantId(currentUserId),
      radius: 28,
      fallbackName: fallbackName,
      role: conversation.otherParticipantRole(currentUserId),
    );
  }
}
