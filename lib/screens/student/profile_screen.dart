import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
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
import '../../providers/subscription_provider.dart';
import 'premium_pass_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/settings/about_futuregate_screen.dart';
import '../../screens/settings/help_center_screen.dart';
import '../../screens/settings/logout_confirmation_sheet.dart';
import '../../screens/settings/security_privacy_screen.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/display_text.dart';
import '../../utils/student_profile_completion.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_directional.dart';
import 'applied_opportunities_screen.dart';
import 'cv_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_screen.dart';

// =============================================================================
// SCREEN
// =============================================================================

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
    if (!mounted) return;
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

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
    AppColors.of(context);

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
    if (currentUser == null) {
      final placeholder = Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.uiNotSignedIn,
            style: AppTypography.product(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SettingsFlowPalette.textSecondary,
            ),
          ),
        ),
      );

      if (widget.embedded) {
        return placeholder;
      }

      return AppShellBackground(child: placeholder);
    }

    final student = studentProvider.student ?? currentUser;
    final cv = cvProvider.cv;

    final savedCount =
        savedProvider.savedOpportunities.length +
        savedScholarshipProvider.savedScholarships.length +
        trainingProvider.savedTrainings.length +
        savedIdeasProvider.savedIdeas.length;

    final appliedCount = applicationsProvider.submittedApplicationsCount;
    final completion = _profileCompletion(student, cv);
    final missingItems = _missingItems(student, cv);
    final completionTitle = _completionTitle(completion);
    final completionMessage = _completionMessage(completion, missingItems);
    final focusItem = _focusItem(missingItems);
    final hasBio = (student.bio ?? '').trim().isNotEmpty;
    final displayName = _resolveDisplayName(student);
    final headline = _resolveHeadline(student, cv);
    final bio = hasBio ? student.bio!.trim() : null;
    final unread = notificationProvider.unreadCount;

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.current.onPrimary,
        backgroundColor: AppColors.current.primaryDeep,
        onRefresh: _loadProfileData,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            // ── Header ──────────────────────────────────────────────────
            _ProfileHeader(
              embedded: widget.embedded,
              user: student,
              name: displayName,
              headline: headline,
              bio: bio,
              badges: _buildHeroBadges(student),
              completion: completion,
              completionTitle: completionTitle,
              completionMessage: completionMessage,
              savedCount: savedCount,
              appliedCount: appliedCount,
              cvStatus: _cvStatus(cv),
              unreadNotifications: unread,
              onBack: () => Navigator.maybePop(context),
              onEdit: () => _push(const EditProfileScreen()),
              onCv: () => _push(const CvScreen()),
              onSaved: () => _push(const SavedScreen()),
              onApplied: () => _push(const AppliedOpportunitiesScreen()),
              onNotifications: () => _push(const NotificationsScreen()),
            ),

            // ── Body ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 960;

                  // ── Activity strip ───────────────────────────────────
                  final _ = _ActivityStrip(
                    completion: completion,
                    completionTitle: completionTitle,
                    completionMessage: completionMessage,
                    missingItems: missingItems,
                    focusItem: focusItem,
                    focusMessage: _focusMessage(focusItem),
                    onEdit: () => _push(const EditProfileScreen()),
                    onCv: () => _push(const CvScreen()),
                  );

                  // ── Profile details ──────────────────────────────────
                  final detailsCard = _DetailsCard(
                    bio: bio,
                    facts: _buildFacts(student),
                    onEdit: () => _push(const EditProfileScreen()),
                  );

                  // ── Quick links ──────────────────────────────────────
                  final linksCard = _LinksCard(
                    appliedCount: appliedCount,
                    savedCount: savedCount,
                    unreadNotifications: unread,
                    onCv: () => _push(const CvScreen()),
                    onSaved: () => _push(const SavedScreen()),
                    onApplied: () => _push(const AppliedOpportunitiesScreen()),
                    onNotifications: () => _push(const NotificationsScreen()),
                    onSettings: () => _push(const SettingsScreen()),
                    onSecurity: () => _push(const SecurityPrivacyScreen()),
                    onHelp: () => _push(const HelpCenterScreen()),
                    onAbout: () => _push(const AboutFutureGateScreen()),
                    onLogout: () => showLogoutConfirmationSheet(context),
                    onPremium: () => _push(const PremiumPassScreen()),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: detailsCard),
                        const SizedBox(width: 14),
                        Expanded(flex: 5, child: linksCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      detailsCard,
                      const SizedBox(height: 14),
                      linksCard,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) return scaffold;
    return AppShellBackground(child: scaffold);
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _resolveDisplayName(UserModel? user) {
    final fullName = (user?.fullName ?? '').trim();
    if (fullName.isNotEmpty) return fullName;
    final email = (user?.email ?? '').trim();
    if (email.contains('@')) return email.split('@').first;
    return AppLocalizations.of(context)!.uiStudent;
  }

  String _resolveHeadline(UserModel? user, CvModel? cv) {
    final fieldOfStudy = _displayProfileValue(user?.fieldOfStudy);
    final university = _displayProfileValue(user?.university);
    final academicLevel = _displayProfileValue(user?.academicLevel);

    if (fieldOfStudy.isNotEmpty && university.isNotEmpty) {
      return '$fieldOfStudy at $university';
    }
    if (fieldOfStudy.isNotEmpty && academicLevel.isNotEmpty) {
      return '$fieldOfStudy · $academicLevel';
    }
    if (fieldOfStudy.isNotEmpty) return fieldOfStudy;
    if (university.isNotEmpty) return university;
    if (academicLevel.isNotEmpty) return academicLevel;
    return AppLocalizations.of(context)!.studentProfileSubtitleFallback;
  }

  String _displayProfileValue(String? value) {
    return DisplayText.capitalizeDisplayValue(value?.trim() ?? '');
  }

  String _cvStatus(CvModel? cv) {
    final l10n = AppLocalizations.of(context)!;
    if (cv == null) return l10n.studentNotStarted;
    if (cv.hasUploadedCv || cv.hasExportedPdf) return l10n.studentReady;
    if (cv.hasBuilderContent) return l10n.studentDraft;
    return l10n.studentNotStarted;
  }

  double _profileCompletion(UserModel? user, CvModel? cv) {
    return buildStudentProfileCompletionSummary(user, cv).completion;
  }

  List<String> _missingItems(UserModel? user, CvModel? cv) {
    return buildStudentProfileCompletionSummary(user, cv).missingItems;
  }

  String _completionTitle(double completion) {
    final l10n = AppLocalizations.of(context)!;
    if (completion >= 0.95) return l10n.studentProfileHeadlineReady;
    if (completion >= 0.75) return l10n.studentProfileHeadlineNearly;
    if (completion >= 0.45) return l10n.studentProfileHeadlineFoundation;
    return l10n.studentProfileHeadlineCatchUp;
  }

  String _completionMessage(double completion, List<String> missingItems) {
    final l10n = AppLocalizations.of(context)!;
    if (missingItems.isEmpty) {
      return l10n.studentProfileCompleteSummary;
    }

    final suffix = l10n.studentProfileDetailsMissingCount(missingItems.length);

    if (completion >= 0.75) {
      return l10n.studentProfileThoughtfulUpdates(suffix);
    }
    if (completion >= 0.45) {
      return l10n.studentProfileCoreStory(suffix);
    }
    return l10n.studentProfileRoomToGrow(suffix);
  }

  String? _focusItem(List<String> missingItems) {
    const priority = <String>[
      'CV',
      'Bio',
      'Field of study',
      'University',
      'Academic level',
      'Full name',
      'Email',
      'Location',
      'Phone',
    ];

    for (final item in priority) {
      if (missingItems.contains(item)) return item;
    }

    if (missingItems.isEmpty) return null;
    return missingItems.first;
  }

  String _focusMessage(String? item) {
    final l10n = AppLocalizations.of(context)!;
    switch (item) {
      case 'CV':
        return l10n.studentCvProfileHint;
      case 'Bio':
        return l10n.studentBioProfileHint;
      case 'Field of study':
        return l10n.studentFieldOfStudyProfileHint;
      case 'University':
        return l10n.studentUniversityProfileHint;
      case 'Academic level':
        return l10n.studentAcademicLevelProfileHint;
      case 'Full name':
        return l10n.studentFullNameProfileHint;
      case 'Email':
        return l10n.studentEmailProfileHint;
      case 'Location':
        return l10n.studentLocationProfileHint;
      case 'Phone':
        return l10n.studentPhoneProfileHint;
      default:
        return l10n.studentProfileKeepRefining;
    }
  }

  List<_HeroBadgeData> _buildHeroBadges(UserModel? user) {
    final badges = <_HeroBadgeData>[];
    final isPremium = context.watch<SubscriptionProvider>().hasActivePremium;
    if (isPremium) {
      badges.add(
        _HeroBadgeData(
          label: AppLocalizations.of(context)!.premiumBadgeLabel,
          icon: Icons.workspace_premium_rounded,
          color: AppColors.of(context).accent,
          premium: true,
        ),
      );
    }
    return badges;
  }

  List<_FactData> _buildFacts(UserModel? user) {
    final email = (user?.email ?? '').trim();
    final phone = (user?.phone ?? '').trim();
    final location = _displayProfileValue(user?.location);
    final academicLevel = _displayProfileValue(user?.academicLevel);
    final university = _displayProfileValue(user?.university);
    final fieldOfStudy = _displayProfileValue(user?.fieldOfStudy);

    return [
      _FactData(
        label: AppLocalizations.of(context)!.uiEmail,
        value: email.isNotEmpty ? email : null,
        icon: Icons.alternate_email_rounded,
        color: SettingsFlowPalette.primary,
      ),
      _FactData(
        label: AppLocalizations.of(context)!.uiPhone,
        value: phone.isNotEmpty ? phone : null,
        icon: Icons.phone_outlined,
        color: SettingsFlowPalette.secondary,
      ),
      _FactData(
        label: AppLocalizations.of(context)!.uiLocation,
        value: location.isNotEmpty ? location : null,
        icon: Icons.location_on_outlined,
        color: SettingsFlowPalette.accent,
      ),
      _FactData(
        label: AppLocalizations.of(context)!.uiAcademicLevel80Cc,
        value: academicLevel.isNotEmpty ? academicLevel : null,
        icon: Icons.layers_outlined,
        color: SettingsFlowPalette.primaryDark,
      ),
      _FactData(
        label: AppLocalizations.of(context)!.uiUniversity,
        value: university.isNotEmpty ? university : null,
        icon: Icons.school_outlined,
        color: SettingsFlowPalette.secondary,
      ),
      _FactData(
        label: AppLocalizations.of(context)!.uiFieldOfStudy,
        value: fieldOfStudy.isNotEmpty ? fieldOfStudy : null,
        icon: Icons.menu_book_outlined,
        color: SettingsFlowPalette.accent,
      ),
    ];
  }
}

