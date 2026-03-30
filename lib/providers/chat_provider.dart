import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  StreamSubscription? _conversationsSub;
  StreamSubscription? _messagesSub;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  void listenToConversations(String userId, String role) {
    _conversationsSub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    final stream = role == 'company'
        ? _chatService.getConversationsAsCompany(userId)
        : _chatService.getConversationsAsStudent(userId);

    _conversationsSub = stream.listen(
      (data) {
        _conversations = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void listenToMessages(String conversationId, String currentUserId) {
    _messagesSub?.cancel();

    _messagesSub = _chatService.getMessages(conversationId).listen(
      (data) {
        _messages = data;
        notifyListeners();

        _markIncomingAsRead(conversationId, currentUserId, data);
      },
      onError: (e) {
        debugPrint('Messages stream error: $e');
      },
    );
  }

  void _markIncomingAsRead(
    String conversationId,
    String currentUserId,
    List<MessageModel> messages,
  ) {
    final hasUnread = messages.any(
      (m) => !m.isRead && m.senderId != currentUserId,
    );
    if (hasUnread) {
      _chatService.markMessagesAsRead(
        conversationId: conversationId,
        currentUserId: currentUserId,
      );
    }
  }

  void stopListeningToMessages() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _messages = [];
    notifyListeners();
  }

  Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String studentName,
    required String companyId,
    required String companyName,
  }) async {
    return await _chatService.getOrCreateConversation(
      studentId: studentId,
      studentName: studentName,
      companyId: companyId,
      companyName: companyName,
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    String? recipientId,
  }) async {
    if (_isSending) return;
    _isSending = true;
    notifyListeners();
    try {
      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderRole: senderRole,
        text: text,
        recipientId: recipientId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    try {
      await _chatService.editMessage(
        conversationId: conversationId,
        messageId: messageId,
        newText: newText,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _chatService.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}
