import 'package:cloud_firestore/cloud_firestore.dart';

import 'project_idea_model.dart';

class SavedIdeaModel {
  final String id;
  final String ideaId;
  final String userId;
  final ProjectIdeaModel idea;
  final Timestamp? savedAt;

  const SavedIdeaModel({
    required this.id,
    required this.ideaId,
    required this.userId,
    required this.idea,
    this.savedAt,
  });
}
