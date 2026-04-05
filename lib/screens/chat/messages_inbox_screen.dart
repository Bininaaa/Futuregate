import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/chat/chat_confirmation_dialog.dart';
import '../../widgets/chat/chat_theme.dart';
import '../../widgets/chat/conversation_list_item.dart';
import '../../widgets/profile_avatar.dart';
import 'conversation_screen.dart';
import 'new_chat_screen.dart';
import 'user_profile_preview_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  _InboxFilter _selectedFilter = _InboxFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<ChatProvider>().listenToConversations(user.uid, user.role);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().userModel;
    final chatProvider = context.watch<ChatProvider>();
    final conversations = List<ConversationModel>.of(
      chatProvider.conversations,
    );
    final filtered = auth == null
        ? const <ConversationModel>[]
        : _filteredConversations(conversations, auth.uid, chatProvider);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: ChatThemePalette.fabGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ChatThemePalette.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: auth == null ? null : _openNewChat,
            child: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (auth != null)
                      GestureDetector(
                        onTap: () => _openProfile(auth),
                        child: ProfileAvatar(user: auth, radius: 20),
                      ),
                    if (auth != null) const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Messages',
                            style: ChatThemeStyles.title().copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFilter == _InboxFilter.archived
                                ? '${filtered.length} archived'
                                : '${filtered.length} conversations',
                            style:
                                ChatThemeStyles.meta(
                                  ChatThemePalette.textSecondary,
                                ).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: ChatThemePalette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'new') {
                          _openNewChat();
                          return;
                        }
                        setState(() {
                          _selectedFilter = value == 'archived'
                              ? _InboxFilter.archived
                              : _InboxFilter.all;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'new',
                          child: Text(
                            'Start New Chat',
                            style: ChatThemeStyles.body(),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'all',
                          child: Text(
                            'Show Inbox',
                            style: ChatThemeStyles.body(),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'archived',
                          child: Text(
                            'Show Archived',
                            style: ChatThemeStyles.body(),
                          ),
                        ),
                      ],
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: ChatThemePalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: ChatThemePalette.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(
                              () => _searchQuery = value.trim().toLowerCase(),
                            );
                          },
                          style: ChatThemeStyles.body().copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search conversations...',
                            hintStyle: ChatThemeStyles.body(
                              ChatThemePalette.textSecondary,
                            ).copyWith(fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.trim().isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: ChatThemePalette.textSecondary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: _InboxFilter.values
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: filter.label,
                            selected: filter == _selectedFilter,
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (chatProvider.isLoading && conversations.isEmpty) {
                      return const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    }

                    if (!chatProvider.hasHydratedConversationState) {
                      return const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    }

                    if (auth == null) {
                      return const _EmptyState(
                        icon: Icons.lock_outline_rounded,
                        title: 'Sign in to see your messages',
                        subtitle:
                            'Your conversations will appear here once you log in.',
                      );
                    }

                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refreshConversations,
                        color: ChatThemePalette.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
                          children: [
                            _EmptyState(
                              icon: _selectedFilter == _InboxFilter.archived
                                  ? Icons.archive_outlined
                                  : _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              title: _selectedFilter == _InboxFilter.archived
                                  ? 'No archived conversations'
                                  : _searchQuery.isNotEmpty
                                  ? 'No results found'
                                  : 'No conversations yet',
                              subtitle: _selectedFilter == _InboxFilter.archived
                                  ? 'Archived conversations will appear here.'
                                  : _searchQuery.isNotEmpty
                                  ? 'Try a different search term.'
                                  : 'Tap the compose button to start chatting.',
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshConversations,
                      color: ChatThemePalette.primary,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conversation = filtered[index];
                          return ConversationListItem(
                            conversation: conversation,
                            currentUserId: auth.uid,
                            unreadCount: chatProvider.unreadCountFor(
                              conversation.id,
                            ),
                            isMuted: chatProvider.isConversationMutedFor(
                              conversation,
                              auth.uid,
                            ),
                            isArchived: chatProvider.isConversationArchivedFor(
                              conversation,
                              auth.uid,
                            ),
                            onTap: () => _openConversation(conversation),
                            onLongPress: () => _showConversationActions(
                              conversation,
                              auth.uid,
                            ),
                            onOpenProfile: () => _openConversationProfile(
                              conversation,
                              auth.uid,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ConversationModel> _filteredConversations(
    List<ConversationModel> conversations,
    String currentUserId,
    ChatProvider chatProvider,
  ) {
    return conversations
        .where((conversation) {
          if (chatProvider.isConversationDeletedFor(
            conversation,
            currentUserId,
          )) {
            return false;
          }

          final unreadCount = chatProvider.unreadCountFor(conversation.id);
          final isArchived = chatProvider.isConversationArchivedFor(
            conversation,
            currentUserId,
          );

          if (_searchQuery.isNotEmpty) {
            final haystack = [
              conversation.displayNameFor(currentUserId),
              conversation.listPreviewText,
              conversation.contextLabel,
              conversation.studentName,
              conversation.companyName,
            ].join(' ').toLowerCase();
            if (!haystack.contains(_searchQuery)) {
              return false;
            }
          }

          switch (_selectedFilter) {
            case _InboxFilter.all:
              return !isArchived;
            case _InboxFilter.unread:
              return !isArchived && unreadCount > 0;
            case _InboxFilter.projects:
              return !isArchived && conversation.isProjectConversation;
            case _InboxFilter.archived:
              return isArchived;
          }
        })
        .toList(growable: false);
  }

  Future<void> _refreshConversations() async {
    await context.read<ChatProvider>().refreshConversations();
  }

  Future<void> _openNewChat() async {
    final result = await Navigator.push<ConversationModel>(
      context,
      MaterialPageRoute(builder: (_) => const NewChatScreen()),
    );
    if (!mounted || result == null) {
      return;
    }
    _openConversation(result);
  }

  void _openConversation(ConversationModel conversation) {
    final currentUserId = context.read<AuthProvider>().userModel?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversationId: conversation.id,
          otherName: conversation.displayNameFor(currentUserId),
          recipientId: conversation.otherParticipantId(currentUserId),
          otherRole: conversation.otherParticipantRole(currentUserId),
          contextLabel: conversation.contextLabel,
        ),
      ),
    );
  }

  void _openConversationProfile(
    ConversationModel conversation,
    String currentUserId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePreviewScreen(
          userId: conversation.otherParticipantId(currentUserId),
          fallbackName: conversation.displayNameFor(currentUserId),
          fallbackRole: conversation.otherParticipantRole(currentUserId),
          fallbackHeadline: conversation.contextLabel,
          fallbackAbout: conversation.contextLabel.trim().isEmpty
              ? ''
              : 'Conversation started around ${conversation.contextLabel.trim()}.',
          contextLabel: conversation.contextLabel,
        ),
      ),
    );
  }

  void _openProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePreviewScreen(
          userId: user.uid,
          fallbackName: user.companyName ?? user.fullName,
          fallbackRole: user.role,
          fallbackHeadline: user.role == 'company'
              ? (user.sector ?? '')
              : [
                  (user.fieldOfStudy ?? '').trim(),
                  (user.university ?? '').trim(),
                ].where((value) => value.isNotEmpty).join(' - '),
          fallbackAbout: user.role == 'company'
              ? (user.description ?? '')
              : (user.bio ?? ''),
          fallbackLocation: user.location,
          fallbackWebsite: user.website ?? '',
        ),
      ),
    );
  }

  Future<void> _showConversationActions(
    ConversationModel conversation,
    String currentUserId,
  ) async {
    final provider = context.read<ChatProvider>();
    final isArchived = provider.isConversationArchivedFor(
      conversation,
      currentUserId,
    );
    final isMuted = provider.isConversationMutedFor(
      conversation,
      currentUserId,
    );

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ActionSheet(isArchived: isArchived, isMuted: isMuted),
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == 'profile') {
      _openConversationProfile(conversation, currentUserId);
      return;
    }

    if (selected == 'mute') {
      final muted = !isMuted;
      await provider.muteConversation(
        conversationId: conversation.id,
        userId: currentUserId,
        muted: muted,
      );
      if (!mounted) return;
      if (provider.error != null) {
        _showProviderError(provider.error!);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(muted ? 'Conversation muted' : 'Conversation unmuted'),
        ),
      );
      return;
    }

    if (selected == 'archive') {
      final archived = !isArchived;
      if (archived) {
        final confirmed = await showChatConfirmationDialog(
          context,
          title: 'Archive conversation?',
          message: 'Are you sure you want to archive this conversation?',
          confirmLabel: 'Archive',
          icon: Icons.archive_outlined,
        );
        if (confirmed != true || !mounted) {
          return;
        }
      }

      await provider.archiveConversation(
        conversationId: conversation.id,
        userId: currentUserId,
        archived: archived,
      );
      if (!mounted) return;
      if (provider.error != null) {
        _showProviderError(provider.error!);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archived
                ? 'Conversation moved to Archived'
                : 'Conversation restored to Inbox',
          ),
        ),
      );
      return;
    }

    final confirmed = await showChatConfirmationDialog(
      context,
      title: 'Delete conversation?',
      message:
          'Are you sure you want to delete this conversation? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await provider.deleteConversation(
      conversationId: conversation.id,
      userId: currentUserId,
    );
    if (!mounted) return;
    if (provider.error != null) {
      _showProviderError(provider.error!);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
  }

  void _showProviderError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.replaceFirst(RegExp(r'^Exception:\\s*'), '')),
      ),
    );
    context.read<ChatProvider>().clearError();
  }
}

