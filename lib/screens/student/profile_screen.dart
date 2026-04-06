import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/saved_scholarship_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/training_provider.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/settings/about_avenirdz_screen.dart';
import '../../screens/settings/help_center_screen.dart';
import '../../screens/settings/logout_confirmation_sheet.dart';
import '../../screens/settings/security_privacy_screen.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';
import '../../screens/settings/settings_screen.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/profile_avatar.dart';
import 'applied_opportunities_screen.dart';
import 'cv_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  Future<void> _loadProfileData() async {
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
      context.read<SavedScholarshipProvider>().fetchSavedScholarships(
        currentUser.uid,
      ),
      context.read<TrainingProvider>().fetchSavedTrainings(currentUser.uid),
      context.read<ProjectIdeaProvider>().fetchSavedIdeas(currentUser.uid),
      context.read<CvProvider>().loadCv(currentUser.uid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final applicationsProvider = context.watch<ApplicationProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final savedScholarshipProvider = context.watch<SavedScholarshipProvider>();
    final savedIdeasProvider = context.watch<ProjectIdeaProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final cvProvider = context.watch<CvProvider>();

    final currentUser = authProvider.userModel;
    final student = studentProvider.student ?? currentUser;
    final cv = cvProvider.cv;

    final savedOpportunitiesCount = savedProvider.savedOpportunities.length;
    final savedScholarshipsCount =
        savedScholarshipProvider.savedScholarships.length;
    final savedTrainingsCount = trainingProvider.savedTrainings.length;
    final savedIdeasCount = savedIdeasProvider.savedIdeas.length;
    final savedCount =
        savedOpportunitiesCount +
        savedScholarshipsCount +
        savedTrainingsCount +
        savedIdeasCount;

    final completion = _profileCompletion(student, cv);
    final hasBio = (student?.bio ?? '').trim().isNotEmpty;
    final displayName = _resolveDisplayName(student);
    final headline = _resolveHeadline(student, cv);
    final email = (student?.email ?? '').trim();
    final bio = hasBio
        ? (student!.bio!).trim()
        : 'Add a short bio so your profile feels more personal and more ready for opportunities.';

    final savedCategories = <_SavedCategoryData>[
      _SavedCategoryData(
        label: 'Opportunities',
        count: savedOpportunitiesCount,
        icon: Icons.work_outline_rounded,
        color: SettingsFlowPalette.primary,
      ),
      _SavedCategoryData(
        label: 'Scholarships',
        count: savedScholarshipsCount,
        icon: Icons.school_outlined,
        color: SettingsFlowPalette.secondary,
      ),
      _SavedCategoryData(
        label: 'Resources',
        count: savedTrainingsCount,
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF4F46E5),
      ),
      _SavedCategoryData(
        label: 'Ideas',
        count: savedIdeasCount,
        icon: Icons.lightbulb_outline_rounded,
        color: SettingsFlowPalette.accent,
      ),
    ];

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: !widget.embedded,
        child: RefreshIndicator(
          color: SettingsFlowPalette.primary,
          onRefresh: _loadProfileData,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (!widget.embedded) ...[
                _ProfileTopBar(
                  onBack: () => Navigator.maybePop(context),
                  onMenuSelected: (value) async {
                    switch (value) {
                      case _ProfileMenuAction.refresh:
                        await _loadProfileData();
                        return;
                      case _ProfileMenuAction.notifications:
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
                      case _ProfileMenuAction.logout:
                        if (!mounted) {
                          return;
                        }
                        await showLogoutConfirmationSheet(context);
                        return;
                    }
                  },
                ),
                const SizedBox(height: 14),
              ],
              _ProfileHeroCard(
                user: student,
                name: displayName,
                headline: headline,
                email: email,
                bio: bio,
                completion: completion,
                badges: _buildHeroBadges(student),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                onOpenCv: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CvScreen()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      title: 'Saved',
                      value: '$savedCount',
                      caption: savedCount == 0
                          ? 'Build your shortlist here.'
                          : 'Everything you bookmarked in one place.',
                      icon: Icons.bookmark_rounded,
                      gradient: SettingsFlowPalette.secondaryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      title: 'Applications',
                      value:
                          '${applicationsProvider.submittedApplicationsCount}',
                      caption:
                          applicationsProvider.submittedApplicationsCount == 0
                          ? 'Start sending strong applications.'
                          : 'Track the roles you already applied to.',
                      icon: Icons.assignment_turned_in_outlined,
                      gradient: SettingsFlowPalette.primaryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppliedOpportunitiesScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 860;

                  final leftColumn = Column(
                    children: [
                      _SavedBreakdownPanel(
                        totalCount: savedCount,
                        categories: savedCategories,
                        onOpenSaved: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileDetailsPanel(
                        completion: completion,
                        bio: bio,
                        hasBio: hasBio,
                        missingItems: _missingItems(student, cv),
                        facts: _buildProfileFacts(student),
                      ),
                    ],
                  );

                  final rightColumn = Column(
                    children: [
                      _QuickActionsPanel(
                        unreadNotifications: notificationProvider.unreadCount,
                        cvSubtitle: _cvQuickActionSubtitle(cv),
                        onEditProfile: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                        onOpenCv: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CvScreen()),
                        ),
                        onNotifications: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        onOpenSettings: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AccountPanel(
                        onSecurity: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SecurityPrivacyScreen(),
                          ),
                        ),
                        onHelp: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        ),
                        onAbout: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutAvenirDzScreen(),
                          ),
                        ),
                        onLogout: () => showLogoutConfirmationSheet(context),
                      ),
                    ],
                  );

                  if (useTwoColumns) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: leftColumn),
                        const SizedBox(width: 12),
                        Expanded(child: rightColumn),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: 12),
                      rightColumn,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return scaffold;
    }

    return AppShellBackground(child: scaffold);
  }

  String _resolveDisplayName(UserModel? user) {
    final fullName = (user?.fullName ?? '').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = (user?.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Student Profile';
  }

  String _resolveHeadline(UserModel? user, CvModel? cv) {
    final fieldOfStudy = (user?.fieldOfStudy ?? '').trim();
    final university = (user?.university ?? '').trim();
    final academicLevel = (user?.academicLevel ?? '').trim();

    if (fieldOfStudy.isNotEmpty && university.isNotEmpty) {
      return '$fieldOfStudy at $university';
    }

    if (fieldOfStudy.isNotEmpty) {
      return fieldOfStudy;
    }

    if (university.isNotEmpty) {
      return university;
    }

    if (academicLevel.isNotEmpty) {
      return academicLevel;
    }

    if (cv != null && (cv.hasBuilderContent || cv.hasUploadedCv)) {
      return 'Your CV is in place and your profile is ready for the next move.';
    }

    return 'A cleaner profile makes every application feel stronger.';
  }

  String _cvQuickActionSubtitle(CvModel? cv) {
    if (cv == null) {
      return 'Build or upload your CV.';
    }

    if (cv.hasUploadedCv || cv.hasExportedPdf) {
      return 'Your CV is ready to share.';
    }

    if (cv.hasBuilderContent) {
      return 'Keep polishing your latest draft.';
    }

    return 'Build or upload your CV.';
  }

  double _profileCompletion(UserModel? user, CvModel? cv) {
    final checks = <bool>[
      (user?.fullName ?? '').trim().isNotEmpty,
      (user?.email ?? '').trim().isNotEmpty,
      (user?.phone ?? '').trim().isNotEmpty,
      (user?.location ?? '').trim().isNotEmpty,
      (user?.academicLevel ?? '').trim().isNotEmpty,
      (user?.university ?? '').trim().isNotEmpty,
      (user?.fieldOfStudy ?? '').trim().isNotEmpty,
      (user?.bio ?? '').trim().isNotEmpty,
      cv != null &&
          (cv.hasBuilderContent || cv.hasUploadedCv || cv.hasExportedPdf),
    ];

    final completed = checks.where((item) => item).length;
    return completed / checks.length;
  }

  List<String> _missingItems(UserModel? user, CvModel? cv) {
    final items = <String>[];

    if ((user?.phone ?? '').trim().isEmpty) {
      items.add('Phone');
    }
    if ((user?.location ?? '').trim().isEmpty) {
      items.add('Location');
    }
    if ((user?.academicLevel ?? '').trim().isEmpty) {
      items.add('Academic level');
    }
    if ((user?.university ?? '').trim().isEmpty) {
      items.add('University');
    }
    if ((user?.fieldOfStudy ?? '').trim().isEmpty) {
      items.add('Field of study');
    }
    if ((user?.bio ?? '').trim().isEmpty) {
      items.add('Bio');
    }
    if (cv == null || (!cv.hasBuilderContent && !cv.hasUploadedCv)) {
      items.add('CV');
    }

    return items;
  }

  List<_HeroBadgeData> _buildHeroBadges(UserModel? user) {
    final badges = <_HeroBadgeData>[];
    final academicLevel = (user?.academicLevel ?? '').trim();
    final university = (user?.university ?? '').trim();
    final fieldOfStudy = (user?.fieldOfStudy ?? '').trim();
    final location = (user?.location ?? '').trim();

    if (academicLevel.isNotEmpty) {
      badges.add(
        _HeroBadgeData(
          label: academicLevel,
          icon: Icons.workspace_premium_outlined,
          color: SettingsFlowPalette.primary,
        ),
      );
    }
    if (university.isNotEmpty) {
      badges.add(
        _HeroBadgeData(
          label: university,
          icon: Icons.school_outlined,
          color: SettingsFlowPalette.secondary,
        ),
      );
    }
    if (fieldOfStudy.isNotEmpty) {
      badges.add(
        _HeroBadgeData(
          label: fieldOfStudy,
          icon: Icons.auto_stories_outlined,
          color: SettingsFlowPalette.accent,
        ),
      );
    }
    if (location.isNotEmpty) {
      badges.add(
        _HeroBadgeData(
          label: location,
          icon: Icons.location_on_outlined,
          color: SettingsFlowPalette.textSecondary,
        ),
      );
    }

    return badges.take(4).toList(growable: false);
  }

  List<_ProfileFactData> _buildProfileFacts(UserModel? user) {
    final email = (user?.email ?? '').trim();
    final phone = (user?.phone ?? '').trim();
    final location = (user?.location ?? '').trim();
    final academicLevel = (user?.academicLevel ?? '').trim();
    final university = (user?.university ?? '').trim();
    final fieldOfStudy = (user?.fieldOfStudy ?? '').trim();

    return [
      _ProfileFactData(
        label: 'Email',
        value: email.isNotEmpty ? email : 'Add your email',
        icon: Icons.alternate_email_rounded,
        color: SettingsFlowPalette.primary,
        isFilled: email.isNotEmpty,
      ),
      _ProfileFactData(
        label: 'Phone',
        value: phone.isNotEmpty ? phone : 'Add your phone number',
        icon: Icons.phone_outlined,
        color: SettingsFlowPalette.secondary,
        isFilled: phone.isNotEmpty,
      ),
      _ProfileFactData(
        label: 'Location',
        value: location.isNotEmpty ? location : 'Add your location',
        icon: Icons.location_on_outlined,
        color: SettingsFlowPalette.accent,
        isFilled: location.isNotEmpty,
      ),
      _ProfileFactData(
        label: 'Academic Level',
        value: academicLevel.isNotEmpty
            ? academicLevel
            : 'Add your academic level',
        icon: Icons.layers_outlined,
        color: SettingsFlowPalette.primaryDark,
        isFilled: academicLevel.isNotEmpty,
      ),
      _ProfileFactData(
        label: 'University',
        value: university.isNotEmpty ? university : 'Add your university',
        icon: Icons.school_outlined,
        color: SettingsFlowPalette.secondary,
        isFilled: university.isNotEmpty,
      ),
      _ProfileFactData(
        label: 'Field of Study',
        value: fieldOfStudy.isNotEmpty
            ? fieldOfStudy
            : 'Add your field of study',
        icon: Icons.menu_book_outlined,
        color: SettingsFlowPalette.accent,
        isFilled: fieldOfStudy.isNotEmpty,
      ),
    ];
  }
}

