import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final String messageType;
  final String attachmentUrl;
  final String attachmentStoragePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String thumbnailUrl;
  final Timestamp? sentAt;
  final Timestamp? deliveredAt;
  final Timestamp? seenAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final Timestamp? editedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.messageType = 'text',
    this.attachmentUrl = '',
    this.attachmentStoragePath = '',
    this.fileName = '',
    this.fileSize = 0,
    this.mimeType = '',
    this.thumbnailUrl = '',
    this.sentAt,
    this.deliveredAt,
    this.seenAt,
    required this.isRead,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final rawType = (map['messageType'] ?? map['type'] ?? '').toString().trim();
    final attachmentUrl = (map['attachmentUrl'] ?? map['fileUrl'] ?? '')
        .toString()
        .trim();
    final mimeType = (map['mimeType'] ?? '').toString().trim();
    final fileName = (map['fileName'] ?? '').toString().trim();

    return MessageModel(
      id: (map['id'] ?? '').toString().trim(),
      senderId: (map['senderId'] ?? '').toString().trim(),
      senderRole: (map['senderRole'] ?? '').toString().trim(),
      text: (map['text'] ?? '').toString(),
      messageType: _resolveMessageType(
        rawType: rawType,
        attachmentUrl: attachmentUrl,
        mimeType: mimeType,
        fileName: fileName,
      ),
      attachmentUrl: attachmentUrl,
      attachmentStoragePath:
          (map['attachmentStoragePath'] ?? map['storagePath'] ?? '')
              .toString()
              .trim(),
      fileName: fileName,
      fileSize: _parseInt(map['fileSize']),
      mimeType: mimeType,
      thumbnailUrl: (map['thumbnailUrl'] ?? '').toString().trim(),
      sentAt: _parseTimestamp(map['sentAt']),
      deliveredAt: _parseTimestamp(map['deliveredAt']),
      seenAt: _parseTimestamp(map['seenAt']),
      isRead: _parseBool(map['isRead']),
      isEdited: _parseBool(map['isEdited']),
      isDeleted: _parseBool(map['isDeleted']),
      editedAt: _parseTimestamp(map['editedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'messageType': messageType,
      'attachmentUrl': attachmentUrl,
      'attachmentStoragePath': attachmentStoragePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'thumbnailUrl': thumbnailUrl,
      'sentAt': sentAt,
      'deliveredAt': deliveredAt,
      'seenAt': seenAt,
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'editedAt': editedAt,
    };
  }

  bool get isTextMessage => messageType == 'text';
  bool get isImageMessage => messageType == 'image';
  bool get isFileMessage => messageType == 'file';

  bool get hasAttachment =>
      attachmentUrl.trim().isNotEmpty ||
      attachmentStoragePath.trim().isNotEmpty;

  String get displayText {
    if (isDeleted) {
      return 'This message was deleted';
    }

    if (text.trim().isNotEmpty) {
      return text.trim();
    }

    if (isImageMessage) {
      return 'Photo';
    }

    if (isFileMessage) {
      return fileName.trim().isNotEmpty ? fileName.trim() : 'File attachment';
    }

    return '';
  }

  String get previewLabel {
    if (isDeleted) {
      return 'Message deleted';
    }

    if (text.trim().isNotEmpty) {
      return text.trim();
    }

    if (isImageMessage) {
      return 'Photo attachment';
    }

    if (isFileMessage) {
      return fileName.trim().isNotEmpty ? fileName.trim() : 'File attachment';
    }

    return '';
  }

  static String _resolveMessageType({
    required String rawType,
    required String attachmentUrl,
    required String mimeType,
    required String fileName,
  }) {
    if (rawType == 'text' || rawType == 'image' || rawType == 'file') {
      return rawType;
    }

    if (attachmentUrl.isEmpty) {
      return 'text';
    }

    if (_looksLikeImage(mimeType, fileName)) {
      return 'image';
    }

    return 'file';
  }

  static bool _looksLikeImage(String mimeType, String fileName) {
    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (normalizedMimeType.startsWith('image/')) {
      return true;
    }

    final normalizedFileName = fileName.trim().toLowerCase();
    return normalizedFileName.endsWith('.png') ||
        normalizedFileName.endsWith('.jpg') ||
        normalizedFileName.endsWith('.jpeg') ||
        normalizedFileName.endsWith('.webp');
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

  static bool _parseBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
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
