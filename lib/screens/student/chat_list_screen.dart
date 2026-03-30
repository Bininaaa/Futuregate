import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/profile_avatar.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const Color strongBlue = Color(0xFF004E98);
  static const Color softGray = Color(0xFFEBEBEB);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      context.read<ChatProvider>().listenToConversations(user.uid, user.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(chatProvider),
    );
  }

  Widget _buildBody(ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a chat from an opportunity page',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final currentUserId = context.read<AuthProvider>().userModel?.uid ?? '';

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: chatProvider.conversations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final conv = chatProvider.conversations[index];
        return _ConversationTile(
          conversation: conv,
          displayName: conv.companyName,
          currentUserId: currentUserId,
          onTap: () => _openChat(conv),
        );
      },
    );
  }

  void _openChat(ConversationModel conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.id,
          otherName: conv.companyName,
          recipientId: conv.companyId,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String displayName;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.displayName,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = conversation.lastMessageTime != null
        ? DateFormat.Hm().format(conversation.lastMessageTime!.toDate())
        : '';

    return StreamBuilder<int>(
      stream: ChatService().getUnreadCount(
        conversationId: conversation.id,
        currentUserId: currentUserId,
      ),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ProfileAvatar(
                      radius: 24,
                      userId: conversation.companyId,
                      fallbackName: displayName,
                      role: 'company',
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6700),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: const Color(0xFF004E98),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conversation.lastMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: hasUnread ? Colors.black87 : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: hasUnread
                            ? const Color(0xFFFF6700)
                            : Colors.grey[500],
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6700),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
