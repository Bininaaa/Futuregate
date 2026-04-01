import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ChatLocalState {
  final Set<String> archivedConversationIds;
  final Set<String> mutedConversationIds;
  final Set<String> hiddenConversationIds;

  ChatLocalState({
    Set<String> archivedConversationIds = const <String>{},
    Set<String> mutedConversationIds = const <String>{},
    Set<String> hiddenConversationIds = const <String>{},
  }) : archivedConversationIds = <String>{...archivedConversationIds},
       mutedConversationIds = <String>{...mutedConversationIds},
       hiddenConversationIds = <String>{...hiddenConversationIds};

  bool get isEmpty =>
      archivedConversationIds.isEmpty &&
      mutedConversationIds.isEmpty &&
      hiddenConversationIds.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'archivedConversationIds': archivedConversationIds.toList()..sort(),
      'mutedConversationIds': mutedConversationIds.toList()..sort(),
      'hiddenConversationIds': hiddenConversationIds.toList()..sort(),
    };
  }

  factory ChatLocalState.fromMap(Map<String, dynamic> map) {
    Set<String> parseSet(Object? value) {
      if (value is! List) {
        return <String>{};
      }

      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    }

    return ChatLocalState(
      archivedConversationIds: parseSet(map['archivedConversationIds']),
      mutedConversationIds: parseSet(map['mutedConversationIds']),
      hiddenConversationIds: parseSet(map['hiddenConversationIds']),
    );
  }
}

class ChatLocalStateService {
  Future<ChatLocalState> load(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return ChatLocalState();
    }

    try {
      final file = await _stateFile(normalizedUserId);
      if (!await file.exists()) {
        return ChatLocalState();
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return ChatLocalState();
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ChatLocalState.fromMap(decoded);
      }
    } catch (_) {}

    return ChatLocalState();
  }

  Future<void> save(String userId, ChatLocalState state) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final file = await _stateFile(normalizedUserId);
    await file.writeAsString(jsonEncode(state.toMap()), flush: true);
  }

  Future<void> clear(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final file = await _stateFile(normalizedUserId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _stateFile(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${directory.path}${Platform.pathSeparator}chat_state',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return File('${folder.path}${Platform.pathSeparator}$userId.json');
  }
}
