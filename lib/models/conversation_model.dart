import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String companyId;
  final String companyName;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final Timestamp? startedAt;
  final String status;

  ConversationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.companyId,
    required this.companyName,
    required this.lastMessage,
    this.lastMessageTime,
    this.startedAt,
    required this.status,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'],
      startedAt: map['startedAt'],
      status: map['status'] ?? 'active',
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
      'lastMessageTime': lastMessageTime,
      'startedAt': startedAt,
      'status': status,
    };
  }
}
