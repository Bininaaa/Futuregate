import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

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
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: hasUnread
                    ? ChatThemePalette.primary.withValues(alpha: 0.04)
                    : ChatThemePalette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasUnread
                      ? ChatThemePalette.primary.withValues(alpha: 0.15)
                      : ChatThemePalette.border.withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ChatThemePalette.primary.withValues(
                      alpha: hasUnread ? 0.06 : 0.03,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: ChatThemeStyles.cardTitle().copyWith(
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 14.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                    fontSize: 10.5,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                style:
                                    ChatThemeStyles.body(
                                      hasUnread
                                          ? ChatThemePalette.textPrimary
                                          : ChatThemePalette.textSecondary,
                                    ).copyWith(
                                      fontSize: 12.5,
                                      fontWeight: hasUnread
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      height: 1.3,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: ChatThemePalette.primaryGradient,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: ChatThemeStyles.meta(Colors.white)
                                        .copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_hasMetaPills) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (conversation.contextLabel.trim().isNotEmpty)
                                _MetaPill(
                                  icon: Icons.work_outline_rounded,
                                  label: conversation.contextLabel.trim(),
                                  foregroundColor: ChatThemePalette.primaryDark,
                                  backgroundColor: ChatThemePalette.primary
                                      .withValues(alpha: 0.07),
                                ),
                              if (widget.isMuted)
                                _MetaPill(
                                  icon: Icons.notifications_off_outlined,
                                  label: AppLocalizations.of(context)!.uiMuted,
                                ),
                              if (widget.isArchived)
                                _MetaPill(
                                  icon: Icons.archive_outlined,
                                  label: AppLocalizations.of(context)!.uiArchived,
                                  foregroundColor: ChatThemePalette.secondary,
                                  backgroundColor: Color(0x1100A38C),
                                ),
                            ],
                          ),
                        ],
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

  bool get _hasMetaPills =>
      widget.conversation.contextLabel.trim().isNotEmpty ||
      widget.isMuted ||
      widget.isArchived;
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ChatThemePalette.primary.withValues(alpha: 0.22),
                ChatThemePalette.secondary.withValues(alpha: 0.14),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: conversation.isGroup
              ? CircleAvatar(
                  radius: 24,
                  backgroundColor: ChatThemePalette.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    _groupInitials(fallbackName),
                    style: ChatThemeStyles.cardTitle(
                      ChatThemePalette.primary,
                    ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                )
              : ProfileAvatar(
                  user: profile,
                  userId: conversation.otherParticipantId(currentUserId),
                  radius: 24,
                  fallbackName: fallbackName,
                  role: conversation.otherParticipantRole(currentUserId),
                ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: ChatThemePalette.success,
                shape: BoxShape.circle,
                border: Border.all(color: ChatThemePalette.surface, width: 2),
              ),
            ),
          ),
      ],
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
  final Color? foregroundColor;
  final Color? backgroundColor;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedForegroundColor =
        foregroundColor ?? ChatThemePalette.textSecondary;
    final resolvedBackgroundColor =
        backgroundColor ?? ChatThemePalette.surfaceMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: resolvedForegroundColor),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              style: ChatThemeStyles.meta(
                resolvedForegroundColor,
              ).copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
