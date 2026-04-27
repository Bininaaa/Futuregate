import 'package:flutter/material.dart';

class CompanyHomeNavigationRequest {
  final int tabIndex;
  final String applicationId;
  final String opportunityId;

  const CompanyHomeNavigationRequest({
    required this.tabIndex,
    this.applicationId = '',
    this.opportunityId = '',
  });
}

class CompanyHomeNavigation {
  CompanyHomeNavigation._();

  static const int dashboardTab = 0;
  static const int opportunitiesTab = 1;
  static const int applicationsTab = 2;
  static const int messagesTab = 3;
  static const int moreTab = 4;

  static final ValueNotifier<CompanyHomeNavigationRequest?> request =
      ValueNotifier<CompanyHomeNavigationRequest?>(null);

  static void switchToApplications(
    BuildContext context, {
    String applicationId = '',
    String opportunityId = '',
  }) {
    request.value = CompanyHomeNavigationRequest(
      tabIndex: applicationsTab,
      applicationId: applicationId,
      opportunityId: opportunityId,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
