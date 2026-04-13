import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import '../notifications_screen.dart';
import '../settings/logout_confirmation_sheet.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_library_screen.dart';
import 'users_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _contentSessionId = 0;
  int _contentInitialTab = AdminContentCenterScreen.projectIdeasTab;
  String _contentInitialTargetId = '';
  final Set<int> _visitedIndexes = <int>{0};

  late final List<_AdminDestination> _destinations = [
    const _AdminDestination(
      title: 'Dashboard',
      subtitle: 'Platform pulse, moderation load, and quick control points.',
      icon: Icons.space_dashboard_rounded,
      navLabel: 'Dashboard',
      compactNavLabel: 'Dashboard',
      navIcon: Icons.space_dashboard_outlined,
      activeNavIcon: Icons.space_dashboard_rounded,
    ),
    const _AdminDestination(
      title: 'Users',
      subtitle: 'Search users, review profiles, and manage account status.',
      icon: Icons.group_rounded,
      navLabel: 'Users',
      compactNavLabel: 'Users',
      navIcon: Icons.groups_outlined,
      activeNavIcon: Icons.groups_rounded,
    ),
    const _AdminDestination(
      title: 'Content',
      subtitle:
          'Moderate ideas, applications, listings, scholarships, and training.',
      icon: Icons.auto_awesome_mosaic_rounded,
      navLabel: 'Content',
      compactNavLabel: 'Content',
      navIcon: Icons.view_quilt_outlined,
      activeNavIcon: Icons.view_quilt_rounded,
    ),
    const _AdminDestination(
      title: 'Activity',
      subtitle:
          'Track platform changes and jump straight into the right queue.',
      icon: Icons.timeline_rounded,
      navLabel: 'Activity',
      compactNavLabel: 'Activity',
      navIcon: Icons.timeline_outlined,
      activeNavIcon: Icons.timeline_rounded,
    ),
    const _AdminDestination(
      title: 'Library',
      subtitle: 'Curate imported books and video resources from one place.',
      icon: Icons.menu_book_rounded,
      navLabel: 'Library',
      compactNavLabel: 'Library',
      navIcon: Icons.library_books_outlined,
      activeNavIcon: Icons.library_books_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final destination = _destinations[_currentIndex];
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AdminPalette.heroGradient(
                            destination.title == 'Library'
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  destination.title,
                                  style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AdminPalette.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdminIconActionButton(
                            icon: Icons.notifications_outlined,
                            tooltip: 'Notification Center',
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
                            tooltip: 'Sign out',
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
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List<Widget>.generate(
                      _destinations.length,
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
                  destinations: _destinations,
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
        return const UsersScreen();
      case 2:
        return AdminContentCenterScreen(
          key: ValueKey('embedded-content-$_contentSessionId'),
          embedded: true,
          initialTab: _contentInitialTab,
          initialTargetId: _contentInitialTargetId,
          resetToken: _contentSessionId,
          onOpenLibrary: _openLibraryTab,
        );
      case 3:
        return AdminActivityCenterScreen(
          embedded: true,
          onOpenContent: _openContentTab,
        );
      default:
        return const AdminLibraryScreen();
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

  void _openActivityTab() => _selectIndex(3);

  void _openLibraryTab() => _selectIndex(4);

  void _openContentTab(int tab, {String targetId = ''}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _contentInitialTab = tab.clamp(
        AdminContentCenterScreen.projectIdeasTab,
        AdminContentCenterScreen.trainingsTab,
      );
      _contentInitialTargetId = targetId;
      _contentSessionId++;
      _currentIndex = 2;
      _visitedIndexes.add(2);
    });
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AdminPalette.border.withValues(alpha: 0.92),
          ),
          boxShadow: [
            BoxShadow(
              color: AdminPalette.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
    const selectedGradient = LinearGradient(
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
          duration: const Duration(milliseconds: 220),
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
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
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
                            style: GoogleFonts.poppins(
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
