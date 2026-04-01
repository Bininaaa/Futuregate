import 'dart:typed_data';

import 'package:avenirdz/models/conversation_model.dart';
import 'package:avenirdz/models/message_model.dart';
import 'package:avenirdz/models/user_model.dart';
import 'package:avenirdz/providers/chat_provider.dart';
import 'package:avenirdz/services/chat_local_state_service.dart';
import 'package:avenirdz/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatService implements ChatService {
  final List<Map<String, String>> archiveCalls = <Map<String, String>>[];
  final List<Map<String, String>> deleteCalls = <Map<String, String>>[];
  bool failArchive = false;

  @override
  Stream<List<ConversationModel>> getConversationsAsStudent(String userId) {
    return const Stream<List<ConversationModel>>.empty();
  }

  @override
  Stream<List<ConversationModel>> getConversationsAsCompany(String userId) {
    return const Stream<List<ConversationModel>>.empty();
  }

  @override
  Stream<ConversationModel?> watchConversation(String conversationId) {
    return const Stream<ConversationModel?>.empty();
  }

  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return const Stream<List<MessageModel>>.empty();
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
  }) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> archiveConversation({
    required String conversationId,
    required String userId,
    required bool archived,
  }) async {
    if (failArchive) {
      throw Exception('archive failed');
    }

    archiveCalls.add(<String, String>{
      'conversationId': conversationId,
      'userId': userId,
      'archived': archived.toString(),
    });
  }

  @override
  Future<void> muteConversation({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {}

  @override
  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    deleteCalls.add(<String, String>{
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  @override
  Future<List<UserModel>> searchChatContacts({
    required String currentUserId,
    required String currentRole,
    String query = '',
  }) async {
    return const <UserModel>[];
  }

  @override
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {}

  @override
  Stream<int> getUnreadCount({
    required String conversationId,
    required String currentUserId,
  }) {
    return const Stream<int>.empty();
  }
}

class _FakeChatLocalStateService extends ChatLocalStateService {
  _FakeChatLocalStateService(this.state);

  final ChatLocalState state;

  @override
  Future<ChatLocalState> load(String userId) async => state;

  @override
  Future<void> clear(String userId) async {}
}

void main() {
  test('ChatLocalState uses mutable sets instead of immutable defaults', () {
    final state = ChatLocalState();

    state.archivedConversationIds.add('conversation-1');
    state.mutedConversationIds.add('conversation-2');
    state.hiddenConversationIds.add('conversation-3');

    expect(state.archivedConversationIds, contains('conversation-1'));
    expect(state.mutedConversationIds, contains('conversation-2'));
    expect(state.hiddenConversationIds, contains('conversation-3'));
  });

  test('ConversationModel tracks deleted state from persisted data', () {
    final conversation = ConversationModel.fromMap(<String, dynamic>{
      'id': 'conversation-1',
      'studentId': 'student-1',
      'studentName': 'Student',
      'companyId': 'company-1',
      'companyName': 'Company',
      'lastMessage': 'Hello',
      'status': 'active',
      'deletedBy': <String>['student-1'],
    });

    expect(conversation.isDeletedFor('student-1'), isTrue);
    expect(conversation.isDeletedFor('company-1'), isFalse);
  });

  test('ChatProvider persists delete and reverts failed archive optimism', () async {
    final fakeService = _FakeChatService();
    final provider = ChatProvider(
      chatService: fakeService,
      localStateService: _FakeChatLocalStateService(ChatLocalState()),
    );
    final conversation = ConversationModel.fromMap(<String, dynamic>{
      'id': 'conversation-1',
      'studentId': 'student-1',
      'studentName': 'Student',
      'companyId': 'company-1',
      'companyName': 'Company',
      'lastMessage': 'Hello',
      'status': 'active',
    });

    await provider.deleteConversation(
      conversationId: conversation.id,
      userId: 'student-1',
    );

    expect(
      provider.isConversationDeletedFor(conversation, 'student-1'),
      isTrue,
    );
    expect(fakeService.deleteCalls, hasLength(1));
    expect(fakeService.deleteCalls.single['conversationId'], 'conversation-1');
    expect(fakeService.deleteCalls.single['userId'], 'student-1');

    fakeService.failArchive = true;
    await provider.archiveConversation(
      conversationId: conversation.id,
      userId: 'student-1',
      archived: true,
    );

    expect(provider.error, contains('archive failed'));
    expect(
      provider.isConversationArchivedFor(conversation, 'student-1'),
      isFalse,
    );
  });
}
