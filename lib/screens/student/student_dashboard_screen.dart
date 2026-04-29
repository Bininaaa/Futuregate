import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/saved_idea_model.dart';
import '../../models/saved_opportunity_model.dart';
import '../../models/saved_scholarship_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/student_application_item_model.dart';
import '../../models/training_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/project_idea_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/saved_scholarship_provider.dart';
import '../../providers/scholarship_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/training_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../utils/application_status.dart';
import '../../utils/display_text.dart';
import '../../utils/localized_display.dart';
import '../../utils/student_profile_completion.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/application_status_badge.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_dashboard_widgets.dart';
import '../../widgets/opportunity_type_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_directional.dart';
import '../../widgets/shared/app_feedback.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'applied_opportunities_screen.dart';
import 'cv_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'idea_details_screen.dart';
import 'internships_screen.dart';
import 'jobs_screen.dart';
import 'opportunities_screen.dart';
import 'opportunity_detail_screen.dart';
import 'project_ideas_screen.dart';
import 'scholarship_detail_screen.dart';
import 'student_home_navigation.dart';
import 'sponsored_opportunities_screen.dart';
import 'trainings_screen.dart';
import 'scholarships_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final bool embedded;

  const StudentDashboardScreen({super.key, this.embedded = false});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  // ── Premium purple theme palette ──
  static Color get primaryPurple => OpportunityDashboardPalette.primary;
  static Color get deepPurple => OpportunityDashboardPalette.primaryDark;
  static Color get lightPurple => OpportunityDashboardPalette.primary;
  static Color get softLavender => OpportunityDashboardPalette.background;
  static Color get accentTeal => OpportunityDashboardPalette.secondary;
  static Color get accentGold => OpportunityDashboardPalette.accent;
  static Color get cardWhite => OpportunityDashboardPalette.surface;
  static Color get textDark => OpportunityDashboardPalette.textPrimary;
  static Color get textMedium => OpportunityDashboardPalette.textSecondary;
  static Color get textLight => AppColors.current.textMuted;
  static Color get cardBorder => OpportunityDashboardPalette.border;

  bool _didLoadBaseData = false;
  String? _loadedStudentId;
  bool _isBootstrappingDashboard = true;
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapDashboard();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _bootstrapDashboard() async {
    final studentId = context.read<AuthProvider>().userModel?.uid.trim();
    final futures = <Future<void>>[_loadBaseData()];

    if (studentId != null && studentId.isNotEmpty) {
      futures.add(_loadStudentData(studentId));
    }

    try {
      await Future.wait(futures);
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrappingDashboard = false;
        });
      }
    }
  }

  Future<void> _loadBaseData() async {
    if (_didLoadBaseData) {
      return;
    }

    _didLoadBaseData = true;
    await Future.wait([
      context.read<OpportunityProvider>().fetchOpportunities(),
      context.read<TrainingProvider>().fetchTrainings(),
      context.read<ScholarshipProvider>().fetchScholarships(),
    ]);
  }

  Future<void> _loadStudentData(String studentId) async {
    if (_loadedStudentId == studentId) {
      return;
    }

    _loadedStudentId = studentId;
    await Future.wait([
      context.read<StudentProvider>().loadStudentProfile(studentId),
      context.read<SavedOpportunityProvider>().fetchSavedOpportunities(
        studentId,
      ),
      context.read<SavedScholarshipProvider>().fetchSavedScholarships(
        studentId,
      ),
      context.read<TrainingProvider>().fetchSavedTrainings(studentId),
      context.read<ProjectIdeaProvider>().fetchSavedIdeas(studentId),
      context.read<ApplicationProvider>().fetchSubmittedApplications(studentId),
      context.read<CvProvider>().loadCv(studentId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().userModel;
    if (_isBootstrappingDashboard) {
      final loadingScaffold = const Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: OpportunityDashboardLoadingSkeleton(),
        ),
      );

      if (widget.embedded) {
        return loadingScaffold;
      }

      return AppShellBackground(child: loadingScaffold);
    }

    final user = context.watch<StudentProvider>().student ?? authUser;
    final cv = context.watch<CvProvider>().cv;
    final opportunityProvider = context.watch<OpportunityProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final savedOpportunityProvider = context.watch<SavedOpportunityProvider>();
    final savedScholarshipProvider = context.watch<SavedScholarshipProvider>();
    final projectIdeaProvider = context.watch<ProjectIdeaProvider>();
    final l10n = AppLocalizations.of(context)!;
    final firstName = (user?.fullName ?? 'Student').split(' ').first;
    final profileCompletion = _profileCompletionPercent(user, cv);
    final showProfilePrompt = profileCompletion < 100;
    final dashboardSnapshot = _buildDashboardSnapshot(
      user: user,
      opportunities: opportunityProvider.opportunities,
      featuredOpportunities: opportunityProvider.featuredOpportunities,
      trainings: trainingProvider.trainings,
      applications: applicationProvider.submittedApplications,
      savedOpportunityCount: savedOpportunityProvider.savedOpportunities.length,
      savedScholarshipCount: savedScholarshipProvider.savedScholarships.length,
      savedTrainingCount: trainingProvider.savedTrainings.length,
      savedIdeaCount: projectIdeaProvider.savedIdeas.length,
    );

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: !widget.embedded,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(
                context,
                firstName,
                user,
                cv,
                profileCompletion,
                dashboardSnapshot,
              ),
            ),
            if (showProfilePrompt)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildProfileCompletionPrompt(
                    context,
                    user,
                    cv,
                    profileCompletion,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  l10n.dashSectionClosingSoon,
                  subtitle: l10n.dashSectionClosingSoonSubtitle,
                  accentColor: accentGold,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _buildClosingSoonSection(context, dashboardSnapshot),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  l10n.dashSectionRecommended,
                  subtitle: l10n.dashSectionRecommendedSubtitle,
                  onSeeAll: () => _openDiscover(context),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _buildRecommendedSection(
                  context,
                  user,
                  dashboardSnapshot,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  l10n.dashSectionQuickAccess,
                  subtitle: l10n.dashSectionQuickAccessSubtitle,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildQuickAccessSection(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  l10n.dashSectionLatestActivity,
                  subtitle: l10n.dashSectionLatestActivitySubtitle,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: _buildLatestActivitiesSection(context, cv),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return scaffold;
    }

    return AppShellBackground(child: scaffold);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PROFILE / HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(
    BuildContext context,
    String firstName,
    UserModel? user,
    CvModel? cv,
    int profileCompletion,
    _DashboardSnapshot snapshot,
  ) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final studentIdentity = _studentIdentityLine(user);
    final focus = _resolveDashboardFocus(
      context,
      user: user,
      cv: cv,
      profileCompletion: profileCompletion,
      snapshot: snapshot,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [deepPurple, primaryPurple, Color(0xFF6D5EF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -14,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lightPurple.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            left: 38,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ProfileCompletionRingPainter(
                                progress: profileCompletion / 100,
                                trackColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                progressColor: profileCompletion >= 100
                                    ? const Color(0xFF47D16C)
                                    : const Color(0xFFFFC857),
                                strokeWidth: 2.6,
                              ),
                            ),
                          ),
                          Center(child: ProfileAvatar(user: user, radius: 25)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greetingForTime(_now, context),
                          style: AppTypography.product(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firstName,
                          style: AppTypography.product(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (studentIdentity.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            studentIdentity,
                            style: AppTypography.product(
                              fontSize: 11.6,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 21,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: OpportunityDashboardPalette.error,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: AppTypography.product(
                                    fontSize: 8.5,
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
                ],
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  focus.badgeLabel,
                  style: AppTypography.product(
                    fontSize: 9.7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.42,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                focus.title,
                style: AppTypography.product(
                  fontSize: 21,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Text(
                focus.subtitle,
                style: AppTypography.product(
                  fontSize: 11.4,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (focus.insight.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(focus.insightIcon, color: focus.accent, size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          focus.insight,
                          style: AppTypography.product(
                            fontSize: 10.9,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderActionChip(
                      icon: focus.primaryActionIcon,
                      label: focus.primaryActionLabel,
                      isPrimary: true,
                      isOnDark: true,
                      onTap: focus.onPrimaryAction,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeaderActionChip(
                      icon: focus.secondaryActionIcon,
                      label: focus.secondaryActionLabel,
                      isOnDark: true,
                      onTap: focus.onSecondaryAction,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSavedShortcutBanner(context, snapshot),
            ],
          ),
        ],
      ),
    );
  }

  _DashboardSnapshot _buildDashboardSnapshot({
    required UserModel? user,
    required List<OpportunityModel> opportunities,
    required List<OpportunityModel> featuredOpportunities,
    required List<TrainingModel> trainings,
    required List<StudentApplicationItemModel> applications,
    required int savedOpportunityCount,
    required int savedScholarshipCount,
    required int savedTrainingCount,
    required int savedIdeaCount,
  }) {
    final discoverableOpportunities = opportunities
        .where(_isHomeOpportunity)
        .toList(growable: false);
    final featuredVisible = featuredOpportunities
        .where(_isHomeOpportunity)
        .toList(growable: false);
    final visibleTrainings = trainings
        .where((item) => item.isApproved && !item.isHidden)
        .toList(growable: false);
    final closingSoonItems = _closingSoonOpportunities(
      discoverableOpportunities,
    );
    final recommendedItems = _recommendedOpportunities(
      user: user,
      opportunities: discoverableOpportunities,
      featuredOpportunities: featuredVisible,
    );
    final appliedCount = applications.length;
    final pendingCount = applications
        .where(
          (item) =>
              ApplicationStatus.parse(item.status) == ApplicationStatus.pending,
        )
        .length;
    final approvedCount = applications
        .where(
          (item) =>
              ApplicationStatus.parse(item.status) ==
              ApplicationStatus.accepted,
        )
        .length;
    final rejectedCount = applications
        .where(
          (item) =>
              ApplicationStatus.parse(item.status) ==
              ApplicationStatus.rejected,
        )
        .length;

    return _DashboardSnapshot(
      savedCount:
          savedOpportunityCount +
          savedScholarshipCount +
          savedTrainingCount +
          savedIdeaCount,
      savedOpportunityCount: savedOpportunityCount,
      savedScholarshipCount: savedScholarshipCount,
      savedTrainingCount: savedTrainingCount,
      savedIdeaCount: savedIdeaCount,
      appliedCount: appliedCount,
      pendingApplicationsCount: pendingCount,
      approvedApplicationsCount: approvedCount,
      rejectedApplicationsCount: rejectedCount,
      closingSoonItems: closingSoonItems,
      recommendedItems: recommendedItems,
      discoverableOpportunities: discoverableOpportunities,
      jobsCount: discoverableOpportunities
          .where(
            (item) => OpportunityType.parse(item.type) == OpportunityType.job,
          )
          .length,
      internshipsCount: discoverableOpportunities
          .where(
            (item) =>
                OpportunityType.parse(item.type) == OpportunityType.internship,
          )
          .length,
      sponsoringCount: discoverableOpportunities
          .where(
            (item) =>
                OpportunityType.parse(item.type) == OpportunityType.sponsoring,
          )
          .length,
      learningCount: visibleTrainings.length,
    );
  }

  _DashboardFocus _resolveDashboardFocus(
    BuildContext context, {
    required UserModel? user,
    required CvModel? cv,
    required int profileCompletion,
    required _DashboardSnapshot snapshot,
  }) {
    final hasReadyCv = _hasReadyCv(cv);
    final missingCount = _missingProfileSignals(user, cv);
    final firstUrgent = snapshot.closingSoonItems.isNotEmpty
        ? snapshot.closingSoonItems.first
        : null;
    final firstUrgentDeadline = firstUrgent == null
        ? null
        : _opportunityDeadline(firstUrgent);
    void openApplications() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppliedOpportunitiesScreen()),
      );
    }

    void openDiscover() {
      _openDiscover(context);
    }

    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }

    void openCv() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CvScreen()),
      );
    }

    void openSaved() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedScreen()),
      );
    }

    if (!hasReadyCv) {
      return _DashboardFocus(
        badgeLabel: AppLocalizations.of(context)!.uiBadgeNextStep,
        title: AppLocalizations.of(context)!.uiBuildCvFirst,
        subtitle: AppLocalizations.of(context)!.dashFocusCvSubtitle,
        insight: AppLocalizations.of(context)!.dashFocusCvInsight,
        accent: accentGold,
        insightIcon: Icons.description_outlined,
        primaryActionLabel: AppLocalizations.of(context)!.uiActionBuildCv,
        primaryActionIcon: Icons.description_outlined,
        onPrimaryAction: openCv,
        secondaryActionLabel: AppLocalizations.of(
          context,
        )!.uiActionCompleteProfile,
        secondaryActionIcon: Icons.person_outline_rounded,
        onSecondaryAction: openProfile,
      );
    }

    if (profileCompletion < 100) {
      return _DashboardFocus(
        badgeLabel: AppLocalizations.of(
          context,
        )!.uiBadgeProfileReady(profileCompletion),
        title: AppLocalizations.of(context)!.uiCompleteProfile,
        subtitle: AppLocalizations.of(
          context,
        )!.dashFocusProfileSubtitle(missingCount),
        insight: _profileHint(user, cv),
        accent: accentGold,
        insightIcon: Icons.verified_user_outlined,
        primaryActionLabel: AppLocalizations.of(
          context,
        )!.uiActionCompleteProfile,
        primaryActionIcon: Icons.person_outline_rounded,
        onPrimaryAction: openProfile,
        secondaryActionLabel: AppLocalizations.of(context)!.uiDiscover,
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    if (snapshot.approvedApplicationsCount > 0) {
      final approved = snapshot.approvedApplicationsCount;
      final pending = snapshot.pendingApplicationsCount;
      final l10n = AppLocalizations.of(context)!;
      return _DashboardFocus(
        badgeLabel: l10n.uiBadgeMomentum,
        title: l10n.studentDashboardApprovedApplicationsTitle(approved),
        subtitle:
            l10n.uiKeepApplyingWhileTeamsAreAlreadyEngagingWithYourProfile,
        insight: pending > 0
            ? l10n.dashFocusClosingSoonSubtitle(pending)
            : firstUrgent != null && firstUrgentDeadline != null
            ? l10n.dashFocusClosingSoonInsight(
                firstUrgent.title,
                _deadlineCountdown(firstUrgentDeadline),
              )
            : l10n.dashFocusInsightApprovedMomentum,
        accent: const Color(0xFF86EFAC),
        insightIcon: Icons.verified_rounded,
        primaryActionLabel: AppLocalizations.of(context)!.uiActionViewStatus,
        primaryActionIcon: Icons.assignment_turned_in_outlined,
        onPrimaryAction: openApplications,
        secondaryActionLabel: AppLocalizations.of(context)!.uiDiscover,
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    if (snapshot.pendingApplicationsCount > 0) {
      final pending = snapshot.pendingApplicationsCount;
      final l10n = AppLocalizations.of(context)!;
      return _DashboardFocus(
        badgeLabel: l10n.uiBadgeInReview,
        title: l10n.studentDashboardPendingApplicationsTitle(pending),
        subtitle: l10n.dashFocusSubtitleInReview,
        insight: firstUrgent != null && firstUrgentDeadline != null
            ? l10n.dashFocusClosingSoonInsight(
                '${firstUrgent.title} (${firstUrgent.companyName})',
                _deadlineCountdown(firstUrgentDeadline),
              )
            : l10n.dashFocusInsightInReview,
        accent: accentTeal,
        insightIcon: Icons.hourglass_top_rounded,
        primaryActionLabel: AppLocalizations.of(context)!.uiActionTrackStatus,
        primaryActionIcon: Icons.assignment_turned_in_outlined,
        onPrimaryAction: openApplications,
        secondaryActionLabel: AppLocalizations.of(context)!.uiDiscover,
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    if (snapshot.closingSoonCount > 0 && firstUrgent != null) {
      final l10n = AppLocalizations.of(context)!;
      final deadlineLabel = firstUrgentDeadline == null
          ? l10n.dashDeadlineSoon
          : _deadlineCountdown(firstUrgentDeadline);
      return _DashboardFocus(
        badgeLabel: l10n.dashSectionClosingSoon,
        title: l10n.uiActBeforeDeadlines,
        subtitle: l10n.dashFocusClosingSoonSubtitle(snapshot.closingSoonCount),
        insight: l10n.dashFocusClosingSoonInsight(
          firstUrgent.companyName,
          deadlineLabel,
        ),
        accent: accentGold,
        insightIcon: Icons.schedule_outlined,
        primaryActionLabel: AppLocalizations.of(context)!.uiActionSeeOpenRoles,
        primaryActionIcon: Icons.explore_outlined,
        onPrimaryAction: openDiscover,
        secondaryActionLabel: snapshot.savedCount > 0
            ? AppLocalizations.of(context)!.uiActionOpenSaved
            : AppLocalizations.of(context)!.uiActionBuildCv,
        secondaryActionIcon: snapshot.savedCount > 0
            ? Icons.bookmark_outline_rounded
            : Icons.description_outlined,
        onSecondaryAction: snapshot.savedCount > 0 ? openSaved : openCv,
      );
    }

    if (snapshot.savedCount > 0) {
      return _DashboardFocus(
        badgeLabel: AppLocalizations.of(context)!.uiBadgeSavedPicks,
        title: AppLocalizations.of(context)!.uiShortlistReady,
        subtitle: AppLocalizations.of(context)!.uiRevisitSavedPicks,
        insight: AppLocalizations.of(context)!.dashFocusInsightSavedReady,
        accent: primaryPurple,
        insightIcon: Icons.bookmark_added_outlined,
        primaryActionLabel: AppLocalizations.of(context)!.uiActionOpenSaved,
        primaryActionIcon: Icons.bookmark_outline_rounded,
        onPrimaryAction: openSaved,
        secondaryActionLabel: AppLocalizations.of(context)!.uiDiscover,
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    return _DashboardFocus(
      badgeLabel: AppLocalizations.of(context)!.uiBadgeDiscover,
      title: AppLocalizations.of(context)!.uiFindNextOpportunity,
      subtitle: AppLocalizations.of(context)!.dashFocusSubtitleDiscover,
      insight: AppLocalizations.of(context)!.dashFocusInsightDiscover,
      accent: primaryPurple,
      insightIcon: Icons.auto_awesome_rounded,
      primaryActionLabel: AppLocalizations.of(context)!.uiDiscover,
      primaryActionIcon: Icons.explore_outlined,
      onPrimaryAction: openDiscover,
      secondaryActionLabel: AppLocalizations.of(context)!.uiActionBuildCv,
      secondaryActionIcon: Icons.description_outlined,
      onSecondaryAction: openCv,
    );
  }

  Widget _buildHeaderActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isOnDark = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isOnDark
                ? (isPrimary
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08))
                : (isPrimary ? textDark : cardWhite),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isOnDark
                  ? Colors.white.withValues(alpha: isPrimary ? 0.18 : 0.16)
                  : (isPrimary ? textDark : cardBorder),
            ),
            boxShadow: isOnDark && isPrimary
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isOnDark
                    ? (isPrimary
                          ? primaryPurple
                          : Colors.white.withValues(alpha: 0.88))
                    : (isPrimary ? Colors.white : primaryPurple),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.product(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w800,
                    color: isOnDark
                        ? (isPrimary
                              ? primaryPurple
                              : Colors.white.withValues(alpha: 0.90))
                        : (isPrimary ? Colors.white : textDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedShortcutBanner(
    BuildContext context,
    _DashboardSnapshot snapshot,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final totalSaved = snapshot.savedCount;
    final summary = totalSaved == 0
        ? l10n.dashSavedBannerEmpty
        : l10n.dashSavedBannerCount(totalSaved);
    final chips = <Widget>[
      if (snapshot.savedOpportunityCount > 0)
        _buildSavedShortcutChip(
          l10n.studentSavedRolesCount(snapshot.savedOpportunityCount),
        ),
      if (snapshot.savedScholarshipCount > 0)
        _buildSavedShortcutChip(
          l10n.studentSavedScholarshipsCount(snapshot.savedScholarshipCount),
        ),
      if (snapshot.savedTrainingCount > 0)
        _buildSavedShortcutChip(
          l10n.studentSavedTrainingsCount(snapshot.savedTrainingCount),
        ),
      if (snapshot.savedIdeaCount > 0)
        _buildSavedShortcutChip(
          l10n.studentSavedIdeasCount(snapshot.savedIdeaCount),
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedScreen()),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.uiSavedShortlist,
                            style: AppTypography.product(
                              fontSize: 12.6,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.studentDashboardSavedBadgeCount(totalSaved),
                            style: AppTypography.product(
                              fontSize: 9.8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: AppTypography.product(
                        fontSize: 10.8,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: chips),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const AppDirectionalIcon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedShortcutChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 9.6,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. QUICK ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickAccessSection(BuildContext context) {
    final items = <_QuickAccessTileItem>[
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiJobs,
        icon: Icons.work_outline_rounded,
        color: const Color(0xFF6C63FF),
        onTap: () =>
            _openQuickAccessPage(context, builder: (_) => const JobsScreen()),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiInternships,
        icon: Icons.school_outlined,
        color: const Color(0xFF19C37D),
        onTap: () => _openQuickAccessPage(
          context,
          builder: (_) => const InternshipsScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiSponsored,
        icon: Icons.campaign_outlined,
        color: const Color(0xFFFFB341),
        onTap: () => _openQuickAccessPage(
          context,
          builder: (_) => const SponsoredOpportunitiesScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiScholarships,
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFF47D16C),
        onTap: () => _openQuickAccessTab(
          context,
          tabIndex: StudentHomeNavigation.scholarshipsTab,
          standaloneBuilder: (_) => const ScholarshipsScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiIdeas,
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFFFF6B6B),
        onTap: () => _openQuickAccessTab(
          context,
          tabIndex: StudentHomeNavigation.ideasTab,
          standaloneBuilder: (_) => const ProjectIdeasScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiCvBuilder,
        icon: Icons.description_outlined,
        color: deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CvScreen()),
        ),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiTraining,
        icon: Icons.cast_for_education_outlined,
        color: const Color(0xFF22CFC3),
        onTap: () => _openQuickAccessTab(
          context,
          tabIndex: StudentHomeNavigation.trainingTab,
          standaloneBuilder: (_) => const TrainingsScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: AppLocalizations.of(context)!.uiSaved,
        icon: Icons.bookmark_border_rounded,
        color: const Color(0xFFF08E72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedScreen()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1080
            ? 6
            : constraints.maxWidth >= 860
            ? 5
            : 4;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _buildQuickAccessTile(item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildQuickAccessTile(_QuickAccessTileItem item) {
    final iconBackground = Color.lerp(item.color, Colors.white, 0.12)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxSize = constraints.maxWidth.clamp(54.0, 62.0).toDouble();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Ink(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [iconBackground, item.color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(boxSize * 0.28),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: boxSize * 0.38,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DisplayText.capitalizeLeadingLabel(item.title),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTypography.product(
                          fontSize: 11.2,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. PROFILE COMPLETION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileCompletionPrompt(
    BuildContext context,
    UserModel? user,
    CvModel? cv,
    int completion,
  ) {
    final accent = _progressColor(completion);
    final primaryLabel = _profilePrimaryActionLabel(user, cv);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _hasReadyCv(cv)
                      ? Icons.account_circle_outlined
                      : Icons.description_outlined,
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.uiCompleteYourProfile,
                      style: AppTypography.product(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.uiCompletionReadyForBetterStudentMatching(completion),
                      style: AppTypography.product(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completion%',
                  style: AppTypography.product(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _profileHint(user, cv),
            style: AppTypography.product(
              fontSize: 12,
              height: 1.4,
              color: textMedium,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 7,
              backgroundColor: softLavender,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openProfilePrimaryAction(context, user, cv),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      primaryLabel,
                      style: AppTypography.product(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: textDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  textStyle: AppTypography.product(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.uiViewProfile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClosingSoonSection(
    BuildContext context,
    _DashboardSnapshot snapshot,
  ) {
    final provider = context.watch<OpportunityProvider>();
    final appliedStatusMap = context
        .watch<ApplicationProvider>()
        .appliedStatusMap;
    final items = snapshot.closingSoonItems;

    if (provider.isLoading && items.isEmpty) {
      return SizedBox(
        height: 124,
        child: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 20),
        child: _buildEmptyState(
          icon: Icons.schedule_outlined,
          message: AppLocalizations.of(context)!.uiNoUrgentDeadlines,
          subtitle: AppLocalizations.of(
            context,
          )!.uiUpcomingDeadlinesAreHighlightedHereAsNewOpportunitiesGoLive,
        ),
      );
    }

    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.only(end: 20),
        itemCount: items.length > 4 ? 4 : items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildClosingSoonCard(
            context,
            item,
            applicationStatus: appliedStatusMap[item.id],
          );
        },
      ),
    );
  }

  Widget _buildClosingSoonCard(
    BuildContext context,
    OpportunityModel item, {
    String? applicationStatus,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedType = OpportunityType.parse(item.type);
    final accent = OpportunityType.color(normalizedType);
    final deadline = _opportunityDeadline(item);
    final dateLabel = deadline == null
        ? item.deadlineLabel
        : OpportunityMetadata.formatDateLabel(deadline);
    final urgencyColor = _closingSoonUrgencyColor(deadline);
    final deadlineLabel = deadline == null
        ? l10n.dashDeadlineSoon
        : _deadlineCountdown(deadline);
    final fundingLabel = normalizedType == OpportunityType.sponsoring
        ? item.fundingLabel()
        : null;
    final footerLabel = fundingLabel == null
        ? _closingSoonFooterLabel(normalizedType, dateLabel)
        : l10n.studentFundingValue(fundingLabel);
    final locationLabel = item.location.trim().isNotEmpty
        ? item.location.trim()
        : _closingSoonLocationFallback(normalizedType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          OpportunityDetailScreen.show(context, item);
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 222,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          OpportunityType.icon(normalizedType),
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          OpportunityType.label(normalizedType, l10n),
                          style: AppTypography.product(
                            fontSize: 10.2,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      deadlineLabel,
                      style: AppTypography.product(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        color: urgencyColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                DisplayText.capitalizeLeadingLabel(item.title),
                style: AppTypography.product(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (applicationStatus != null) ...[
                const SizedBox(height: 8),
                ApplicationStatusBadge(
                  status: applicationStatus,
                  fontSize: 9.2,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildClosingSoonCompanyMark(item.companyName, accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.companyName,
                          style: AppTypography.product(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: textLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationLabel,
                                style: AppTypography.product(
                                  fontSize: 10.4,
                                  fontWeight: FontWeight.w500,
                                  color: textMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      fundingLabel == null
                          ? Icons.schedule_outlined
                          : Icons.savings_outlined,
                      size: 14,
                      color: urgencyColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        footerLabel,
                        style: AppTypography.product(
                          fontSize: 10.6,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppDirectionalIcon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: urgencyColor,
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

  Widget _buildClosingSoonCompanyMark(String companyName, Color accent) {
    final letter = companyName.trim().isNotEmpty
        ? companyName.trim()[0].toUpperCase()
        : 'C';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.product(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  String _closingSoonFooterLabel(String type, String dateLabel) {
    final l10n = AppLocalizations.of(context)!;
    switch (OpportunityType.parse(type)) {
      case OpportunityType.internship:
        return l10n.studentClosesDate(dateLabel);
      case OpportunityType.sponsoring:
        return l10n.studentClosesDate(dateLabel);
      case OpportunityType.job:
      default:
        return l10n.studentApplyByDate(dateLabel);
    }
  }

  String _closingSoonLocationFallback(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (OpportunityType.parse(type)) {
      case OpportunityType.internship:
        return l10n.studentStudentPlacement;
      case OpportunityType.sponsoring:
        return l10n.studentPartnerBackedProgram;
      case OpportunityType.job:
      default:
        return l10n.studentCareerOpportunity;
    }
  }

  Color _closingSoonUrgencyColor(DateTime? deadline) {
    if (deadline == null) {
      return accentGold;
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final normalized = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = normalized.difference(startOfToday).inDays;

    if (difference <= 1) {
      return OpportunityDashboardPalette.error;
    }
    if (difference <= 4) {
      return accentGold;
    }

    return primaryPurple;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. RECOMMENDED SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  void _openDiscover(BuildContext context) {
    if (widget.embedded) {
      StudentHomeNavigation.switchToDiscover(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OpportunitiesScreen()),
    );
  }

  void _openQuickAccessPage(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  void _openQuickAccessTab(
    BuildContext context, {
    required int tabIndex,
    required WidgetBuilder standaloneBuilder,
  }) {
    if (widget.embedded) {
      StudentHomeNavigation.switchToTab(context, tabIndex);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: standaloneBuilder));
  }

  Widget _buildRecommendedSection(
    BuildContext context,
    UserModel? user,
    _DashboardSnapshot snapshot,
  ) {
    final carouselHeight = _recommendedCarouselHeight(context);
    final provider = context.watch<OpportunityProvider>();
    final appliedStatusMap = context
        .watch<ApplicationProvider>()
        .appliedStatusMap;
    final items = snapshot.recommendedItems;
    final isLoading =
        items.isEmpty && (provider.isFeaturedLoading || provider.isLoading);

    if (isLoading) {
      return SizedBox(
        height: carouselHeight,
        child: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        message: AppLocalizations.of(context)!.uiNoRecommendations,
        subtitle: AppLocalizations.of(context)!.uiCheckBackSoon,
      );
    }

    return SizedBox(
      height: carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length > 6 ? 6 : items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildRecommendedCard(
            context,
            item,
            user,
            applicationStatus: appliedStatusMap[item.id],
          );
        },
      ),
    );
  }

  double _recommendedCarouselHeight(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    if (textScale > 1.16) {
      return 252;
    }

    if (screenWidth < 390 || textScale > 1.0) {
      return 240;
    }

    return 236;
  }

  Widget _buildRecommendedCard(
    BuildContext context,
    OpportunityModel item,
    UserModel? user, {
    String? applicationStatus,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final freshness = _timeAgo(
      item.createdAt?.toDate() ?? item.updatedAt?.toDate(),
    );
    final accent = OpportunityType.color(item.type);
    final reason = _recommendationReason(item, user);
    final deadlineLabel = _recentFriendlyDeadline(item);
    final normalizedType = OpportunityType.parse(item.type);
    final fundingLabel = normalizedType == OpportunityType.sponsoring
        ? item.fundingLabel()
        : null;
    final footerMetaLabel = fundingLabel ?? deadlineLabel;
    final locationLabel = item.location.trim().isNotEmpty
        ? item.location.trim()
        : _closingSoonLocationFallback(normalizedType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => OpportunityDetailScreen.show(context, item),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 236,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.26), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OpportunityTypeBadge(
                          type: item.type,
                          showIcon: false,
                          fontSize: 9.2,
                        ),
                        if (applicationStatus != null)
                          ApplicationStatusBadge(
                            status: applicationStatus,
                            fontSize: 9.2,
                          ),
                      ],
                    ),
                  ),
                  if (freshness != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      freshness,
                      style: AppTypography.product(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textLight,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCompanyLogo(
                    item.companyLogo,
                    item.companyName,
                    size: 34,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.companyName,
                          style: AppTypography.product(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 10,
                              color: textLight,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                locationLabel,
                                style: AppTypography.product(
                                  fontSize: 10,
                                  color: textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                DisplayText.capitalizeLeadingLabel(item.title),
                style: AppTypography.product(
                  fontSize: 15.2,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _summarize(
                  item.description,
                  fallback: l10n.studentStrongOpportunitySubtitle,
                ),
                style: AppTypography.product(
                  fontSize: 10.8,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: accent),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTypography.product(
                          fontSize: 9.6,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (footerMetaLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fundingLabel != null
                                ? Icons.savings_outlined
                                : Icons.schedule,
                            size: 11,
                            color: accent,
                          ),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 128),
                            child: Text(
                              fundingLabel != null
                                  ? AppLocalizations.of(
                                      context,
                                    )!.studentFundingValue(footerMetaLabel)
                                  : footerMetaLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 9.2,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      AppLocalizations.of(context)!.uiOpenDetails,
                      style: AppTypography.product(
                        fontSize: 9.6,
                        fontWeight: FontWeight.w700,
                        color: textMedium,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AppDirectionalIcon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogo(
    String logoUrl,
    String companyName, {
    double size = 42,
  }) {
    final hasLogo = logoUrl.trim().isNotEmpty;
    final fontSize = size <= 38 ? 16.0 : 18.0;
    final initial = companyName.trim().isNotEmpty
        ? companyName.trim().substring(0, 1).toUpperCase()
        : 'C';
    Widget fallbackLogo(Color color) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          initial,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: AppTypography.product(
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      padding: hasLogo ? EdgeInsets.all(size * 0.12) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: hasLogo ? softLavender : primaryPurple,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              placeholder: (_, _) => fallbackLogo(primaryPurple),
              errorWidget: (_, _, _) => fallbackLogo(primaryPurple),
            )
          : fallbackLogo(Colors.white),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. LATEST ACTIVITIES
  // ═══════════════════════════════════════════════════════════════════════════

  SliverList _buildLatestActivitiesSection(BuildContext context, CvModel? cv) {
    final applicationProvider = context.watch<ApplicationProvider>();
    final savedOpportunityProvider = context.watch<SavedOpportunityProvider>();
    final savedScholarshipProvider = context.watch<SavedScholarshipProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final projectIdeaProvider = context.watch<ProjectIdeaProvider>();
    final cvProvider = context.watch<CvProvider>();
    final opportunityProvider = context.watch<OpportunityProvider>();
    final scholarshipProvider = context.watch<ScholarshipProvider>();
    final cvActivity = _cvActivityEntry(context, cv ?? cvProvider.cv);

    final activities = <_DashboardActivityEntry>[
      ..._applicationActivityEntries(
        context,
        applicationProvider.submittedApplications,
      ),
      ..._savedOpportunityActivityEntries(
        context,
        savedOpportunityProvider.savedOpportunities,
        opportunityProvider,
      ),
      ..._savedScholarshipActivityEntries(
        context,
        savedScholarshipProvider.savedScholarships,
        scholarshipProvider,
      ),
      ..._savedTrainingActivityEntries(
        context,
        trainingProvider.savedTrainings,
      ),
      ..._savedIdeaActivityEntries(context, projectIdeaProvider.savedIdeas),
      ?cvActivity,
    ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    final visibleActivities = activities.take(5).toList(growable: false);

    final isLoading =
        activities.isEmpty &&
        (applicationProvider.submittedApplicationsLoading ||
            savedOpportunityProvider.isLoading ||
            savedScholarshipProvider.isLoading ||
            trainingProvider.isSavedLoading ||
            projectIdeaProvider.savedIdeasLoading ||
            cvProvider.isLoading);

    if (isLoading) {
      return SliverList(
        delegate: SliverChildListDelegate([
          SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: primaryPurple),
            ),
          ),
        ]),
      );
    }

    if (activities.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(
            icon: Icons.bolt_rounded,
            message: AppLocalizations.of(context)!.uiNoRecentActivity,
            subtitle: AppLocalizations.of(
              context,
            )!.uiYourLatestApplicationsSavesAndCvUpdatesAreReflectedHere,
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLatestActivityCard(visibleActivities[index]),
        );
      }, childCount: visibleActivities.length),
    );
  }

  Widget _buildLatestActivityCard(_DashboardActivityEntry item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: _recentCardDecoration(item.accent),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildRecentLabelChip(
                                label: item.badgeLabel,
                                color: item.accent,
                              ),
                            ],
                          ),
                        ),
                        if (item.trailingLabel != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 8,
                              top: 2,
                            ),
                            child: Text(
                              item.trailingLabel!,
                              style: AppTypography.product(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: textLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DisplayText.capitalizeLeadingLabel(item.title),
                      style: AppTypography.product(
                        fontSize: 13.6,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: AppTypography.product(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w600,
                        color: textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.metaLabel != null) ...[
                      const SizedBox(height: 4),
                      _buildRecentMetaItem(
                        icon: item.metaIcon ?? Icons.info_outline_rounded,
                        label: item.metaLabel!,
                        color: item.metaColor,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRecentArrowChip(item.accent),
            ],
          ),
        ),
      ),
    );
  }

  List<_DashboardActivityEntry> _applicationActivityEntries(
    BuildContext context,
    List<StudentApplicationItemModel> items,
  ) {
    final applications = [...items];
    applications.sort((a, b) {
      final first = a.appliedAt?.millisecondsSinceEpoch ?? 0;
      final second = b.appliedAt?.millisecondsSinceEpoch ?? 0;
      return second.compareTo(first);
    });

    return applications
        .where((item) => item.appliedAt != null)
        .map((item) {
          final accent = _applicationActivityColor(item.status);
          final deadline = item.deadline;
          final hasUpcomingDeadline =
              deadline != null && _daysUntil(deadline) >= 0;
          final meta = hasUpcomingDeadline
              ? AppLocalizations.of(context)!.studentClosesMonthDay(
                  LocalizedDisplay.shortDate(context, deadline),
                )
              : item.location;

          return _DashboardActivityEntry(
            dedupeKey: 'application:${item.id}',
            sortDate: item.appliedAt!,
            badgeLabel: _applicationActivityBadge(context, item.status),
            accent: accent,
            icon: _applicationActivityIcon(item.status),
            title: DisplayText.capitalizeLeadingLabel(item.title),
            subtitle: item.companyName,
            metaLabel: meta.trim().isEmpty ? null : meta,
            metaIcon: hasUpcomingDeadline
                ? Icons.schedule_outlined
                : Icons.location_on_outlined,
            metaColor: hasUpcomingDeadline ? accentGold : null,
            trailingLabel: _timeAgo(item.appliedAt),
            onTap: () {
              if (item.canOpenDetails && item.opportunity != null) {
                OpportunityDetailScreen.show(context, item.opportunity!);
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppliedOpportunitiesScreen(),
                ),
              );
            },
          );
        })
        .toList(growable: false);
  }

  List<_DashboardActivityEntry> _savedOpportunityActivityEntries(
    BuildContext context,
    List<SavedOpportunityModel> items,
    OpportunityProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final activities = <_DashboardActivityEntry>[];

    for (final item in items) {
      final savedAt = item.savedAt?.toDate();
      if (savedAt == null) {
        continue;
      }

      final deadline = OpportunityMetadata.parseDateTimeLike(item.deadline);
      final isUrgent =
          deadline != null &&
          _daysUntil(deadline) >= 0 &&
          _daysUntil(deadline) <= 7;
      final key = 'saved_opp:${item.opportunityId}';

      final accent = isUrgent
          ? _closingSoonUrgencyColor(deadline)
          : OpportunityType.color(item.type);
      final companyName = item.companyName.trim();
      final subtitle = isUrgent
          ? companyName.isNotEmpty
                ? l10n.savedTypeFromCompany(
                    OpportunityType.lowercaseLabel(item.type, l10n),
                    companyName,
                  )
                : l10n.savedTypeNeedsAttention(
                    OpportunityType.lowercaseLabel(item.type, l10n),
                  )
          : (companyName.isNotEmpty
                ? companyName
                : OpportunityType.label(item.type, l10n));
      final meta = deadline != null
          ? l10n.closesDateLabel(LocalizedDisplay.shortDate(context, deadline))
          : item.location.trim();

      activities.add(
        _DashboardActivityEntry(
          dedupeKey: key,
          sortDate: savedAt,
          badgeLabel: isUrgent
              ? l10n.closingSoonBadge
              : l10n.savedTypeBadge(
                  OpportunityType.lowercaseLabel(item.type, l10n),
                ),
          accent: accent,
          icon: isUrgent
              ? Icons.schedule_outlined
              : OpportunityType.icon(item.type),
          title: DisplayText.opportunityTitle(
            item.title,
            fallback: l10n.savedOpportunityFallback,
          ),
          subtitle: subtitle,
          metaLabel: meta.trim().isEmpty ? null : meta,
          metaIcon: deadline != null
              ? Icons.schedule_outlined
              : Icons.location_on_outlined,
          metaColor: deadline != null ? accent : null,
          trailingLabel: _timeAgo(savedAt),
          onTap: () => _openSavedOpportunityActivity(context, item, provider),
        ),
      );
    }

    activities.sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return activities;
  }

  List<_DashboardActivityEntry> _savedScholarshipActivityEntries(
    BuildContext context,
    List<SavedScholarshipModel> items,
    ScholarshipProvider provider,
  ) {
    const scholarshipAccent = Color(0xFF47D16C);
    final activities = <_DashboardActivityEntry>[];

    for (final item in items) {
      final savedAt = item.savedAt?.toDate();
      if (savedAt == null) {
        continue;
      }

      final deadline = OpportunityMetadata.parseDateTimeLike(item.deadline);
      final isUrgent =
          deadline != null &&
          _daysUntil(deadline) >= 0 &&
          _daysUntil(deadline) <= 7;
      final key = 'saved_scholarship:${item.scholarshipId}';

      final accent = isUrgent
          ? _closingSoonUrgencyColor(deadline)
          : scholarshipAccent;
      final providerName = item.provider.trim();
      final subtitle = isUrgent
          ? providerName.isNotEmpty
                ? AppLocalizations.of(
                    context,
                  )!.studentSavedScholarshipFrom(providerName)
                : AppLocalizations.of(
                    context,
                  )!.studentSavedScholarshipNeedsAttention
          : (providerName.isNotEmpty
                ? providerName
                : AppLocalizations.of(context)!.studentScholarshipFallback);
      final meta = deadline != null
          ? AppLocalizations.of(context)!.studentClosesMonthDay(
              LocalizedDisplay.shortDate(context, deadline),
            )
          : LocalizedDisplay.metadataLabel(
              context,
              _firstNonEmpty([item.level, item.location, item.fundingType]),
            );

      activities.add(
        _DashboardActivityEntry(
          dedupeKey: key,
          sortDate: savedAt,
          badgeLabel: isUrgent
              ? AppLocalizations.of(context)!.uiClosingSoon
              : AppLocalizations.of(context)!.uiSavedScholarshipBadge,
          accent: accent,
          icon: isUrgent
              ? Icons.schedule_outlined
              : Icons.emoji_events_outlined,
          title: item.title.trim().isNotEmpty
              ? DisplayText.capitalizeLeadingLabel(item.title)
              : AppLocalizations.of(context)!.uiSavedScholarshipBadge,
          subtitle: subtitle,
          metaLabel: meta.trim().isEmpty ? null : meta,
          metaIcon: deadline != null
              ? Icons.schedule_outlined
              : Icons.school_outlined,
          metaColor: deadline != null ? accent : null,
          trailingLabel: _timeAgo(savedAt),
          onTap: () => _openSavedScholarshipActivity(context, item, provider),
        ),
      );
    }

    activities.sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return activities;
  }

  List<_DashboardActivityEntry> _savedTrainingActivityEntries(
    BuildContext context,
    List<TrainingModel> items,
  ) {
    final trainings = [...items];
    trainings.sort((a, b) {
      final first = a.savedAt?.millisecondsSinceEpoch ?? 0;
      final second = b.savedAt?.millisecondsSinceEpoch ?? 0;
      return second.compareTo(first);
    });

    return trainings
        .where((item) => item.savedAt != null)
        .map((item) {
          final typeLabel = _recentTrainingTypeLabel(item.type);
          final providerName = item.provider.trim();
          final subtitle = providerName.isNotEmpty ? providerName : typeLabel;
          final meta = recentTrainingSupportingLine(item);

          return _DashboardActivityEntry(
            dedupeKey: 'saved_training:${item.id}',
            sortDate: item.savedAt!.toDate(),
            badgeLabel: AppLocalizations.of(
              context,
            )!.uiSavedTypeBadge(typeLabel.toLowerCase()),
            accent: accentTeal,
            icon: _savedTrainingActivityIcon(item.type),
            title: item.title.trim().isNotEmpty
                ? item.title.trim()
                : AppLocalizations.of(
                    context,
                  )!.uiSavedTypeBadge(AppLocalizations.of(context)!.uiResource),
            subtitle: subtitle,
            metaLabel: meta.trim().isEmpty ? null : meta,
            metaIcon: Icons.auto_stories_outlined,
            trailingLabel: _timeAgo(item.savedAt?.toDate()),
            onTap: () {
              unawaited(_openSavedTrainingActivity(context, item));
            },
          );
        })
        .toList(growable: false);
  }

  List<_DashboardActivityEntry> _savedIdeaActivityEntries(
    BuildContext context,
    List<SavedIdeaModel> items,
  ) {
    final ideas = [...items];
    ideas.sort((a, b) {
      final first = a.savedAt?.millisecondsSinceEpoch ?? 0;
      final second = b.savedAt?.millisecondsSinceEpoch ?? 0;
      return second.compareTo(first);
    });

    return ideas
        .where((item) => item.savedAt != null)
        .map((item) {
          return _DashboardActivityEntry(
            dedupeKey: 'saved_idea:${item.ideaId}',
            sortDate: item.savedAt!.toDate(),
            badgeLabel: AppLocalizations.of(context)!.studentSavedIdea,
            accent: accentGold,
            icon: Icons.lightbulb_outline_rounded,
            title: item.idea.title.trim().isNotEmpty
                ? item.idea.title.trim()
                : AppLocalizations.of(context)!.studentSavedIdea,
            subtitle: item.idea.creatorName,
            metaLabel: _firstNonEmpty([
              item.idea.displayCategory,
              item.idea.displayStage,
            ]),
            metaIcon: Icons.auto_awesome_outlined,
            trailingLabel: _timeAgo(item.savedAt?.toDate()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IdeaDetailsScreen(
                    ideaId: item.ideaId,
                    initialIdea: item.idea,
                  ),
                ),
              );
            },
          );
        })
        .toList(growable: false);
  }

  _DashboardActivityEntry? _cvActivityEntry(BuildContext context, CvModel? cv) {
    if (cv == null) {
      return null;
    }

    final timestamp =
        cv.updatedAt?.toDate() ??
        cv.uploadedCvUploadedAt?.toDate() ??
        cv.createdAt?.toDate();
    if (timestamp == null || (!cv.hasUploadedCv && !cv.hasBuilderContent)) {
      return null;
    }

    final subtitle = switch (cv.sourceType.trim()) {
      'uploaded' => AppLocalizations.of(context)!.studentUploadedCvReady,
      'hybrid' => AppLocalizations.of(context)!.studentHybridCvReady,
      _ =>
        cv.hasBuilderContent
            ? AppLocalizations.of(context)!.studentBuilderCvRefreshed
            : AppLocalizations.of(context)!.studentCvReadyNextApplication,
    };

    final l10n = AppLocalizations.of(context)!;
    final cvSignals = <String>[
      if (cv.skills.isNotEmpty) l10n.studentSkillCount(cv.skills.length),
      if (cv.experience.isNotEmpty)
        l10n.studentExperienceBlockCount(cv.experience.length),
      if (cv.languages.isNotEmpty)
        l10n.studentLanguageCount(cv.languages.length),
    ];

    return _DashboardActivityEntry(
      dedupeKey: 'cv:${cv.id.isNotEmpty ? cv.id : cv.studentId}',
      sortDate: timestamp,
      badgeLabel: AppLocalizations.of(context)!.studentCvUpdated,
      accent: primaryPurple,
      icon: Icons.description_outlined,
      title: cv.hasUploadedCv
          ? AppLocalizations.of(context)!.studentYourCvReady
          : AppLocalizations.of(context)!.studentBuilderCvUpdated,
      subtitle: subtitle,
      metaLabel: cvSignals.isNotEmpty
          ? cvSignals.take(2).join(' - ')
          : (cv.hasUploadedCv
                ? AppLocalizations.of(context)!.studentPrimaryFileAttached
                : AppLocalizations.of(context)!.studentProfileDataSynced),
      metaIcon: cv.hasUploadedCv
          ? Icons.file_present_outlined
          : Icons.auto_awesome_outlined,
      trailingLabel: _timeAgo(timestamp),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CvScreen()),
        );
      },
    );
  }

  OpportunityModel? _dashboardOpportunityById(
    OpportunityProvider provider,
    String opportunityId,
  ) {
    final normalizedId = opportunityId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final item in [
      ...provider.opportunities,
      ...provider.featuredOpportunities,
    ]) {
      if (item.id == normalizedId && item.isVisibleToStudents()) {
        return item;
      }
    }

    return null;
  }

  void _openSavedOpportunityActivity(
    BuildContext context,
    SavedOpportunityModel item,
    OpportunityProvider provider,
  ) {
    final opportunity = _dashboardOpportunityById(provider, item.opportunityId);
    if (opportunity != null) {
      OpportunityDetailScreen.show(context, opportunity);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedScreen()),
    );
  }

  void _openSavedScholarshipActivity(
    BuildContext context,
    SavedScholarshipModel item,
    ScholarshipProvider provider,
  ) {
    ScholarshipModel? scholarship;
    for (final candidate in provider.scholarships) {
      if (candidate.id == item.scholarshipId) {
        scholarship = candidate;
        break;
      }
    }

    if (scholarship != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScholarshipDetailScreen(scholarship: scholarship!),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedScreen()),
    );
  }

  Future<void> _openSavedTrainingActivity(
    BuildContext context,
    TrainingModel item,
  ) async {
    final link = item.displayLink.trim();
    if (link.isEmpty) {
      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedScreen()),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        AppLocalizations.of(
          context,
        )!.studentDashboardSavedResourceLinkUnavailable,
        title: AppLocalizations.of(context)!.uiLinkUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.studentDashboardSavedResourceOpenError,
        title: AppLocalizations.of(context)!.uiOpenUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  String _applicationActivityBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;

    switch (ApplicationStatus.parse(status)) {
      case ApplicationStatus.accepted:
        return l10n.uiApproved;
      case ApplicationStatus.rejected:
        return l10n.uiRejected;
      case ApplicationStatus.pending:
      default:
        return l10n.uiApplied;
    }
  }

  IconData _applicationActivityIcon(String status) {
    switch (ApplicationStatus.parse(status)) {
      case ApplicationStatus.accepted:
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case ApplicationStatus.pending:
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _applicationActivityColor(String status) {
    switch (ApplicationStatus.parse(status)) {
      case ApplicationStatus.accepted:
        return OpportunityDashboardPalette.success;
      case ApplicationStatus.rejected:
        return OpportunityDashboardPalette.error;
      case ApplicationStatus.pending:
      default:
        return accentGold;
    }
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  int _recentOpportunityTimestamp(OpportunityModel item) {
    return item.createdAt?.millisecondsSinceEpoch ??
        item.updatedAt?.millisecondsSinceEpoch ??
        item.applicationDeadline?.millisecondsSinceEpoch ??
        OpportunityMetadata.parseDateTimeLike(
          item.deadlineLabel,
        )?.millisecondsSinceEpoch ??
        0;
  }

  String recentOpportunitySupportingLine(
    OpportunityModel item,
    AppLocalizations l10n,
  ) {
    final parts = <String>[
      if (item.location.trim().isNotEmpty) item.location.trim(),
      if (_recentFriendlyDeadline(item) != null) _recentFriendlyDeadline(item)!,
    ];

    if (parts.isEmpty) {
      return OpportunityType.subtitle(item.type, l10n);
    }

    return parts.join(' • ');
  }

  String recentTrainingSupportingLine(TrainingModel item) {
    final parts = <String>[
      if (item.duration.trim().isNotEmpty)
        LocalizedDisplay.duration(context, item.duration),
      if (item.level.trim().isNotEmpty)
        LocalizedDisplay.metadataLabel(
          context,
          _recentCompactLabel(item.level),
        ),
    ];

    if (parts.isEmpty) {
      return _recentTrainingTypeLabel(item.type);
    }

    return parts.join(' • ');
  }

  String _recentTrainingTypeLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type.trim().toLowerCase()) {
      case 'book':
        return l10n.studentRecentTrainingBook;
      case 'course':
        return l10n.studentRecentTrainingCourse;
      case 'video':
        return l10n.studentRecentTrainingVideo;
      case 'file':
        return l10n.studentRecentTrainingFile;
      default:
        return l10n.studentRecentTrainingLearning;
    }
  }

  IconData _savedTrainingActivityIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'course':
        return Icons.play_lesson_rounded;
      case 'video':
        return Icons.ondemand_video_rounded;
      case 'file':
        return Icons.description_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  String? _recentFriendlyDeadline(OpportunityModel item) {
    final deadline = _opportunityDeadline(item);
    if (deadline != null) {
      return AppLocalizations.of(
        context,
      )!.studentClosesMonthDay(LocalizedDisplay.shortDate(context, deadline));
    }

    final raw = item.deadlineLabel.trim();
    if (raw.isEmpty) {
      return null;
    }

    return AppLocalizations.of(context)!.studentClosesMonthDay(raw);
  }

  String _recentCompactLabel(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return '';
    }

    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  BoxDecoration _recentCardDecoration(Color accent) {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: 0.24), width: 1),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Widget _buildRecentLabelChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 9.8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRecentArrowChip(Color accent) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: AppDirectionalIcon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: accent,
      ),
    );
  }

  Widget _buildRecentMetaItem({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final tone = color ?? textLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: tone),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.product(
            fontSize: 10.4,
            fontWeight: FontWeight.w500,
            color: tone == textLight ? textLight : tone,
          ),
        ),
      ],
    );
  }

  int _missingProfileSignals(UserModel? user, CvModel? cv) {
    return buildStudentProfileCompletionSummary(user, cv).missingCount;
  }

  bool _isHomeOpportunity(OpportunityModel item) {
    return item.isVisibleToStudents();
  }

  int _daysUntil(DateTime value) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.difference(startOfToday).inDays;
  }

  List<OpportunityModel> _recommendedOpportunities({
    required UserModel? user,
    required List<OpportunityModel> opportunities,
    required List<OpportunityModel> featuredOpportunities,
  }) {
    final featuredIds = featuredOpportunities
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final seen = <String>{};
    final candidates = opportunities
        .where((item) => seen.add(item.id))
        .toList(growable: false);

    final sorted = [...candidates];
    sorted.sort((a, b) {
      final scoreComparison =
          _recommendationScore(
            b,
            user,
            isFeaturedOverride: featuredIds.contains(b.id),
          ).compareTo(
            _recommendationScore(
              a,
              user,
              isFeaturedOverride: featuredIds.contains(a.id),
            ),
          );
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      final firstDays = _opportunityDeadline(a) == null
          ? 999
          : (_daysUntil(_opportunityDeadline(a)!) < 0
                ? 999
                : _daysUntil(_opportunityDeadline(a)!));
      final secondDays = _opportunityDeadline(b) == null
          ? 999
          : (_daysUntil(_opportunityDeadline(b)!) < 0
                ? 999
                : _daysUntil(_opportunityDeadline(b)!));
      if (firstDays != secondDays) {
        return firstDays.compareTo(secondDays);
      }

      return _recentOpportunityTimestamp(
        b,
      ).compareTo(_recentOpportunityTimestamp(a));
    });

    return sorted.take(8).toList(growable: false);
  }

  int _recommendationScore(
    OpportunityModel item,
    UserModel? user, {
    bool isFeaturedOverride = false,
  }) {
    var score = 0;
    final haystack = _opportunitySearchText(item);
    final field = _formatStudentIdentityValue(user?.fieldOfStudy);
    final level = _formatStudentIdentityValue(user?.academicLevel);
    final university = _formatStudentIdentityValue(user?.university);
    final location = _formatStudentIdentityValue(user?.location);
    final deadline = _opportunityDeadline(item);
    final daysLeft = deadline == null ? null : _daysUntil(deadline);
    final workMode = (item.workMode ?? '').trim().toLowerCase();

    if (isFeaturedOverride || item.isFeatured) {
      score += 80;
    }
    if (_matchesRecommendationSignal(field, haystack)) {
      score += 38;
    }
    if (_matchesRecommendationSignal(level, haystack)) {
      score += 18;
    }
    if (_matchesRecommendationSignal(university, haystack)) {
      score += 12;
    }
    if (_matchesRecommendationSignal(location, haystack)) {
      score += 10;
    }
    if (OpportunityType.parse(item.type) == OpportunityType.internship) {
      score += 16;
    }
    if (workMode == 'remote') {
      score += 14;
    } else if (workMode == 'hybrid') {
      score += 10;
    }
    if (item.isPaid == true) {
      score += 12;
    }
    if (daysLeft != null && daysLeft >= 0 && daysLeft <= 10) {
      score += 18;
    } else if (daysLeft != null && daysLeft >= 0 && daysLeft <= 21) {
      score += 10;
    }
    if ((item.tags.isNotEmpty) || (item.requirementItems.isNotEmpty)) {
      score += 6;
    }
    if (_recentOpportunityTimestamp(item) > 0) {
      final publishedAt = DateTime.fromMillisecondsSinceEpoch(
        _recentOpportunityTimestamp(item),
      );
      if (DateTime.now().difference(publishedAt).inDays <= 7) {
        score += 8;
      }
    }

    return score;
  }

  String _recommendationReason(OpportunityModel item, UserModel? user) {
    final haystack = _opportunitySearchText(item);
    final field = _formatStudentIdentityValue(user?.fieldOfStudy);
    final level = _formatStudentIdentityValue(user?.academicLevel);
    final location = _formatStudentIdentityValue(user?.location);
    final deadline = _opportunityDeadline(item);
    final daysLeft = deadline == null ? null : _daysUntil(deadline);
    final workMode = (item.workMode ?? '').trim().toLowerCase();

    if (_matchesRecommendationSignal(field, haystack)) {
      final compactField = _compactRecommendationValue(field);
      if (compactField.isNotEmpty) {
        return AppLocalizations.of(
          context,
        )!.studentRecommendationFitsFocus(compactField);
      }
    }
    if (_matchesRecommendationSignal(level, haystack)) {
      final compactLevel = _compactRecommendationValue(level);
      if (compactLevel.isNotEmpty) {
        return AppLocalizations.of(
          context,
        )!.studentRecommendationGoodForLevel(compactLevel);
      }
    }
    if (_matchesRecommendationSignal(location, haystack)) {
      return AppLocalizations.of(context)!.studentRecommendationNearLocation;
    }
    if (workMode == 'remote') {
      return AppLocalizations.of(context)!.studentRecommendationRemoteFriendly;
    }
    if (workMode == 'hybrid') {
      return AppLocalizations.of(context)!.studentRecommendationHybridSchedule;
    }
    if (item.isPaid == true) {
      return AppLocalizations.of(context)!.studentRecommendationPaidOpportunity;
    }
    if (daysLeft != null && daysLeft >= 0 && daysLeft <= 7) {
      return AppLocalizations.of(context)!.studentDeadlineComingUp;
    }
    if (item.isFeatured) {
      return AppLocalizations.of(context)!.studentRecommendationTeamHighlighted;
    }

    switch (OpportunityType.parse(item.type)) {
      case OpportunityType.internship:
        return AppLocalizations.of(
          context,
        )!.studentRecommendationBuildsExperience;
      case OpportunityType.sponsoring:
        return AppLocalizations.of(context)!.studentRecommendationSupportPath;
      case OpportunityType.job:
      default:
        return AppLocalizations.of(
          context,
        )!.studentRecommendationStrongNextStep;
    }
  }

  String _compactRecommendationValue(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return '';
    }

    if (words.length == 1) {
      return words.first;
    }

    final twoWords = words.take(2).join(' ');
    if (twoWords.length <= 18) {
      return twoWords;
    }

    return words.first;
  }

  String _opportunitySearchText(OpportunityModel item) {
    return <String>[
      item.title,
      item.description,
      item.requirements,
      item.companyName,
      item.location,
      item.workMode ?? '',
      item.duration ?? '',
      item.compensationText ?? '',
      item.fundingLabel() ?? '',
      item.tags.join(' '),
      item.requirementItems.join(' '),
      item.benefits.join(' '),
    ].join(' ').toLowerCase();
  }

  bool _matchesRecommendationSignal(String value, String haystack) {
    final normalized = value.trim().toLowerCase();
    if (normalized.length < 3) {
      return false;
    }

    return haystack.contains(normalized);
  }

  String _greetingForTime(DateTime currentTime, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = currentTime.hour;
    if (hour < 12) return l10n.uiGoodMorning;
    if (hour < 18) return l10n.uiGoodAfternoon;
    return l10n.uiGoodEvening;
  }

  String? _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return l10n.uiJustNow;
    }
    if (difference.inHours < 1) {
      return l10n.studentMinutesAgoCompact(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return l10n.studentHoursAgoCompact(difference.inHours);
    }
    if (difference.inDays < 7) {
      return l10n.studentDaysAgoCompact(difference.inDays);
    }
    return l10n.studentWeeksAgoCompact((difference.inDays / 7).floor());
  }

  String _summarize(String text, {required String fallback}) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return fallback;
    }
    if (normalized.length <= 82) {
      return normalized;
    }
    return '${normalized.substring(0, 79).trimRight()}...';
  }

  String _studentIdentityLine(UserModel? user) {
    final level = _formatStudentIdentityValue(user?.academicLevel);
    final field = _formatStudentIdentityValue(user?.fieldOfStudy);
    final university = _formatStudentIdentityValue(user?.university);

    if (level.isNotEmpty && field.isNotEmpty) {
      return '$level • $field';
    }
    if (level.isNotEmpty) {
      return level;
    }
    if (field.isNotEmpty) {
      return field;
    }
    if (university.isNotEmpty) {
      return university;
    }

    return '';
  }

  String _formatStudentIdentityValue(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }

    const replacements = <String, String>{
      'info': 'Info',
      'cs': 'CS',
      'it': 'IT',
      'ai': 'AI',
      'licence': 'Licence',
      'license': 'License',
      'master': 'Master',
      'bachelor': 'Bachelor',
      'phd': 'PhD',
    };

    final lower = raw.toLowerCase();
    if (replacements.containsKey(lower)) {
      return replacements[lower]!;
    }

    final words = raw
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length <= 2) {
            return part.toUpperCase();
          }
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .toList();

    return words.join(' ');
  }

  bool _hasReadyCv(CvModel? cv) {
    return hasReadyStudentCv(cv);
  }

  int _profileCompletionPercent(UserModel? user, CvModel? cv) {
    return buildStudentProfileCompletionSummary(user, cv).completionPercent;
  }

  String _profileHint(UserModel? user, CvModel? cv) {
    final profileSummary = buildStudentProfileCompletionSummary(user, cv);
    if (!profileSummary.hasReadyCv) {
      return AppLocalizations.of(context)!.studentProfileHintAddCv;
    }
    if ((user?.academicLevel ?? '').trim().isEmpty ||
        (user?.fieldOfStudy ?? '').trim().isEmpty ||
        (user?.university ?? '').trim().isEmpty) {
      return AppLocalizations.of(context)!.studentProfileHintAcademic;
    }
    if ((user?.bio ?? '').trim().isEmpty) {
      return AppLocalizations.of(context)!.studentProfileHintBio;
    }
    if ((user?.fullName ?? '').trim().isEmpty ||
        (user?.email ?? '').trim().isEmpty ||
        (user?.location ?? '').trim().isEmpty ||
        (user?.phone ?? '').trim().isEmpty) {
      return AppLocalizations.of(context)!.studentProfileHintContact;
    }

    return AppLocalizations.of(context)!.studentProfileHintGoodShape;
  }

  String _profilePrimaryActionLabel(UserModel? user, CvModel? cv) {
    final profileSummary = buildStudentProfileCompletionSummary(user, cv);
    if (!profileSummary.hasReadyCv) {
      return AppLocalizations.of(context)!.studentAddCv;
    }

    if (!profileSummary.isComplete) {
      return AppLocalizations.of(context)!.studentCompleteProfile;
    }

    return AppLocalizations.of(context)!.studentReviewProfile;
  }

  void _openProfilePrimaryAction(
    BuildContext context,
    UserModel? user,
    CvModel? cv,
  ) {
    if (!_hasReadyCv(cv)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CvScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Color _progressColor(int completion) {
    if (completion >= 80) {
      return accentTeal;
    }
    if (completion >= 55) {
      return primaryPurple;
    }

    return accentGold;
  }

  List<OpportunityModel> _closingSoonOpportunities(
    List<OpportunityModel> items,
  ) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final results = items.where((item) {
      if (!_isHomeOpportunity(item)) {
        return false;
      }

      final deadline = _opportunityDeadline(item);
      if (deadline == null) {
        return false;
      }

      final normalized = DateTime(deadline.year, deadline.month, deadline.day);
      final daysLeft = normalized.difference(startOfToday).inDays;
      return daysLeft >= 0 && daysLeft <= 14;
    }).toList();

    results.sort((a, b) {
      final first = _opportunityDeadline(a) ?? DateTime(9999);
      final second = _opportunityDeadline(b) ?? DateTime(9999);
      return first.compareTo(second);
    });

    return results;
  }

  DateTime? _opportunityDeadline(OpportunityModel item) {
    return item.effectiveDeadline;
  }

  String _deadlineCountdown(DateTime deadline) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final normalized = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = normalized.difference(startOfToday).inDays;

    if (difference <= 0) {
      return l10n.dashLastDay;
    }
    if (difference == 1) {
      return l10n.dashDayLeft;
    }
    return l10n.dashDaysLeft(difference);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(
    String title, {
    required String subtitle,
    Color? accentColor,
    VoidCallback? onSeeAll,
  }) {
    return OpportunitySectionHeader(
      title: title,
      subtitle: subtitle,
      actionLabel: onSeeAll != null
          ? AppLocalizations.of(context)!.uiViewAll
          : null,
      onAction: onSeeAll,
      accentColor: accentColor ?? accentTeal,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: softLavender,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: primaryPurple, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: AppTypography.product(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.product(fontSize: 12, color: textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Data classes
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardSnapshot {
  final int savedCount;
  final int savedOpportunityCount;
  final int savedScholarshipCount;
  final int savedTrainingCount;
  final int savedIdeaCount;
  final int appliedCount;
  final int pendingApplicationsCount;
  final int approvedApplicationsCount;
  final int rejectedApplicationsCount;
  final List<OpportunityModel> closingSoonItems;
  final List<OpportunityModel> recommendedItems;
  final List<OpportunityModel> discoverableOpportunities;
  final int jobsCount;
  final int internshipsCount;
  final int sponsoringCount;
  final int learningCount;

  int get closingSoonCount => closingSoonItems.length;

  const _DashboardSnapshot({
    required this.savedCount,
    required this.savedOpportunityCount,
    required this.savedScholarshipCount,
    required this.savedTrainingCount,
    required this.savedIdeaCount,
    required this.appliedCount,
    required this.pendingApplicationsCount,
    required this.approvedApplicationsCount,
    required this.rejectedApplicationsCount,
    required this.closingSoonItems,
    required this.recommendedItems,
    required this.discoverableOpportunities,
    required this.jobsCount,
    required this.internshipsCount,
    required this.sponsoringCount,
    required this.learningCount,
  });
}

class _DashboardFocus {
  final String badgeLabel;
  final String title;
  final String subtitle;
  final String insight;
  final Color accent;
  final IconData insightIcon;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onPrimaryAction;
  final String secondaryActionLabel;
  final IconData secondaryActionIcon;
  final VoidCallback onSecondaryAction;

  const _DashboardFocus({
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    required this.insight,
    required this.accent,
    required this.insightIcon,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.secondaryActionLabel,
    required this.secondaryActionIcon,
    required this.onSecondaryAction,
  });
}

class _QuickAccessTileItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessTileItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DashboardActivityEntry {
  final String dedupeKey;
  final DateTime sortDate;
  final String badgeLabel;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? metaLabel;
  final IconData? metaIcon;
  final Color? metaColor;
  final String? trailingLabel;
  final VoidCallback onTap;

  const _DashboardActivityEntry({
    required this.dedupeKey,
    required this.sortDate,
    required this.badgeLabel,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.metaLabel,
    this.metaIcon,
    this.metaColor,
    this.trailingLabel,
    required this.onTap,
  });
}

class _ProfileCompletionRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProfileCompletionRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileCompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
