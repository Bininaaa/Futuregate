import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scholarship_model.dart';

class ScholarshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ScholarshipModel>> getAllScholarships() async {
    final snapshot = await _firestore.collection('scholarships').get();

    return snapshot.docs
        .map((doc) => ScholarshipModel.fromMap({...doc.data(), 'id': doc.id}))
        .where((scholarship) => scholarship.isVisibleToStudents())
        .toList();
  }

  Future<ScholarshipModel?> getScholarshipById(String id) async {
    final doc = await _firestore.collection('scholarships').doc(id).get();

    if (!doc.exists) return null;

    final scholarship = ScholarshipModel.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });
    return scholarship.isVisibleToStudents() ? scholarship : null;
  }
}
