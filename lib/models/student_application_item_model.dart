import '../utils/opportunity_metadata.dart';
import 'application_model.dart';
import 'opportunity_model.dart';

class StudentApplicationItemModel {
  final ApplicationModel application;
  final OpportunityModel? opportunity;

  const StudentApplicationItemModel({
    required this.application,
    required this.opportunity,
  });

  String get id => application.id;
  String get opportunityId => application.opportunityId;
  String get status => application.status;

  String get title {
    final value = opportunity?.title.trim() ?? '';
    return value.isNotEmpty ? value : 'Opportunity unavailable';
  }

  String get companyName {
    final value = opportunity?.companyName.trim() ?? '';
    return value.isNotEmpty ? value : 'Company unavailable';
  }

  String get type => opportunity?.type ?? '';

  String get location {
    final value = opportunity?.location.trim() ?? '';
    return value.isNotEmpty ? value : 'Location not specified';
  }

  String get description => opportunity?.description.trim() ?? '';

  DateTime? get appliedAt => application.appliedAt?.toDate();

  DateTime? get deadline =>
      opportunity?.applicationDeadline ??
      OpportunityMetadata.parseDateTimeLike(opportunity?.deadline);

  bool get hasOpportunity => opportunity != null;
  bool get isUnavailable => opportunity == null || opportunity!.isHidden;
  bool get canOpenDetails => opportunity != null && !opportunity!.isHidden;

  bool get isOpen {
    final rawStatus = opportunity?.status.trim().toLowerCase() ?? '';
    return rawStatus == 'open';
  }
}
