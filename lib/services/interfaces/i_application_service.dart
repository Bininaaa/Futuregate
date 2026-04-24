import '../../models/student_application_item_model.dart';
import '../application_service.dart';

abstract interface class IApplicationService {
  Future<int> getApplicationsCount(String studentId);

  Future<List<StudentApplicationItemModel>> getSubmittedApplications(
    String studentId, {
    bool onlyVisibleOpportunities = true,
  });

  Future<ApplicationEligibilityStatus> getEligibility({
    required String studentId,
    required String opportunityId,
  });

  Future<void> applyToOpportunity({
    required String studentId,
    required String studentName,
    required String opportunityId,
    required String cvId,
  });

  Future<void> withdrawApplication({
    required String studentId,
    required String opportunityId,
  });
}
