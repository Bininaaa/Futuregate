import 'dart:typed_data';

import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

abstract interface class IChatService {
  Stream<List<ConversationModel>> getConversationsAsStudent(String userId);
  Stream<List<ConversationModel>> getConversationsAsCompany(String userId);
  Stream<ConversationModel?> watchConversation(String conversationId);
  Stream<List<MessageModel>> getMessages(String conversationId);

  Stream<int> getUnreadCount({
    required String conversationId,
    required String currentUserId,
  });

  Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String studentName,
    required String companyId,
    required String companyName,
    String contextType,
    String contextLabel,
    String currentUserId,
    required String currentUserRole,
  });

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    String? recipientId,
    String messageType,
    String attachmentFileName,
    String attachmentFilePath,
    Uint8List? attachmentFileBytes,
    int attachmentFileSize,
    String attachmentMimeType,
  });

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  });

  Future<void> archiveConversation({
    required String conversationId,
    required String userId,
    required bool archived,
  });

  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  });
}
