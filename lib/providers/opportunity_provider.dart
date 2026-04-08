import 'package:flutter/material.dart';
import '../models/opportunity_model.dart';
import '../services/opportunity_service.dart';

class OpportunityProvider extends ChangeNotifier {
  final OpportunityService _service = OpportunityService();

  List<OpportunityModel> _opportunities = [];
  List<OpportunityModel> _featuredOpportunities = [];
  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  Future<void>? _catalogLoadFuture;

  List<OpportunityModel> get opportunities => _opportunities;
  List<OpportunityModel> get featuredOpportunities => _featuredOpportunities;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;

  Future<void> fetchOpportunities() async {
    final existingRequest = _catalogLoadFuture;
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _loadOpportunityCatalog();
    _catalogLoadFuture = request;

    try {
      await request;
    } finally {
      if (identical(_catalogLoadFuture, request)) {
        _catalogLoadFuture = null;
      }
    }
  }

  Future<void> fetchFeaturedOpportunities() async {
    if (_featuredOpportunities.isNotEmpty || _opportunities.isNotEmpty) {
      _featuredOpportunities = _deriveFeatured(_opportunities);
      notifyListeners();
      return;
    }

    await fetchOpportunities();
  }

  Future<void> _loadOpportunityCatalog() async {
    try {
      _isLoading = true;
      _isFeaturedLoading = true;
      notifyListeners();

      final opportunities = await _service.getAllOpportunities();
      _opportunities = opportunities;
      _featuredOpportunities = _deriveFeatured(opportunities);
    } catch (e) {
      debugPrint('fetchOpportunities error: $e');
    } finally {
      _isLoading = false;
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  List<OpportunityModel> _deriveFeatured(List<OpportunityModel> opportunities) {
    return opportunities
        .where((opportunity) => opportunity.isFeatured)
        .toList();
  }
}
