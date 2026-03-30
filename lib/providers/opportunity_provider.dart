import 'package:flutter/material.dart';
import '../models/opportunity_model.dart';
import '../services/opportunity_service.dart';

class OpportunityProvider extends ChangeNotifier {
  final OpportunityService _service = OpportunityService();

  List<OpportunityModel> _opportunities = [];
  List<OpportunityModel> _featuredOpportunities = [];
  bool _isLoading = false;
  bool _isFeaturedLoading = false;

  List<OpportunityModel> get opportunities => _opportunities;
  List<OpportunityModel> get featuredOpportunities => _featuredOpportunities;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;

  Future<void> fetchOpportunities() async {
    try {
      _isLoading = true;
      notifyListeners();

      _opportunities = await _service.getAllOpportunities();
    } catch (e) {
      debugPrint('fetchOpportunities error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedOpportunities() async {
    try {
      _isFeaturedLoading = true;
      notifyListeners();

      _featuredOpportunities = await _service.getFeaturedOpportunities();
    } catch (e) {
      debugPrint('fetchFeaturedOpportunities error: $e');
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }
}