enum _InboxFilter {
  all('Inbox'),
  unread('Unread'),
  projects('Projects'),
  archived('Archived');

  final String label;

  const _InboxFilter(this.label);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? ChatThemePalette.primaryGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : ChatThemePalette.border,
          ),
        ),
        child: Text(
          label,
          style:
              ChatThemeStyles.meta(
                selected ? Colors.white : ChatThemePalette.textSecondary,
              ).copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11.5,
              ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ChatThemePalette.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ChatThemePalette.primary, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ChatThemeStyles.cardTitle().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: ChatThemeStyles.body(
                ChatThemePalette.textSecondary,
              ).copyWith(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final bool isArchived;
  final bool isMuted;

  const _ActionSheet({required this.isArchived, required this.isMuted});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: ChatThemePalette.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: ChatThemeStyles.softShadow(0.08),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                color: ChatThemePalette.primary,
              ),
              title: Text('View Profile', style: ChatThemeStyles.cardTitle()),
              onTap: () => Navigator.pop(context, 'profile'),
            ),
            ListTile(
              leading: Icon(
                isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: ChatThemePalette.textSecondary,
              ),
              title: Text(
                isMuted ? 'Unmute' : 'Mute',
                style: ChatThemeStyles.cardTitle(),
              ),
              onTap: () => Navigator.pop(context, 'mute'),
            ),
            ListTile(
              leading: Icon(
                isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: ChatThemePalette.secondary,
              ),
              title: Text(
                isArchived ? 'Unarchive' : 'Archive',
                style: ChatThemeStyles.cardTitle(),
              ),
              onTap: () => Navigator.pop(context, 'archive'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: ChatThemePalette.error,
              ),
              title: Text(
                'Delete',
                style: ChatThemeStyles.cardTitle(ChatThemePalette.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
  }
}
