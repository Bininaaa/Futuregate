import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_idea_model.dart';
import 'worker_api_service.dart';

enum ProjectIdeaInteractionType { spark, interest, save }

extension on ProjectIdeaInteractionType {
  String get storageKey {
    switch (this) {
      case ProjectIdeaInteractionType.spark:
        return 'spark';
      case ProjectIdeaInteractionType.interest:
        return 'interest';
      case ProjectIdeaInteractionType.save:
        return 'save';
    }
  }
}

class ProjectIdeaEngagementSnapshot {
  final Map<String, int> sparksByIdeaId;
  final Map<String, int> interestedByIdeaId;
  final Set<String> savedIdeaIds;
  final Set<String> sparkedIdeaIds;
  final Set<String> joinedIdeaIds;

  const ProjectIdeaEngagementSnapshot({
    this.sparksByIdeaId = const <String, int>{},
    this.interestedByIdeaId = const <String, int>{},
    this.savedIdeaIds = const <String>{},
    this.sparkedIdeaIds = const <String>{},
    this.joinedIdeaIds = const <String>{},
  });
}

class ProjectIdeaService {
  ProjectIdeaService({
    WorkerApiService? workerApi,
    FirebaseFirestore? firestore,
  }) : _workerApi = workerApi ?? WorkerApiService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final WorkerApiService _workerApi;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ideasCollection =>
      _firestore.collection('projectIdeas');

  CollectionReference<Map<String, dynamic>> get _interactionCollection =>
      _firestore.collection('projectIdeaInteractions');

