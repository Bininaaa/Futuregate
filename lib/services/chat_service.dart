import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/application_status.dart';
import 'file_storage_service.dart';
import 'interfaces/i_chat_service.dart';
import 'notification_worker_service.dart';
import 'worker_api_service.dart';
import '../utils/crashlytics_logger.dart';

class ChatService implements IChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final StorageService _storageService = StorageService();
  final WorkerApiService _workerApi = WorkerApiService();

  @override
  Stream<List<ConversationModel>> getConversationsAsStudent(String userId) {
    return _firestore
        .collection('conversations')
        .where('studentId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => _mapConversations(snapshot.docs));
  }

  @override
  Stream<List<ConversationModel>> getConversationsAsCompany(String userId) {
    return _firestore
        .collection('conversations')
        .where('companyId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => _mapConversations(snapshot.docs));
  }

  @override
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

  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => _mapMessages(snapshot.docs));
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String studentName,
    required String companyId,
    required String companyName,
    String contextType = '',
    String contextLabel = '',
    String currentUserId = '',
    required String currentUserRole,
  }) async {
    final normalizedCurrentUserId = currentUserId.trim();
    final actorRole = _resolveActorRole(
      currentUserRole: currentUserRole,
      currentUserId: normalizedCurrentUserId,
      studentId: studentId,
      companyId: companyId,
    );
    final application = await _resolveApplicationForConversationStart(
      studentId: studentId,
      companyId: companyId,
      currentUserRole: actorRole,
    );

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
      if (!_hasValidConversationStatus(existingData['status'])) {
        updates['status'] = 'active';
      }
      final existingApplicationId = (existingData['applicationId'] ?? '')
          .toString()
          .trim();
      final existingApplication = existingApplicationId.isEmpty
          ? null
          : await _applicationById(existingApplicationId);
      if (existingApplicationId.isEmpty ||
          (actorRole == 'student' &&
              existingApplication?.isAccepted != true &&
              application.isAccepted)) {
        updates['applicationId'] = application.id;
      }
      if ((existingData['createdById'] ?? '').toString().trim().isEmpty &&
          normalizedCurrentUserId.isNotEmpty) {
        updates['createdById'] = normalizedCurrentUserId;
      }
      if ((existingData['createdByRole'] ?? '').toString().trim().isEmpty &&
          actorRole.isNotEmpty) {
        updates['createdByRole'] = actorRole;
      }
      if (!existingData.containsKey('companyHasMessaged')) {
        updates['companyHasMessaged'] = false;
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
          if (updates.containsKey('applicationId'))
            'applicationId': updates['applicationId'],
          if (updates.containsKey('createdById'))
            'createdById': updates['createdById'],
          if (updates.containsKey('createdByRole'))
            'createdByRole': updates['createdByRole'],
          if (updates.containsKey('companyHasMessaged'))
            'companyHasMessaged': updates['companyHasMessaged'],
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
      'contextType': contextType.trim(),
      'contextLabel': contextLabel.trim(),
      'applicationId': application.id,
      'createdById': normalizedCurrentUserId,
      'createdByRole': actorRole,
      'companyHasMessaged': false,
    };

    await _createConversationWithFallbacks(docRef, legacyConversationData);

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
      applicationId: application.id,
      createdById: normalizedCurrentUserId,
      createdByRole: actorRole,
      companyHasMessaged: false,
    );

    return conversation;
  }

  @override
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
    final chatApplication = await _assertCanSendMessage(
      conversationData: conversationData,
      senderId: senderId,
      senderRole: senderRole,
    );
    final senderIsCompany =
        _resolveActorRole(
          currentUserRole: senderRole,
          currentUserId: senderId,
          studentId: (conversationData['studentId'] ?? '').toString(),
          companyId: (conversationData['companyId'] ?? '').toString(),
        ) ==
        'company';
    if ((conversationData['applicationId'] ?? '').toString().trim() !=
        chatApplication.id) {
      await _safeConversationMetadataUpdate(conversationRef, {
        'applicationId': chatApplication.id,
      });
      conversationData['applicationId'] = chatApplication.id;
    }
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
          if (senderIsCompany) 'companyHasMessaged': true,
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
          if (senderIsCompany) 'companyHasMessaged': true,
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

      recordNonFatal(error, StackTrace.current, context: 'chat_send_message');
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

  @override
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

  @override
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

  @override
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

  @override
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

  Future<_ChatApplication> _resolveApplicationForConversationStart({
    required String studentId,
    required String companyId,
    required String currentUserRole,
  }) async {
    final applications = await _applicationsForPair(
      studentId: studentId,
      companyId: companyId,
      preferStudentQuery: currentUserRole == 'student',
    );

    if (applications.isEmpty) {
      throw Exception(
        currentUserRole == 'company'
            ? 'This student has not applied to your company.'
            : 'You can chat with a company after applying and getting approved.',
      );
    }

    if (currentUserRole == 'student') {
      final accepted = applications.where((item) => item.isAccepted).toList();
      if (accepted.isEmpty) {
        throw Exception(
          'You can chat with this company after your application is approved.',
        );
      }
      return accepted.first;
    }

    if (currentUserRole != 'company') {
      throw Exception('Only students and companies can start chats.');
    }

    return applications.first;
  }

  Future<_ChatApplication> _assertCanSendMessage({
    required Map<String, dynamic> conversationData,
    required String senderId,
    required String senderRole,
  }) async {
    final studentId = (conversationData['studentId'] ?? '').toString().trim();
    final companyId = (conversationData['companyId'] ?? '').toString().trim();
    final actorRole = _resolveActorRole(
      currentUserRole: senderRole,
      currentUserId: senderId,
      studentId: studentId,
      companyId: companyId,
    );

    if (actorRole == 'company') {
      if (senderId.trim() != companyId) {
        throw Exception('Only the company can send from this chat.');
      }
      final application = await _applicationForConversation(conversationData);
      if (application == null) {
        throw Exception('This student has not applied to your company.');
      }
      return application;
    }

    if (actorRole == 'student') {
      if (senderId.trim() != studentId) {
        throw Exception('Only the student can send from this chat.');
      }
      final application = await _applicationForConversation(conversationData);
      if (application == null) {
        throw Exception(
          'You can chat with a company after applying and getting approved.',
        );
      }
      if (application.isAccepted ||
          conversationData['companyHasMessaged'] == true) {
        return application;
      }

      throw Exception(
        'You can chat after the company approves your application or messages you.',
      );
    }

    throw Exception('Only students and companies can send chat messages.');
  }

  Future<_ChatApplication?> _applicationForConversation(
    Map<String, dynamic> conversationData,
  ) async {
    final applicationId = (conversationData['applicationId'] ?? '')
        .toString()
        .trim();
    final studentId = (conversationData['studentId'] ?? '').toString().trim();
    final companyId = (conversationData['companyId'] ?? '').toString().trim();

    if (applicationId.isNotEmpty) {
      final application = await _applicationById(applicationId);
      if (application != null &&
          application.studentId == studentId &&
          application.companyId == companyId) {
        return application;
      }
    }

    final applications = await _applicationsForPair(
      studentId: studentId,
      companyId: companyId,
    );
    if (applications.isEmpty) {
      return null;
    }

    final accepted = applications.where((item) => item.isAccepted).toList();
    return accepted.isNotEmpty ? accepted.first : applications.first;
  }

  Future<_ChatApplication?> _applicationById(String applicationId) async {
    final normalizedApplicationId = applicationId.trim();
    if (normalizedApplicationId.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('applications')
        .doc(normalizedApplicationId)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    return _ChatApplication.fromMap({
      ...data,
      'id': (data['id'] ?? snapshot.id).toString(),
    });
  }

  Future<List<_ChatApplication>> _applicationsForPair({
    required String studentId,
    required String companyId,
    bool preferStudentQuery = false,
  }) async {
    final normalizedStudentId = studentId.trim();
    final normalizedCompanyId = companyId.trim();
    if (normalizedStudentId.isEmpty || normalizedCompanyId.isEmpty) {
      return const <_ChatApplication>[];
    }

    final query = preferStudentQuery
        ? _firestore
              .collection('applications')
              .where('studentId', isEqualTo: normalizedStudentId)
        : _firestore
              .collection('applications')
              .where('companyId', isEqualTo: normalizedCompanyId);
    final snapshot = await query.get();
    final applications = snapshot.docs
        .map((doc) {
          final data = doc.data();
          return _ChatApplication.fromMap({
            ...data,
            'id': (data['id'] ?? doc.id).toString(),
          });
        })
        .where(
          (application) =>
              application.studentId == normalizedStudentId &&
              application.companyId == normalizedCompanyId,
        )
        .toList();

    applications.sort((left, right) {
      final leftTime = left.appliedAt?.millisecondsSinceEpoch ?? 0;
      final rightTime = right.appliedAt?.millisecondsSinceEpoch ?? 0;
      return rightTime.compareTo(leftTime);
    });

    return applications;
  }

  String _resolveActorRole({
    required String currentUserRole,
    required String currentUserId,
    required String studentId,
    required String companyId,
  }) {
    final normalizedRole = currentUserRole.trim().toLowerCase();
    if (normalizedRole == 'student' || normalizedRole == 'company') {
      return normalizedRole;
    }

    final normalizedCurrentUserId = currentUserId.trim();
    if (normalizedCurrentUserId.isNotEmpty) {
      if (normalizedCurrentUserId == studentId.trim()) {
        return 'student';
      }
      if (normalizedCurrentUserId == companyId.trim()) {
        return 'company';
      }
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
        'applicationId': payload['applicationId'],
        'createdById': payload['createdById'],
        'createdByRole': payload['createdByRole'],
        'companyHasMessaged': payload['companyHasMessaged'],
      },
      {
        'id': payload['id'],
        'studentId': payload['studentId'],
        'studentName': payload['studentName'],
        'companyId': payload['companyId'],
        'companyName': payload['companyName'],
        'lastMessage': payload['lastMessage'],
        'lastMessageTime': payload['lastMessageTime'],
        'applicationId': payload['applicationId'],
        'createdById': payload['createdById'],
        'createdByRole': payload['createdByRole'],
        'companyHasMessaged': payload['companyHasMessaged'],
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

class _ChatApplication {
  final String id;
  final String studentId;
  final String companyId;
  final String status;
  final Timestamp? appliedAt;

  const _ChatApplication({
    required this.id,
    required this.studentId,
    required this.companyId,
    required this.status,
    this.appliedAt,
  });

  bool get isAccepted => status == ApplicationStatus.accepted;

  factory _ChatApplication.fromMap(Map<String, dynamic> map) {
    return _ChatApplication(
      id: (map['id'] ?? '').toString().trim(),
      studentId: (map['studentId'] ?? '').toString().trim(),
      companyId: (map['companyId'] ?? '').toString().trim(),
      status: ApplicationStatus.parse(map['status']?.toString()),
      appliedAt: map['appliedAt'] is Timestamp
          ? map['appliedAt'] as Timestamp
          : null,
    );
  }
}
