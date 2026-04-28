import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityModel {
  final String id;
  final String type;
  final String action;
  final String source;
  final String relatedId;
  final String relatedCollection;
  final String title;
  final String description;
  final String actorId;
  final String actorName;
  final String status;
  final Timestamp? createdAt;

  const AdminActivityModel({
    required this.id,
    required this.type,
    this.action = '',
    this.source = '',
    required this.relatedId,
    required this.relatedCollection,
    required this.title,
    required this.description,
    this.actorId = '',
    this.actorName = '',
    this.status = '',
    this.createdAt,
  });

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return type.toLowerCase().contains(normalizedQuery) ||
        title.toLowerCase().contains(normalizedQuery) ||
        description.toLowerCase().contains(normalizedQuery) ||
        action.toLowerCase().contains(normalizedQuery) ||
        actorName.toLowerCase().contains(normalizedQuery) ||
        status.toLowerCase().contains(normalizedQuery);
  }

  factory AdminActivityModel.fromEventDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final type = (data['type'] ?? data['targetType'] ?? 'activity')
        .toString()
        .trim();
    final targetId = (data['targetId'] ?? data['relatedId'] ?? '')
        .toString()
        .trim();
    final targetCollection =
        (data['targetCollection'] ?? data['relatedCollection'] ?? '')
            .toString()
            .trim();

    return AdminActivityModel(
      id: 'event_${doc.id}',
      type: type.isNotEmpty ? type : 'activity',
      action: (data['action'] ?? '').toString(),
      source: 'adminActivityEvents',
      relatedId: targetId,
      relatedCollection: targetCollection,
      title: (data['title'] ?? 'Admin activity').toString(),
      description: (data['description'] ?? '').toString(),
      actorId: (data['actorId'] ?? '').toString(),
      actorName: (data['actorName'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

class AdminActivityBatch {
  final List<AdminActivityModel> activities;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const AdminActivityBatch({
    required this.activities,
    required this.lastDocument,
    required this.hasMore,
  });
}
