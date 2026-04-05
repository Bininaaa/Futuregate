import 'package:flutter/material.dart';

import '../models/saved_scholarship_model.dart';
import '../services/saved_scholarship_service.dart';

class SavedScholarshipProvider extends ChangeNotifier {
  final SavedScholarshipService _service = SavedScholarshipService();

  List<SavedScholarshipModel> _savedScholarships = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<SavedScholarshipModel> get savedScholarships => _savedScholarships;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> fetchSavedScholarships(String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _savedScholarships = await _service.getSavedScholarships(studentId);
    } catch (e) {
      debugPrint('fetchSavedScholarships error: $e');
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveScholarship({
    required String studentId,
    required String scholarshipId,
    required String title,
    required String provider,
    required String deadline,
    required String location,
    required String fundingType,
    required String level,
  }) async {
    try {
      await _service.saveScholarship(
        studentId: studentId,
        scholarshipId: scholarshipId,
        title: title,
        provider: provider,
        deadline: deadline,
        location: location,
        fundingType: fundingType,
        level: level,
      );
      await fetchSavedScholarships(studentId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> unsaveScholarship(String id, String studentId) async {
    try {
      await _service.unsaveScholarship(id);
      _savedScholarships.removeWhere((item) => item.id == id);
      _hasLoaded = true;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
