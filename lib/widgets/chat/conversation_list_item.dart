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
  final bool isArchived;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onOpenProfile;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.unreadCount,
    this.isMuted = false,
    this.isArchived = false,
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

    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final subtitle = conversation.listPreviewText;
        final isOnline = profile?.isOnline ?? false;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(30),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: ChatThemePalette.headerGradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: hasUnread
                      ? ChatThemePalette.primary.withValues(alpha: 0.2)
                      : ChatThemePalette.border,
                ),
                boxShadow: ChatThemeStyles.softShadow(hasUnread ? 0.11 : 0.06),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: hasUnread || widget.isArchived
                          ? LinearGradient(
                              colors: [
                                hasUnread
                                    ? ChatThemePalette.primary
                                    : ChatThemePalette.secondary,
                                ChatThemePalette.primaryDark,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: hasUnread || widget.isArchived
                          ? null
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: widget.onOpenProfile,
                    child: _ConversationAvatar(
                      conversation: conversation,
                      currentUserId: widget.currentUserId,
                      profile: profile,
                      fallbackName: displayName,
                      isOnline: isOnline,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: ChatThemeStyles.cardTitle().copyWith(
                                      fontWeight: hasUnread
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      fontSize: 15.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (conversation.contextLabel.trim().isNotEmpty)
                                        _MetaPill(
                                          icon: Icons.work_outline_rounded,
                                          label: conversation.contextLabel.trim(),
                                          foregroundColor:
                                              ChatThemePalette.primaryDark,
                                          backgroundColor: ChatThemePalette.primary
                                              .withValues(alpha: 0.08),
                                        ),
                                      if (widget.isMuted)
                                        const _MetaPill(
                                          icon: Icons.notifications_off_outlined,
                                          label: 'Muted',
                                        ),
                                      if (widget.isArchived)
                                        const _MetaPill(
                                          icon: Icons.archive_outlined,
                                          label: 'Archived',
                                          foregroundColor:
                                              ChatThemePalette.secondary,
                                          backgroundColor: Color(0x1100A38C),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasUnread
                                        ? ChatThemePalette.primary.withValues(
                                            alpha: 0.09,
                                          )
                                        : ChatThemePalette.surfaceMuted,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    ChatFormatters.inboxTimestamp(
                                      conversation.lastMessageTime,
                                    ),
                                    style: ChatThemeStyles.meta(
                                      hasUnread
                                          ? ChatThemePalette.primary
                                          : ChatThemePalette.textSecondary,
                                    ).copyWith(
                                      fontWeight: hasUnread
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (hasUnread)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: ChatThemePalette.primaryGradient,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(999),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: ChatThemeStyles.meta(
                                          Colors.white,
                                        ).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 28),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          style: ChatThemeStyles.body(
                            hasUnread
                                ? ChatThemePalette.textPrimary
                                : ChatThemePalette.textSecondary,
                          ).copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

class _ConversationAvatar extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final UserModel? profile;
  final String fallbackName;
  final bool isOnline;

  const _ConversationAvatar({
    required this.conversation,
    required this.currentUserId,
    required this.profile,
    required this.fallbackName,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ChatThemePalette.primary.withValues(alpha: 0.32),
            ChatThemePalette.secondary.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (conversation.isGroup)
            CircleAvatar(
              radius: 28,
              backgroundColor: ChatThemePalette.primary.withValues(alpha: 0.12),
              child: Text(
                _groupInitials(fallbackName),
                style: ChatThemeStyles.cardTitle(
                  ChatThemePalette.primary,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            )
          else
            ProfileAvatar(
              user: profile,
              userId: conversation.otherParticipantId(currentUserId),
              radius: 28,
              fallbackName: fallbackName,
              role: conversation.otherParticipantRole(currentUserId),
            ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: ChatThemePalette.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _groupInitials(String name) {
    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .join();
    return initials.isEmpty ? 'G' : initials;
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.foregroundColor = ChatThemePalette.textSecondary,
    this.backgroundColor = const Color(0xFFF3F6FD),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: foregroundColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 146),
            child: Text(
              label,
              style: ChatThemeStyles.meta(
                foregroundColor,
              ).copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
