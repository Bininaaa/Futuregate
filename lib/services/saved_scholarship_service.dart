import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saved_scholarship_model.dart';

class SavedScholarshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SavedScholarshipModel>> getSavedScholarships(
    String studentId,
  ) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('savedScholarships')
          .where('studentId', isEqualTo: studentId)
          .orderBy('savedAt', descending: true)
          .get();
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('index') ||
          errorText.contains('requires an index')) {
        snapshot = await _firestore
            .collection('savedScholarships')
            .where('studentId', isEqualTo: studentId)
            .get();
      } else {
        rethrow;
      }
    }

    final results = snapshot.docs
        .map((doc) => SavedScholarshipModel.fromMap(doc.data()))
        .toList();

    final visibleScholarshipIds = await _resolveVisibleScholarshipIds(
      results.map((item) => item.scholarshipId).toSet(),
    );

    results.removeWhere(
      (item) => !visibleScholarshipIds.contains(item.scholarshipId),
    );

    if (results.length > 1) {
      results.sort((a, b) {
        final aTime = a.savedAt;
        final bTime = b.savedAt;
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
    }

    return results;
  }

  Future<void> saveScholarship({
    required String studentId,
    required String scholarshipId,
    required String title,
    required String provider,
    required String deadline,
    required String location,
    required String fundingType,
    required String level,
  }) async {
    final existing = await _firestore
        .collection('savedScholarships')
        .where('studentId', isEqualTo: studentId)
        .where('scholarshipId', isEqualTo: scholarshipId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Scholarship already saved');
    }

    final docRef = _firestore.collection('savedScholarships').doc();
    await docRef.set({
      'id': docRef.id,
      'scholarshipId': scholarshipId,
      'studentId': studentId,
      'title': title,
      'provider': provider,
      'deadline': deadline,
      'location': location,
      'fundingType': fundingType,
      'level': level,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsaveScholarship(String id) async {
    await _firestore.collection('savedScholarships').doc(id).delete();
  }

  Future<bool> isScholarshipSaved(
    String studentId,
    String scholarshipId,
  ) async {
    final snapshot = await _firestore
        .collection('savedScholarships')
        .where('studentId', isEqualTo: studentId)
        .where('scholarshipId', isEqualTo: scholarshipId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<Set<String>> _resolveVisibleScholarshipIds(
    Set<String> scholarshipIds,
  ) async {
    final normalizedIds = scholarshipIds
        .map((scholarshipId) => scholarshipId.trim())
        .where((scholarshipId) => scholarshipId.isNotEmpty)
        .toSet();

    if (normalizedIds.isEmpty) {
      return const <String>{};
    }

    final visibleIds = <String>{};
    final docs = await Future.wait(
      normalizedIds.map(
        (scholarshipId) =>
            _firestore.collection('scholarships').doc(scholarshipId).get(),
      ),
    );

    for (final doc in docs) {
      if (!doc.exists || doc.data() == null) {
        continue;
      }

      if (doc.data()!['isHidden'] == true) {
        continue;
      }

      visibleIds.add(doc.id);
    }

    return visibleIds;
  }
}
