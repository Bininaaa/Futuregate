import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_local_state_service.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    ChatService? chatService,
    ChatLocalStateService? localStateService,
  }) : _chatService = chatService ?? ChatService(),
       _localStateService = localStateService ?? ChatLocalStateService();

  final ChatService _chatService;
  final ChatLocalStateService _localStateService;

  List<ConversationModel> _conversations = <ConversationModel>[];
  List<MessageModel> _messages = <MessageModel>[];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String _currentUserId = '';
  String _currentUserRole = '';
  String _activeConversationId = '';
  final Map<String, int> _unreadCounts = <String, int>{};
  bool _hasHydratedConversationState = false;

  final Set<String> _legacyArchivedConversationIds = <String>{};
  final Set<String> _legacyMutedConversationIds = <String>{};
  final Set<String> _legacyDeletedConversationIds = <String>{};
  final Map<String, bool> _archivedConversationOverrides = <String, bool>{};
  final Map<String, bool> _mutedConversationOverrides = <String, bool>{};
  final Map<String, bool> _deletedConversationOverrides = <String, bool>{};

  StreamSubscription<List<ConversationModel>>? _conversationsSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  final Map<String, StreamSubscription<int>> _unreadSubs =
      <String, StreamSubscription<int>>{};

  List<ConversationModel> get conversations =>
      List<ConversationModel>.unmodifiable(_conversations);
  List<MessageModel> get messages =>
      List<MessageModel>.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasHydratedConversationState => _hasHydratedConversationState;

  int unreadCountFor(String conversationId) => _unreadCounts[conversationId] ?? 0;

  bool isConversationArchivedFor(
    ConversationModel conversation,
    String userId,
  ) {
    final override = _archivedConversationOverrides[conversation.id];
    if (override != null) {
      return override;
    }

    return conversation.isArchivedFor(userId) ||
        _legacyArchivedConversationIds.contains(conversation.id);
  }

  bool isConversationMutedFor(ConversationModel conversation, String userId) {
    final override = _mutedConversationOverrides[conversation.id];
    if (override != null) {
      return override;
    }

    return conversation.isMutedFor(userId) ||
        _legacyMutedConversationIds.contains(conversation.id);
  }

  bool isConversationDeletedFor(
    ConversationModel conversation,
    String userId,
  ) {
    final override = _deletedConversationOverrides[conversation.id];
    if (override != null) {
      return override;
    }

    return conversation.isDeletedFor(userId) ||
        _legacyDeletedConversationIds.contains(conversation.id);
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
    _currentUserId = userId.trim();
    _currentUserRole = role.trim();
    _resetConversationStateHydration();
    _hydrateLegacyConversationState(_currentUserId);
    _isLoading = true;
    _error = null;
    notifyListeners();

    final stream = _currentUserRole == 'company'
        ? _chatService.getConversationsAsCompany(_currentUserId)
        : _chatService.getConversationsAsStudent(_currentUserId);

    _conversationsSub = stream.listen(
      (data) {
        _conversations = List<ConversationModel>.from(data);
        _reconcileConversationStateOverrides(_conversations);
        _syncUnreadStreams(_conversations);
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        if (_isIgnorableFirebaseCancellation(error)) {
          return;
        }
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refreshConversations() async {
    if (_currentUserId.isEmpty || _currentUserRole.isEmpty) {
      return;
    }

    listenToConversations(_currentUserId, _currentUserRole);
  }

  void _resetConversationStateHydration() {
    _legacyArchivedConversationIds.clear();
    _legacyMutedConversationIds.clear();
    _legacyDeletedConversationIds.clear();
    _archivedConversationOverrides.clear();
    _mutedConversationOverrides.clear();
    _deletedConversationOverrides.clear();
    _hasHydratedConversationState = _currentUserId.isEmpty;
  }

  void _hydrateLegacyConversationState(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    unawaited(() async {
      final state = await _localStateService.load(normalizedUserId);
      if (_currentUserId != normalizedUserId) {
        return;
      }

      _legacyArchivedConversationIds
        ..clear()
        ..addAll(state.archivedConversationIds);
      _legacyMutedConversationIds
        ..clear()
        ..addAll(state.mutedConversationIds);
      _legacyDeletedConversationIds
        ..clear()
        ..addAll(state.hiddenConversationIds);
      _hasHydratedConversationState = true;
      notifyListeners();

      unawaited(_migrateLegacyConversationState(normalizedUserId, state));
    }());
  }

  Future<void> _migrateLegacyConversationState(
    String userId,
    ChatLocalState state,
  ) async {
    if (state.isEmpty) {
      await _localStateService.clear(userId);
      return;
    }

    var migrationSucceeded = true;

    Future<void> runMigration(
      Iterable<String> conversationIds,
      Future<void> Function(String conversationId) task,
    ) async {
      for (final conversationId in conversationIds) {
        if (_currentUserId != userId) {
          return;
        }

        try {
          await task(conversationId);
        } catch (error) {
          if (_isPermissionDeniedError(error) ||
              _isIgnorableFirebaseCancellation(error)) {
            migrationSucceeded = false;
            return;
          }
          migrationSucceeded = false;
          debugPrint(
            'Legacy chat state migration failed for $conversationId: $error',
          );
        }
      }
    }

    await runMigration(
      state.archivedConversationIds,
      (conversationId) => _chatService.archiveConversation(
        conversationId: conversationId,
        userId: userId,
        archived: true,
      ),
    );
    await runMigration(
      state.mutedConversationIds,
      (conversationId) => _chatService.muteConversation(
        conversationId: conversationId,
        userId: userId,
        muted: true,
      ),
    );
    await runMigration(
      state.hiddenConversationIds,
      (conversationId) => _chatService.deleteConversation(
        conversationId: conversationId,
        userId: userId,
      ),
    );

    if (migrationSucceeded && _currentUserId == userId) {
      await _localStateService.clear(userId);
    }
  }

  void _syncUnreadStreams(List<ConversationModel> conversations) {
    final visibleConversationIds = conversations
        .where((conversation) => !isConversationDeletedFor(conversation, _currentUserId))
        .map((conversation) => conversation.id)
        .toSet();

    final idsToRemove = _unreadSubs.keys
        .where((id) => !visibleConversationIds.contains(id))
        .toList(growable: false);
    for (final id in idsToRemove) {
      _unreadSubs.remove(id)?.cancel();
      _unreadCounts.remove(id);
    }

    for (final conversation in conversations) {
      if (isConversationDeletedFor(conversation, _currentUserId) ||
          _unreadSubs.containsKey(conversation.id) ||
          _currentUserId.isEmpty) {
        continue;
      }

      _unreadSubs[conversation.id] = _chatService
          .getUnreadCount(
            conversationId: conversation.id,
            currentUserId: _currentUserId,
          )
          .listen((unreadCount) {
            _unreadCounts[conversation.id] = unreadCount;
            notifyListeners();
          });
    }
  }

  void _reconcileConversationStateOverrides(
    List<ConversationModel> conversations,
  ) {
    if (_currentUserId.isEmpty) {
      return;
    }

    for (final conversation in conversations) {
      final conversationId = conversation.id;

      if (_archivedConversationOverrides[conversationId] ==
          conversation.isArchivedFor(_currentUserId)) {
        _archivedConversationOverrides.remove(conversationId);
      }
      if (conversation.isArchivedFor(_currentUserId)) {
        _legacyArchivedConversationIds.remove(conversationId);
      }

      if (_mutedConversationOverrides[conversationId] ==
          conversation.isMutedFor(_currentUserId)) {
        _mutedConversationOverrides.remove(conversationId);
      }
      if (conversation.isMutedFor(_currentUserId)) {
        _legacyMutedConversationIds.remove(conversationId);
      }

      if (_deletedConversationOverrides[conversationId] ==
          conversation.isDeletedFor(_currentUserId)) {
        _deletedConversationOverrides.remove(conversationId);
      }
      if (conversation.isDeletedFor(_currentUserId)) {
        _legacyDeletedConversationIds.remove(conversationId);
      }

      if (conversation.isDeletedFor(_currentUserId)) {
        _unreadCounts[conversationId] = 0;
      }
    }
  }

  void listenToMessages(String conversationId, String currentUserId) {
    if (_activeConversationId != conversationId) {
      _messages = <MessageModel>[];
      _activeConversationId = conversationId;
    }

    _messagesSub?.cancel();
    _error = null;
    notifyListeners();

    _messagesSub = _chatService
        .getMessages(conversationId)
        .listen(
          (data) {
            _messages = List<MessageModel>.from(data);
            notifyListeners();

            _markIncomingAsRead(conversationId, currentUserId, data);
          },
          onError: (Object error) {
            if (_isIgnorableFirebaseCancellation(error)) {
              return;
            }
            _error = error.toString();
            debugPrint('Messages stream error: $error');
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
      (message) => !message.isRead && message.senderId != currentUserId,
    );
    if (!hasUnread) {
      return;
    }

    _chatService
        .markMessagesAsRead(
          conversationId: conversationId,
          currentUserId: currentUserId,
        )
        .catchError((Object error) {
          debugPrint('markMessagesAsRead failed: $error');
        });
  }

  void stopListeningToMessages() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _activeConversationId = '';
    _messages = <MessageModel>[];
    notifyListeners();
  }

  Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String studentName,
    required String companyId,
    required String companyName,
    String contextType = '',
    String contextLabel = '',
    String currentUserId = '',
  }) async {
    _error = null;
    final resolvedCurrentUserId = currentUserId.trim().isEmpty
        ? _currentUserId
        : currentUserId.trim();
    final conversation = await _chatService.getOrCreateConversation(
      studentId: studentId,
      studentName: studentName,
      companyId: companyId,
      companyName: companyName,
      contextType: contextType,
      contextLabel: contextLabel,
      currentUserId: resolvedCurrentUserId,
    );

    final restoredArchived = _legacyArchivedConversationIds.remove(conversation.id);
    final restoredDeleted = _legacyDeletedConversationIds.remove(conversation.id);
    final didRestoreVisibility = restoredArchived || restoredDeleted;
    _archivedConversationOverrides[conversation.id] = false;
    _deletedConversationOverrides[conversation.id] = false;

    if (didRestoreVisibility) {
      await _persistLegacyConversationState();
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
    if (_isSending) {
      return;
    }

    _error = null;
    _isSending = true;
    _archivedConversationOverrides[conversationId] = false;
    _deletedConversationOverrides[conversationId] = false;
    _legacyArchivedConversationIds.remove(conversationId);
    _legacyDeletedConversationIds.remove(conversationId);
    await _persistLegacyConversationState();
    notifyListeners();

    try {
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
    } catch (error) {
      if (!_isIgnorableFirebaseCancellation(error)) {
        _error = error.toString();
      }
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
    } catch (error) {
      if (_isIgnorableFirebaseCancellation(error)) {
        return;
      }
      _error = error.toString();
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
    } catch (error) {
      if (_isIgnorableFirebaseCancellation(error)) {
        return;
      }
      _error = error.toString();
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
    final previousOverride = _archivedConversationOverrides[conversationId];
    _error = null;
    _archivedConversationOverrides[conversationId] = archived;
    if (!archived) {
      _legacyArchivedConversationIds.remove(conversationId);
    }
    notifyListeners();

    try {
      await _chatService.archiveConversation(
        conversationId: conversationId,
        userId: userId,
        archived: archived,
      );
      if (archived) {
        _legacyArchivedConversationIds.remove(conversationId);
        _legacyDeletedConversationIds.remove(conversationId);
      } else {
        _legacyArchivedConversationIds.remove(conversationId);
      }
      await _persistLegacyConversationState();
    } catch (error) {
      if (_isPermissionDeniedError(error)) {
        if (archived) {
          _legacyArchivedConversationIds.add(conversationId);
          _legacyDeletedConversationIds.remove(conversationId);
        } else {
          _legacyArchivedConversationIds.remove(conversationId);
        }
        await _persistLegacyConversationState();
        _error = null;
        notifyListeners();
        return;
      }
      if (_isIgnorableFirebaseCancellation(error)) {
        _error = null;
        notifyListeners();
        return;
      }
      if (previousOverride == null) {
        _archivedConversationOverrides.remove(conversationId);
      } else {
        _archivedConversationOverrides[conversationId] = previousOverride;
      }
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> muteConversation({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    final previousOverride = _mutedConversationOverrides[conversationId];
    _error = null;
    _mutedConversationOverrides[conversationId] = muted;
    if (!muted) {
      _legacyMutedConversationIds.remove(conversationId);
    }
    notifyListeners();

    try {
      await _chatService.muteConversation(
        conversationId: conversationId,
        userId: userId,
        muted: muted,
      );
      if (muted) {
        _legacyMutedConversationIds.remove(conversationId);
      } else {
        _legacyMutedConversationIds.remove(conversationId);
      }
      await _persistLegacyConversationState();
    } catch (error) {
      if (_isPermissionDeniedError(error)) {
        if (muted) {
          _legacyMutedConversationIds.add(conversationId);
        } else {
          _legacyMutedConversationIds.remove(conversationId);
        }
        await _persistLegacyConversationState();
        _error = null;
        notifyListeners();
        return;
      }
      if (_isIgnorableFirebaseCancellation(error)) {
        _error = null;
        notifyListeners();
        return;
      }
      if (previousOverride == null) {
        _mutedConversationOverrides.remove(conversationId);
      } else {
        _mutedConversationOverrides[conversationId] = previousOverride;
      }
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    final previousOverride = _deletedConversationOverrides[conversationId];
    _error = null;
    _deletedConversationOverrides[conversationId] = true;
    _archivedConversationOverrides[conversationId] = false;
    _legacyArchivedConversationIds.remove(conversationId);
    _unreadCounts[conversationId] = 0;
    notifyListeners();

    try {
      await _chatService.deleteConversation(
        conversationId: conversationId,
        userId: userId,
      );
      _legacyDeletedConversationIds.remove(conversationId);
      _legacyArchivedConversationIds.remove(conversationId);
      await _persistLegacyConversationState();
    } catch (error) {
      if (_isPermissionDeniedError(error)) {
        _legacyDeletedConversationIds.add(conversationId);
        _legacyArchivedConversationIds.remove(conversationId);
        await _persistLegacyConversationState();
        _error = null;
        notifyListeners();
        return;
      }
      if (_isIgnorableFirebaseCancellation(error)) {
        _error = null;
        notifyListeners();
        return;
      }
      if (previousOverride == null) {
        _deletedConversationOverrides.remove(conversationId);
      } else {
        _deletedConversationOverrides[conversationId] = previousOverride;
      }
      _error = error.toString();
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
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return const <UserModel>[];
    }
  }

  Future<void> _persistLegacyConversationState() async {
    if (_currentUserId.isEmpty) {
      return;
    }

    final state = ChatLocalState(
      archivedConversationIds: _legacyArchivedConversationIds,
      mutedConversationIds: _legacyMutedConversationIds,
      hiddenConversationIds: _legacyDeletedConversationIds,
    );

    if (state.isEmpty) {
      await _localStateService.clear(_currentUserId);
      return;
    }

    await _localStateService.save(_currentUserId, state);
  }

  bool _isPermissionDeniedError(Object error) {
    return error is FirebaseException && error.code == 'permission-denied' ||
        error.toString().contains('[cloud_firestore/permission-denied]');
  }

  bool _isIgnorableFirebaseCancellation(Object error) {
    if (error is FirebaseException &&
        (error.code == 'aborted' || error.code == 'cancelled')) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('firebaseignoreexception') &&
        message.contains('http request was aborted');
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
