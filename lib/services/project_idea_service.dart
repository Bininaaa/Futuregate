import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/project_idea_model.dart';
import '../models/saved_idea_model.dart';
import 'worker_api_service.dart';

enum ProjectIdeaInteractionType { interest, save }

extension on ProjectIdeaInteractionType {
  String get storageKey {
    switch (this) {
      case ProjectIdeaInteractionType.interest:
        return 'interest';
      case ProjectIdeaInteractionType.save:
        return 'save';
    }
  }
}

class ProjectIdeaEngagementSnapshot {
  final Map<String, int> interestedByIdeaId;
  final Set<String> savedIdeaIds;
  final Set<String> joinedIdeaIds;

  const ProjectIdeaEngagementSnapshot({
    this.interestedByIdeaId = const <String, int>{},
    this.savedIdeaIds = const <String>{},
    this.joinedIdeaIds = const <String>{},
  });

  factory ProjectIdeaEngagementSnapshot.fromMap(Map<String, dynamic> map) {
    Map<String, int> readCounts(Object? value) {
      final result = <String, int>{};
      for (final entry in _stringDynamicMap(value).entries) {
        final key = entry.key.trim();
        if (key.isEmpty) {
          continue;
        }
        result[key] = _parseWorkerInt(entry.value);
      }
      return result;
    }

    return ProjectIdeaEngagementSnapshot(
      interestedByIdeaId: readCounts(map['interestedByIdeaId']),
      savedIdeaIds: _parseWorkerIdSet(map['savedIdeaIds']),
      joinedIdeaIds: _parseWorkerIdSet(map['joinedIdeaIds']),
    );
  }

