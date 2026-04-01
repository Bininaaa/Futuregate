import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String companyId;
  final String companyName;
  final String lastMessage;
  final String lastMessageType;
  final String lastMessageSenderId;
  final String lastMessageSenderName;
  final Timestamp? lastMessageTime;
  final Timestamp? startedAt;
  final String status;
  final int studentUnreadCount;
  final int companyUnreadCount;
  final List<String> archivedBy;
  final List<String> mutedBy;
  final List<String> deletedBy;
  final String contextType;
  final String contextLabel;
  final bool isGroup;
  final String groupName;
  final String groupAvatarUrl;

  ConversationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.companyId,
    required this.companyName,
    required this.lastMessage,
    this.lastMessageType = 'text',
    this.lastMessageSenderId = '',
    this.lastMessageSenderName = '',
    this.lastMessageTime,
    this.startedAt,
    required this.status,
    this.studentUnreadCount = 0,
    this.companyUnreadCount = 0,
    List<String> archivedBy = const <String>[],
    List<String> mutedBy = const <String>[],
    List<String> deletedBy = const <String>[],
    this.contextType = '',
    this.contextLabel = '',
    this.isGroup = false,
    this.groupName = '',
    this.groupAvatarUrl = '',
  }) : archivedBy = List<String>.unmodifiable(archivedBy),
       mutedBy = List<String>.unmodifiable(mutedBy),
       deletedBy = List<String>.unmodifiable(deletedBy);

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: (map['lastMessageType'] ?? 'text').toString().trim(),
      lastMessageSenderId: (map['lastMessageSenderId'] ?? '').toString().trim(),
      lastMessageSenderName: (map['lastMessageSenderName'] ?? '')
          .toString()
          .trim(),
      lastMessageTime: _parseTimestamp(map['lastMessageTime']),
      startedAt: _parseTimestamp(map['startedAt']),
      status: map['status'] ?? 'active',
      studentUnreadCount: _parseInt(map['studentUnreadCount']),
      companyUnreadCount: _parseInt(map['companyUnreadCount']),
      archivedBy: _parseStringList(map['archivedBy']),
      mutedBy: _parseStringList(map['mutedBy']),
      deletedBy: _parseStringList(map['deletedBy']),
      contextType: (map['contextType'] ?? '').toString().trim(),
      contextLabel: (map['contextLabel'] ?? '').toString().trim(),
      isGroup: map['isGroup'] == true,
      groupName: (map['groupName'] ?? '').toString().trim(),
      groupAvatarUrl: (map['groupAvatarUrl'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'companyId': companyId,
      'companyName': companyName,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTime': lastMessageTime,
      'startedAt': startedAt,
      'status': status,
      'studentUnreadCount': studentUnreadCount,
      'companyUnreadCount': companyUnreadCount,
      'archivedBy': List<String>.from(archivedBy),
      'mutedBy': List<String>.from(mutedBy),
      'deletedBy': List<String>.from(deletedBy),
      'contextType': contextType,
      'contextLabel': contextLabel,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
    };
  }

  String displayNameFor(String currentUserId) {
    if (isGroup && groupName.trim().isNotEmpty) {
      return groupName.trim();
    }

    return currentUserId == studentId ? companyName : studentName;
  }

  String otherParticipantId(String currentUserId) {
    return currentUserId == studentId ? companyId : studentId;
  }

  String otherParticipantRole(String currentUserId) {
    return currentUserId == studentId ? 'company' : 'student';
  }

  int unreadCountFor(String currentUserId) {
    return currentUserId == studentId ? studentUnreadCount : companyUnreadCount;
  }

  bool isArchivedFor(String currentUserId) {
    return archivedBy.contains(currentUserId);
  }

  bool isMutedFor(String currentUserId) {
    return mutedBy.contains(currentUserId);
  }

  bool isDeletedFor(String currentUserId) {
    return deletedBy.contains(currentUserId);
  }

  bool get isProjectConversation {
    if (contextType == 'project' ||
        contextType == 'opportunity' ||
        contextType == 'application') {
      return true;
    }

    return !isGroup && studentId.isNotEmpty && companyId.isNotEmpty;
  }

  String get listPreviewText {
    final preview = lastMessage.trim();
    if (preview.isNotEmpty) {
      if (isGroup &&
          lastMessageSenderName.trim().isNotEmpty &&
          lastMessageSenderId.trim().isNotEmpty) {
        return '${lastMessageSenderName.trim()}: $preview';
      }

      return preview;
    }

    if (lastMessageType == 'image') {
      return 'Photo attachment';
    }

    if (lastMessageType == 'file') {
      return 'File attachment';
    }

    return 'Start the conversation';
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static Timestamp? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return Timestamp.fromDate(parsed);
      }
    }

    return null;
  }
}
