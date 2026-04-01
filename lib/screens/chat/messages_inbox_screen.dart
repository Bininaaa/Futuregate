import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
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
  _InboxFilter _selectedFilter = _InboxFilter.all;

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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().userModel;
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: ChatThemePalette.background,
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ChatThemePalette.fabGradient,
          shape: BoxShape.circle,
          boxShadow: ChatThemeStyles.softShadow(0.16),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: auth == null ? null : _openNewChat,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChatThemePalette.primary.withValues(alpha: 0.07),
              ChatThemePalette.background,
              ChatThemePalette.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.24, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: auth == null ? null : () => _openProfile(auth),
                      child: ProfileAvatar(user: auth, radius: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Messages',
                        style: ChatThemeStyles.title(ChatThemePalette.primary),
                      ),
                    ),
                    _ToolbarButton(
                      icon: Icons.search_rounded,
                      onTap: auth == null
                          ? null
                          : () => _openConversationSearch(
                              chatProvider.conversations,
                              auth.uid,
                            ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<String>(
                      color: ChatThemePalette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (value) {
                        if (value == 'archived') {
                          setState(
                            () => _selectedFilter = _InboxFilter.archived,
                          );
                          return;
                        }
                        if (value == 'all') {
                          setState(() => _selectedFilter = _InboxFilter.all);
                          return;
                        }
                        _openNewChat();
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
                            'Show All Chats',
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
                      child: const _ToolbarButton(
                        icon: Icons.more_vert_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: _InboxFilter.values
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _FilterChipButton(
                            label: filter.label,
                            selected: filter == _selectedFilter,
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (chatProvider.isLoading &&
                        chatProvider.conversations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!chatProvider.hasHydratedConversationState) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (auth == null) {
                      return _EmptyState(
                        title: 'Sign in to see your chats',
                        subtitle:
                            'Your student or company conversations appear here.',
                      );
                    }

                    final filteredConversations = _filteredConversations(
                      chatProvider.conversations,
                      auth.uid,
                    );

                    if (filteredConversations.isEmpty) {
                      return _EmptyState(
                        title: _selectedFilter == _InboxFilter.archived
                            ? 'No archived chats'
                            : 'No conversations yet',
                        subtitle: _selectedFilter == _InboxFilter.archived
                            ? 'Archived conversations will appear here.'
                            : 'Start a new chat to begin your premium inbox flow.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: filteredConversations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final conversation = filteredConversations[index];
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
                          onTap: () => _openConversation(conversation),
                          onLongPress: () =>
                              _showConversationActions(conversation, auth.uid),
                          onOpenProfile: () =>
                              _openConversationProfile(conversation, auth.uid),
                        );
                      },
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
  ) {
    return conversations.where((conversation) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.isConversationHidden(conversation.id)) {
        return false;
      }

      final unreadCount = chatProvider.unreadCountFor(conversation.id);
      final isArchived = chatProvider.isConversationArchivedFor(
        conversation,
        currentUserId,
      );

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
    }).toList();
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

  Future<void> _openConversationSearch(
    List<ConversationModel> conversations,
    String currentUserId,
  ) async {
    final selected = await showSearch<ConversationModel?>(
      context: context,
      delegate: _ConversationSearchDelegate(
        conversations: conversations
            .where(
              (conversation) => !context
                  .read<ChatProvider>()
                  .isConversationHidden(conversation.id),
            )
            .toList(),
        currentUserId: currentUserId,
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    _openConversation(selected);
  }

  Future<void> _showConversationActions(
    ConversationModel conversation,
    String currentUserId,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final chatProvider = context.read<ChatProvider>();
        final isArchived = chatProvider.isConversationArchivedFor(
          conversation,
          currentUserId,
        );
        final isMuted = chatProvider.isConversationMutedFor(
          conversation,
          currentUserId,
        );
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: ChatThemePalette.surface,
              borderRadius: BorderRadius.circular(28),
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
                  title: Text(
                    'View Profile',
                    style: ChatThemeStyles.cardTitle(),
                  ),
                  onTap: () => Navigator.pop(context, 'profile'),
                ),
                ListTile(
                  leading: Icon(
                    isMuted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: ChatThemePalette.textPrimary,
                  ),
                  title: Text(
                    isMuted ? 'Unmute Chat' : 'Mute Chat',
                    style: ChatThemeStyles.cardTitle(),
                  ),
                  onTap: () => Navigator.pop(context, 'mute'),
                ),
                ListTile(
                  leading: Icon(
                    isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    color: ChatThemePalette.textPrimary,
                  ),
                  title: Text(
                    isArchived ? 'Unarchive Chat' : 'Archive Chat',
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
                    'Delete Chat',
                    style: ChatThemeStyles.cardTitle(ChatThemePalette.error),
                  ),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == 'profile') {
      _openConversationProfile(conversation, currentUserId);
      return;
    }

    final chatProvider = context.read<ChatProvider>();

    if (selected == 'mute') {
      final muted = !chatProvider.isConversationMutedFor(
        conversation,
        currentUserId,
      );
      await chatProvider.muteConversation(
        conversationId: conversation.id,
        userId: currentUserId,
        muted: muted,
      );
      if (!mounted) {
        return;
      }

      if (chatProvider.error != null) {
        _showProviderError(chatProvider.error!);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(muted ? 'Chat muted' : 'Chat unmuted')),
      );
      return;
    }

    if (selected == 'archive') {
      final archived = !chatProvider.isConversationArchivedFor(
        conversation,
        currentUserId,
      );
      if (archived) {
        final confirmed = await _confirmConversationAction(
          title: 'Archive Chat',
          message:
              'Archive this conversation? You can still find it later in Archived chats.',
          confirmLabel: 'Archive',
        );
        if (confirmed != true || !mounted) {
          return;
        }
      }

      await chatProvider.archiveConversation(
        conversationId: conversation.id,
        userId: currentUserId,
        archived: archived,
      );
      if (!mounted) {
        return;
      }

      if (chatProvider.error != null) {
        _showProviderError(chatProvider.error!);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(archived ? 'Chat archived' : 'Chat restored to inbox'),
        ),
      );
      return;
    }

    final confirmed = await _confirmConversationAction(
      title: 'Delete Chat',
      message:
          'Delete this conversation from your inbox? You can start it again later if needed.',
      confirmLabel: 'Delete',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await chatProvider.hideConversation(conversation.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation removed from your inbox')),
    );
  }

  void _showProviderError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.replaceFirst(RegExp(r'^Exception:\s*'), '')),
      ),
    );
    context.read<ChatProvider>().clearError();
  }

  Future<bool?> _confirmConversationAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: ChatThemePalette.surface,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: confirmLabel == 'Delete'
                      ? ChatThemePalette.error
                      : ChatThemePalette.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _InboxFilter {
  all('All Chats'),
  unread('Unread'),
  projects('Projects'),
  archived('Archived');

  final String label;

  const _InboxFilter(this.label);
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ChatThemePalette.primary
              : ChatThemePalette.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? ChatThemePalette.primary
                : ChatThemePalette.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: ChatThemeStyles.meta(
              selected ? Colors.white : ChatThemePalette.textSecondary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ChatThemePalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChatThemePalette.border),
          ),
          child: Icon(icon, color: ChatThemePalette.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ChatThemePalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ChatThemePalette.border),
          ),
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
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: ChatThemePalette.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: ChatThemeStyles.cardTitle().copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationSearchDelegate extends SearchDelegate<ConversationModel?> {
  final List<ConversationModel> conversations;
  final String currentUserId;

  _ConversationSearchDelegate({
    required this.conversations,
    required this.currentUserId,
  });

  @override
  String get searchFieldLabel => 'Search chats';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: ChatThemePalette.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: ChatThemePalette.background,
        foregroundColor: ChatThemePalette.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final matches = conversations.where((conversation) {
      final target = [
        conversation.displayNameFor(currentUserId),
        conversation.listPreviewText,
        conversation.contextLabel,
      ].join(' ').toLowerCase();
      return target.contains(query.trim().toLowerCase());
    }).toList();

    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No chats match your search.',
          style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final conversation = matches[index];
        return ConversationListItem(
          conversation: conversation,
          currentUserId: currentUserId,
          unreadCount: context.read<ChatProvider>().unreadCountFor(
            conversation.id,
          ),
          isMuted: context.read<ChatProvider>().isConversationMutedFor(
            conversation,
            currentUserId,
          ),
          onTap: () => close(context, conversation),
          onOpenProfile: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePreviewScreen(
                  userId: conversation.otherParticipantId(currentUserId),
                  fallbackName: conversation.displayNameFor(currentUserId),
                  fallbackRole: conversation.otherParticipantRole(
                    currentUserId,
                  ),
                  fallbackHeadline: conversation.contextLabel,
                  fallbackAbout: conversation.contextLabel.trim().isEmpty
                      ? ''
                      : 'Conversation started around ${conversation.contextLabel.trim()}.',
                  contextLabel: conversation.contextLabel,
                ),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: matches.length,
    );
  }
}
