import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
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
    final conversations = List<ConversationModel>.of(chatProvider.conversations);
    final filtered = auth == null
        ? const <ConversationModel>[]
        : _filteredConversations(conversations, auth.uid, chatProvider);

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
          child: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChatThemePalette.primary.withValues(alpha: 0.08),
              ChatThemePalette.secondary.withValues(alpha: 0.04),
              ChatThemePalette.background,
              ChatThemePalette.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.16, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _HeaderCard(
                  auth: auth,
                  filter: _selectedFilter,
                  visibleCount: filtered.length,
                  onProfileTap: auth == null ? null : () => _openProfile(auth),
                  onActionSelected: (value) {
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim().toLowerCase());
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: _InboxFilter.values
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _FilterChip(
                            label: filter.label,
                            selected: filter == _selectedFilter,
                            onTap: () => setState(() => _selectedFilter = filter),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (chatProvider.isLoading && conversations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!chatProvider.hasHydratedConversationState) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (auth == null) {
                      return const _EmptyState(
                        title: 'Sign in to see your conversations',
                        subtitle:
                            'Your messages with students and companies will appear here.',
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
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                          children: [
                            _EmptyState(
                              title: _selectedFilter == _InboxFilter.archived
                                  ? 'No archived conversations'
                                  : _searchQuery.isNotEmpty
                                  ? 'No matching conversations'
                                  : 'No conversations yet',
                              subtitle: _selectedFilter == _InboxFilter.archived
                                  ? 'Archived conversations will stay here until you restore them.'
                                  : _searchQuery.isNotEmpty
                                  ? 'Try a different name, company, or project keyword.'
                                  : 'Start a new conversation to bring your inbox to life.',
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
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final conversation = filtered[index];
                          return ConversationListItem(
                            conversation: conversation,
                            currentUserId: auth.uid,
                            unreadCount: chatProvider.unreadCountFor(conversation.id),
                            isMuted: chatProvider.isConversationMutedFor(
                              conversation,
                              auth.uid,
                            ),
                            isArchived: chatProvider.isConversationArchivedFor(
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
    return conversations.where((conversation) {
      if (chatProvider.isConversationDeletedFor(conversation, currentUserId)) {
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
    }).toList(growable: false);
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
    final isMuted = provider.isConversationMutedFor(conversation, currentUserId);

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActionSheet(isArchived: isArchived, isMuted: isMuted),
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
        SnackBar(content: Text(muted ? 'Conversation muted' : 'Conversation unmuted')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation deleted')),
    );
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

class _HeaderCard extends StatelessWidget {
  final UserModel? auth;
  final _InboxFilter filter;
  final int visibleCount;
  final VoidCallback? onProfileTap;
  final ValueChanged<String> onActionSelected;

  const _HeaderCard({
    required this.auth,
    required this.filter,
    required this.visibleCount,
    required this.onProfileTap,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = filter == _InboxFilter.archived
        ? '$visibleCount archived conversations'
        : '$visibleCount conversations ready for follow-up';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: ChatThemePalette.heroGradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: ChatThemeStyles.softShadow(0.1),
      ),
      child: Row(
        children: [
          GestureDetector(onTap: onProfileTap, child: ProfileAvatar(user: auth, radius: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messages', style: ChatThemeStyles.title()),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: ChatThemePalette.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            onSelected: onActionSelected,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'new',
                child: Text('Start New Chat', style: ChatThemeStyles.body()),
              ),
              PopupMenuItem<String>(
                value: 'all',
                child: Text('Show Inbox', style: ChatThemeStyles.body()),
              ),
              PopupMenuItem<String>(
                value: 'archived',
                child: Text('Show Archived', style: ChatThemeStyles.body()),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ChatThemePalette.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ChatThemePalette.border),
              ),
              child: const Icon(Icons.more_horiz_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChatThemePalette.border),
        boxShadow: ChatThemeStyles.softShadow(0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: ChatThemePalette.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: ChatThemeStyles.body(),
              decoration: InputDecoration(
                hintText: 'Search conversations, companies, or projects',
                hintStyle: ChatThemeStyles.body(ChatThemePalette.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            IconButton(
              onPressed: onClear,
              splashRadius: 18,
              icon: const Icon(
                Icons.close_rounded,
                color: ChatThemePalette.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected ? ChatThemePalette.primaryGradient : null,
          color: selected ? null : ChatThemePalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : ChatThemePalette.border,
          ),
          boxShadow: selected ? ChatThemeStyles.softShadow(0.08) : null,
        ),
        child: Text(
          label,
          style: ChatThemeStyles.meta(
            selected ? Colors.white : ChatThemePalette.textSecondary,
          ).copyWith(fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: ChatThemePalette.headerGradient,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ChatThemePalette.border),
          boxShadow: ChatThemeStyles.softShadow(0.05),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ChatThemePalette.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: ChatThemePalette.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: ChatThemeStyles.dialogTitle()),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
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
    Widget action({
      required String value,
      required IconData icon,
      required String label,
      bool destructive = false,
    }) {
      final color = destructive ? ChatThemePalette.error : ChatThemePalette.textPrimary;
      return ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: ChatThemeStyles.cardTitle(color)),
        onTap: () => Navigator.pop(context, value),
      );
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          gradient: ChatThemePalette.headerGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
          boxShadow: ChatThemeStyles.softShadow(0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: ChatThemePalette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            action(
              value: 'profile',
              icon: Icons.person_outline_rounded,
              label: 'View profile',
            ),
            action(
              value: 'mute',
              icon: isMuted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              label: isMuted ? 'Unmute conversation' : 'Mute conversation',
            ),
            action(
              value: 'archive',
              icon: isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
              label: isArchived ? 'Restore to inbox' : 'Archive conversation',
            ),
            action(
              value: 'delete',
              icon: Icons.delete_outline_rounded,
              label: 'Delete conversation',
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }
}
