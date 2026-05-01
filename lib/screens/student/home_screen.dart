import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/app_intro_preferences_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowDailyWelcome(),
    );
  }

  Future<void> _maybeShowDailyWelcome() async {
    if (!mounted) return;
    final user = context.read<AuthProvider>().userModel;
    if (user == null || user.role != 'student') return;

    final hasActivePremium = await _hasActivePremium(user.uid);
    if (!mounted) return;

    final prefs = AppIntroPreferencesService();
    final shouldShow = await prefs.shouldShowDailyWelcome(
      hasActivePremium: hasActivePremium,
    );
    if (!shouldShow || !mounted) return;

    await prefs.markDailyWelcomeShown();
    if (!mounted) return;
    await _DailyPremiumUpgradeScreen.show(context);
  }

  Future<bool> _hasActivePremium(String uid) async {
    if (uid.isEmpty) return true;

    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (subscriptionProvider.hasActivePremium) return true;

    try {
      return await SubscriptionService().hasActivePremium(uid);
    } catch (_) {
      return true;
    }
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

// Daily premium upgrade screen

class _DailyPremiumUpgradeScreen extends StatelessWidget {
  const _DailyPremiumUpgradeScreen();

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _DailyPremiumUpgradeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final premium = context.watch<PremiumProvider>();
    final compact = MediaQuery.sizeOf(context).width < 390;
    final priceLabel =
        '${premium.config.price} ${premium.config.currency} - ${l10n.premiumPassPriceLabel}';

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.shellGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 24,
              14,
              compact ? 18 : 24,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _UpgradeLabel(
                          colors: colors,
                          text: l10n.premiumPassTitle,
                        ),
                        const Spacer(),
                        Tooltip(
                          message: l10n.cancelLabel,
                          child: Material(
                            color: colors.surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.close_rounded,
                                  color: colors.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 18 : 24),
                    _UpgradeHero(
                      colors: colors,
                      title: l10n.premiumPassUpgradeButton,
                      subtitle: l10n.premiumPassDescription,
                      priceLabel: priceLabel,
                    ),
                    const SizedBox(height: 18),
                    _UpgradeBenefits(
                      colors: colors,
                      l10n: l10n,
                      earlyAccessHours:
                          premium.config.earlyAccessDefaultDelayHours,
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const PremiumPassScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: Text(l10n.premiumPassUpgradeButton),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: AppTypography.product(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textMuted,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: AppTypography.product(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.cancelLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeHero extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String subtitle;
  final String priceLabel;

  const _UpgradeHero({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryDeep,
            colors.primary,
            colors.accent.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: colors.softShadow(0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTypography.product(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.product(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.48,
            ),
          ),
          const SizedBox(height: 18),
          _PricePill(text: priceLabel),
        ],
      ),
    );
  }
}

class _UpgradeBenefits extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  final int earlyAccessHours;

  const _UpgradeBenefits({
    required this.colors,
    required this.l10n,
    required this.earlyAccessHours,
  });

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (
        icon: Icons.bolt_rounded,
        title: l10n.premiumFeatureEarlyAccess,
        detail: '${earlyAccessHours}h advantage window',
        color: colors.accent,
      ),
      (
        icon: Icons.trending_up_rounded,
        title: l10n.premiumFeaturePriority,
        detail: 'Stand higher when companies review applicants',
        color: colors.secondary,
      ),
      (
        icon: Icons.bookmark_rounded,
        title: l10n.premiumFeatureSaved,
        detail: 'Keep every opportunity you want to revisit',
        color: colors.info,
      ),
      (
        icon: Icons.verified_rounded,
        title: l10n.premiumFeatureBadge,
        detail: 'Make your profile instantly recognizable',
        color: colors.success,
      ),
    ];

    return Column(
      children: benefits
          .map((benefit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UpgradeBenefitTile(
                colors: colors,
                icon: benefit.icon,
                title: benefit.title,
                detail: benefit.detail,
                color: benefit.color,
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _UpgradeBenefitTile extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  const _UpgradeBenefitTile({
    required this.colors,
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(
          alpha: colors.isDarkMode ? 0.86 : 0.94,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.78)),
        boxShadow: colors.softShadow(0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.stateLayer(color),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.product(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: AppTypography.product(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: colors.success, size: 20),
          ],
        ),
      ),
    );
  }
}

class _UpgradeLabel extends StatelessWidget {
  final AppColors colors;
  final String text;

  const _UpgradeLabel({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: colors.accent, size: 17),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTypography.product(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text;

  const _PricePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sell_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
