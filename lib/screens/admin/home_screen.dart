import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/shared/app_animated_tab_body.dart';
import '../../widgets/shared/app_nav_scroll_switcher.dart';
import '../notifications_screen.dart';
import '../settings/logout_confirmation_sheet.dart';
import '../settings/settings_screen.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_home_navigation.dart';
import 'users_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _usersSessionId = 0;
  String _usersInitialTargetId = '';
  String _usersInitialRoleFilter = 'all';
  String _usersInitialCompanyApprovalFilter = 'all';
  int _contentSessionId = 0;
  int _contentInitialTab = AdminContentCenterScreen.projectIdeasTab;
  String _contentInitialTargetId = '';
  final Set<int> _visitedIndexes = <int>{0};

  @override
  void initState() {
    super.initState();
    AdminHomeNavigation.request.addListener(_handleNavigationRequest);
    _handleNavigationRequest();
  }

  @override
  void dispose() {
    AdminHomeNavigation.request.removeListener(_handleNavigationRequest);
    super.dispose();
  }

  List<_AdminDestination> _buildDestinations(AppLocalizations l10n) => [
    _AdminDestination(
      title: l10n.uiDashboard,
      subtitle: l10n.uiDashboardSubtitle,
      icon: Icons.space_dashboard_rounded,
      navLabel: l10n.uiDashboard,
      compactNavLabel: l10n.uiDashboard,
      navIcon: Icons.space_dashboard_outlined,
      activeNavIcon: Icons.space_dashboard_rounded,
    ),
    _AdminDestination(
      title: l10n.uiUsers,
      subtitle: l10n.uiUsersSubtitle,
      icon: Icons.group_rounded,
      navLabel: l10n.uiUsers,
      compactNavLabel: l10n.uiUsers,
      navIcon: Icons.groups_outlined,
      activeNavIcon: Icons.groups_rounded,
    ),
    _AdminDestination(
      title: l10n.uiContent,
      subtitle: l10n.uiContentSubtitle,
      icon: Icons.auto_awesome_mosaic_rounded,
      navLabel: l10n.uiContent,
      compactNavLabel: l10n.uiContent,
      navIcon: Icons.view_quilt_outlined,
      activeNavIcon: Icons.view_quilt_rounded,
    ),
    _AdminDestination(
      title: l10n.uiActivity,
      subtitle: l10n.uiActivitySubtitle,
      icon: Icons.timeline_rounded,
      navLabel: l10n.uiActivity,
      compactNavLabel: l10n.uiActivity,
      navIcon: Icons.timeline_outlined,
      activeNavIcon: Icons.timeline_rounded,
    ),
    _AdminDestination(
      title: l10n.uiSettings,
      subtitle: l10n.uiSettingsSubtitle,
      icon: Icons.settings_rounded,
      navLabel: l10n.uiSettings,
      compactNavLabel: l10n.uiSettings,
      navIcon: Icons.settings_outlined,
      activeNavIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = _buildDestinations(l10n);
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final destination = destinations[_currentIndex];
    final isCompactHeader = MediaQuery.sizeOf(context).width < 720;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AdminShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: AdminSurface(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  radius: 22,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.82,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey(destination.title),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AdminPalette.heroGradient(
                              _currentIndex == 2
                                  ? AdminPalette.secondary
                                  : AdminPalette.accent,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            destination.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Column(
                            key: ValueKey(destination.title),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    destination.title,
                                    style: AppTypography.product(
                                      fontSize: isCompactHeader ? 16 : 17,
                                      fontWeight: FontWeight.w700,
                                      color: AdminPalette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isCompactHeader) ...[
                                const SizedBox(height: 2),
                                Text(
                                  destination.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.product(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AdminPalette.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdminIconActionButton(
                            icon: Icons.notifications_outlined,
                            tooltip: l10n.uiNotificationCenter,
                            badgeCount: unreadCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          AdminIconActionButton(
                            icon: Icons.logout_rounded,
                            tooltip: l10n.uiSignOutTooltip,
                            color: AdminPalette.danger,
                            onTap: _showLogoutDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AppAnimatedTabBody(
                    currentIndex: _currentIndex,
                    onIndexChanged: _selectIndex,
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
                child: _AdminPillNavigationBar(
                  destinations: destinations,
                  currentIndex: _currentIndex,
                  onTap: _selectIndex,
                ),
              ),
      ),
    );
  }

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return AdminDashboardScreen(
          onOpenUsers: _openUsersTab,
          onOpenContent: _openContentTab,
          onOpenActivity: _openActivityTab,
          onOpenLibrary: _openLibraryTab,
        );
      case 1:
        return UsersScreen(
          key: ValueKey('embedded-users-$_usersSessionId'),
          initialRoleFilter: _usersInitialRoleFilter,
          initialCompanyApprovalFilter: _usersInitialCompanyApprovalFilter,
          initialTargetId: _usersInitialTargetId,
        );
      case 2:
        return AdminContentCenterScreen(
          key: ValueKey('embedded-content-$_contentSessionId'),
          embedded: true,
          initialTab: _contentInitialTab,
          initialTargetId: _contentInitialTargetId,
          resetToken: _contentSessionId,
        );
      case 3:
        return AdminActivityCenterScreen(
          embedded: true,
          onOpenContent: _openContentTab,
          onOpenUsers: _openUsersTarget,
        );
      default:
        return const SettingsScreen(embedded: true);
    }
  }

  void _selectIndex(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      if (index == 2 && _currentIndex != 2) {
        _contentInitialTab = AdminContentCenterScreen.projectIdeasTab;
        _contentInitialTargetId = '';
        _contentSessionId++;
      }
      _currentIndex = index;
      _visitedIndexes.add(index);
    });
  }

  void _openUsersTab() => _selectIndex(1);

  void _openUsersTarget({
    String targetId = '',
    String roleFilter = 'all',
    String companyApprovalFilter = 'all',
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _usersInitialTargetId = targetId;
      _usersInitialRoleFilter = roleFilter;
      _usersInitialCompanyApprovalFilter = companyApprovalFilter;
      _usersSessionId++;
      _currentIndex = 1;
      _visitedIndexes.add(1);
    });
  }

  void _openActivityTab() => _selectIndex(3);

  void _openLibraryTab() =>
      _openContentTab(AdminContentCenterScreen.libraryTab);

  void _openContentTab(int tab, {String targetId = ''}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _contentInitialTab = tab.clamp(
        AdminContentCenterScreen.projectIdeasTab,
        AdminContentCenterScreen.libraryTab,
      );
      _contentInitialTargetId = targetId;
      _contentSessionId++;
      _currentIndex = 2;
      _visitedIndexes.add(2);
    });
  }

  void _handleNavigationRequest() {
    final request = AdminHomeNavigation.request.value;
    if (request == null) {
      return;
    }

    AdminHomeNavigation.request.value = null;
    if (!mounted) {
      return;
    }

    if (request.tabIndex == AdminHomeNavigation.usersTab) {
      _openUsersTarget(
        targetId: request.targetId,
        roleFilter: request.userRoleFilter,
        companyApprovalFilter: request.companyApprovalFilter,
      );
      return;
    }

    if (request.tabIndex == AdminHomeNavigation.contentTab) {
      _openContentTab(request.contentTab, targetId: request.targetId);
      return;
    }

    _selectIndex(request.tabIndex);
  }

  void _showLogoutDialog() {
    showLogoutConfirmationSheet(context);
  }
}

