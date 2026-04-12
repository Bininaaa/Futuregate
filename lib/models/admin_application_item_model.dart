import 'package:cloud_firestore/cloud_firestore.dart';

import 'application_model.dart';

class AdminApplicationItemModel {
  final ApplicationModel application;
  final String opportunityTitle;
  final String companyName;
  final String companyId;
  final String opportunityCreatedBy;
  final String opportunityCreatedByRole;
  final Timestamp? opportunityCreatedAt;

  const AdminApplicationItemModel({
    required this.application,
    this.opportunityTitle = '',
    this.companyName = '',
    this.companyId = '',
    this.opportunityCreatedBy = '',
    this.opportunityCreatedByRole = '',
    this.opportunityCreatedAt,
  });

  String get id => application.id;
  String get studentName => application.studentName;
  String get status => application.status;
  String get opportunityId => application.opportunityId;
  Timestamp? get appliedAt => application.appliedAt;
  bool get isAdminPostedOpportunity =>
      opportunityCreatedByRole.trim().toLowerCase() == 'admin';

  bool canBeManagedByAdmin(String adminId) {
    final normalizedAdminId = adminId.trim();
    return normalizedAdminId.isNotEmpty &&
        isAdminPostedOpportunity &&
        companyId.trim() == normalizedAdminId;
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return application.studentName.toLowerCase().contains(normalizedQuery) ||
        opportunityTitle.toLowerCase().contains(normalizedQuery) ||
        companyName.toLowerCase().contains(normalizedQuery) ||
        application.status.toLowerCase().contains(normalizedQuery) ||
        application.id.toLowerCase().contains(normalizedQuery);
  }
}
