import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/student_provider.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/settings/about_avenirdz_screen.dart';
import '../../screens/settings/help_center_screen.dart';
import '../../screens/settings/logout_confirmation_sheet.dart';
import '../../screens/settings/security_privacy_screen.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';
import '../../screens/settings/settings_screen.dart';
import '../../widgets/profile_avatar.dart';
import 'cv_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) {
      return;
    }

    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      return;
    }

    await Future.wait([
      context.read<StudentProvider>().loadStudentProfile(currentUser.uid),
      context.read<ApplicationProvider>().fetchSubmittedApplicationsCount(
        currentUser.uid,
      ),
      context.read<SavedOpportunityProvider>().fetchSavedOpportunities(
        currentUser.uid,
      ),
      context.read<CvProvider>().loadCv(currentUser.uid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final applicationsProvider = context.watch<ApplicationProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final cvProvider = context.watch<CvProvider>();

    final currentUser = authProvider.userModel;
    final student = studentProvider.student ?? currentUser;
    final firstName = _resolveFirstName(student);
    final greeting = firstName == null
        ? 'Hi there \u{1F44B}'
        : 'Hi, $firstName \u{1F44B}';
    final subtitle = _resolveSubtitle(cvProvider.cv);

    return Scaffold(
      backgroundColor: SettingsFlowPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: SettingsFlowPalette.primary,
          onRefresh: _loadDashboardData,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              _DashboardTopBar(
                onBack: () => Navigator.maybePop(context),
                onMenuSelected: (value) async {
                  switch (value) {
                    case _DashboardMenuAction.refresh:
                      await _loadDashboardData();
                      return;
                    case _DashboardMenuAction.notifications:
                      if (!mounted) {
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                      return;
                    case _DashboardMenuAction.logout:
                      if (!mounted) {
                        return;
                      }
                      await showLogoutConfirmationSheet(context);
                      return;
                  }
                },
              ),
              const SizedBox(height: 14),
              _DashboardHeader(
                greeting: greeting,
                subtitle: subtitle,
                user: student,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DashboardStatCard(
                      title: 'Applications',
                      value:
                          '${applicationsProvider.submittedApplicationsCount}',
                      icon: Icons.assignment_turned_in_outlined,
                      gradient: SettingsFlowPalette.primaryGradient,
                      accentColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DashboardStatCard(
                      title: 'Saved',
                      value: '${savedProvider.savedOpportunities.length}',
                      icon: Icons.bookmark_outline_rounded,
                      gradient: SettingsFlowPalette.secondaryGradient,
                      accentColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SettingsSectionHeading(title: 'Quick Actions'),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.22,
                children: [
                  _QuickActionCard(
                    icon: Icons.edit_outlined,
                    iconColor: SettingsFlowPalette.primary,
                    title: 'Edit Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  _QuickActionCard(
                    icon: Icons.description_outlined,
                    iconColor: SettingsFlowPalette.secondary,
                    title: 'Cv builder',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CvScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    icon: Icons.notifications_none_rounded,
                    iconColor: SettingsFlowPalette.accent,
                    title: 'Notifications',
                    showAlertDot: notificationProvider.unreadCount > 0,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  _QuickActionCard(
                    icon: Icons.tune_rounded,
                    iconColor: SettingsFlowPalette.primaryDark,
                    title: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.surfaceTint,
                  borderRadius: SettingsFlowTheme.radius(26),
                  border: Border.all(
                    color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    SettingsListRow(
                      icon: Icons.lock_outline_rounded,
                      iconColor: SettingsFlowPalette.primary,
                      title: 'Security & Privacy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityPrivacyScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsListRow(
                      icon: Icons.help_outline_rounded,
                      iconColor: SettingsFlowPalette.secondary,
                      title: 'Help Center',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpCenterScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsListRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: SettingsFlowPalette.accent,
                      title: 'About AvenirDZ',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutAvenirDzScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsListRow(
                      icon: Icons.logout_rounded,
                      iconColor: SettingsFlowPalette.error,
                      title: 'Logout',
                      destructive: true,
                      onTap: () => showLogoutConfirmationSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveFirstName(UserModel? user) {
    final rawName = (user?.fullName ?? '').trim();
    if (rawName.isEmpty) {
      return null;
    }

    return rawName.split(RegExp(r'\s+')).first;
  }

  String _resolveSubtitle(CvModel? cv) {
    if (cv == null) {
      return 'Ready for your next milestone?';
    }

    if (cv.hasBuilderContent || cv.hasUploadedCv) {
      return 'Your profile is ready for the next opportunity.';
    }

    return 'Ready for your next milestone?';
  }
}

class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final ValueChanged<_DashboardMenuAction> onMenuSelected;

  const _DashboardTopBar({required this.onBack, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolbarButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Settings', style: SettingsFlowTheme.appBarTitle()),
        ),
        PopupMenuButton<_DashboardMenuAction>(
          onSelected: onMenuSelected,
          color: SettingsFlowPalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: SettingsFlowTheme.radius(18),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _DashboardMenuAction.refresh,
              child: Text('Refresh'),
            ),
            PopupMenuItem(
              value: _DashboardMenuAction.notifications,
              child: Text('Notifications'),
            ),
            PopupMenuItem(
              value: _DashboardMenuAction.logout,
              child: Text('Logout'),
            ),
          ],
          child: const _ToolbarButton(icon: Icons.more_vert_rounded),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final UserModel? user;

  const _DashboardHeader({
    required this.greeting,
    required this.subtitle,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: SettingsFlowTheme.heroTitle()),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: SettingsFlowTheme.body(
                  SettingsFlowPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: _ProfileVisualCard(user: user, compact: true),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: SettingsFlowTheme.heroTitle()),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: SettingsFlowTheme.body(
                        SettingsFlowPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ProfileVisualCard(user: user),
          ],
        );
      },
    );
  }
}

class _ProfileVisualCard extends StatelessWidget {
  final UserModel? user;
  final bool compact;

  const _ProfileVisualCard({required this.user, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cardWidth = compact ? 104.0 : 112.0;
    final cardHeight = compact ? 118.0 : 126.0;
    final avatarContainer = compact ? 74.0 : 80.0;
    final avatarRadius = compact ? 23.0 : 25.0;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: SettingsFlowPalette.surface,
              borderRadius: SettingsFlowTheme.radius(26),
              boxShadow: SettingsFlowTheme.softShadow(),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: SettingsFlowPalette.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SettingsFlowPalette.secondary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: avatarContainer,
                    height: avatarContainer,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0F4FF), Color(0xFFE6FFFB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: SettingsFlowTheme.radius(24),
                    ),
                    child: Center(
                      child: ProfileAvatar(user: user, radius: avatarRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: SettingsFlowPalette.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: SettingsFlowTheme.softShadow(0.05),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: SettingsFlowTheme.radius(14),
                        ),
                        child: Icon(icon, color: accentColor),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.north_east_rounded,
                        color: accentColor.withValues(alpha: 0.88),
                        size: 18,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: SettingsFlowTheme.heroTitle(
                      Colors.white,
                    ).copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: SettingsFlowTheme.body(
                      Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool showAlertDot;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.showAlertDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.surface,
          borderRadius: SettingsFlowTheme.radius(24),
          border: Border.all(color: SettingsFlowPalette.border),
          boxShadow: SettingsFlowTheme.softShadow(0.06),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SettingsIconBox(icon: icon, color: iconColor),
                if (showAlertDot)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: SettingsFlowPalette.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: SettingsFlowTheme.cardTitle(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SettingsFlowTheme.radius(14),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: SettingsFlowPalette.surface,
            borderRadius: SettingsFlowTheme.radius(14),
            border: Border.all(color: SettingsFlowPalette.border),
          ),
          child: Icon(icon, color: SettingsFlowPalette.textPrimary, size: 18),
        ),
      ),
    );
  }
}

enum _DashboardMenuAction { refresh, notifications, logout }
