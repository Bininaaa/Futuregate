import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;
  final String recipientId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    this.recipientId = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  static const Color strongBlue = Color(0xFF004E98);
  static const Color vibrantOrange = Color(0xFFFF6700);

  String _recipientId = '';
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _recipientId = widget.recipientId;
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid != null) {
      context.read<ChatProvider>().listenToMessages(widget.conversationId, uid);
      if (_recipientId.isEmpty) {
        _lookupRecipientId(uid);
      }
    }
  }

  Future<void> _lookupRecipientId(String myUid) async {
    final conversations = context.read<ChatProvider>().conversations;
    for (final conv in conversations) {
      if (conv.id == widget.conversationId) {
        setState(() {
          _recipientId =
              conv.studentId == myUid ? conv.companyId : conv.studentId;
        });
        return;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatProvider>().stopListeningToMessages();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    if (_editingMessageId != null) {
      await chatProvider.editMessage(
        conversationId: widget.conversationId,
        messageId: _editingMessageId!,
        newText: text,
      );
      setState(() => _editingMessageId = null);
      _messageController.clear();
      return;
    }

    final auth = context.read<AuthProvider>();
    final uid = auth.userModel?.uid;
    final role = auth.userModel?.role;
    if (uid == null || role == null) return;

    _messageController.clear();

    await chatProvider.sendMessage(
      conversationId: widget.conversationId,
      senderId: uid,
      senderRole: role,
      text: text,
      recipientId: _recipientId.isNotEmpty ? _recipientId : null,
    );
  }

  void _startEdit(String messageId, String currentText) {
    setState(() {
      _editingMessageId = messageId;
      _messageController.text = currentText;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _messageController.clear();
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message for everyone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ChatProvider>().deleteMessage(
            conversationId: widget.conversationId,
            messageId: messageId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final uid = context.read<AuthProvider>().userModel?.uid ?? '';

    if (chatProvider.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: strongBlue),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? Center(
                    child: Text(
                      'Start the conversation',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatProvider.messages[index];
                      final isMe = msg.senderId == uid;
                      return MessageBubble(
                        message: msg,
                        isMe: isMe,
                        onEdit: isMe && !msg.isDeleted
                            ? () => _startEdit(msg.id, msg.text)
                            : null,
                        onDelete: isMe && !msg.isDeleted
                            ? () => _deleteMessage(msg.id)
                            : null,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editingMessageId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: strongBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: strongBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Editing message',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: strongBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cancelEdit,
                      child: const Icon(Icons.close, size: 18, color: strongBlue),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _editingMessageId != null
                          ? 'Edit message...'
                          : 'Type a message...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _editingMessageId != null ? strongBlue : vibrantOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _editingMessageId != null ? Icons.check : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
