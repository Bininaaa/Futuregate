import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/app_intro_preferences_service.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_animated_tab_body.dart';
import '../../widgets/student/student_workspace_shell.dart';
import '../notifications_screen.dart';
import 'chat_list_screen.dart';
import 'opportunities_screen.dart';
import 'premium_pass_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDailyWelcome());
  }

  Future<void> _maybeShowDailyWelcome() async {
    if (!mounted) return;
    final prefs = AppIntroPreferencesService();
    final shouldShow = await prefs.shouldShowDailyWelcome();
    if (!shouldShow || !mounted) return;
    await prefs.markDailyWelcomeShown();
    if (!mounted) return;
    await _DailyWelcomeSheet.show(context);
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
                    onIndexChanged: _selectIndex,
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

// ── Daily Welcome Sheet ────────────────────────────────────────────────────────

class _DailyWelcomeSheet extends StatefulWidget {
  const _DailyWelcomeSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DailyWelcomeSheet(),
    );
  }

  @override
  State<_DailyWelcomeSheet> createState() => _DailyWelcomeSheetState();
}

class _DailyWelcomeSheetState extends State<_DailyWelcomeSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _tips = [
    (
      icon: Icons.rocket_launch_rounded,
      title: 'Apply Early, Stand Out',
      body:
          'Companies review the earliest applicants first. Don\'t wait — the best roles fill up fast.',
      color: Color(0xFF6C63FF),
    ),
    (
      icon: Icons.workspace_premium_rounded,
      title: 'Early Access = First Mover',
      body:
          'Premium members see new opportunities 48 h before everyone else. Get in before the rush.',
      color: Color(0xFFF59E0B),
    ),
    (
      icon: Icons.auto_awesome_rounded,
      title: 'A Strong CV Opens Doors',
      body:
          'Take 5 minutes to update your CV today. A complete profile gets 3× more views.',
      color: Color(0xFF10B981),
    ),
    (
      icon: Icons.lightbulb_rounded,
      title: 'Share Your Ideas',
      body:
          'The Innovation Hub is growing. Post your project idea and connect with teams looking for your skills.',
      color: Color(0xFFEF4444),
    ),
    (
      icon: Icons.school_rounded,
      title: 'Scholarships Are Waiting',
      body:
          'New scholarships are added every week. Bookmark the ones that match your field and never miss a deadline.',
      color: Color(0xFF3B82F6),
    ),
  ];

  late final _tip = _tips[math.Random().nextInt(_tips.length)];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel;
    final firstName = (user?.fullName ?? '').split(' ').first.trim();
    final greeting = firstName.isEmpty ? 'Welcome back' : 'Hey, $firstName 👋';
    final now = DateTime.now();
    final hour = now.hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _tip.color,
                            _tip.color.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _tip.color.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(_tip.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$timeGreeting!',
                            style: AppTypography.product(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _tip.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            greeting,
                            style: AppTypography.product(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white.withValues(alpha: 0.5),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tip card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _tip.color.withValues(alpha: 0.18),
                        _tip.color.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _tip.color.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _tip.color.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tip of the day',
                              style: AppTypography.product(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: _tip.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tip.title,
                        style: AppTypography.product(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tip.body,
                        style: AppTypography.product(
                          fontSize: 13,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _DailyAction(
                        icon: Icons.explore_rounded,
                        label: 'Discover',
                        color: const Color(0xFF6C63FF),
                        onTap: () {
                          Navigator.pop(context);
                          StudentHomeNavigation.switchToDiscover(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DailyAction(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Go Premium',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PremiumPassScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DailyAction(
                        icon: Icons.school_rounded,
                        label: 'Scholarships',
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.pop(context);
                          StudentHomeNavigation.switchToTab(
                              context, StudentHomeNavigation.scholarshipsTab);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DailyAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.product(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
