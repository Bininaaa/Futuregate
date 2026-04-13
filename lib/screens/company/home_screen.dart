import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/company_dashboard_palette.dart';
import '../settings/settings_screen.dart';
import '../../widgets/app_shell_background.dart';
import 'applications_screen.dart';
import 'chat_list_screen.dart';
import 'company_dashboard_screen.dart';
import 'my_opportunities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;

  static const List<_CompanyDestination> _destinations = [
    _CompanyDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _CompanyDestination(
      label: 'Opportunities',
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
    ),
    _CompanyDestination(
      label: 'Applications',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    _CompanyDestination(
      label: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _CompanyDestination(
      label: 'Settings',
      icon: Icons.tune_rounded,
      activeIcon: Icons.tune_rounded,
    ),
  ];

  final List<Widget> _screens = const [
    CompanyDashboardScreen(),
    MyOpportunitiesScreen(),
    ApplicationsScreen(),
    ChatListScreen(),
    SettingsScreen(),
  ];

  void _selectIndex(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == _currentIndex) {
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: keyboardVisible
            ? null
            : SafeArea(
                top: false,
                child: _CompanyPillNavigationBar(
                  destinations: _destinations,
                  currentIndex: _currentIndex,
                  onTap: _selectIndex,
                ),
              ),
      ),
    );
  }
}

class _CompanyDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _CompanyDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _CompanyPillNavigationBar extends StatelessWidget {
  final List<_CompanyDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CompanyPillNavigationBar({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 370;
    final selectedFlex = compact ? 14 : 12;
    final idleFlex = compact ? 5 : 6;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: CompanyDashboardPalette.border.withValues(alpha: 0.94),
          ),
          boxShadow: [
            BoxShadow(
              color: CompanyDashboardPalette.primary.withValues(alpha: 0.11),
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
                child: _CompanyPillNavItem(
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

class _CompanyPillNavItem extends StatelessWidget {
  final _CompanyDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _CompanyPillNavItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedGradient = LinearGradient(
      colors: [
        CompanyDashboardPalette.primaryDark,
        CompanyDashboardPalette.primary,
        CompanyDashboardPalette.secondaryDark,
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
                      color: CompanyDashboardPalette.primary.withValues(
                        alpha: 0.24,
                      ),
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
                    key: ValueKey<String>('selected-${destination.label}'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destination.activeIcon,
                        size: compact ? 15 : 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            destination.label,
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
                    key: ValueKey<String>('idle-${destination.label}'),
                    child: Icon(
                      destination.icon,
                      size: compact ? 17 : 19,
                      color: CompanyDashboardPalette.textMuted.withValues(
                        alpha: 0.92,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
