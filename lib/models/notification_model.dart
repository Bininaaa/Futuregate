import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String body;
  final String type;
  final Timestamp? createdAt;
  final bool isRead;
  final String conversationId;
  final String targetId;
  final String route;
  final String eventKey;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.body = '',
    required this.type,
    this.createdAt,
    required this.isRead,
    this.conversationId = '',
    this.targetId = '',
    this.route = '',
    this.eventKey = '',
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    final resolvedBody = (map['body'] ?? map['message'] ?? '').toString();
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: (map['message'] ?? resolvedBody).toString(),
      body: resolvedBody,
      type: map['type'] ?? '',
      createdAt: map['createdAt'],
      isRead: map['isRead'] ?? false,
      conversationId: map['conversationId'] ?? '',
      targetId: map['targetId'] ?? '',
      route: (map['route'] ?? '').toString(),
      eventKey: (map['eventKey'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt,
      'isRead': isRead,
      'conversationId': conversationId,
      'targetId': targetId,
      if (route.isNotEmpty) 'route': route,
      if (eventKey.isNotEmpty) 'eventKey': eventKey,
    };
  }
}