class _ProfileTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final ValueChanged<_ProfileMenuAction> onMenuSelected;

  const _ProfileTopBar({required this.onBack, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolbarButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Profile', style: SettingsFlowTheme.appBarTitle()),
        ),
        PopupMenuButton<_ProfileMenuAction>(
          onSelected: onMenuSelected,
          color: SettingsFlowPalette.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: SettingsFlowTheme.radius(18),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _ProfileMenuAction.refresh,
              child: Text('Refresh'),
            ),
            PopupMenuItem(
              value: _ProfileMenuAction.notifications,
              child: Text('Notifications'),
            ),
            PopupMenuItem(
              value: _ProfileMenuAction.logout,
              child: Text('Logout'),
            ),
          ],
          child: const _ToolbarButton(icon: Icons.more_horiz_rounded),
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final UserModel? user;
  final String name;
  final String headline;
  final String email;
  final String bio;
  final double completion;
  final List<_HeroBadgeData> badges;
  final VoidCallback onEdit;
  final VoidCallback onOpenCv;

  const _ProfileHeroCard({
    required this.user,
    required this.name,
    required this.headline,
    required this.email,
    required this.bio,
    required this.completion,
    required this.badges,
    required this.onEdit,
    required this.onOpenCv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6F3FF), Color(0xFFF1FFFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: SettingsFlowTheme.radius(30),
        border: Border.all(color: SettingsFlowPalette.border),
        boxShadow: SettingsFlowTheme.softShadow(0.08),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -18,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: -22,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: SettingsFlowPalette.secondary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EyebrowChip(
                    label: 'Student profile',
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: SettingsFlowTheme.heroTitle().copyWith(
                      fontSize: compact ? 25 : 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    headline,
                    style: SettingsFlowTheme.body(
                      SettingsFlowPalette.textSecondary,
                    ).copyWith(height: 1.45),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: SettingsFlowTheme.caption(
                        SettingsFlowPalette.primaryDark.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: SettingsFlowTheme.radius(20),
                      border: Border.all(
                        color: SettingsFlowPalette.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    child: Text(
                      bio,
                      style: SettingsFlowTheme.caption(
                        SettingsFlowPalette.textPrimary,
                      ).copyWith(fontSize: 12.3),
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges
                          .map((badge) => _HeroBadgeChip(data: badge))
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroActionButton(
                        label: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        filled: true,
                        onTap: onEdit,
                      ),
                      _HeroActionButton(
                        label: 'Open CV',
                        icon: Icons.description_outlined,
                        onTap: onOpenCv,
                      ),
                    ],
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _HeroAvatarPanel(
                        user: user,
                        completion: completion,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 16),
                  _HeroAvatarPanel(user: user, completion: completion),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroAvatarPanel extends StatelessWidget {
  final UserModel? user;
  final double completion;

  const _HeroAvatarPanel({required this.user, required this.completion});

  @override
  Widget build(BuildContext context) {
    final progressColor = completion >= 0.85
        ? SettingsFlowPalette.success
        : SettingsFlowPalette.primary;

    return Container(
      width: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: SettingsFlowTheme.radius(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: SettingsFlowTheme.softShadow(0.05),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0F4FF), Color(0xFFE6FFFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: SettingsFlowTheme.radius(28),
                ),
                child: Center(child: ProfileAvatar(user: user, radius: 34)),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: progressColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(completion * 100).round()}% ready',
            style: SettingsFlowTheme.cardTitle(progressColor),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 7,
              backgroundColor: SettingsFlowPalette.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completion >= 0.85
                ? 'Sharp and ready for new opportunities.'
                : 'A few small updates will make it even stronger.',
            style: SettingsFlowTheme.caption(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(24),
      child: Ink(
        height: 122,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: SettingsFlowTheme.radius(24),
          boxShadow: SettingsFlowTheme.softShadow(0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: SettingsFlowTheme.radius(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Icon(
                  Icons.north_east_rounded,
                  color: Colors.white.withValues(alpha: 0.86),
                  size: 16,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: SettingsFlowTheme.heroTitle(
                Colors.white,
              ).copyWith(fontSize: 23),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: SettingsFlowTheme.body(
                Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SettingsFlowTheme.caption(
                Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedBreakdownPanel extends StatelessWidget {
  final int totalCount;
  final List<_SavedCategoryData> categories;
  final VoidCallback onOpenSaved;

  const _SavedBreakdownPanel({
    required this.totalCount,
    required this.categories,
    required this.onOpenSaved,
  });

  @override
  Widget build(BuildContext context) {
    final activeCategories = categories.where((item) => item.count > 0).length;
    final summary = totalCount == 0
        ? 'Save jobs, scholarships, resources, or ideas to see them here.'
        : activeCategories <= 1
        ? 'Your saved list is focused and easy to manage.'
        : 'Your saved list is spread across $activeCategories categories.';

    return SettingsPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Library',
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCount == 0
                          ? 'Nothing saved yet, but the space is ready.'
                          : 'Everything you bookmarked stays one tap away.',
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenSaved,
                style: TextButton.styleFrom(
                  foregroundColor: SettingsFlowPalette.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final split = constraints.maxWidth >= 360;
              final tileWidth = split
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories
                    .map(
                      (item) => SizedBox(
                        width: tileWidth,
                        child: _SavedCategoryCard(data: item),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpenSaved,
            borderRadius: SettingsFlowTheme.radius(20),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SettingsFlowPalette.mintTint,
                borderRadius: SettingsFlowTheme.radius(20),
                border: Border.all(
                  color: SettingsFlowPalette.secondary.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: SettingsFlowPalette.secondary.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: SettingsFlowTheme.radius(14),
                    ),
                    child: const Icon(
                      Icons.bookmark_added_outlined,
                      color: SettingsFlowPalette.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary,
                      style: SettingsFlowTheme.caption(
                        SettingsFlowPalette.textPrimary,
                      ).copyWith(fontSize: 12.2),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: SettingsFlowPalette.textSecondary.withValues(
                      alpha: 0.6,
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

class _SavedCategoryCard extends StatelessWidget {
  final _SavedCategoryData data;

  const _SavedCategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.08),
        borderRadius: SettingsFlowTheme.radius(20),
        border: Border.all(color: data.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          SettingsIconBox(
            icon: data.icon,
            color: data.color,
            size: 17,
            backgroundColor: Colors.white.withValues(alpha: 0.72),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: SettingsFlowTheme.micro(
                    SettingsFlowPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.count}',
                  style: SettingsFlowTheme.cardTitle(
                    SettingsFlowPalette.textPrimary,
                  ).copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailsPanel extends StatelessWidget {
  final double completion;
  final String bio;
  final bool hasBio;
  final List<String> missingItems;
  final List<_ProfileFactData> facts;

  const _ProfileDetailsPanel({
    required this.completion,
    required this.bio,
    required this.hasBio,
    required this.missingItems,
    required this.facts,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = completion >= 0.85
        ? SettingsFlowPalette.success
        : SettingsFlowPalette.primary;

    return SettingsPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Details',
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Small details make your profile feel sharper and more trustworthy.',
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: '${(completion * 100).round()}% ready',
                color: progressColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: SettingsFlowPalette.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (missingItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingItems
                  .take(4)
                  .map((item) => _MissingItemChip(label: item))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasBio
                  ? SettingsFlowPalette.surfaceTint
                  : const Color(0xFFFFF7ED),
              borderRadius: SettingsFlowTheme.radius(20),
              border: Border.all(
                color: hasBio
                    ? SettingsFlowPalette.primary.withValues(alpha: 0.10)
                    : SettingsFlowPalette.accent.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SettingsIconBox(
                      icon: hasBio
                          ? Icons.auto_awesome_outlined
                          : Icons.edit_note_rounded,
                      color: hasBio
                          ? SettingsFlowPalette.primary
                          : SettingsFlowPalette.accent,
                      size: 17,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasBio ? 'About You' : 'Add a short bio',
                        style: SettingsFlowTheme.cardTitle(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: hasBio
                      ? SettingsFlowTheme.body(
                          SettingsFlowPalette.textSecondary,
                        ).copyWith(height: 1.5)
                      : SettingsFlowTheme.caption(
                          SettingsFlowPalette.textPrimary,
                        ).copyWith(fontSize: 12.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final split = constraints.maxWidth >= 360;
              final tileWidth = split
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: facts
                    .map(
                      (fact) => SizedBox(
                        width: tileWidth,
                        child: _ProfileFactCard(data: fact),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileFactCard extends StatelessWidget {
  final _ProfileFactData data;

  const _ProfileFactCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = data.isFilled
        ? Colors.white
        : SettingsFlowPalette.background;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: SettingsFlowTheme.radius(20),
        border: Border.all(
          color: data.isFilled
              ? data.color.withValues(alpha: 0.14)
              : SettingsFlowPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingsIconBox(
                icon: data.icon,
                color: data.color,
                size: 16,
                backgroundColor: data.color.withValues(alpha: 0.10),
              ),
              const Spacer(),
              if (!data.isFilled)
                _StatusPill(
                  label: 'Add',
                  color: SettingsFlowPalette.textSecondary,
                  subtle: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            style: SettingsFlowTheme.micro(SettingsFlowPalette.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SettingsFlowTheme.body(
              data.isFilled
                  ? SettingsFlowPalette.textPrimary
                  : SettingsFlowPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  final int unreadNotifications;
  final String cvSubtitle;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenCv;
  final VoidCallback onNotifications;
  final VoidCallback onOpenSettings;

  const _QuickActionsPanel({
    required this.unreadNotifications,
    required this.cvSubtitle,
    required this.onEditProfile,
    required this.onOpenCv,
    required this.onNotifications,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: SettingsFlowTheme.sectionTitle()),
          const SizedBox(height: 4),
          Text(
            'Fast shortcuts for the things you use most.',
            style: SettingsFlowTheme.caption(),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.24,
                children: [
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    color: SettingsFlowPalette.primary,
                    title: 'Edit Profile',
                    subtitle: 'Refresh your photo, bio, and details.',
                    onTap: onEditProfile,
                  ),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    color: SettingsFlowPalette.secondary,
                    title: 'CV Builder',
                    subtitle: cvSubtitle,
                    onTap: onOpenCv,
                  ),
                  _ActionTile(
                    icon: Icons.notifications_none_rounded,
                    color: SettingsFlowPalette.accent,
                    title: 'Notifications',
                    subtitle: unreadNotifications > 0
                        ? '$unreadNotifications unread updates waiting.'
                        : 'Everything important in one calm place.',
                    onTap: onNotifications,
                    showAlertDot: unreadNotifications > 0,
                  ),
                  _ActionTile(
                    icon: Icons.tune_rounded,
                    color: SettingsFlowPalette.primaryDark,
                    title: 'Settings',
                    subtitle: 'Privacy, preferences, and controls.',
                    onTap: onOpenSettings,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showAlertDot;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showAlertDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: SettingsFlowTheme.radius(22),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SettingsIconBox(
                      icon: icon,
                      color: color,
                      size: 17,
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                    ),
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
                Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: SettingsFlowPalette.textSecondary.withValues(
                    alpha: 0.55,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: SettingsFlowTheme.cardTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: SettingsFlowTheme.caption(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  final VoidCallback onSecurity;
  final VoidCallback onHelp;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const _AccountPanel({
    required this.onSecurity,
    required this.onHelp,
    required this.onAbout,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: SettingsFlowTheme.sectionTitle()),
          const SizedBox(height: 4),
          Text(
            'Security, support, and app info in one clean section.',
            style: SettingsFlowTheme.caption(),
          ),
          const SizedBox(height: 12),
          SettingsListRow(
            icon: Icons.lock_outline_rounded,
            iconColor: SettingsFlowPalette.primary,
            title: 'Security & Privacy',
            subtitle: 'Password, account safety, and privacy controls.',
            onTap: onSecurity,
          ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.help_outline_rounded,
            iconColor: SettingsFlowPalette.secondary,
            title: 'Help Center',
            subtitle: 'Get answers and support when you need it.',
            onTap: onHelp,
          ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.info_outline_rounded,
            iconColor: SettingsFlowPalette.accent,
            title: 'About AvenirDZ',
            subtitle: 'See what the app is built for and where it is going.',
            onTap: onAbout,
          ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.logout_rounded,
            iconColor: SettingsFlowPalette.error,
            title: 'Logout',
            subtitle: 'Sign out of this account safely.',
            destructive: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = filled
        ? Colors.transparent
        : SettingsFlowPalette.primary.withValues(alpha: 0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SettingsFlowTheme.radius(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: filled
                ? SettingsFlowPalette.primary
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: SettingsFlowTheme.radius(18),
            border: Border.all(color: borderColor),
            boxShadow: filled ? SettingsFlowTheme.softShadow(0.05) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled ? Colors.white : SettingsFlowPalette.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: SettingsFlowTheme.body(
                  filled ? Colors.white : SettingsFlowPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadgeChip extends StatelessWidget {
  final _HeroBadgeData data;

  const _HeroBadgeChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.09),
        borderRadius: SettingsFlowTheme.radius(999),
        border: Border.all(color: data.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: data.color),
          const SizedBox(width: 6),
          Text(data.label, style: SettingsFlowTheme.micro(data.color)),
        ],
      ),
    );
  }
}

class _EyebrowChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _EyebrowChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.surfaceTint,
        borderRadius: SettingsFlowTheme.radius(999),
        border: Border.all(
          color: SettingsFlowPalette.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SettingsFlowPalette.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: SettingsFlowTheme.micro(SettingsFlowPalette.primary),
          ),
        ],
      ),
    );
  }
}

class _MissingItemChip extends StatelessWidget {
  final String label;

  const _MissingItemChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.background,
        borderRadius: SettingsFlowTheme.radius(999),
        border: Border.all(color: SettingsFlowPalette.border),
      ),
      child: Text(
        label,
        style: SettingsFlowTheme.micro(SettingsFlowPalette.textSecondary),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;

  const _StatusPill({
    required this.label,
    required this.color,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: subtle
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.12),
        borderRadius: SettingsFlowTheme.radius(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(label, style: SettingsFlowTheme.micro(color)),
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

class _HeroBadgeData {
  final String label;
  final IconData icon;
  final Color color;

  const _HeroBadgeData({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _ProfileFactData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFilled;

  const _ProfileFactData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isFilled,
  });
}

class _SavedCategoryData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _SavedCategoryData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

enum _ProfileMenuAction { refresh, notifications, logout }
