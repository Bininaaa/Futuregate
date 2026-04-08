import 'package:flutter/material.dart';
import '../models/scholarship_model.dart';
import '../services/scholarship_service.dart';

class ScholarshipProvider extends ChangeNotifier {
  final ScholarshipService _service = ScholarshipService();

  List<ScholarshipModel> _scholarships = [];
  bool _isLoading = false;

  List<ScholarshipModel> get scholarships => _scholarships;
  bool get isLoading => _isLoading;

  Future<void> fetchScholarships() async {
    try {
      _isLoading = true;
      notifyListeners();

      _scholarships = await _service.getAllScholarships();
    } catch (e) {
      debugPrint('fetchScholarships error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