// =============================================================================
// 1. PROFILE HEADER
//    Avatar with progress ring, name, headline, bio, single edit button.
//    No badges, no email pill, no CV button — those live in the body.
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  final bool embedded;
  final UserModel? user;
  final String name;
  final String headline;
  final String? bio;
  final List<_HeroBadgeData> badges;
  final double completion;
  final String completionTitle;
  final String completionMessage;
  final int savedCount;
  final int appliedCount;
  final String cvStatus;
  final int unreadNotifications;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onCv;
  final VoidCallback onSaved;
  final VoidCallback onApplied;
  final VoidCallback onNotifications;

  const _ProfileHeader({
    required this.embedded,
    required this.user,
    required this.name,
    required this.headline,
    required this.bio,
    required this.badges,
    required this.completion,
    required this.completionTitle,
    required this.completionMessage,
    required this.savedCount,
    required this.appliedCount,
    required this.cvStatus,
    required this.unreadNotifications,
    required this.onBack,
    required this.onEdit,
    required this.onCv,
    required this.onSaved,
    required this.onApplied,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF08101E),
            SettingsFlowPalette.primaryDark,
            SettingsFlowPalette.primary,
            SettingsFlowPalette.secondary.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            top: -62,
            right: -42,
            child: _Orb(158, Colors.white.withValues(alpha: 0.09)),
          ),
          Positioned(
            top: 80,
            right: 36,
            child: _Orb(56, SettingsFlowPalette.accent.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -54,
            left: -28,
            child: _Orb(
              126,
              SettingsFlowPalette.secondary.withValues(alpha: 0.14),
            ),
          ),
          SafeArea(
            top: !embedded,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, embedded ? 14 : 8, 18, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final alignment = wide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center;

                  final identityPanel = Column(
                    crossAxisAlignment: alignment,
                    children: [
                      _AvatarRing(user: user, completion: completion),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: wide ? TextAlign.start : TextAlign.center,
                        style: AppTypography.product(
                          fontSize: wide ? 26 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        headline,
                        textAlign: wide ? TextAlign.start : TextAlign.center,
                        style: AppTypography.product(
                          fontSize: 12.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.45,
                        ),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: wide
                              ? WrapAlignment.start
                              : WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: badges
                              .map(
                                (badge) => badge.premium
                                    ? const PremiumBadge(
                                        size: PremiumBadgeSize.medium,
                                      )
                                    : _HeroBadge(
                                        label: badge.label,
                                        icon: badge.icon,
                                        color: badge.color,
                                      ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: alignment,
                          children: [
                            Row(
                              mainAxisSize: wide
                                  ? MainAxisSize.max
                                  : MainAxisSize.min,
                              mainAxisAlignment: wide
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: [
                                Icon(
                                  bio == null
                                      ? Icons.auto_awesome_rounded
                                      : Icons.notes_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    bio == null
                                        ? AppLocalizations.of(
                                            context,
                                          )!.studentProfileTip
                                        : AppLocalizations.of(
                                            context,
                                          )!.studentAboutYou,
                                    style: AppTypography.product(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              bio ??
                                  AppLocalizations.of(
                                    context,
                                  )!.studentBioHelpText,
                              textAlign: wide
                                  ? TextAlign.start
                                  : TextAlign.center,
                              maxLines: bio == null ? 3 : 4,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 11.8,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(
                                  alpha: bio == null ? 0.76 : 0.88,
                                ),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: wide
                            ? Alignment.centerLeft
                            : Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: wide ? 320 : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeaderButton(
                                label: AppLocalizations.of(
                                  context,
                                )!.uiEditProfile,
                                icon: Icons.edit_outlined,
                                onTap: onEdit,
                                filled: true,
                              ),
                              const SizedBox(height: 10),
                              _HeaderButton(
                                label: AppLocalizations.of(
                                  context,
                                )!.uiOpenCvStudio,
                                icon: Icons.description_outlined,
                                onTap: onCv,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );

                  final statusPanel = _HeroStatusCard(
                    completion: completion,
                    completionTitle: completionTitle,
                    completionMessage: completionMessage,
                    savedCount: savedCount,
                    appliedCount: appliedCount,
                    cvStatus: cvStatus,
                    unreadNotifications: unreadNotifications,
                    onSaved: onSaved,
                    onApplied: onApplied,
                    onCv: onCv,
                    onNotifications: onNotifications,
                  );

                  return Column(
                    children: [
                      if (!embedded) ...[
                        _buildTopBar(context),
                        const SizedBox(height: 14),
                      ],
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: identityPanel),
                            const SizedBox(width: 18),
                            Expanded(flex: 5, child: statusPanel),
                          ],
                        )
                      else ...[
                        identityPanel,
                        const SizedBox(height: 18),
                        statusPanel,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _FrostedCircle(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const Spacer(),
        Text(
          AppLocalizations.of(context)!.uiProfile,
          style: AppTypography.product(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const Spacer(),
        // Invisible matching spacer to keep title centered
        const SizedBox(width: 42),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _FrostedCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _FrostedCircle({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: AppDirectionalIcon(
          icon,
          color: Colors.white.withValues(alpha: 0.85),
          size: 18,
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final UserModel? user;
  final double completion;

  const _AvatarRing({required this.user, required this.completion});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<SubscriptionProvider>().hasActivePremium;
    final ringColor = completion >= 0.85
        ? SettingsFlowPalette.success
        : isPremium
        ? const Color(0xFFF6C453)
        : Colors.white;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: CustomPaint(
              painter: _RingPainter(
                progress: completion,
                trackColor: Colors.white.withValues(alpha: 0.12),
                progressColor: ringColor,
              ),
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ProfileAvatar(user: user, radius: 39, isPremium: isPremium),
          ),
          // Student badge for non-premium profiles.
          if (!isPremium)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? SettingsFlowPalette.primaryDark : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: AppInlineIconLabel(
            icon: icon,
            iconSize: 16,
            iconColor: foreground,
            gap: 8,
            label: Text(
              label,
              style: AppTypography.product(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeroBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  final double completion;
  final String completionTitle;
  final String completionMessage;
  final int savedCount;
  final int appliedCount;
  final String cvStatus;
  final int unreadNotifications;
  final VoidCallback onSaved;
  final VoidCallback onApplied;
  final VoidCallback onCv;
  final VoidCallback onNotifications;

  const _HeroStatusCard({
    required this.completion,
    required this.completionTitle,
    required this.completionMessage,
    required this.savedCount,
    required this.appliedCount,
    required this.cvStatus,
    required this.unreadNotifications,
    required this.onSaved,
    required this.onApplied,
    required this.onCv,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (completion * 100).round();
    final progressColor = completion >= 0.85
        ? SettingsFlowPalette.success
        : SettingsFlowPalette.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDark
              ? [
                  AppColors.current.surfaceElevated,
                  AppColors.current.surfaceMuted,
                  Color.alphaBlend(
                    SettingsFlowPalette.secondary.withValues(alpha: 0.10),
                    AppColors.current.surface,
                  ),
                ]
              : [
                  const Color(0xFFF9FBFF),
                  SettingsFlowPalette.surfaceTint,
                  SettingsFlowPalette.mintTint,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SettingsFlowPalette.border.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: SettingsFlowPalette.primaryDark.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionChip(
                icon: Icons.insights_outlined,
                label: AppLocalizations.of(context)!.uiProfileStrength,
                color: SettingsFlowPalette.secondary,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent%',
                  style: AppTypography.product(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SettingsFlowPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            completionTitle,
            style: AppTypography.product(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SettingsFlowPalette.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completionMessage,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 11.8,
              fontWeight: FontWeight.w500,
              color: SettingsFlowPalette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 7,
              backgroundColor: SettingsFlowPalette.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _HeroMetricTile(
                      value: '$savedCount',
                      label: AppLocalizations.of(context)!.uiSaved,
                      icon: Icons.bookmark_outline_rounded,
                      color: SettingsFlowPalette.secondary,
                      onTap: onSaved,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HeroMetricTile(
                      value: '$appliedCount',
                      label: AppLocalizations.of(context)!.uiApplied,
                      icon: Icons.send_rounded,
                      color: SettingsFlowPalette.accent,
                      onTap: onApplied,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HeroMetricTile(
                      value: cvStatus,
                      label: AppLocalizations.of(context)!.uiCvStudio,
                      icon: Icons.description_outlined,
                      color: cvStatus == 'Ready'
                          ? SettingsFlowPalette.success
                          : SettingsFlowPalette.primary,
                      onTap: onCv,
                      compactValue: true,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HeroMetricTile(
                      value: unreadNotifications > 0
                          ? AppLocalizations.of(
                              context,
                            )!.studentProfileUnreadNotificationsCount(
                              unreadNotifications,
                            )
                          : AppLocalizations.of(context)!.studentAllClear,
                      label: AppLocalizations.of(context)!.uiAlerts,
                      icon: Icons.notifications_none_rounded,
                      color: SettingsFlowPalette.primary,
                      onTap: onNotifications,
                      compactValue: true,
                    ),
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

class _HeroMetricTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compactValue;

  const _HeroMetricTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compactValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.current.surfaceElevated.withValues(
              alpha: AppColors.isDark ? 0.96 : 0.92,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SettingsFlowPalette.border.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.product(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w600,
                        color: SettingsFlowPalette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: compactValue ? 11.5 : 16,
                  fontWeight: FontWeight.w700,
                  color: SettingsFlowPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. ACTIVITY STRIP
//    Four compact tiles: Saved, Applied, Completion %, CV status.
//    Each is one small card. No overlap with anything else.
// =============================================================================

String _localizedProfileFocusItem(BuildContext context, String item) {
  final l10n = AppLocalizations.of(context)!;
  return switch (item) {
    'Bio' => l10n.studentAboutYou,
    'Field of study' => l10n.studentFieldOfStudy,
    'University' => l10n.studentUniversity,
    'Academic level' => l10n.studentAcademicLevel,
    'Full name' => l10n.studentFullName,
    'Email' => l10n.studentEmail,
    'Location' => l10n.studentLocation,
    'Phone' => l10n.studentPhone,
    _ => item,
  };
}

class _ActivityStrip extends StatelessWidget {
  final double completion;
  final String completionTitle;
  final String completionMessage;
  final List<String> missingItems;
  final String? focusItem;
  final String focusMessage;
  final VoidCallback onEdit;
  final VoidCallback onCv;

  const _ActivityStrip({
    required this.completion,
    required this.completionTitle,
    required this.completionMessage,
    required this.missingItems,
    required this.focusItem,
    required this.focusMessage,
    required this.onEdit,
    required this.onCv,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completion * 100).round();
    final completed = missingItems.isEmpty;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.uiProfileCompletion,
                style: AppTypography.product(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SettingsFlowPalette.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct%',
                  style: AppTypography.product(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SettingsFlowPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            completionTitle,
            style: AppTypography.product(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SettingsFlowPalette.textPrimary,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completionMessage,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 11.8,
              fontWeight: FontWeight.w500,
              color: SettingsFlowPalette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SettingsFlowPalette.primary.withValues(alpha: 0.08),
                  SettingsFlowPalette.secondary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: SettingsFlowPalette.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      completed
                          ? AppLocalizations.of(
                              context,
                            )!.studentEverythingImportantFilled
                          : AppLocalizations.of(
                              context,
                            )!.studentProfileDetailsMissingCount(
                              missingItems.length,
                            ),
                      style: AppTypography.product(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SettingsFlowPalette.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      completed
                          ? AppLocalizations.of(context)!.studentComplete
                          : AppLocalizations.of(context)!.studentInProgress,
                      style: AppTypography.product(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: completed
                            ? SettingsFlowPalette.success
                            : SettingsFlowPalette.accent,
                      ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completed
                          ? SettingsFlowPalette.success
                          : SettingsFlowPalette.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (completed)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SettingsFlowPalette.success.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: SettingsFlowPalette.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.uiTheProfileAlreadyLooksPolishedAQuickRefreshFromTime,
                            style: AppTypography.product(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: SettingsFlowPalette.textPrimary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: missingItems
                        .map((item) => _MissingChip(label: item))
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SettingsFlowPalette.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: SettingsFlowPalette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        (focusItem == null
                                ? SettingsFlowPalette.success
                                : SettingsFlowPalette.accent)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    focusItem == null
                        ? Icons.workspace_premium_outlined
                        : Icons.auto_fix_high_rounded,
                    color: focusItem == null
                        ? SettingsFlowPalette.success
                        : SettingsFlowPalette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        focusItem == null
                            ? AppLocalizations.of(context)!.studentStrongPlace
                            : AppLocalizations.of(
                                context,
                              )!.studentBestNextUpdate(
                                _localizedProfileFocusItem(context, focusItem!),
                              ),
                        style: AppTypography.product(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SettingsFlowPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        focusItem == null
                            ? AppLocalizations.of(
                                context,
                              )!.studentKeepProfileCurrent
                            : focusMessage,
                        style: AppTypography.product(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w500,
                          color: SettingsFlowPalette.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 390;
              final editButton = _SurfaceActionButton(
                label: AppLocalizations.of(context)!.uiEditProfile,
                icon: Icons.edit_outlined,
                filled: true,
                onTap: onEdit,
              );
              final cvButton = _SurfaceActionButton(
                label: AppLocalizations.of(context)!.uiOpenCvStudio,
                icon: Icons.description_outlined,
                onTap: onCv,
              );

              if (stacked) {
                return Column(
                  children: [editButton, const SizedBox(height: 10), cvButton],
                );
              }

              return Row(
                children: [
                  Expanded(child: editButton),
                  const SizedBox(width: 10),
                  Expanded(child: cvButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. PROFILE DETAILS
//    Single card: progress bar, missing-item chips, all fact rows.
//    This is the ONLY place profile fields appear. No duplication.
// =============================================================================

class _DetailsCard extends StatelessWidget {
  final String? bio;
  final List<_FactData> facts;
  final VoidCallback onEdit;

  const _DetailsCard({
    required this.bio,
    required this.facts,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionChip(
                icon: Icons.account_circle_outlined,
                label: AppLocalizations.of(context)!.uiStudentSnapshot,
                color: SettingsFlowPalette.accent,
              ),
              const Spacer(),
              _PillActionButton(
                label: AppLocalizations.of(context)!.uiEdit,
                icon: Icons.edit_outlined,
                color: SettingsFlowPalette.primary,
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(
              context,
            )!.uiTheEssentialsRecruitersAndProgramsOftenScanFirst,
            style: AppTypography.product(
              fontSize: 11.6,
              fontWeight: FontWeight.w500,
              color: SettingsFlowPalette.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SettingsFlowPalette.primary.withValues(alpha: 0.07),
                  SettingsFlowPalette.accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.current.surfaceElevated.withValues(
                          alpha: AppColors.isDark ? 0.96 : 0.88,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        bio == null
                            ? Icons.edit_note_rounded
                            : Icons.format_quote_rounded,
                        color: SettingsFlowPalette.primary,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      bio == null
                          ? AppLocalizations.of(context)!.studentBioStillMissing
                          : AppLocalizations.of(context)!.studentAboutYou,
                      style: AppTypography.product(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                        color: SettingsFlowPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  bio ?? AppLocalizations.of(context)!.studentBioHelpText,
                  style: AppTypography.product(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w500,
                    color: bio == null
                        ? SettingsFlowPalette.textSecondary
                        : SettingsFlowPalette.textPrimary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1040
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (columns - 1) * spacing) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: facts
                    .map(
                      (fact) => SizedBox(
                        width: itemWidth,
                        child: _FactRow(data: fact),
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

class _FactRow extends StatelessWidget {
  final _FactData data;

  const _FactRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final filled = data.value != null;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.current.surfaceElevated.withValues(
                alpha: AppColors.isDark ? 0.96 : 0.94,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 17, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: AppTypography.product(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: SettingsFlowPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  filled
                      ? DisplayText.capitalizeDisplayValue(data.value!)
                      : AppLocalizations.of(context)!.uiNotProvided,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.product(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                        color: filled
                            ? SettingsFlowPalette.textPrimary
                            : SettingsFlowPalette.textSecondary,
                        height: 1.35,
                      ).copyWith(
                        fontStyle: filled ? FontStyle.normal : FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. LINKS CARD
//    Single unified list: CV Studio, Notifications, Settings,
//    Security, Help, About, Logout. No duplicate of anything in the header.
// =============================================================================

class _LinksCard extends StatelessWidget {
  final int appliedCount;
  final int savedCount;
  final int unreadNotifications;
  final VoidCallback onCv;
  final VoidCallback onSaved;
  final VoidCallback onApplied;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onSecurity;
  final VoidCallback onHelp;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final VoidCallback? onPremium;

  const _LinksCard({
    required this.appliedCount,
    required this.savedCount,
    required this.unreadNotifications,
    required this.onCv,
    required this.onSaved,
    required this.onApplied,
    required this.onNotifications,
    required this.onSettings,
    required this.onSecurity,
    required this.onHelp,
    required this.onAbout,
    required this.onLogout,
    this.onPremium,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionChip(
            icon: Icons.dashboard_customize_outlined,
            label: AppLocalizations.of(context)!.uiStudentToolkit,
            color: SettingsFlowPalette.primaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(
              context,
            )!.uiEverythingAroundYourProfileDocumentsNotificationsAndAccountSettings,
            style: AppTypography.product(
              fontSize: 12.8,
              fontWeight: FontWeight.w500,
              color: SettingsFlowPalette.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cvCard = _FeaturedActionCard(
                title: AppLocalizations.of(context)!.uiCvStudio,
                subtitle: AppLocalizations.of(context)!.uiCvStudioSubtitle,
                icon: Icons.description_outlined,
                color: SettingsFlowPalette.secondary,
                onTap: onCv,
              );
              final savedCard = _FeaturedActionCard(
                title: AppLocalizations.of(context)!.uiSavedCollection,
                subtitle: AppLocalizations.of(
                  context,
                )!.studentProfileSavedItemsCount(savedCount),
                icon: Icons.bookmark_outline_rounded,
                color: SettingsFlowPalette.primary,
                onTap: onSaved,
              );
              final appliedCard = _FeaturedActionCard(
                title: AppLocalizations.of(context)!.uiApplied,
                subtitle: AppLocalizations.of(
                  context,
                )!.studentProfileSubmittedOpportunitiesCount(appliedCount),
                icon: Icons.assignment_turned_in_outlined,
                color: SettingsFlowPalette.accent,
                onTap: onApplied,
              );

              final cards = [cvCard, savedCard, appliedCard];
              final columns = constraints.maxWidth >= 720 ? 3 : 1;
              final cardWidth =
                  (constraints.maxWidth - (10 * (columns - 1))) / columns;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cards
                    .map((card) => SizedBox(width: cardWidth, child: card))
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 16),
          _LinkRow(
            icon: Icons.notifications_none_rounded,
            color: SettingsFlowPalette.accent,
            title: AppLocalizations.of(context)!.uiNotifications,
            subtitle: AppLocalizations.of(
              context,
            )!.studentProfileUnreadNotificationsCount(unreadNotifications),
            onTap: onNotifications,
            badge: unreadNotifications > 0 ? '$unreadNotifications' : null,
          ),
          _linkDivider(),
          Consumer<SubscriptionProvider>(
            builder: (context, subProvider, _) => _LinkRow(
              icon: Icons.workspace_premium_rounded,
              color: AppColors.of(context).accent,
              title: AppLocalizations.of(context)!.premiumPassTitle,
              subtitle: subProvider.hasActivePremium
                  ? AppLocalizations.of(context)!.premiumPassActiveTitle
                  : AppLocalizations.of(context)!.premiumPassSubtitle,
              onTap: onPremium ?? () {},
            ),
          ),
          _linkDivider(),
          _LinkRow(
            icon: Icons.tune_rounded,
            color: SettingsFlowPalette.primaryDark,
            title: AppLocalizations.of(context)!.uiSettings,
            subtitle: AppLocalizations.of(context)!.uiSettingsSubtitle,
            onTap: onSettings,
          ),
          _linkDivider(),
          _LinkRow(
            icon: Icons.lock_outline_rounded,
            color: SettingsFlowPalette.primary,
            title: AppLocalizations.of(context)!.uiSecurityPrivacy,
            subtitle: AppLocalizations.of(context)!.uiSecuritySubtitle,
            onTap: onSecurity,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 1,
              color: SettingsFlowPalette.border.withValues(alpha: 0.6),
            ),
          ),
          _LinkRow(
            icon: Icons.help_outline_rounded,
            color: SettingsFlowPalette.secondary,
            title: AppLocalizations.of(context)!.uiHelpCenter,
            subtitle: AppLocalizations.of(context)!.uiHelpCenterSubtitle,
            onTap: onHelp,
          ),
          _linkDivider(),
          _LinkRow(
            icon: Icons.info_outline_rounded,
            color: SettingsFlowPalette.accent,
            title: AppLocalizations.of(context)!.uiAboutFutureGate,
            subtitle: AppLocalizations.of(context)!.uiAboutSubtitle,
            onTap: onAbout,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 1,
              color: SettingsFlowPalette.border.withValues(alpha: 0.6),
            ),
          ),
          _LinkRow(
            icon: Icons.logout_rounded,
            color: SettingsFlowPalette.error,
            title: AppLocalizations.of(context)!.signOutTitle,
            subtitle: AppLocalizations.of(context)!.uiSignOutSubtitle,
            onTap: onLogout,
            destructive: true,
          ),
        ],
      ),
    );
  }

  static Widget _linkDivider() => Divider(
    height: 1,
    thickness: 1,
    indent: 50,
    color: SettingsFlowPalette.border.withValues(alpha: 0.35),
  );
}

class _FeaturedActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeaturedActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.current.surfaceElevated.withValues(
                    alpha: AppColors.isDark ? 0.96 : 0.95,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w700,
                        color: SettingsFlowPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.product(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w500,
                        color: SettingsFlowPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              AppDirectionalIcon(
                Icons.chevron_right_rounded,
                size: 20,
                color: color.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final String? badge;

  const _LinkRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = destructive ? SettingsFlowPalette.error : color;
    final rowPadding = destructive ? 7.0 : 10.0;
    final iconSize = destructive ? 34.0 : 38.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: rowPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: effectiveColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: destructive ? 12.9 : 13.2,
                        fontWeight: FontWeight.w700,
                        color: destructive
                            ? SettingsFlowPalette.error
                            : SettingsFlowPalette.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTypography.product(
                          fontSize: 11.8,
                          fontWeight: FontWeight.w500,
                          color: destructive
                              ? SettingsFlowPalette.error.withValues(
                                  alpha: 0.72,
                                )
                              : SettingsFlowPalette.textSecondary,
                          height: 1.45,
                        ),
                        maxLines: destructive ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SettingsFlowPalette.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.product(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (!destructive)
                AppDirectionalIcon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SettingsFlowPalette.textSecondary.withValues(
                    alpha: 0.38,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED PRIMITIVES
// =============================================================================

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.current.surface.withValues(
          alpha: AppColors.isDark ? 0.98 : 0.97,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: SettingsFlowPalette.border.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: SettingsFlowPalette.primaryDark.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.current.shadow.withValues(
              alpha: AppColors.isDark ? 0.18 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            top: -34,
            right: -18,
            child: _Orb(
              90,
              SettingsFlowPalette.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -42,
            left: -22,
            child: _Orb(
              102,
              SettingsFlowPalette.secondary.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            top: 0,
            left: 28,
            right: 28,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SettingsFlowPalette.primary,
                    SettingsFlowPalette.secondary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(999),
                  bottomRight: Radius.circular(999),
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.product(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingChip extends StatelessWidget {
  final String label;

  const _MissingChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.current.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SettingsFlowPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 14,
            color: SettingsFlowPalette.accent,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.product(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: SettingsFlowPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _SurfaceActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled
        ? SettingsFlowPalette.primary
        : AppColors.current.surfaceElevated;
    final foregroundColor = filled ? Colors.white : SettingsFlowPalette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled
                  ? SettingsFlowPalette.primary
                  : SettingsFlowPalette.border,
            ),
          ),
          child: AppInlineIconLabel(
            icon: icon,
            iconSize: 18,
            iconColor: foregroundColor,
            gap: 10,
            label: Text(
              label,
              style: AppTypography.product(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AppInlineIconLabel(
            icon: icon,
            iconSize: 14,
            iconColor: color,
            gap: 6,
            label: Text(
              label,
              style: AppTypography.product(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DATA
// =============================================================================

class _HeroBadgeData {
  final String label;
  final IconData icon;
  final Color color;
  final bool premium;

  const _HeroBadgeData({
    required this.label,
    required this.icon,
    required this.color,
    this.premium = false,
  });
}

class _FactData {
  final String label;
  final String? value;
  final IconData icon;
  final Color color;

  const _FactData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
