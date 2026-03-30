import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final Timestamp? sentAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final Timestamp? editedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.sentAt,
    required this.isRead,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? '',
      text: map['text'] ?? '',
      sentAt: map['sentAt'],
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      editedAt: map['editedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'sentAt': sentAt,
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'editedAt': editedAt,
    };
  }
}
