import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import '../notifications_screen.dart';
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
      compactNavLabel: 'Dash',
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
      compactNavLabel: 'Feed',
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
    final isCompactNavigation = MediaQuery.sizeOf(context).width < 390;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: AdminPalette.background,
      body: AdminShellBackground(
        child: SafeArea(
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
      ),
      bottomNavigationBar: keyboardVisible
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AdminPalette.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List<Widget>.generate(
                      _destinations.length,
                      (index) => Expanded(
                        child: _AdminBottomNavItem(
                          destination: _destinations[index],
                          compact: isCompactNavigation,
                          selected: _currentIndex == index,
                          onTap: () => _selectIndex(index),
                        ),
                      ),
                    ),
                  ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminPalette.danger),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
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

class _AdminBottomNavItem extends StatelessWidget {
  final _AdminDestination destination;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _AdminBottomNavItem({
    required this.destination,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AdminPalette.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? destination.activeNavIcon : destination.navIcon,
              size: 22,
              color: selected ? AdminPalette.primary : AdminPalette.textMuted,
            ),
            const SizedBox(height: 5),
            Text(
              compact ? destination.compactNavLabel : destination.navLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: compact ? 9.6 : 10.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AdminPalette.primary : AdminPalette.textMuted,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
