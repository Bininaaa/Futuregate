import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'file_storage_service.dart';
import 'notification_worker_service.dart';
import 'worker_api_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final StorageService _storageService = StorageService();
  final WorkerApiService _workerApi = WorkerApiService();

  Stream<List<ConversationModel>> getConversationsAsStudent(String userId) {
    return _firestore
        .collection('conversations')
        .where('studentId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => _mapConversations(snapshot.docs));
  }

  Stream<List<ConversationModel>> getConversationsAsCompany(String userId) {
    return _firestore
        .collection('conversations')
        .where('companyId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => _mapConversations(snapshot.docs));
  }

  Stream<ConversationModel?> watchConversation(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            return null;
          }

          return ConversationModel.fromMap({
            ...data,
            'id': (data['id'] ?? snapshot.id).toString(),
          });
        });
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => _mapMessages(snapshot.docs));
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
    final query = await _firestore
        .collection('conversations')
        .where('studentId', isEqualTo: studentId)
        .where('companyId', isEqualTo: companyId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final existingSnapshot = query.docs.first;
      final existingData = existingSnapshot.data();
      final updates = <String, dynamic>{};
      final normalizedCurrentUserId = currentUserId.trim();
      if (!_hasValidConversationStatus(existingData['status'])) {
        updates['status'] = 'active';
      }
      if ((existingData['contextType'] ?? '').toString().trim().isEmpty &&
          contextType.trim().isNotEmpty) {
        updates['contextType'] = contextType.trim();
      }
      if ((existingData['contextLabel'] ?? '').toString().trim().isEmpty &&
          contextLabel.trim().isNotEmpty) {
        updates['contextLabel'] = contextLabel.trim();
      }
      if (normalizedCurrentUserId.isNotEmpty) {
        updates['archivedBy'] = FieldValue.arrayRemove([
          normalizedCurrentUserId,
        ]);
        updates['deletedBy'] = FieldValue.arrayRemove([
          normalizedCurrentUserId,
        ]);
      }
      if (updates.isNotEmpty) {
        await _safeConversationMetadataUpdate(
          existingSnapshot.reference,
          updates,
        );
        return ConversationModel.fromMap({
          ...existingData,
          if (updates.containsKey('status')) 'status': updates['status'],
          if (updates.containsKey('contextType'))
            'contextType': updates['contextType'],
          if (updates.containsKey('contextLabel'))
            'contextLabel': updates['contextLabel'],
          if (normalizedCurrentUserId.isNotEmpty)
            'archivedBy': _removeUserFromStringList(
              existingData['archivedBy'],
              normalizedCurrentUserId,
            ),
          if (normalizedCurrentUserId.isNotEmpty)
            'deletedBy': _removeUserFromStringList(
              existingData['deletedBy'],
              normalizedCurrentUserId,
            ),
          'id': (existingData['id'] ?? existingSnapshot.id).toString(),
        });
      }
      return ConversationModel.fromMap({
        ...existingData,
        'id': (existingData['id'] ?? existingSnapshot.id).toString(),
      });
    }

    final now = Timestamp.now();
    final docRef = _firestore.collection('conversations').doc();
    final legacyConversationData = {
      'id': docRef.id,
      'studentId': studentId,
      'studentName': studentName,
      'companyId': companyId,
      'companyName': companyName,
      'lastMessage': '',
      'lastMessageType': 'text',
      'lastMessageSenderId': '',
      'lastMessageSenderName': '',
      'lastMessageTime': now,
      'startedAt': now,
      'status': 'active',
      'studentUnreadCount': 0,
      'companyUnreadCount': 0,
      'archivedBy': <String>[],
      'mutedBy': <String>[],
      'deletedBy': <String>[],
      'isGroup': false,
      'groupName': '',
      'groupAvatarUrl': '',
    };

    await _createConversationWithFallbacks(docRef, legacyConversationData);
    await _safeConversationMetadataUpdate(docRef, {
      'contextType': contextType.trim(),
      'contextLabel': contextLabel.trim(),
    });

    final conversation = ConversationModel(
      id: docRef.id,
      studentId: studentId,
      studentName: studentName,
      companyId: companyId,
      companyName: companyName,
      lastMessage: '',
      lastMessageTime: now,
      startedAt: now,
      status: 'active',
      contextType: contextType.trim(),
      contextLabel: contextLabel.trim(),
    );

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
    final trimmedText = text.trim();
    final resolvedType = _normalizeMessageType(
      messageType,
      attachmentFileName: attachmentFileName,
      attachmentMimeType: attachmentMimeType,
    );

    if (resolvedType == 'text' && trimmedText.isEmpty) {
      return;
    }

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final conversationSnap = await conversationRef.get();
    if (!conversationSnap.exists) {
      throw Exception('Conversation not found.');
    }

    final conversationData =
        conversationSnap.data() ?? const <String, dynamic>{};
    final resolvedStatus = _resolvedConversationStatus(
      conversationData['status'],
    );
    final resolvedRecipientId = _resolveRecipientId(
      conversationData,
      senderId,
      recipientId,
    );
    final conversationVisibilityRestoreTargets = _conversationStateTargets(
      senderId,
      resolvedRecipientId,
    );
    final msgRef = conversationRef.collection('messages').doc();

    StoredFileUploadResult? uploadedAttachment;
    if (resolvedType == 'image') {
      uploadedAttachment = await _storageService.uploadChatImage(
        userId: senderId,
        fileName: attachmentFileName,
        filePath: attachmentFilePath,
        fileBytes: attachmentFileBytes,
      );
    } else if (resolvedType == 'file') {
      uploadedAttachment = await _storageService.uploadChatFile(
        userId: senderId,
        fileName: attachmentFileName,
        filePath: attachmentFilePath,
        fileBytes: attachmentFileBytes,
        fallbackMimeType: attachmentMimeType.trim().isEmpty
            ? 'application/octet-stream'
            : attachmentMimeType.trim(),
      );
    }

    final now = Timestamp.now();
    final senderName = _senderNameFromConversation(
      conversationData,
      senderRole,
    );
    final message = MessageModel(
      id: msgRef.id,
      senderId: senderId,
      senderRole: senderRole,
      text: trimmedText,
      messageType: resolvedType,
      attachmentUrl: uploadedAttachment?.fileUrl ?? '',
      attachmentStoragePath: uploadedAttachment?.objectKey ?? '',
      fileName: uploadedAttachment?.fileName ?? attachmentFileName.trim(),
      fileSize: uploadedAttachment?.sizeOriginal ?? attachmentFileSize,
      mimeType: uploadedAttachment?.mimeType ?? attachmentMimeType.trim(),
      thumbnailUrl: resolvedType == 'image'
          ? uploadedAttachment?.fileUrl ?? ''
          : '',
      sentAt: now,
      deliveredAt: now,
      seenAt: null,
      isRead: false,
      isEdited: false,
      isDeleted: false,
      editedAt: null,
    );

    try {
      if (resolvedType == 'text' && !message.hasAttachment) {
        await _sendLegacyTextMessage(
          conversationRef: conversationRef,
          messageRef: msgRef,
          message: message,
          conversationStatus: resolvedStatus,
        );
        await _safeConversationMetadataUpdate(conversationRef, {
          'lastMessageType': 'text',
          'lastMessageSenderId': senderId,
          'lastMessageSenderName': senderName,
          'studentUnreadCount': senderId == conversationData['studentId']
              ? 0
              : FieldValue.increment(1),
          'companyUnreadCount': senderId == conversationData['studentId']
              ? FieldValue.increment(1)
              : 0,
          'archivedBy': FieldValue.arrayRemove(
            conversationVisibilityRestoreTargets,
          ),
          'deletedBy': FieldValue.arrayRemove(
            conversationVisibilityRestoreTargets,
          ),
          'status': 'active',
        });
      } else {
        final unreadField = senderId == conversationData['studentId']
            ? 'companyUnreadCount'
            : 'studentUnreadCount';
        final batch = _firestore.batch();
        batch.set(msgRef, message.toMap());
        batch.update(conversationRef, {
          'lastMessage': _buildConversationPreview(message),
          'lastMessageType': message.messageType,
          'lastMessageSenderId': senderId,
          'lastMessageSenderName': senderName,
          'lastMessageTime': now,
          unreadField: FieldValue.increment(1),
          'archivedBy': FieldValue.arrayRemove(
            conversationVisibilityRestoreTargets,
          ),
          'status': 'active',
        });
        await batch.commit();
        await _safeConversationMetadataUpdate(conversationRef, {
          'deletedBy': FieldValue.arrayRemove(
            conversationVisibilityRestoreTargets,
          ),
        });
      }
    } on FirebaseException catch (error) {
      if (uploadedAttachment != null &&
          uploadedAttachment.objectKey.trim().isNotEmpty) {
        try {
          await _storageService.deleteFileByPath(uploadedAttachment.objectKey);
        } catch (_) {}
      }

      if (resolvedType != 'text' && _isPermissionDeniedError(error)) {
        throw Exception(
          'Attachments need the updated chat backend to be deployed first. Text messages still work.',
        );
      }

      rethrow;
    }

    if (resolvedRecipientId.trim().isNotEmpty) {
      await _notificationWorker.notifyChatMessage(
        conversationId: conversationId,
        messageId: msgRef.id,
        message: _buildConversationPreview(message),
      );
    }
  }

  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'text': newText.trim(),
          'isEdited': true,
          'editedAt': Timestamp.now(),
        });

    await _updateConversationPreviewIfLatest(
      conversationId,
      messageId,
      newText,
    );
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true, 'text': ''});

    await _rebuildConversationPreview(
      conversationId,
      deletedMessageId: messageId,
    );
  }

  Future<void> archiveConversation({
    required String conversationId,
    required String userId,
    required bool archived,
  }) async {
    final conversationData = await _conversationData(conversationId);
    await _updateConversationDocument(
      _firestore.collection('conversations').doc(conversationId),
      {
        'archivedBy': archived
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
        'deletedBy': FieldValue.arrayRemove([userId]),
        'status': _resolvedConversationStatus(conversationData['status']),
      },
    );
  }

  Future<void> muteConversation({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    final conversationData = await _conversationData(conversationId);
    await _updateConversationDocument(
      _firestore.collection('conversations').doc(conversationId),
      {
        'mutedBy': muted
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
        'status': _resolvedConversationStatus(conversationData['status']),
      },
    );
  }

  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    final conversationData = await _conversationData(conversationId);
    final unreadField = userId == conversationData['studentId']
        ? 'studentUnreadCount'
        : 'companyUnreadCount';

    await _updateConversationDocument(
      _firestore.collection('conversations').doc(conversationId),
      {
        'deletedBy': FieldValue.arrayUnion([userId]),
        'archivedBy': FieldValue.arrayRemove([userId]),
        unreadField: 0,
        'status': _resolvedConversationStatus(conversationData['status']),
      },
    );
  }

  Future<List<UserModel>> searchChatContacts({
    required String currentUserId,
    required String currentRole,
    String query = '',
  }) async {
    final targetRole = currentRole == 'company' ? 'student' : 'company';
    final result = await _workerApi.get(
      '/api/chat/contacts?role=${Uri.encodeQueryComponent(targetRole)}&query=${Uri.encodeQueryComponent(query.trim())}',
    );

    final payload = result['users'];
    if (payload is! List) {
      return const [];
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromMap)
        .where((user) => user.uid.isNotEmpty && user.uid != currentUserId)
        .toList();
  }

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final conversationSnap = await conversationRef.get();
    final conversationData =
        conversationSnap.data() ?? const <String, dynamic>{};

    final unreadSnapshot = await conversationRef
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    final unread = unreadSnapshot.docs
        .where(
          (doc) =>
              (doc.data()['senderId'] ?? '').toString().trim() != currentUserId,
        )
        .toList();

    if (unread.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = Timestamp.now();
    for (final doc in unread) {
      batch.update(doc.reference, {'isRead': true, 'seenAt': now});
    }

    final unreadField = currentUserId == conversationData['studentId']
        ? 'studentUnreadCount'
        : 'companyUnreadCount';
    batch.update(conversationRef, {
      unreadField: 0,
      'status': _resolvedConversationStatus(conversationData['status']),
    });
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (_isIgnorableAbort(error)) {
        return;
      }
      if (!_isPermissionDeniedError(error)) {
        rethrow;
      }

      try {
        final legacyBatch = _firestore.batch();
        for (final doc in unread) {
          legacyBatch.update(doc.reference, {'isRead': true});
        }
        legacyBatch.update(conversationRef, {unreadField: 0});
        await legacyBatch.commit();
      } on FirebaseException catch (legacyError) {
        if (_isIgnorableAbort(legacyError)) {
          return;
        }
        if (!_isPermissionDeniedError(legacyError)) {
          rethrow;
        }

        final messagesOnlyBatch = _firestore.batch();
        for (final doc in unread) {
          messagesOnlyBatch.update(doc.reference, {'isRead': true});
        }
        await messagesOnlyBatch.commit();
      }
    }
  }

  Stream<int> getUnreadCount({
    required String conversationId,
    required String currentUserId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where(
                (doc) =>
                    (doc.data()['senderId'] ?? '').toString().trim() !=
                    currentUserId,
              )
              .length,
        );
  }

  Future<void> _updateConversationPreviewIfLatest(
    String conversationId,
    String messageId,
    String newText,
  ) async {
    final conversationData = await _conversationData(conversationId);
    final latestSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (latestSnapshot.docs.isNotEmpty &&
        latestSnapshot.docs.first.id == messageId) {
      await _updateConversationDocument(
        _firestore.collection('conversations').doc(conversationId),
        {
          'lastMessage': newText.trim(),
          'status': _resolvedConversationStatus(conversationData['status']),
        },
      );
    }
  }

  Future<void> _rebuildConversationPreview(
    String conversationId, {
    String deletedMessageId = '',
  }) async {
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final conversationSnap = await conversationRef.get();
    final conversationData =
        conversationSnap.data() ?? const <String, dynamic>{};

    final recentMsgs = await conversationRef
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(20)
        .get();

    Map<String, dynamic>? previewMessage;
    for (final doc in recentMsgs.docs) {
      final data = doc.data();
      if (doc.id == deletedMessageId ||
          data['isDeleted'] == true ||
          !_messageHasRenderableContent(data)) {
        continue;
      }
      previewMessage = data;
      break;
    }

    if (previewMessage == null) {
      await _updateConversationDocument(conversationRef, {
        'lastMessage': 'Message deleted',
        'lastMessageType': 'text',
        'lastMessageSenderId': '',
        'lastMessageSenderName': '',
        'status': _resolvedConversationStatus(conversationData['status']),
      });
      return;
    }

    final senderRole = (previewMessage['senderRole'] ?? '').toString().trim();
    await _updateConversationDocument(conversationRef, {
      'lastMessage': _buildPreviewFromMessageData(previewMessage),
      'lastMessageType': (previewMessage['messageType'] ?? 'text')
          .toString()
          .trim(),
      'lastMessageSenderId': (previewMessage['senderId'] ?? '')
          .toString()
          .trim(),
      'lastMessageSenderName': _senderNameFromConversation(
        conversationData,
        senderRole,
      ),
      'status': _resolvedConversationStatus(conversationData['status']),
    });
  }

  bool _messageHasRenderableContent(Map<String, dynamic> data) {
    final text = (data['text'] ?? '').toString().trim();
    final attachmentUrl = (data['attachmentUrl'] ?? '').toString().trim();
    final storagePath = (data['attachmentStoragePath'] ?? '').toString().trim();
    return text.isNotEmpty ||
        attachmentUrl.isNotEmpty ||
        storagePath.isNotEmpty;
  }

  String _buildConversationPreview(MessageModel message) {
    if (message.isImageMessage) {
      if (message.text.trim().isNotEmpty) {
        return message.text.trim();
      }
      return 'Photo attachment';
    }

    if (message.isFileMessage) {
      if (message.text.trim().isNotEmpty) {
        return message.text.trim();
      }
      return message.fileName.trim().isNotEmpty
          ? message.fileName.trim()
          : 'File attachment';
    }

    return message.text.trim();
  }

  String _buildPreviewFromMessageData(Map<String, dynamic> data) {
    final text = (data['text'] ?? '').toString().trim();
    final messageType = (data['messageType'] ?? 'text').toString().trim();
    final fileName = (data['fileName'] ?? '').toString().trim();

    if (text.isNotEmpty) {
      return text;
    }

    if (messageType == 'image') {
      return 'Photo attachment';
    }

    if (messageType == 'file') {
      return fileName.isNotEmpty ? fileName : 'File attachment';
    }

    return '';
  }

  String _normalizeMessageType(
    String value, {
    required String attachmentFileName,
    required String attachmentMimeType,
  }) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'image' || normalized == 'file') {
      return normalized;
    }

    final mimeType = attachmentMimeType.trim().toLowerCase();
    final fileName = attachmentFileName.trim().toLowerCase();
    final hasAttachment = fileName.isNotEmpty;
    if (!hasAttachment) {
      return 'text';
    }

    final isImage =
        mimeType.startsWith('image/') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.webp');
    return isImage ? 'image' : 'file';
  }

  String _resolveRecipientId(
    Map<String, dynamic> conversationData,
    String senderId,
    String? fallbackRecipientId,
  ) {
    final preferred = (fallbackRecipientId ?? '').trim();
    if (preferred.isNotEmpty) {
      return preferred;
    }

    final studentId = (conversationData['studentId'] ?? '').toString().trim();
    final companyId = (conversationData['companyId'] ?? '').toString().trim();
    return senderId == studentId ? companyId : studentId;
  }

  List<String> _conversationStateTargets(
    String leftUserId,
    String rightUserId,
  ) {
    return <String>{
      leftUserId.trim(),
      rightUserId.trim(),
    }.where((userId) => userId.isNotEmpty).toList(growable: false);
  }

  String _senderNameFromConversation(
    Map<String, dynamic> conversationData,
    String senderRole,
  ) {
    if (senderRole == 'company') {
      return (conversationData['companyName'] ?? '').toString().trim();
    }

    return (conversationData['studentName'] ?? '').toString().trim();
  }

  Future<void> _sendLegacyTextMessage({
    required DocumentReference<Map<String, dynamic>> conversationRef,
    required DocumentReference<Map<String, dynamic>> messageRef,
    required MessageModel message,
    required String conversationStatus,
  }) async {
    final candidatePayloads = <Map<String, dynamic>>[
      {
        'id': message.id,
        'senderId': message.senderId,
        'senderRole': message.senderRole,
        'text': message.text.trim(),
        'messageType': 'text',
        'attachmentUrl': '',
        'attachmentStoragePath': '',
        'fileName': '',
        'fileSize': 0,
        'mimeType': '',
        'thumbnailUrl': '',
        'sentAt': message.sentAt,
        'deliveredAt': message.deliveredAt,
        'seenAt': null,
        'isRead': false,
        'isEdited': false,
        'isDeleted': false,
        'editedAt': null,
      },
      {
        'id': message.id,
        'senderId': message.senderId,
        'senderRole': message.senderRole,
        'text': message.text.trim(),
        'sentAt': message.sentAt,
        'isRead': false,
      },
      {
        'id': message.id,
        'senderId': message.senderId,
        'text': message.text.trim(),
        'sentAt': message.sentAt,
        'isRead': false,
      },
    ];

    FirebaseException? lastPermissionError;
    for (final payload in candidatePayloads) {
      final conversationUpdates = <Map<String, dynamic>>[
        {
          'lastMessage': message.text.trim(),
          'lastMessageTime': message.sentAt,
          'status': conversationStatus,
        },
        {'lastMessage': message.text.trim(), 'lastMessageTime': message.sentAt},
        {'lastMessage': message.text.trim()},
      ];

      for (final conversationUpdate in conversationUpdates) {
        final batch = _firestore.batch();
        batch.set(messageRef, payload);
        batch.update(conversationRef, conversationUpdate);

        try {
          await batch.commit();
          return;
        } on FirebaseException catch (error) {
          if (_isIgnorableAbort(error)) {
            return;
          }
          if (!_isPermissionDeniedError(error)) {
            rethrow;
          }

          lastPermissionError = error;
        }
      }
    }

    if (lastPermissionError != null) {
      throw lastPermissionError;
    }
  }

  Future<void> _safeConversationMetadataUpdate(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is String && value.trim().isEmpty) {
        return;
      }
      sanitized[key] = value;
    });

    if (sanitized.isEmpty) {
      return;
    }

    try {
      await _updateConversationDocument(ref, sanitized);
    } on FirebaseException catch (error) {
      if (!_isPermissionDeniedError(error)) {
        rethrow;
      }
    }
  }

  bool _isPermissionDeniedError(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }

  bool _isIgnorableAbort(Object error) {
    if (error is FirebaseException &&
        (error.code == 'aborted' || error.code == 'cancelled')) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('firebaseignoreexception') &&
        message.contains('http request was aborted');
  }

  Future<void> _updateConversationDocument(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    final candidates = <Map<String, dynamic>>[
      data,
      _withoutKeys(data, const <String>{'status'}),
      _withoutKeys(data, const <String>{'deletedBy'}),
      _withoutKeys(data, const <String>{'status', 'deletedBy'}),
    ].where((candidate) => candidate.isNotEmpty).toList(growable: false);

    FirebaseException? lastPermissionError;
    for (final candidate in candidates) {
      try {
        await ref.update(candidate);
        return;
      } on FirebaseException catch (error) {
        if (_isIgnorableAbort(error)) {
          return;
        }
        if (!_isPermissionDeniedError(error)) {
          rethrow;
        }

        lastPermissionError = error;
      }
    }

    if (lastPermissionError != null) {
      throw lastPermissionError;
    }
  }

  Map<String, dynamic> _withoutKeys(
    Map<String, dynamic> source,
    Set<String> keys,
  ) {
    final copy = Map<String, dynamic>.from(source);
    copy.removeWhere((key, value) => keys.contains(key));
    return copy;
  }

  bool _hasValidConversationStatus(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'active' || normalized == 'closed';
  }

  String _resolvedConversationStatus(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'closed' ? 'closed' : 'active';
  }

  List<String> _removeUserFromStringList(Object? value, String userId) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty && item != userId)
        .toList(growable: false);
  }

  Future<void> _createConversationWithFallbacks(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> payload,
  ) async {
    final candidatePayloads = <Map<String, dynamic>>[
      payload,
      {
        'id': payload['id'],
        'studentId': payload['studentId'],
        'studentName': payload['studentName'],
        'companyId': payload['companyId'],
        'companyName': payload['companyName'],
        'lastMessage': payload['lastMessage'],
        'lastMessageTime': payload['lastMessageTime'],
        'status': payload['status'],
      },
      {
        'id': payload['id'],
        'studentId': payload['studentId'],
        'studentName': payload['studentName'],
        'companyId': payload['companyId'],
        'companyName': payload['companyName'],
        'lastMessage': payload['lastMessage'],
        'lastMessageTime': payload['lastMessageTime'],
      },
    ];

    FirebaseException? lastPermissionError;
    for (final candidate in candidatePayloads) {
      try {
        await ref.set(candidate);
        return;
      } on FirebaseException catch (error) {
        if (_isIgnorableAbort(error)) {
          return;
        }
        if (!_isPermissionDeniedError(error)) {
          rethrow;
        }

        lastPermissionError = error;
      }
    }

    if (lastPermissionError != null) {
      throw lastPermissionError;
    }
  }

  Future<Map<String, dynamic>> _conversationData(String conversationId) async {
    final snapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    return snapshot.data() ?? const <String, dynamic>{};
  }

  List<ConversationModel> _mapConversations(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = <ConversationModel>[];
    for (final doc in docs) {
      try {
        final data = doc.data();
        items.add(
          ConversationModel.fromMap({
            ...data,
            'id': (data['id'] ?? doc.id).toString(),
          }),
        );
      } catch (error) {
        debugPrint('Skipping invalid conversation ${doc.id}: $error');
      }
    }

    return items;
  }

  List<MessageModel> _mapMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = <MessageModel>[];
    for (final doc in docs) {
      try {
        final data = doc.data();
        items.add(
          MessageModel.fromMap({
            ...data,
            'id': (data['id'] ?? doc.id).toString(),
          }),
        );
      } catch (error) {
        debugPrint('Skipping invalid message ${doc.id}: $error');
      }
    }

    return items;
  }
}
