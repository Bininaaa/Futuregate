import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../notifications_screen.dart';
import '../settings/logout_confirmation_sheet.dart';
import 'chat_list_screen.dart';
import 'opportunities_screen.dart';
import 'project_ideas_screen.dart';
import 'scholarships_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_home_navigation.dart';
import 'trainings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  static void switchToTab(
    BuildContext context,
    int index, {
    String? discoverFilter,
  }) {
    StudentHomeNavigation.switchToTab(
      context,
      index,
      discoverFilter: discoverFilter,
    );
  }

  static void switchToDiscover(BuildContext context, {String? filter}) {
    StudentHomeNavigation.switchToDiscover(context, filter: filter);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final Set<int> _visitedIndexes = <int>{};

  late final List<_StudentDestination> _destinations = [
    const _StudentDestination(
      title: 'Home',
      subtitle: 'Your daily student pulse, shortcuts, and fresh momentum.',
      icon: Icons.home_rounded,
      navLabel: 'Home',
      compactNavLabel: 'Home',
      navIcon: Icons.home_outlined,
      activeNavIcon: Icons.home_rounded,
    ),
    const _StudentDestination(
      title: 'Discover',
      subtitle:
          'Jobs, internships, and sponsored tracks matched to your next move.',
      icon: Icons.explore_rounded,
      navLabel: 'Discover',
      compactNavLabel: 'Discover',
      navIcon: Icons.explore_outlined,
      activeNavIcon: Icons.explore_rounded,
    ),
    const _StudentDestination(
      title: 'Scholarships',
      subtitle: 'Funding opportunities, deadlines, and global study paths.',
      icon: Icons.school_rounded,
      navLabel: 'Scholarships',
      compactNavLabel: 'Scholarships',
      navIcon: Icons.school_outlined,
      activeNavIcon: Icons.school_rounded,
    ),
    const _StudentDestination(
      title: 'Training',
      subtitle: 'Courses, books, and certifications that sharpen your journey.',
      icon: Icons.cast_for_education_rounded,
      navLabel: 'Training',
      compactNavLabel: 'Training',
      navIcon: Icons.cast_for_education_outlined,
      activeNavIcon: Icons.cast_for_education_rounded,
    ),
    const _StudentDestination(
      title: 'Ideas',
      subtitle: 'Build, save, and grow your next project idea with confidence.',
      icon: Icons.lightbulb_rounded,
      navLabel: 'Ideas',
      compactNavLabel: 'Ideas',
      navIcon: Icons.lightbulb_outline,
      activeNavIcon: Icons.lightbulb_rounded,
    ),
    const _StudentDestination(
      title: 'Chat',
      subtitle: 'Stay close to conversations, follow-ups, and collaboration.',
      icon: Icons.chat_bubble_rounded,
      navLabel: 'Chat',
      compactNavLabel: 'Chat',
      navIcon: Icons.chat_bubble_outline_rounded,
      activeNavIcon: Icons.chat_bubble_rounded,
    ),
  ];

  final List<Widget> _screens = const [
    StudentDashboardScreen(embedded: true),
    OpportunitiesScreen(embedded: true),
    ScholarshipsScreen(embedded: true),
    TrainingsScreen(embedded: true),
    ProjectIdeasScreen(embedded: true),
    ChatListScreen(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizeIndex(widget.initialIndex);
    _visitedIndexes.add(_currentIndex);
    StudentHomeNavigation.requestedTabIndex.addListener(_handleRequestedTab);
    _handleRequestedTab();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      final nextIndex = _normalizeIndex(widget.initialIndex);
      _visitedIndexes.add(nextIndex);
      _currentIndex = nextIndex;
    }
  }

  @override
  void dispose() {
    StudentHomeNavigation.requestedTabIndex.removeListener(_handleRequestedTab);
    super.dispose();
  }

  void _handleRequestedTab() {
    final requestedIndex = StudentHomeNavigation.requestedTabIndex.value;
    if (requestedIndex == null) {
      return;
    }

    final normalizedIndex = _normalizeIndex(requestedIndex);
    StudentHomeNavigation.requestedTabIndex.value = null;

    if (!mounted || normalizedIndex == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = normalizedIndex;
      _visitedIndexes.add(normalizedIndex);
    });
  }

  int _normalizeIndex(int index) {
    if (index < 0) {
      return 0;
    }
    if (index >= _screens.length) {
      return _screens.length - 1;
    }
    return index;
  }

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
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destination = _destinations[_currentIndex];

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              if (_currentIndex != 0)
                StudentWorkspaceTopBar(
                  title: destination.title,
                  subtitle: destination.subtitle,
                  icon: destination.icon,
                  actions: [
                    StudentWorkspaceActionButton(
                      icon: Icons.notifications_outlined,
                      tooltip: 'Notifications',
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
                    StudentWorkspaceActionButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'Logout',
                      color: OpportunityDashboardPalette.error,
                      onTap: () => showLogoutConfirmationSheet(context),
                    ),
                  ],
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List<Widget>.generate(
                      _screens.length,
                      (index) => _visitedIndexes.contains(index)
                          ? _screens[index]
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
                child: StudentPillNavigationBar(
                  destinations: _destinations
                      .map(
                        (destination) => StudentWorkspaceNavDestination(
                          label: destination.navLabel,
                          compactLabel: destination.compactNavLabel,
                          icon: destination.navIcon,
                          activeIcon: destination.activeNavIcon,
                        ),
                      )
                      .toList(growable: false),
                  currentIndex: _currentIndex,
                  onTap: _selectIndex,
                ),
              ),
      ),
    );
  }
}

class _StudentDestination {
  final String title;
  final String subtitle;
  final IconData icon;
  final String navLabel;
  final String compactNavLabel;
  final IconData navIcon;
  final IconData activeNavIcon;

  const _StudentDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.navLabel,
    required this.compactNavLabel,
    required this.navIcon,
    required this.activeNavIcon,
  });
}
