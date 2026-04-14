import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/chat/chat_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import 'user_profile_preview_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _contacts = const [];
  bool _isLoading = true;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts([String query = '']) async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) {
      return;
    }

    setState(() => _isLoading = true);
    final contacts = await context.read<ChatProvider>().searchChatContacts(
      currentUserId: auth.uid,
      currentRole: auth.role,
      query: query,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadContacts(value.trim());
    });
  }

  Future<void> _startConversation(UserModel contact) async {
    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) {
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    late final ConversationModel conversation;
    try {
      conversation = auth.role == 'company'
          ? await chatProvider.getOrCreateConversation(
              studentId: contact.uid,
              studentName: contact.fullName,
              companyId: auth.uid,
              companyName: auth.companyName ?? auth.fullName,
              contextType: 'application',
              contextLabel: 'Application conversation',
              currentUserId: auth.uid,
              currentUserRole: auth.role,
            )
          : await chatProvider.getOrCreateConversation(
              studentId: auth.uid,
              studentName: auth.fullName,
              companyId: contact.uid,
              companyName: contact.companyName ?? contact.fullName,
              contextType: 'application',
              contextLabel: 'Application conversation',
              currentUserId: auth.uid,
              currentUserRole: auth.role,
            );
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        _readableError(error),
        title: 'Chat unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pop<ConversationModel>(context, conversation);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;
    final chatProvider = context.watch<ChatProvider>();
    final conversations = chatProvider.conversations
        .where(
          (conversation) =>
              currentUser == null ||
              !chatProvider.isConversationDeletedFor(
                conversation,
                currentUser.uid,
              ),
        )
        .toList(growable: false);
    final recentIds = conversations
        .map(
          (conversation) =>
              conversation.otherParticipantId(currentUser?.uid ?? ''),
        )
        .where((id) => id.isNotEmpty)
        .toSet();
    final recentContacts = _contacts
        .where((contact) => recentIds.contains(contact.uid))
        .toList();
    final suggestions = _contacts
        .where((contact) => !recentIds.contains(contact.uid))
        .toList();

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(
                  children: [
                    _ToolbarButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'New Chat',
                        style: ChatThemeStyles.title().copyWith(fontSize: 22),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ChatThemePalette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: ChatThemePalette.border),
                    boxShadow: ChatThemeStyles.softShadow(0.04),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: ChatThemeStyles.body(),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search_rounded,
                        color: ChatThemePalette.textSecondary,
                      ),
                      hintText: currentUser?.role == 'company'
                          ? 'Search applicants'
                          : 'Search approved companies',
                      hintStyle: ChatThemeStyles.body(
                        ChatThemePalette.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        children: [
                          if (recentContacts.isNotEmpty) ...[
                            Text(
                              'Recent contacts',
                              style: ChatThemeStyles.meta().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...recentContacts.map(_buildContactTile),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            recentContacts.isNotEmpty
                                ? 'Suggested'
                                : currentUser?.role == 'company'
                                ? 'Applicants'
                                : 'Approved companies',
                            style: ChatThemeStyles.meta().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (suggestions.isEmpty && recentContacts.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: ChatThemePalette.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: ChatThemePalette.border,
                                ),
                              ),
                              child: Text(
                                currentUser?.role == 'company'
                                    ? 'No applicants match your search.'
                                    : 'No approved companies match your search.',
                                style: ChatThemeStyles.body(
                                  ChatThemePalette.textSecondary,
                                ),
                              ),
                            )
                          else
                            ...suggestions.map(_buildContactTile),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(UserModel contact) {
    final displayName = (contact.companyName ?? '').trim().isNotEmpty
        ? (contact.companyName ?? '').trim()
        : contact.fullName.trim();
    final subtitle = contact.role == 'company'
        ? (contact.sector ?? '').trim()
        : [
            (contact.fieldOfStudy ?? '').trim(),
            (contact.university ?? '').trim(),
          ].where((item) => item.isNotEmpty).join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChatThemePalette.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePreviewScreen(
                userId: contact.uid,
                fallbackName: displayName,
                fallbackRole: contact.role,
                fallbackHeadline: contact.role == 'company'
                    ? (contact.sector ?? '')
                    : [
                        (contact.fieldOfStudy ?? '').trim(),
                        (contact.university ?? '').trim(),
                      ].where((value) => value.isNotEmpty).join(' - '),
                fallbackAbout: contact.role == 'company'
                    ? (contact.description ?? '')
                    : (contact.bio ?? ''),
                fallbackLocation: contact.location,
                fallbackWebsite: contact.website ?? '',
              ),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(user: contact, radius: 24),
              if (contact.isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
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
        title: Text(
          displayName,
          style: ChatThemeStyles.cardTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        trailing: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ChatThemePalette.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: ChatThemeStyles.softShadow(0.08),
          ),
          child: IconButton(
            onPressed: () => _startConversation(contact),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ),
        ),
        onTap: () => _startConversation(contact),
      ),
    );
  }

  String _readableError(Object error) {
    return error.toString().trim().replaceFirst(RegExp(r'^Exception:\s*'), '');
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
