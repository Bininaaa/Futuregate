import 'package:flutter/material.dart';
import '../models/saved_opportunity_model.dart';
import '../services/saved_opportunity_service.dart';

class SavedOpportunityProvider extends ChangeNotifier {
  final SavedOpportunityService _service = SavedOpportunityService();

  List<SavedOpportunityModel> _savedOpportunities = [];
  bool _isLoading = false;

  List<SavedOpportunityModel> get savedOpportunities => _savedOpportunities;
  bool get isLoading => _isLoading;

  Future<void> fetchSavedOpportunities(String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _savedOpportunities = await _service.getSavedOpportunities(studentId);
    } catch (e) {
      debugPrint('fetchSavedOpportunities error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveOpportunity({
    required String studentId,
    required String opportunityId,
    required String title,
    required String companyName,
    required String type,
    required String location,
    required String deadline,
  }) async {
    try {
      await _service.saveOpportunity(
        studentId: studentId,
        opportunityId: opportunityId,
        title: title,
        companyName: companyName,
        type: type,
        location: location,
        deadline: deadline,
      );

      await fetchSavedOpportunities(studentId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> unsaveOpportunity(String id, String studentId) async {
    try {
      await _service.unsaveOpportunity(id);
      _savedOpportunities.removeWhere((s) => s.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
