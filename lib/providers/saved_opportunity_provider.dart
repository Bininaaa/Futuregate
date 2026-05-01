import 'package:flutter/material.dart';
import '../models/saved_opportunity_model.dart';
import '../services/saved_opportunity_service.dart';

export '../services/saved_opportunity_service.dart'
    show SavedLimitReachedException;

class SavedOpportunityProvider extends ChangeNotifier {
  final SavedOpportunityService _service = SavedOpportunityService();

  List<SavedOpportunityModel> _savedOpportunities = [];
  final Set<String> _savingOpportunityIds = <String>{};
  bool _isLoading = false;

  List<SavedOpportunityModel> get savedOpportunities => _savedOpportunities;
  bool get isSaving => _savingOpportunityIds.isNotEmpty;
  bool get isLoading => _isLoading || isSaving;
  bool isSavingOpportunity(String opportunityId) =>
      _savingOpportunityIds.contains(opportunityId);

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
    String fundingLabel = '',
  }) async {
    if (_savingOpportunityIds.isNotEmpty) {
      return 'Please wait for the current save to finish.';
    }

    _savingOpportunityIds.add(opportunityId);
    notifyListeners();

    try {
      // Re-throw SavedLimitReachedException so callers can show upgrade modal.
      await _service.saveOpportunity(
        studentId: studentId,
        opportunityId: opportunityId,
        title: title,
        companyName: companyName,
        type: type,
        location: location,
        deadline: deadline,
        fundingLabel: fundingLabel,
      );

      await fetchSavedOpportunities(studentId);
      return null;
    } finally {
      _savingOpportunityIds.remove(opportunityId);
      notifyListeners();
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

  void clearSavedOpportunities() {
    _savedOpportunities = <SavedOpportunityModel>[];
    _savingOpportunityIds.clear();
    _isLoading = false;
    notifyListeners();
  }
}
