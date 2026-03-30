import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_idea_model.dart';
import 'worker_api_service.dart';

class ProjectIdeaService {
  final WorkerApiService _workerApi = WorkerApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProjectIdeaModel>> getApprovedProjectIdeas() async {
    // Single-field equality filter only — no orderBy to avoid requiring
    // a composite index that may not exist. Sort client-side instead.
    final snapshot = await _firestore
        .collection('projectIdeas')
        .where('status', isEqualTo: 'approved')
        .get();

    final list = snapshot.docs
        .map((doc) => ProjectIdeaModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    list.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return list;
  }

  Future<List<ProjectIdeaModel>> getAllProjectIdeas() async {
    final snapshot = await _firestore
        .collection('projectIdeas')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProjectIdeaModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<ProjectIdeaModel>> getProjectIdeasByStudent(
    String studentId,
  ) async {
    // Single-field equality filter only — no orderBy to avoid requiring
    // a composite index that may not exist. Sort client-side instead.
    final snapshot = await _firestore
        .collection('projectIdeas')
        .where('submittedBy', isEqualTo: studentId)
        .get();

    final list = snapshot.docs
        .map((doc) => ProjectIdeaModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    list.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return list;
  }

  Future<void> submitProjectIdea({
    required String title,
    required String description,
    required String domain,
    required String level,
    required String tools,
  }) async {
    await _workerApi.post(
      '/api/project-ideas/submit',
      body: {
        'title': title,
        'description': description,
        'domain': domain,
        'level': level,
        'tools': tools,
      },
    );
  }

  Future<void> updateProjectIdea({
    required String id,
    required String title,
    required String description,
    required String domain,
    required String level,
    required String tools,
  }) async {
    await _firestore.collection('projectIdeas').doc(id).update({
      'title': title,
      'description': description,
      'domain': domain,
      'level': level,
      'tools': tools,
    });
  }

  Future<void> deleteProjectIdea(String id) async {
    await _firestore.collection('projectIdeas').doc(id).delete();
  }
}
