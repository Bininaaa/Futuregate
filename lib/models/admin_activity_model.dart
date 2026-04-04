import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityModel {
  final String id;
  final String type;
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
        actorName.toLowerCase().contains(normalizedQuery) ||
        status.toLowerCase().contains(normalizedQuery);
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
