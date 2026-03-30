import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scholarship_model.dart';

class ScholarshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ScholarshipModel>> getAllScholarships() async {
    final snapshot = await _firestore.collection('scholarships').get();

    return snapshot.docs
        .map((doc) => ScholarshipModel.fromMap(doc.data()))
        .toList();
  }

  Future<ScholarshipModel?> getScholarshipById(String id) async {
    final doc = await _firestore.collection('scholarships').doc(id).get();

    if (!doc.exists) return null;

    return ScholarshipModel.fromMap(doc.data()!);
  }
}