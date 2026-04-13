import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';

class OpportunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<OpportunityModel>> getAllOpportunities() async {
    final snapshot = await _firestore
        .collection('opportunities')
        .where('status', isEqualTo: 'open')
        .get();

    final opportunities = snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return OpportunityModel.fromMap(data);
        })
        .where((opportunity) => opportunity.isVisibleToStudents())
        .toList();

    opportunities.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
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

    return opportunities;
  }

  Future<OpportunityModel?> getOpportunityById(String id) async {
    final doc = await _firestore.collection('opportunities').doc(id).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    final opportunity = OpportunityModel.fromMap(data);
    return opportunity.isVisibleToStudents() ? opportunity : null;
  }

  Future<List<OpportunityModel>> getFeaturedOpportunities() async {
    final snapshot = await _firestore
        .collection('opportunities')
        .where('status', isEqualTo: 'open')
        .where('isFeatured', isEqualTo: true)
        .get();

    final opportunities = snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return OpportunityModel.fromMap(data);
        })
        .where((opportunity) => opportunity.isVisibleToStudents())
        .toList();

    opportunities.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return opportunities;
  }
}
