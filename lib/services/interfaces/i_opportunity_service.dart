import '../../models/opportunity_model.dart';

abstract interface class IOpportunityService {
  Future<List<OpportunityModel>> getAllOpportunities();
  Future<OpportunityModel?> getOpportunityById(String id);
  Future<List<OpportunityModel>> getFeaturedOpportunities();
}
