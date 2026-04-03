import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../settings/settings_screen.dart';
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

  final List<Widget> _screens = const [
    CompanyDashboardScreen(),
    MyOpportunitiesScreen(),
    ApplicationsScreen(),
    ChatListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CompanyShellPalette.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _CompanyShellPalette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CompanyBottomNavItem(
                    label: 'DASHBOARD',
                    icon: Icons.dashboard_outlined,
                    selected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _CompanyBottomNavItem(
                    label: 'OPPS',
                    icon: Icons.work_outline_rounded,
                    selected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                Expanded(
                  child: _CompanyBottomNavItem(
                    label: 'APPS',
                    icon: Icons.groups_outlined,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Expanded(
                  child: _CompanyBottomNavItem(
                    label: 'CHAT',
                    icon: Icons.chat_bubble_outline_rounded,
                    selected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                Expanded(
                  child: _CompanyBottomNavItem(
                    label: 'MORE',
                    icon: Icons.widgets_outlined,
                    selected: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyBottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CompanyBottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _CompanyShellPalette.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? _CompanyShellPalette.primary
                  : _CompanyShellPalette.textMuted,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? _CompanyShellPalette.primary
                    : _CompanyShellPalette.textMuted,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyShellPalette {
  static const Color primary = Color(0xFF4328D8);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
}
