import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'student_dashboard_screen.dart';
import 'opportunities_screen.dart';
import 'scholarships_screen.dart';
import 'project_ideas_screen.dart';
import 'chat_list_screen.dart';
import 'saved_screen.dart';
import 'cv_screen.dart';
import 'profile_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/logout_confirmation_sheet.dart';
import '../../utils/opportunity_dashboard_palette.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  static final ValueNotifier<int?> _requestedTabIndex = ValueNotifier<int?>(
    null,
  );

  static void switchToTab(BuildContext context, int index) {
    _requestedTabIndex.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    StudentDashboardScreen(),
    OpportunitiesScreen(),
    ScholarshipsScreen(),
    ProjectIdeasScreen(),
    ChatListScreen(),
    _MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizeIndex(widget.initialIndex);
    HomeScreen._requestedTabIndex.addListener(_handleRequestedTab);
    _handleRequestedTab();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _currentIndex = _normalizeIndex(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    HomeScreen._requestedTabIndex.removeListener(_handleRequestedTab);
    super.dispose();
  }

  void _handleRequestedTab() {
    final requestedIndex = HomeScreen._requestedTabIndex.value;
    if (requestedIndex == null) {
      return;
    }

    final normalizedIndex = _normalizeIndex(requestedIndex);
    HomeScreen._requestedTabIndex.value = null;

    if (!mounted || normalizedIndex == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = normalizedIndex;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: OpportunityDashboardPalette.primary,
          unselectedItemColor: OpportunityDashboardPalette.textSecondary,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Opportunities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Scholarships',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline),
              activeIcon: Icon(Icons.lightbulb),
              label: 'Ideas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpportunityDashboardPalette.background,
      appBar: AppBar(
        title: Text(
          'More',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: OpportunityDashboardPalette.textPrimary,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'My Profile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.description_outlined,
            title: 'My CV',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CvScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.bookmark_outline,
            title: 'Saved Items',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
            onTap: () => showLogoutConfirmationSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.08)
                    : OpportunityDashboardPalette.primary.withValues(
                        alpha: 0.08,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : OpportunityDashboardPalette.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? Colors.red
                      : OpportunityDashboardPalette.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.4)
                  : OpportunityDashboardPalette.textSecondary.withValues(
                      alpha: 0.5,
                    ),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
