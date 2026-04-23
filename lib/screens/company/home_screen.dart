import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/company/company_workspace_shell.dart';
import '../../widgets/shared/app_animated_tab_body.dart';
import '../../widgets/shared/app_double_back_exit_scope.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'applications_screen.dart';
import 'chat_list_screen.dart';
import 'company_dashboard_screen.dart';
import 'profile_screen.dart';
import 'my_opportunities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<int> _visitedIndexes = <int>{0};

  void _selectIndex(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
      _visitedIndexes.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final user = context.watch<AuthProvider>().userModel;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destinations = <CompanyWorkspaceDestination>[
      CompanyWorkspaceDestination(
        label: l10n.uiDashboard,
        subtitle: l10n.companyDashboardTabSubtitle,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
      ),
      CompanyWorkspaceDestination(
        label: l10n.uiOpportunities,
        subtitle: l10n.companyOpportunitiesTabSubtitle,
        icon: Icons.work_outline_rounded,
        activeIcon: Icons.work_rounded,
      ),
      CompanyWorkspaceDestination(
        label: l10n.uiApplications,
        subtitle: l10n.companyApplicationsTabSubtitle,
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups_rounded,
      ),
      CompanyWorkspaceDestination(
        label: l10n.uiMessages,
        subtitle: l10n.companyMessagesTabSubtitle,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
      ),
      CompanyWorkspaceDestination(
        label: l10n.moreTitle,
        subtitle: l10n.companyWorkspaceSubtitle,
        icon: Icons.widgets_outlined,
        activeIcon: Icons.widgets_rounded,
      ),
    ];
    final destination = destinations[_currentIndex];

    return AppDoubleBackExitScope(
      child: AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                CompanyWorkspaceTopBar(
                  destination: destination,
                  user: user,
                  unreadCount: unreadCount,
                  onNotificationsTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  onProfileTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CompanyProfileScreen(),
                      ),
                    );
                  },
                  onSettingsTap: _currentIndex == 0
                      ? () => _selectIndex(4)
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppAnimatedTabBody(
                      currentIndex: _currentIndex,
                      children: List<Widget>.generate(
                        destinations.length,
                        (index) => _visitedIndexes.contains(index)
                            ? _screenForIndex(index)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: keyboardVisible
              ? null
              : SafeArea(
                  top: false,
                  child: CompanyPillNavigationBar(
                    destinations: destinations,
                    currentIndex: _currentIndex,
                    onTap: _selectIndex,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _screenForIndex(int index) {
    return switch (index) {
      0 => const CompanyDashboardScreen(embedded: true),
      1 => const MyOpportunitiesScreen(embedded: true),
      2 => const ApplicationsScreen(embedded: true),
      3 => const ChatListScreen(embedded: true),
      _ => const SettingsScreen(embedded: true),
    };
  }
}