  Future<List<ProjectIdeaModel>> getApprovedProjectIdeas() async {
    final snapshot = await _ideasCollection
        .where('status', isEqualTo: 'approved')
        .get();

    return _sortIdeas(
      snapshot.docs
          .map((doc) => ProjectIdeaModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  Future<List<ProjectIdeaModel>> getAllProjectIdeas() async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _ideasCollection
          .orderBy('createdAt', descending: true)
          .get();
    } catch (_) {
      snapshot = await _ideasCollection.get();
    }

    return _sortIdeas(
      snapshot.docs
          .map((doc) => ProjectIdeaModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  Future<List<ProjectIdeaModel>> getProjectIdeasByStudent(
    String studentId,
  ) async {
    if (studentId.trim().isEmpty) {
      return const <ProjectIdeaModel>[];
    }

    final snapshot = await _ideasCollection
        .where('submittedBy', isEqualTo: studentId)
        .get();

    return _sortIdeas(
      snapshot.docs
          .map((doc) => ProjectIdeaModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  Future<void> submitProjectIdea({
    required String title,
    required String description,
    required String domain,
    required String level,
    required String tools,
    String tagline = '',
    String shortDescription = '',
    String category = '',
    List<String> tags = const <String>[],
    String stage = '',
    List<String> skillsNeeded = const <String>[],
    List<String> teamNeeded = const <String>[],
    String targetAudience = '',
    String problemStatement = '',
    String solution = '',
    String resourcesNeeded = '',
    String benefits = '',
    String imageUrl = '',
    String attachmentUrl = '',
    bool isPublic = true,
  }) async {
    await _workerApi.post(
      '/api/project-ideas/submit',
      body: <String, dynamic>{
        'title': title,
        'description': description,
        'domain': domain,
        'level': level,
        'tools': tools,
        'tagline': tagline,
        'shortDescription': shortDescription,
        'category': category,
        'tags': tags,
        'stage': stage,
        'skillsNeeded': skillsNeeded,
        'teamNeeded': teamNeeded,
        'targetAudience': targetAudience,
        'problemStatement': problemStatement,
        'solution': solution,
        'resourcesNeeded': resourcesNeeded,
        'benefits': benefits,
        'imageUrl': imageUrl,
        'attachmentUrl': attachmentUrl,
        'isPublic': isPublic,
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
    String tagline = '',
    String shortDescription = '',
    String category = '',
    List<String> tags = const <String>[],
    String stage = '',
    List<String> skillsNeeded = const <String>[],
    List<String> teamNeeded = const <String>[],
    String targetAudience = '',
    String problemStatement = '',
    String solution = '',
    String resourcesNeeded = '',
    String benefits = '',
    String imageUrl = '',
    String attachmentUrl = '',
    bool isPublic = true,
  }) async {
    await _ideasCollection.doc(id).update(<String, dynamic>{
      'title': title,
      'description': description,
      'domain': domain,
      'level': level,
      'tools': tools,
      'tagline': tagline,
      'shortDescription': shortDescription,
      'category': category,
      'tags': tags,
      'stage': stage,
      'skillsNeeded': skillsNeeded,
      'teamNeeded': teamNeeded,
      'targetAudience': targetAudience,
      'problemStatement': problemStatement,
      'solution': solution,
      'resourcesNeeded': resourcesNeeded,
      'benefits': benefits,
      'imageUrl': imageUrl,
      'attachmentUrl': attachmentUrl,
      'isPublic': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProjectIdea(String id) async {
    await _ideasCollection.doc(id).delete();
  }

  Future<ProjectIdeaEngagementSnapshot> getEngagementForIdeas({
    required List<String> ideaIds,
    required String currentUserId,
  }) async {
    final normalizedIdeaIds = ideaIds
        .map((ideaId) => ideaId.trim())
        .where((ideaId) => ideaId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIdeaIds.isEmpty) {
      return const ProjectIdeaEngagementSnapshot();
    }

    final sparks = <String, int>{};
    final interested = <String, int>{};
    final saved = <String>{};
    final sparked = <String>{};
    final joined = <String>{};

    for (final chunk in _chunkIds(normalizedIdeaIds)) {
      final snapshot = await _interactionCollection
          .where('ideaId', whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ideaId = (data['ideaId'] ?? '').toString().trim();
        final userId = (data['userId'] ?? '').toString().trim();
        final type = (data['type'] ?? '').toString().trim().toLowerCase();
        if (ideaId.isEmpty) {
          continue;
        }

        switch (type) {
          case 'spark':
            sparks[ideaId] = (sparks[ideaId] ?? 0) + 1;
            if (userId == currentUserId) {
              sparked.add(ideaId);
            }
            break;
          case 'interest':
            interested[ideaId] = (interested[ideaId] ?? 0) + 1;
            if (userId == currentUserId) {
              joined.add(ideaId);
            }
            break;
          case 'save':
            if (userId == currentUserId) {
              saved.add(ideaId);
            }
            break;
        }
      }
    }

    return ProjectIdeaEngagementSnapshot(
      sparksByIdeaId: sparks,
      interestedByIdeaId: interested,
      savedIdeaIds: saved,
      sparkedIdeaIds: sparked,
      joinedIdeaIds: joined,
    );
  }

  Future<void> setInteraction({
    required String ideaId,
    required String userId,
    required ProjectIdeaInteractionType type,
    required bool enabled,
  }) async {
    final normalizedIdeaId = ideaId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedIdeaId.isEmpty || normalizedUserId.isEmpty) {
      return;
    }

    final docId = '${type.storageKey}_${normalizedUserId}_$normalizedIdeaId';
    final docRef = _interactionCollection.doc(docId);

    if (enabled) {
      await docRef.set(<String, dynamic>{
        'id': docId,
        'ideaId': normalizedIdeaId,
        'userId': normalizedUserId,
        'type': type.storageKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await docRef.delete();
  }

  List<List<String>> _chunkIds(List<String> ideaIds) {
    const int chunkSize = 10;
    final chunks = <List<String>>[];
    for (var i = 0; i < ideaIds.length; i += chunkSize) {
      chunks.add(
        ideaIds.sublist(
          i,
          i + chunkSize > ideaIds.length ? ideaIds.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  List<ProjectIdeaModel> _sortIdeas(List<ProjectIdeaModel> ideas) {
    ideas.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt;
      final bTime = b.updatedAt ?? b.createdAt;
      if (aTime == null && bTime == null) {
        return 0;
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return bTime.compareTo(aTime);
    });
    return ideas;
  }
}
