import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifications_screen.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import 'admin_dashboard_screen.dart';
import 'users_screen.dart';
import 'admin_google_books_import_screen.dart';
import 'admin_youtube_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    UsersScreen(),
    AdminContentCenterScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8E0F0), Color(0xFFFDE8D8), Color(0xFFF8D8E0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1B4E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFFFF8C00),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.people, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D1B4E),
                            ),
                          ),
                          Text(
                            'AvenirDZ Management',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HeaderCircleButton(
                                tooltip: 'Recent Activity',
                                icon: Icons.timeline,
                                color: const Color(0xFF2D1B4E),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminActivityCenterScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _HeaderBadgeButton(
                                tooltip: 'Notification Center',
                                icon: Icons.notifications_outlined,
                                badgeCount: unreadCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Import Google Books',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminGoogleBooksImportScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF2D1B4E),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Import YouTube Videos',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminYoutubeImportScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.ondemand_video_rounded,
                                  color: Color(0xFF2D1B4E),
                                ),
                              ),
                              _HeaderCircleButton(
                                tooltip: 'Logout',
                                icon: Icons.logout,
                                color: const Color(0xFF2D1B4E),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text(
                                        'Are you sure you want to logout?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            context
                                                .read<AuthProvider>()
                                                .logout();
                                          },
                                          child: const Text(
                                            'Logout',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFFFF8C00),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_compact_outlined),
              label: 'Content',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadgeButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _HeaderBadgeButton({
    required this.tooltip,
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: const Color(0xFF2D1B4E)),
                if (badgeCount > 0)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8C00),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
