import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_local_state_service.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ChatLocalStateService _localStateService = ChatLocalStateService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String _currentUserId = '';
  String _activeConversationId = '';
  final Map<String, int> _unreadCounts = {};
  bool _hasHydratedConversationState = false;
  Set<String> _archivedConversationIds = <String>{};
  Set<String> _mutedConversationIds = <String>{};
  Set<String> _hiddenConversationIds = <String>{};

  StreamSubscription? _conversationsSub;
  StreamSubscription? _messagesSub;
  final Map<String, StreamSubscription<int>> _unreadSubs = {};

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasHydratedConversationState => _hasHydratedConversationState;
  int unreadCountFor(String conversationId) =>
      _unreadCounts[conversationId] ?? 0;
  bool isConversationArchivedFor(
    ConversationModel conversation,
    String userId,
  ) {
    return conversation.isArchivedFor(userId) ||
        _archivedConversationIds.contains(conversation.id);
  }

  bool isConversationMutedFor(ConversationModel conversation, String userId) {
    return conversation.isMutedFor(userId) ||
        _mutedConversationIds.contains(conversation.id);
  }

  bool isConversationHidden(String conversationId) {
    return _hiddenConversationIds.contains(conversationId);
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  void listenToConversations(String userId, String role) {
    _conversationsSub?.cancel();
    for (final subscription in _unreadSubs.values) {
      subscription.cancel();
    }
    _unreadSubs.clear();
    _unreadCounts.clear();
    _currentUserId = userId;
    _hasHydratedConversationState = false;
    _restoreLocalState(userId);
    _isLoading = true;
    _error = null;
    notifyListeners();

    final stream = role == 'company'
        ? _chatService.getConversationsAsCompany(userId)
        : _chatService.getConversationsAsStudent(userId);

    _conversationsSub = stream.listen(
      (data) {
        _conversations = data;
        _syncUnreadStreams(data);
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

  void _restoreLocalState(String userId) {
    final normalizedUserId = userId.trim();
    _archivedConversationIds = <String>{};
    _mutedConversationIds = <String>{};
    _hiddenConversationIds = <String>{};
    _hasHydratedConversationState = normalizedUserId.isEmpty;

    unawaited(() async {
      final state = await _localStateService.load(normalizedUserId);
      if (_currentUserId != normalizedUserId) {
        return;
      }

      _archivedConversationIds = state.archivedConversationIds;
      _mutedConversationIds = state.mutedConversationIds;
      _hiddenConversationIds = state.hiddenConversationIds;
      _hasHydratedConversationState = true;
      notifyListeners();
    }());
  }

  void _syncUnreadStreams(List<ConversationModel> conversations) {
    final activeIds = conversations
        .map((conversation) => conversation.id)
        .toSet();

    final idsToRemove = _unreadSubs.keys
        .where((id) => !activeIds.contains(id))
        .toList();
    for (final id in idsToRemove) {
      _unreadSubs.remove(id)?.cancel();
      _unreadCounts.remove(id);
    }

    for (final conversation in conversations) {
      if (_unreadSubs.containsKey(conversation.id) || _currentUserId.isEmpty) {
        continue;
      }

      _unreadSubs[conversation.id] = _chatService
          .getUnreadCount(
            conversationId: conversation.id,
            currentUserId: _currentUserId,
          )
          .listen((count) {
            _unreadCounts[conversation.id] = count;
            notifyListeners();
          });
    }
  }

  void listenToMessages(String conversationId, String currentUserId) {
    if (_activeConversationId != conversationId) {
      _messages = [];
      _activeConversationId = conversationId;
    }

    _messagesSub?.cancel();
    _error = null;
    notifyListeners();

    _messagesSub = _chatService
        .getMessages(conversationId)
        .listen(
          (data) {
            _messages = data;
            notifyListeners();

            _markIncomingAsRead(conversationId, currentUserId, data);
          },
          onError: (e) {
            _error = e.toString();
            debugPrint('Messages stream error: $e');
            notifyListeners();
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
      _chatService
          .markMessagesAsRead(
            conversationId: conversationId,
            currentUserId: currentUserId,
          )
          .catchError((error) {
            debugPrint('markMessagesAsRead failed: $error');
          });
    }
  }

  void stopListeningToMessages() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _activeConversationId = '';
    _messages = [];
    notifyListeners();
  }

  Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String studentName,
    required String companyId,
    required String companyName,
    String contextType = '',
    String contextLabel = '',
  }) async {
    _error = null;
    final conversation = await _chatService.getOrCreateConversation(
      studentId: studentId,
      studentName: studentName,
      companyId: companyId,
      companyName: companyName,
      contextType: contextType,
      contextLabel: contextLabel,
    );

    final wasHidden = _hiddenConversationIds.remove(conversation.id);
    final wasArchived = _archivedConversationIds.remove(conversation.id);
    if (wasHidden || wasArchived) {
      await _persistLocalState();
      notifyListeners();
    }

    return conversation;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    String? recipientId,
    String messageType = 'text',
    String attachmentFileName = '',
    String attachmentFilePath = '',
    Uint8List? attachmentFileBytes,
    int attachmentFileSize = 0,
    String attachmentMimeType = '',
  }) async {
    if (_isSending) return;
    _error = null;
    _isSending = true;
    notifyListeners();
    try {
      var didRestoreConversation = false;
      if (_hiddenConversationIds.remove(conversationId)) {
        didRestoreConversation = true;
      }
      if (_archivedConversationIds.remove(conversationId)) {
        didRestoreConversation = true;
      }
      if (didRestoreConversation) {
        await _persistLocalState();
      }

      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderRole: senderRole,
        text: text,
        recipientId: recipientId,
        messageType: messageType,
        attachmentFileName: attachmentFileName,
        attachmentFilePath: attachmentFilePath,
        attachmentFileBytes: attachmentFileBytes,
        attachmentFileSize: attachmentFileSize,
        attachmentMimeType: attachmentMimeType,
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
      _error = null;
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
      _error = null;
      await _chatService.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Stream<ConversationModel?> watchConversation(String conversationId) {
    return _chatService.watchConversation(conversationId);
  }

  Future<void> archiveConversation({
    required String conversationId,
    required String userId,
    required bool archived,
  }) async {
    try {
      _error = null;
      if (archived) {
        _archivedConversationIds.add(conversationId);
      } else {
        _archivedConversationIds.remove(conversationId);
      }
      await _persistLocalState();
      notifyListeners();
      await _chatService.archiveConversation(
        conversationId: conversationId,
        userId: userId,
        archived: archived,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> muteConversation({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    try {
      _error = null;
      if (muted) {
        _mutedConversationIds.add(conversationId);
      } else {
        _mutedConversationIds.remove(conversationId);
      }
      await _persistLocalState();
      notifyListeners();
      await _chatService.muteConversation(
        conversationId: conversationId,
        userId: userId,
        muted: muted,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<UserModel>> searchChatContacts({
    required String currentUserId,
    required String currentRole,
    String query = '',
  }) async {
    try {
      _error = null;
      return await _chatService.searchChatContacts(
        currentUserId: currentUserId,
        currentRole: currentRole,
        query: query,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return const [];
    }
  }

  Future<void> hideConversation(String conversationId) async {
    _error = null;
    _hiddenConversationIds.add(conversationId);
    _archivedConversationIds.remove(conversationId);
    await _persistLocalState();
    notifyListeners();
  }

  Future<void> _persistLocalState() {
    return _localStateService.save(
      _currentUserId,
      ChatLocalState(
        archivedConversationIds: _archivedConversationIds,
        mutedConversationIds: _mutedConversationIds,
        hiddenConversationIds: _hiddenConversationIds,
      ),
    );
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    for (final subscription in _unreadSubs.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
