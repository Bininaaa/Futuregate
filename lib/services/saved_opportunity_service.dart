import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';
import '../models/saved_opportunity_model.dart';

class SavedOpportunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SavedOpportunityModel>> getSavedOpportunities(
    String studentId,
  ) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('savedOpportunities')
          .where('studentId', isEqualTo: studentId)
          .orderBy('savedAt', descending: true)
          .get();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('index') || errStr.contains('requires an index')) {
        snapshot = await _firestore
            .collection('savedOpportunities')
            .where('studentId', isEqualTo: studentId)
            .get();
      } else {
        rethrow;
      }
    }

    final results = snapshot.docs
        .map((doc) => SavedOpportunityModel.fromMap(doc.data()))
        .toList();

    final visibleOpportunityIds = await _resolveVisibleOpportunityIds(
      results.map((item) => item.opportunityId).toSet(),
    );

    results.removeWhere(
      (item) => !visibleOpportunityIds.contains(item.opportunityId),
    );

    if (results.length > 1) {
      results.sort((a, b) {
        final aTime = a.savedAt;
        final bTime = b.savedAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    }

    return results;
  }

  Future<void> saveOpportunity({
    required String studentId,
    required String opportunityId,
    required String title,
    required String companyName,
    required String type,
    required String location,
    required String deadline,
    String fundingLabel = '',
  }) async {
    final existing = await _firestore
        .collection('savedOpportunities')
        .where('studentId', isEqualTo: studentId)
        .where('opportunityId', isEqualTo: opportunityId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Opportunity already saved');
    }

    final opportunityDoc = await _firestore
        .collection('opportunities')
        .doc(opportunityId)
        .get();
    if (!opportunityDoc.exists || opportunityDoc.data() == null) {
      throw Exception('This opportunity is no longer available');
    }

    final opportunity = OpportunityModel.fromMap({
      ...opportunityDoc.data()!,
      'id': opportunityDoc.id,
    });
    if (!opportunity.isVisibleToStudents()) {
      throw Exception('This opportunity is no longer available');
    }

    final docRef = _firestore.collection('savedOpportunities').doc();

    final data = {
      'id': docRef.id,
      'opportunityId': opportunityId,
      'studentId': studentId,
      'title': title,
      'companyName': companyName,
      'type': type,
      'location': location,
      'deadline': deadline,
      'fundingLabel': fundingLabel.trim(),
      'savedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);
  }

  Future<void> unsaveOpportunity(String id) async {
    await _firestore.collection('savedOpportunities').doc(id).delete();
  }

  Future<bool> isOpportunitySaved(
    String studentId,
    String opportunityId,
  ) async {
    final snapshot = await _firestore
        .collection('savedOpportunities')
        .where('studentId', isEqualTo: studentId)
        .where('opportunityId', isEqualTo: opportunityId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<Set<String>> _resolveVisibleOpportunityIds(
    Set<String> opportunityIds,
  ) async {
    final normalizedIds = opportunityIds
        .map((opportunityId) => opportunityId.trim())
        .where((opportunityId) => opportunityId.isNotEmpty)
        .toSet();

    if (normalizedIds.isEmpty) {
      return const <String>{};
    }

    final visibleIds = <String>{};
    final docs = await Future.wait(
      normalizedIds.map(_readOpportunityIfAllowed),
    );

    for (final doc in docs) {
      if (doc == null || !doc.exists || doc.data() == null) {
        continue;
      }

      final opportunity = OpportunityModel.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });
      if (!opportunity.isVisibleToStudents()) {
        continue;
      }

      visibleIds.add(doc.id);
    }

    return visibleIds;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _readOpportunityIfAllowed(
    String opportunityId,
  ) async {
    try {
      return await _firestore
          .collection('opportunities')
          .doc(opportunityId)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }
}
