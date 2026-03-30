import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'notification_worker_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();

  Stream<List<ConversationModel>> getConversationsAsStudent(String userId) {
    return _firestore
        .collection('conversations')
        .where('studentId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<ConversationModel>> getConversationsAsCompany(String userId) {
    return _firestore
        .collection('conversations')
        .where('companyId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String studentName,
    required String companyId,
    required String companyName,
  }) async {
    final query = await _firestore
        .collection('conversations')
        .where('studentId', isEqualTo: studentId)
        .where('companyId', isEqualTo: companyId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ConversationModel.fromMap(query.docs.first.data());
    }

    final docRef = _firestore.collection('conversations').doc();
    final conversation = ConversationModel(
      id: docRef.id,
      studentId: studentId,
      studentName: studentName,
      companyId: companyId,
      companyName: companyName,
      lastMessage: '',
      lastMessageTime: Timestamp.now(),
      startedAt: Timestamp.now(),
      status: 'active',
    );

    await docRef.set(conversation.toMap());
    return conversation;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    String? recipientId,
  }) async {
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    final message = MessageModel(
      id: msgRef.id,
      senderId: senderId,
      senderRole: senderRole,
      text: text,
      sentAt: Timestamp.now(),
      isRead: false,
    );

    final batch = _firestore.batch();
    batch.set(msgRef, message.toMap());
    batch.update(conversationRef, {
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
    });
    await batch.commit();

    String resolvedRecipientId = recipientId ?? '';

    if (resolvedRecipientId.isEmpty) {
      final convSnap = await conversationRef.get();
      if (convSnap.exists) {
        final convData = convSnap.data()!;
        resolvedRecipientId = (senderId == convData['studentId'])
            ? convData['companyId'] ?? ''
            : convData['studentId'] ?? '';
      }
    }

    if (resolvedRecipientId.isNotEmpty) {
      await _notificationWorker.notifyChatMessage(
        conversationId: conversationId,
        messageId: msgRef.id,
        message: text,
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
      'text': newText,
      'isEdited': true,
      'editedAt': Timestamp.now(),
    });

    await _updateConversationPreviewIfLatest(conversationId, messageId, newText);
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
        .update({
      'isDeleted': true,
      'text': '',
    });

    final latestSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (latestSnapshot.docs.isNotEmpty &&
        latestSnapshot.docs.first.id == messageId) {
      final recentMsgs = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(20)
          .get();

      String previewText = 'Message deleted';
      for (final doc in recentMsgs.docs) {
        final data = doc.data();
        if (data['isDeleted'] != true && (data['text'] ?? '').toString().isNotEmpty) {
          previewText = data['text'];
          break;
        }
      }

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'lastMessage': previewText});
    }
  }

  Future<void> _updateConversationPreviewIfLatest(
    String conversationId,
    String messageId,
    String newText,
  ) async {
    final latestSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (latestSnapshot.docs.isNotEmpty &&
        latestSnapshot.docs.first.id == messageId) {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'lastMessage': newText});
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
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    final unread = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
