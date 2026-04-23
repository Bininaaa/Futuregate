import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_animated_tab_body.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../notifications_screen.dart';
import 'chat_list_screen.dart';
import 'opportunities_screen.dart';
import 'project_ideas_screen.dart';
import 'saved_screen.dart';
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

  List<_StudentDestination> _buildDestinations(AppLocalizations l10n) {
    return [
      _StudentDestination(
        title: l10n.uiHome,
        subtitle: l10n.studentHomeSubtitle,
        icon: Icons.home_rounded,
        navLabel: l10n.uiHome,
        compactNavLabel: l10n.uiHome,
        navIcon: Icons.home_outlined,
        activeNavIcon: Icons.home_rounded,
      ),
      _StudentDestination(
        title: l10n.uiDiscover,
        subtitle: l10n.studentDiscoverSubtitle,
        icon: Icons.explore_rounded,
        navLabel: l10n.uiDiscover,
        compactNavLabel: l10n.uiDiscover,
        navIcon: Icons.explore_outlined,
        activeNavIcon: Icons.explore_rounded,
      ),
      _StudentDestination(
        title: l10n.uiScholarships,
        subtitle: l10n.studentScholarshipsSubtitle,
        icon: Icons.school_rounded,
        navLabel: l10n.uiScholarships,
        compactNavLabel: l10n.uiScholarships,
        navIcon: Icons.school_outlined,
        activeNavIcon: Icons.school_rounded,
      ),
      _StudentDestination(
        title: l10n.uiTraining,
        subtitle: l10n.studentTrainingSubtitle,
        icon: Icons.cast_for_education_rounded,
        navLabel: l10n.uiTraining,
        compactNavLabel: l10n.uiTraining,
        navIcon: Icons.cast_for_education_outlined,
        activeNavIcon: Icons.cast_for_education_rounded,
      ),
      _StudentDestination(
        title: l10n.uiIdeas,
        subtitle: l10n.studentIdeasSubtitle,
        icon: Icons.lightbulb_rounded,
        navLabel: l10n.uiIdeas,
        compactNavLabel: l10n.uiIdeas,
        navIcon: Icons.lightbulb_outline,
        activeNavIcon: Icons.lightbulb_rounded,
      ),
      _StudentDestination(
        title: l10n.uiChat,
        subtitle: l10n.studentChatSubtitle,
        icon: Icons.chat_bubble_rounded,
        navLabel: l10n.uiChat,
        compactNavLabel: l10n.uiChat,
        navIcon: Icons.chat_bubble_outline_rounded,
        activeNavIcon: Icons.chat_bubble_rounded,
      ),
    ];
  }

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

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openSavedFilter(SavedScreenFilter filter) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SavedScreen(initialFilter: filter)),
    );
  }

  List<Widget> _buildTopBarActions(AppLocalizations l10n, int unreadCount) {
    return switch (_currentIndex) {
      1 => [
        StudentWorkspaceActionButton(
          icon: Icons.notifications_outlined,
          tooltip: l10n.notificationsTooltip,
          badgeCount: unreadCount,
          onTap: _openNotifications,
        ),
      ],
      2 => [
        StudentWorkspaceActionButton(
          icon: Icons.notifications_outlined,
          tooltip: l10n.notificationsTooltip,
          badgeCount: unreadCount,
          onTap: _openNotifications,
        ),
        StudentWorkspaceActionButton(
          icon: Icons.bookmark_outline_rounded,
          tooltip: l10n.savedScholarshipsTooltip,
          onTap: () => _openSavedFilter(SavedScreenFilter.scholarships),
        ),
      ],
      3 => [
        StudentWorkspaceActionButton(
          icon: Icons.bookmark_outline_rounded,
          tooltip: l10n.savedTrainingTooltip,
          onTap: () => _openSavedFilter(SavedScreenFilter.trainings),
        ),
      ],
      4 => [
        StudentWorkspaceActionButton(
          icon: Icons.bookmark_outline_rounded,
          tooltip: l10n.savedIdeasTooltip,
          onTap: () => _openSavedFilter(SavedScreenFilter.ideas),
        ),
      ],
      5 => [
        StudentWorkspaceActionButton(
          icon: Icons.notifications_outlined,
          tooltip: l10n.notificationsTooltip,
          badgeCount: unreadCount,
          onTap: _openNotifications,
        ),
      ],
      _ => const <Widget>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = _buildDestinations(l10n);
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destination = destinations[_currentIndex];

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _currentIndex != 0
                    ? StudentWorkspaceTopBar(
                        key: const ValueKey(true),
                        title: destination.title,
                        subtitle: destination.subtitle,
                        icon: destination.icon,
                        actions: _buildTopBarActions(l10n, unreadCount),
                      )
                    : const SizedBox.shrink(key: ValueKey(false)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AppAnimatedTabBody(
                    currentIndex: _currentIndex,
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
                  destinations: destinations
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