  ProjectIdeaEngagementSnapshot merge(ProjectIdeaEngagementSnapshot other) {
    final mergedInterested = <String, int>{...interestedByIdeaId};
    for (final entry in other.interestedByIdeaId.entries) {
      mergedInterested[entry.key] =
          (mergedInterested[entry.key] ?? 0) + entry.value;
    }

    return ProjectIdeaEngagementSnapshot(
      interestedByIdeaId: mergedInterested,
      savedIdeaIds: <String>{...savedIdeaIds, ...other.savedIdeaIds},
      joinedIdeaIds: <String>{...joinedIdeaIds, ...other.joinedIdeaIds},
    );
  }
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
          .where((doc) => doc.data()['isHidden'] != true)
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
          .where((doc) => doc.data()['isHidden'] != true)
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
    String originalLanguage = '',
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
        'originalLanguage': originalLanguage,
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
    String originalLanguage = '',
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
    try {
      await _ideasCollection.doc(id).update(<String, dynamic>{
        'title': title,
        'description': description,
        'domain': domain,
        'level': level,
        'tools': tools,
        'originalLanguage': originalLanguage,
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
    } on FirebaseException catch (error) {
      if (_isPermissionDeniedError(error)) {
        throw Exception(
          'Idea editing is temporarily unavailable until the latest Firestore permissions are live.',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteProjectIdea(String id) async {
    await _ideasCollection.doc(id).delete();
  }

  Future<List<SavedIdeaModel>> getSavedIdeas(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <SavedIdeaModel>[];
    }

    final ideasById = <String, ProjectIdeaModel>{};
    final readableIdeas = <ProjectIdeaModel>[
      ...await getApprovedProjectIdeas(),
      ...await getProjectIdeasByStudent(normalizedUserId),
    ];
    for (final idea in readableIdeas) {
      ideasById[idea.id] = idea;
    }

    final readableIdeaIds = ideasById.keys.toList(growable: false);
    if (readableIdeaIds.isEmpty) {
      return const <SavedIdeaModel>[];
    }

    final interactions = await _getSavedIdeaInteractions(
      userId: normalizedUserId,
      readableIdeaIds: readableIdeaIds,
    );

    final results = <SavedIdeaModel>[];
    for (final interaction in interactions) {
      final ideaId = interaction.ideaId;
      final idea = ideasById[ideaId];
      if (idea == null) {
        continue;
      }

      results.add(
        SavedIdeaModel(
          id: interaction.id,
          ideaId: ideaId,
          userId: normalizedUserId,
          idea: idea.copyWith(isSavedByCurrentUser: true),
          savedAt: interaction.createdAt,
        ),
      );
    }

    return results;
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

    final workerSnapshot = await _getEngagementFromWorker(normalizedIdeaIds);
    if (workerSnapshot != null) {
      return workerSnapshot;
    }

    return _getEngagementFromFirestore(
      ideaIds: normalizedIdeaIds,
      currentUserId: currentUserId,
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

    final handledByWorker = await _setInteractionViaWorker(
      ideaId: normalizedIdeaId,
      type: type,
      enabled: enabled,
    );
    if (handledByWorker) {
      return;
    }

    await _setInteractionViaFirestore(
      ideaId: normalizedIdeaId,
      userId: normalizedUserId,
      type: type,
      enabled: enabled,
    );
  }

  Future<List<_SavedIdeaInteractionRecord>> _getSavedIdeaInteractions({
    required String userId,
    required List<String> readableIdeaIds,
  }) async {
    final workerInteractions = await _getSavedIdeaInteractionsFromWorker();
    if (workerInteractions != null) {
      return workerInteractions;
    }

    return _getSavedIdeaInteractionsFromFirestore(
      userId: userId,
      readableIdeaIds: readableIdeaIds,
    );
  }

  Future<List<_SavedIdeaInteractionRecord>?>
  _getSavedIdeaInteractionsFromWorker() async {
    try {
      final payload = await _workerApi.get('/api/project-ideas/saved');
      final rawItems = payload['savedItems'];
      if (rawItems is! List) {
        return const <_SavedIdeaInteractionRecord>[];
      }

      final items = <_SavedIdeaInteractionRecord>[];
      for (final item in rawItems) {
        final data = _stringDynamicMap(item);
        if (data.isEmpty) {
          continue;
        }
        items.add(_SavedIdeaInteractionRecord.fromMap(data));
      }

      items.sort((first, second) {
        final firstTime = first.createdAt?.millisecondsSinceEpoch ?? 0;
        final secondTime = second.createdAt?.millisecondsSinceEpoch ?? 0;
        return secondTime.compareTo(firstTime);
      });
      return items;
    } catch (error) {
      if (_isWorkerRouteUnavailable(error)) {
        debugPrint(
          'Project idea saved-items worker route unavailable. Falling back to Firestore reads: $error',
        );
        return null;
      }
      rethrow;
    }
  }

  Future<List<_SavedIdeaInteractionRecord>>
  _getSavedIdeaInteractionsFromFirestore({
    required String userId,
    required List<String> readableIdeaIds,
  }) async {
    final interactionDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final chunk in _chunkIds(readableIdeaIds)) {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _interactionCollection
            .where('ideaId', whereIn: chunk)
            .get();
      } on FirebaseException catch (error) {
        if (_isPermissionDeniedError(error)) {
          debugPrint(
            'Saved project ideas read skipped because Firestore permissions are not live yet: $error',
          );
          return const <_SavedIdeaInteractionRecord>[];
        }
        rethrow;
      }

      interactionDocs.addAll(
        snapshot.docs.where((doc) {
          final data = doc.data();
          return (data['userId'] ?? '').toString().trim() == userId &&
              (data['type'] ?? '').toString().trim().toLowerCase() ==
                  ProjectIdeaInteractionType.save.storageKey;
        }),
      );
    }

    interactionDocs.sort((first, second) {
      final firstTime =
          (first.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      final secondTime =
          (second.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      return secondTime.compareTo(firstTime);
    });

    return interactionDocs
        .map(
          (interaction) => _SavedIdeaInteractionRecord(
            id: interaction.id,
            ideaId: (interaction.data()['ideaId'] ?? '').toString().trim(),
            createdAt: interaction.data()['createdAt'] as Timestamp?,
          ),
        )
        .where((interaction) => interaction.ideaId.isNotEmpty)
        .toList(growable: false);
  }

  Future<ProjectIdeaEngagementSnapshot?> _getEngagementFromWorker(
    List<String> ideaIds,
  ) async {
    try {
      var snapshot = const ProjectIdeaEngagementSnapshot();
      for (final chunk in _chunkIds(ideaIds)) {
        final query = Uri(
          queryParameters: <String, String>{'ideaIds': chunk.join(',')},
        ).query;
        final payload = await _workerApi.get(
          '/api/project-ideas/engagement?$query',
        );
        snapshot = snapshot.merge(
          ProjectIdeaEngagementSnapshot.fromMap(payload),
        );
      }
      return snapshot;
    } catch (error) {
      if (_isWorkerRouteUnavailable(error)) {
        debugPrint(
          'Project idea engagement worker route unavailable. Falling back to Firestore reads: $error',
        );
        return null;
      }
      rethrow;
    }
  }

  Future<ProjectIdeaEngagementSnapshot> _getEngagementFromFirestore({
    required List<String> ideaIds,
    required String currentUserId,
  }) async {
    final interested = <String, int>{};
    final saved = <String>{};
    final joined = <String>{};

    for (final chunk in _chunkIds(ideaIds)) {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _interactionCollection
            .where('ideaId', whereIn: chunk)
            .get();
      } on FirebaseException catch (error) {
        if (_isPermissionDeniedError(error)) {
          debugPrint(
            'Project idea engagement read skipped because Firestore permissions are not live yet: $error',
          );
          return const ProjectIdeaEngagementSnapshot();
        }
        rethrow;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ideaId = (data['ideaId'] ?? '').toString().trim();
        final userId = (data['userId'] ?? '').toString().trim();
        final type = (data['type'] ?? '').toString().trim().toLowerCase();
        if (ideaId.isEmpty) {
          continue;
        }

        switch (type) {
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
      interestedByIdeaId: interested,
      savedIdeaIds: saved,
      joinedIdeaIds: joined,
    );
  }

  Future<bool> _setInteractionViaWorker({
    required String ideaId,
    required ProjectIdeaInteractionType type,
    required bool enabled,
  }) async {
    try {
      await _workerApi.post(
        '/api/project-ideas/interactions',
        body: <String, dynamic>{
          'ideaId': ideaId,
          'type': type.storageKey,
          'enabled': enabled,
        },
      );
      return true;
    } catch (error) {
      if (_isWorkerRouteUnavailable(error)) {
        debugPrint(
          'Project idea interaction worker route unavailable. Falling back to Firestore write: $error',
        );
        return false;
      }
      rethrow;
    }
  }

  Future<void> _setInteractionViaFirestore({
    required String ideaId,
    required String userId,
    required ProjectIdeaInteractionType type,
    required bool enabled,
  }) async {
    final docId = '${type.storageKey}_${userId}_$ideaId';
    final docRef = _interactionCollection.doc(docId);

    try {
      if (enabled) {
        await docRef.set(<String, dynamic>{
          'id': docId,
          'ideaId': ideaId,
          'userId': userId,
          'type': type.storageKey,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      await docRef.delete();
    } on FirebaseException catch (error) {
      if (_isPermissionDeniedError(error)) {
        throw Exception(
          'Idea engagement is temporarily unavailable until the latest Firestore permissions are live.',
        );
      }
      rethrow;
    }
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

  bool _isPermissionDeniedError(Object error) {
    return error is FirebaseException && error.code == 'permission-denied' ||
        error.toString().contains('[cloud_firestore/permission-denied]');
  }

  bool _isWorkerRouteUnavailable(Object error) {
    final message = error.toString().trim().toLowerCase();
    return message == 'exception: not found' ||
        message.endsWith('request failed with status 404');
  }
}

class _SavedIdeaInteractionRecord {
  final String id;
  final String ideaId;
  final Timestamp? createdAt;

  const _SavedIdeaInteractionRecord({
    required this.id,
    required this.ideaId,
    this.createdAt,
  });

  factory _SavedIdeaInteractionRecord.fromMap(Map<String, dynamic> map) {
    return _SavedIdeaInteractionRecord(
      id: (map['id'] ?? '').toString().trim(),
      ideaId: (map['ideaId'] ?? '').toString().trim(),
      createdAt: _parseWorkerTimestamp(map['createdAt']),
    );
  }
}

Map<String, dynamic> _stringDynamicMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
  }
  return const <String, dynamic>{};
}

Set<String> _parseWorkerIdSet(Object? value) {
  if (value is! Iterable) {
    return const <String>{};
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet();
}

int _parseWorkerInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Timestamp? _parseWorkerTimestamp(Object? value) {
  if (value is Timestamp) {
    return value;
  }
  if (value is int) {
    return Timestamp.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return Timestamp.fromMillisecondsSinceEpoch(value.toInt());
  }

  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  final parsedDate = DateTime.tryParse(normalized);
  if (parsedDate == null) {
    return null;
  }

  return Timestamp.fromDate(parsedDate);
}
