import 'package:flutter/material.dart';

import 'admin_content_center_screen.dart';

class AdminHomeNavigationRequest {
  final int tabIndex;
  final int contentTab;
  final String targetId;
  final String userRoleFilter;
  final String companyApprovalFilter;

  const AdminHomeNavigationRequest({
    required this.tabIndex,
    this.contentTab = AdminContentCenterScreen.projectIdeasTab,
    this.targetId = '',
    this.userRoleFilter = 'all',
    this.companyApprovalFilter = 'all',
  });
}

class AdminHomeNavigation {
  AdminHomeNavigation._();

  static const int dashboardTab = 0;
  static const int usersTab = 1;
  static const int contentTab = 2;
  static const int activityTab = 3;
  static const int settingsTab = 4;

  static final ValueNotifier<AdminHomeNavigationRequest?> request =
      ValueNotifier<AdminHomeNavigationRequest?>(null);

  static void switchToUsers(
    BuildContext context, {
    String targetId = '',
    String roleFilter = 'all',
    String companyApprovalFilter = 'all',
  }) {
    request.value = AdminHomeNavigationRequest(
      tabIndex: usersTab,
      targetId: targetId,
      userRoleFilter: roleFilter,
      companyApprovalFilter: companyApprovalFilter,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void switchToContent(
    BuildContext context, {
    required int contentTab,
    String targetId = '',
  }) {
    request.value = AdminHomeNavigationRequest(
      tabIndex: AdminHomeNavigation.contentTab,
      contentTab: contentTab,
      targetId: targetId,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
