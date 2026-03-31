import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/training_model.dart';
import 'worker_api_service.dart';

class TrainingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkerApiService _workerApi = WorkerApiService();

  CollectionReference<Map<String, dynamic>> get _trainingsCollection =>
      _firestore.collection('trainings');

  CollectionReference<Map<String, dynamic>> _savedTrainingsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_trainings');
  }

  // ── Worker HTTP helper ──────────────────────────────────────────────

  Future<Map<String, dynamic>> _workerRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    switch (method) {
      case 'POST':
        return _workerApi.post(path, body: body);
      case 'DELETE':
        return _workerApi.delete(path);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // ── Reads (still via Firestore client SDK) ──────────────────────────

  Future<List<TrainingModel>> getAllTrainings() async {
    final snapshot = await _trainingsCollection.get();

    final items = snapshot.docs
        .map(
          (doc) => TrainingModel.fromMap({
            ...doc.data(),
            'id': (doc.data()['id'] ?? doc.id).toString(),
          }),
        )
        .toList();

    items.sort((a, b) {
      final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });

    return items;
  }

  Future<TrainingModel?> getTrainingById(String id) async {
    final doc = await _trainingsCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return TrainingModel.fromMap({
      ...doc.data()!,
      'id': (doc.data()!['id'] ?? doc.id).toString(),
    });
  }

  // ── Admin writes (via Cloudflare Worker) ────────────────────────────

  Future<void> importGoogleBook({
    required TrainingModel book,
    required String adminId,
    required String domain,
    required String level,
  }) async {
    await _workerRequest(
      'POST',
      '/api/trainings/import/google-book',
      body: {
        'selectedBook': {
          'googleBookId': book.id,
          'title': book.title,
          'description': book.description,
          'authors': book.authors,
          'provider': book.provider,
          'thumbnail': book.thumbnail,
          'language': book.language,
          'previewLink': book.previewLink,
          'infoLink': book.link,
          'pageCount': _parsePageCount(book.duration),
        },
        'domain': domain,
        'level': level,
      },
    );
  }

  Future<void> importYoutubeVideo({
    required TrainingModel video,
    required String adminId,
    required String domain,
    required String level,
  }) async {
    await _workerRequest(
      'POST',
      '/api/trainings/import/youtube-video',
      body: {
        'selectedVideo': {
          'youtubeVideoId': video.id.trim(),
          'title': video.title,
          'description': video.description,
          'provider': video.provider,
          'thumbnail': video.thumbnail,
          'link': video.link,
        },
        'domain': domain,
        'level': level,
      },
    );
  }

  Future<void> updateFeaturedStatus({
    required String trainingId,
    required bool isFeatured,
  }) async {
    await _workerRequest(
      'POST',
      '/api/trainings/${Uri.encodeComponent(trainingId)}/featured',
      body: {'isFeatured': isFeatured},
    );
  }

  Future<void> deleteTraining(String trainingId) async {
    await _workerRequest(
      'DELETE',
      '/api/trainings/${Uri.encodeComponent(trainingId)}',
    );
  }

  // ── User save/unsave (still via Firestore client SDK) ───────────────

  Future<void> saveTraining({
    required String userId,
    required TrainingModel training,
  }) async {
    await _savedTrainingsCollection(userId).doc(training.id).set({
      'id': training.id,
      'trainingId': training.id,
      'title': training.title,
      'description': training.description,
      'provider': training.provider,
      'providerLogo': training.providerLogo,
      'duration': training.duration,
      'level': training.level,
      'link': training.link,
      'type': training.type,
      'source': training.source,
      'authors': training.authors,
      'thumbnail': training.thumbnail,
      'domain': training.domain,
      'language': training.language,
      'previewLink': training.previewLink,
      'isApproved': training.isApproved,
      'isFeatured': training.isFeatured,
      'rating': training.rating,
      'learnerCount': training.learnerCount,
      'learnerCountLabel': training.learnerCountLabel,
      'isFree': training.isFree,
      'hasCertificate': training.hasCertificate,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unsaveTraining({
    required String userId,
    required String trainingId,
  }) async {
    await _savedTrainingsCollection(userId).doc(trainingId).delete();
  }

  Future<bool> isTrainingSaved({
    required String userId,
    required String trainingId,
  }) async {
    final doc = await _savedTrainingsCollection(userId).doc(trainingId).get();
    return doc.exists;
  }

  Future<List<TrainingModel>> getSavedTrainings(String userId) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _savedTrainingsCollection(
        userId,
      ).orderBy('savedAt', descending: true).get();
    } catch (_) {
      snapshot = await _savedTrainingsCollection(userId).get();
    }

    return snapshot.docs
        .map(
          (doc) => TrainingModel.fromMap({
            ...doc.data(),
            'id': (doc.data()['id'] ?? doc.id).toString(),
          }),
        )
        .toList();
  }

  // ── Internal helpers ────────────────────────────────────────────────

  int? _parsePageCount(String duration) {
    final match = RegExp(r'(\d+)\s*pages?').firstMatch(duration);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