class _AdminDestination {
  final String title;
  final String subtitle;
  final IconData icon;
  final String navLabel;
  final String compactNavLabel;
  final IconData navIcon;
  final IconData activeNavIcon;

  const _AdminDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.navLabel,
    required this.compactNavLabel,
    required this.navIcon,
    required this.activeNavIcon,
  });
}

class _AdminPillNavigationBar extends StatelessWidget {
  final List<_AdminDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AdminPillNavigationBar({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 370;
    final selectedFlex = compact ? 13 : 11;
    const idleFlex = 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AppNavScrollSwitcher(
        currentIndex: currentIndex,
        itemCount: destinations.length,
        onIndexChanged: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.isDark
                ? AdminPalette.surface.withValues(alpha: 0.96)
                : AdminPalette.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AdminPalette.border.withValues(alpha: 0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: AdminPalette.primary.withValues(
                  alpha: AppColors.isDark ? 0.16 : 0.10,
                ),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.current.shadow.withValues(
                  alpha: AppColors.isDark ? 0.24 : 0.06,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: List<Widget>.generate(
              destinations.length,
              (index) => Flexible(
                flex: currentIndex == index ? selectedFlex : idleFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _AdminPillNavItem(
                    destination: destinations[index],
                    selected: currentIndex == index,
                    compact: compact,
                    onTap: () => onTap(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminPillNavItem extends StatelessWidget {
  final _AdminDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _AdminPillNavItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = compact ? destination.compactNavLabel : destination.navLabel;
    final selectedGradient = LinearGradient(
      colors: [
        AdminPalette.primaryDark,
        AdminPalette.primary,
        AdminPalette.activity,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 46,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? (compact ? 4 : 6) : 0,
          ),
          decoration: BoxDecoration(
            gradient: selected ? selectedGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AdminPalette.primary.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.72, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: selected
                ? Row(
                    key: ValueKey<String>('selected-${destination.navLabel}'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destination.activeNavIcon,
                        size: compact ? 15 : 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.product(
                              fontSize: compact ? 8.6 : 9.8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    key: ValueKey<String>('idle-${destination.navLabel}'),
                    child: Icon(
                      destination.navIcon,
                      size: compact ? 17 : 19,
                      color: AdminPalette.textMuted.withValues(alpha: 0.92),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
