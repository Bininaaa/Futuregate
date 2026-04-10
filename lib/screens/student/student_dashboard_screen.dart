import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
import '../../utils/application_status.dart';
import '../../utils/student_profile_completion.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/application_status_badge.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_dashboard_widgets.dart';
import '../../widgets/opportunity_type_badge.dart';
import '../../widgets/profile_avatar.dart';
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
  static const Color primaryPurple = OpportunityDashboardPalette.primary;
  static const Color deepPurple = OpportunityDashboardPalette.primaryDark;
  static const Color lightPurple = Color(0xFFEFF4FF);
  static const Color softLavender = Color(0xFFF4F7FB);
  static const Color accentTeal = OpportunityDashboardPalette.secondary;
  static const Color accentGold = OpportunityDashboardPalette.accent;
  static const Color cardWhite = OpportunityDashboardPalette.surface;
  static const Color textDark = OpportunityDashboardPalette.textPrimary;
  static const Color textMedium = OpportunityDashboardPalette.textSecondary;
  static const Color textLight = Color(0xFF94A3B8);
  static const Color cardBorder = OpportunityDashboardPalette.border;

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
      if (!mounted) {
        return;
      }

      setState(() {
        _isBootstrappingDashboard = false;
      });
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
                child: _buildSectionHeader('Closing Soon'),
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
                  'Recommended',
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
                child: _buildSectionHeader('Quick Access'),
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
                child: _buildSectionHeader('Latest Activities'),
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
        gradient: const LinearGradient(
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
                          _greetingForTime(_now),
                          style: GoogleFonts.poppins(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firstName,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (studentIdentity.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            studentIdentity,
                            style: GoogleFonts.poppins(
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
                                  style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
        badgeLabel: 'NEXT STEP',
        title: 'Build your CV first.',
        subtitle:
            'A ready CV makes jobs, internships, and scholarships much quicker to apply for.',
        insight:
            'Start with your CV, then tighten the profile details that make matching feel smarter.',
        accent: accentGold,
        insightIcon: Icons.description_outlined,
        primaryActionLabel: 'Build CV',
        primaryActionIcon: Icons.description_outlined,
        onPrimaryAction: openCv,
        secondaryActionLabel: 'Complete Profile',
        secondaryActionIcon: Icons.person_outline_rounded,
        onSecondaryAction: openProfile,
      );
    }

    if (profileCompletion < 100) {
      return _DashboardFocus(
        badgeLabel: 'PROFILE $profileCompletion% READY',
        title: 'Complete your profile.',
        subtitle:
            '$missingCount ${_pluralizedWord(missingCount, "detail is", "details are")} still missing for better matching.',
        insight: _profileHint(user, cv),
        accent: accentGold,
        insightIcon: Icons.verified_user_outlined,
        primaryActionLabel: 'Complete Profile',
        primaryActionIcon: Icons.person_outline_rounded,
        onPrimaryAction: openProfile,
        secondaryActionLabel: 'Discover',
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    if (snapshot.approvedApplicationsCount > 0) {
      final approved = snapshot.approvedApplicationsCount;
      final pending = snapshot.pendingApplicationsCount;
      return _DashboardFocus(
        badgeLabel: 'MOMENTUM',
        title:
            '$approved ${_pluralizedWord(approved, "application", "applications")} approved.',
        subtitle:
            'Keep applying while teams are already engaging with your profile.',
        insight: pending > 0
            ? '$pending ${_pluralizedWord(pending, "application is", "applications are")} still in review.'
            : firstUrgent != null && firstUrgentDeadline != null
            ? '${firstUrgent.title} closes ${_deadlineCountdown(firstUrgentDeadline).toLowerCase()}.'
            : 'This is a strong moment to keep exploring while your profile is landing well.',
        accent: const Color(0xFF86EFAC),
        insightIcon: Icons.verified_rounded,
        primaryActionLabel: 'View Status',
        primaryActionIcon: Icons.assignment_turned_in_outlined,
        onPrimaryAction: openApplications,
        secondaryActionLabel: 'Discover',
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    if (snapshot.pendingApplicationsCount > 0) {
      final pending = snapshot.pendingApplicationsCount;
      return _DashboardFocus(
        badgeLabel: 'IN REVIEW',
        title:
            '$pending ${_pluralizedWord(pending, "application", "applications")} in review.',
        subtitle:
            'Keep a few strong options moving while you wait for responses.',
        insight: firstUrgent != null && firstUrgentDeadline != null
            ? '${firstUrgent.title} at ${firstUrgent.companyName} closes ${_deadlineCountdown(firstUrgentDeadline).toLowerCase()}.'
            : 'A little follow-through now keeps your pipeline healthier later.',
        accent: accentTeal,
        insightIcon: Icons.hourglass_top_rounded,
        primaryActionLabel: 'Track Status',
        primaryActionIcon: Icons.assignment_turned_in_outlined,
        onPrimaryAction: openApplications,
        secondaryActionLabel: 'Discover',
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    if (snapshot.closingSoonCount > 0 && firstUrgent != null) {
      final deadlineLabel = firstUrgentDeadline == null
          ? 'deadline soon'
          : _deadlineCountdown(firstUrgentDeadline).toLowerCase();
      return _DashboardFocus(
        badgeLabel:
            '${snapshot.closingSoonCount} ${snapshot.closingSoonCount == 1 ? "DEADLINE" : "DEADLINES"} SOON',
        title: 'Act before deadlines close.',
        subtitle:
            '${snapshot.closingSoonCount} opportunities close within the next two weeks.',
        insight:
            '${firstUrgent.companyName} is first up, and it closes $deadlineLabel.',
        accent: accentGold,
        insightIcon: Icons.schedule_outlined,
        primaryActionLabel: 'See Open Roles',
        primaryActionIcon: Icons.explore_outlined,
        onPrimaryAction: openDiscover,
        secondaryActionLabel: snapshot.savedCount > 0
            ? 'Open Saved'
            : 'Build CV',
        secondaryActionIcon: snapshot.savedCount > 0
            ? Icons.bookmark_outline_rounded
            : Icons.description_outlined,
        onSecondaryAction: snapshot.savedCount > 0 ? openSaved : openCv,
      );
    }

    if (snapshot.savedCount > 0) {
      return _DashboardFocus(
        badgeLabel: 'SAVED PICKS',
        title: 'Your shortlist is ready.',
        subtitle: 'Revisit saved picks before the strongest deadlines slip by.',
        insight:
            'Your saved list is ready for a second pass before deadlines tighten.',
        accent: primaryPurple,
        insightIcon: Icons.bookmark_added_outlined,
        primaryActionLabel: 'Open Saved',
        primaryActionIcon: Icons.bookmark_outline_rounded,
        onPrimaryAction: openSaved,
        secondaryActionLabel: 'Discover',
        secondaryActionIcon: Icons.explore_outlined,
        onSecondaryAction: openDiscover,
      );
    }

    return _DashboardFocus(
      badgeLabel: 'DISCOVER',
      title: 'Find your next best opportunity.',
      subtitle:
          'Explore open roles, internships, funding, and learning picks designed for students building momentum.',
      insight:
          'Use quick access below to jump into jobs, internships, scholarships, learning, or your saved shortlist.',
      accent: primaryPurple,
      insightIcon: Icons.auto_awesome_rounded,
      primaryActionLabel: 'Discover',
      primaryActionIcon: Icons.explore_outlined,
      onPrimaryAction: openDiscover,
      secondaryActionLabel: 'Build CV',
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
                  style: GoogleFonts.poppins(
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
    final totalSaved = snapshot.savedCount;
    final summary = totalSaved == 0
        ? 'Keep your strongest roles, funding, and learning picks one tap away.'
        : '$totalSaved ${_pluralizedWord(totalSaved, "saved item", "saved items")} ready for a second look.';
    final chips = <Widget>[
      if (snapshot.savedOpportunityCount > 0)
        _buildSavedShortcutChip(
          '${snapshot.savedOpportunityCount} ${_pluralizedWord(snapshot.savedOpportunityCount, "role", "roles")}',
        ),
      if (snapshot.savedScholarshipCount > 0)
        _buildSavedShortcutChip(
          '${snapshot.savedScholarshipCount} ${_pluralizedWord(snapshot.savedScholarshipCount, "scholarship", "scholarships")}',
        ),
      if (snapshot.savedTrainingCount > 0)
        _buildSavedShortcutChip('${snapshot.savedTrainingCount} learning'),
      if (snapshot.savedIdeaCount > 0)
        _buildSavedShortcutChip(
          '${snapshot.savedIdeaCount} ${_pluralizedWord(snapshot.savedIdeaCount, "idea", "ideas")}',
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
                            'Saved shortlist',
                            style: GoogleFonts.poppins(
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
                            totalSaved == 0
                                ? 'Start saving'
                                : '$totalSaved saved',
                            style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
                child: const Icon(
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
        style: GoogleFonts.poppins(
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
        title: 'Jobs',
        icon: Icons.work_outline_rounded,
        color: const Color(0xFF6C63FF),
        onTap: () =>
            _openQuickAccessPage(context, builder: (_) => const JobsScreen()),
      ),
      _QuickAccessTileItem(
        title: 'Internships',
        icon: Icons.school_outlined,
        color: const Color(0xFF19C37D),
        onTap: () => _openQuickAccessPage(
          context,
          builder: (_) => const InternshipsScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: 'Sponsored',
        icon: Icons.campaign_outlined,
        color: const Color(0xFFFFB341),
        onTap: () => _openQuickAccessPage(
          context,
          builder: (_) => const SponsoredOpportunitiesScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: 'Scholarships',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFF47D16C),
        onTap: () => _openQuickAccessTab(
          context,
          tabIndex: StudentHomeNavigation.scholarshipsTab,
          standaloneBuilder: (_) => const ScholarshipsScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: 'Ideas',
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFFFF6B6B),
        onTap: () => _openQuickAccessTab(
          context,
          tabIndex: StudentHomeNavigation.ideasTab,
          standaloneBuilder: (_) => const ProjectIdeasScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: 'CV Builder',
        icon: Icons.description_outlined,
        color: deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CvScreen()),
        ),
      ),
      _QuickAccessTileItem(
        title: 'Training',
        icon: Icons.cast_for_education_outlined,
        color: const Color(0xFF22CFC3),
        onTap: () => _openQuickAccessTab(
          context,
          tabIndex: StudentHomeNavigation.trainingTab,
          standaloneBuilder: (_) => const TrainingsScreen(),
        ),
      ),
      _QuickAccessTileItem(
        title: 'Saved',
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
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.poppins(
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
                      'Complete your profile',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completion% ready for better student matching',
                      style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
                  textStyle: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('View profile'),
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
      return const SizedBox(
        height: 124,
        child: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 20),
        child: _buildEmptyState(
          icon: Icons.schedule_outlined,
          message: 'No urgent deadlines right now',
          subtitle:
              'Upcoming deadlines are highlighted here as new opportunities go live.',
        ),
      );
    }

    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
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
    final normalizedType = OpportunityType.parse(item.type);
    final accent = OpportunityType.color(normalizedType);
    final deadline = _opportunityDeadline(item);
    final dateLabel = deadline == null
        ? item.deadlineLabel
        : OpportunityMetadata.formatDateLabel(deadline);
    final urgencyColor = _closingSoonUrgencyColor(deadline);
    final deadlineLabel = deadline == null
        ? 'Deadline soon'
        : _deadlineCountdown(deadline);
    final footerLabel = _closingSoonFooterLabel(normalizedType, dateLabel);
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
                          OpportunityType.label(normalizedType),
                          style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
                item.title,
                style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                      Icons.schedule_outlined,
                      size: 14,
                      color: urgencyColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        footerLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10.6,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
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
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  String _closingSoonFooterLabel(String type, String dateLabel) {
    switch (OpportunityType.parse(type)) {
      case OpportunityType.internship:
        return 'Closes $dateLabel';
      case OpportunityType.sponsoring:
        return 'Closes $dateLabel';
      case OpportunityType.job:
      default:
        return 'Apply by $dateLabel';
    }
  }

  String _closingSoonLocationFallback(String type) {
    switch (OpportunityType.parse(type)) {
      case OpportunityType.internship:
        return 'Student placement';
      case OpportunityType.sponsoring:
        return 'Partner-backed program';
      case OpportunityType.job:
      default:
        return 'Career opportunity';
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
    final provider = context.watch<OpportunityProvider>();
    final appliedStatusMap = context
        .watch<ApplicationProvider>()
        .appliedStatusMap;
    final items = snapshot.recommendedItems;
    final isLoading =
        items.isEmpty && (provider.isFeaturedLoading || provider.isLoading);

    if (isLoading) {
      return const SizedBox(
        height: 210,
        child: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        message: 'No recommendations right now',
        subtitle: 'Check back soon for fresh curated opportunities.',
      );
    }

    return SizedBox(
      height: 220,
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

  Widget _buildRecommendedCard(
    BuildContext context,
    OpportunityModel item,
    UserModel? user, {
    String? applicationStatus,
  }) {
    final freshness = _timeAgo(
      item.createdAt?.toDate() ?? item.updatedAt?.toDate(),
    );
    final accent = OpportunityType.color(item.type);
    final reason = _recommendationReason(item, user);
    final deadlineLabel = _recentFriendlyDeadline(item);
    final normalizedType = OpportunityType.parse(item.type);
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
            border: Border.all(color: accent.withValues(alpha: 0.12)),
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
                      style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                item.title,
                style: GoogleFonts.poppins(
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
                  fallback: 'A strong opportunity worth a closer look.',
                ),
                style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                  if (deadlineLabel != null)
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
                          Icon(Icons.schedule, size: 11, color: accent),
                          const SizedBox(width: 3),
                          Text(
                            deadlineLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 9.2,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Open details',
                      style: GoogleFonts.poppins(
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
                    child: Icon(
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
    final borderRadius = size <= 38 ? 11.0 : 12.0;
    final fontSize = size <= 38 ? 16.0 : 18.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: softLavender,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Center(
                child: Text(
                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: primaryPurple,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => Center(
                child: Text(
                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: primaryPurple,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: primaryPurple,
                ),
              ),
            ),
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
          const SizedBox(
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
            message: 'No recent activity yet',
            subtitle:
                'Your latest applications, saves, and CV updates are reflected here.',
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
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              item.trailingLabel!,
                              style: GoogleFonts.poppins(
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
                      item.title,
                      style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
              ? 'Closes ${DateFormat('MMM d').format(deadline)}'
              : item.location;

          return _DashboardActivityEntry(
            dedupeKey: 'application:${item.id}',
            sortDate: item.appliedAt!,
            badgeLabel: _applicationActivityBadge(item.status),
            accent: accent,
            icon: _applicationActivityIcon(item.status),
            title: item.title,
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
                ? 'Saved ${OpportunityType.lowercaseLabel(item.type)} from $companyName'
                : 'Saved ${OpportunityType.lowercaseLabel(item.type)} that needs attention'
          : (companyName.isNotEmpty
                ? companyName
                : OpportunityType.label(item.type));
      final meta = deadline != null
          ? 'Closes ${DateFormat('MMM d').format(deadline)}'
          : item.location.trim();

      activities.add(
        _DashboardActivityEntry(
          dedupeKey: key,
          sortDate: savedAt,
          badgeLabel: isUrgent
              ? 'Closing soon'
              : 'Saved ${OpportunityType.lowercaseLabel(item.type)}',
          accent: accent,
          icon: isUrgent
              ? Icons.schedule_outlined
              : OpportunityType.icon(item.type),
          title: item.title.trim().isNotEmpty
              ? item.title.trim()
              : 'Saved opportunity',
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
                ? 'Saved scholarship from $providerName'
                : 'Saved scholarship that needs attention'
          : (providerName.isNotEmpty ? providerName : 'Scholarship');
      final meta = deadline != null
          ? 'Closes ${DateFormat('MMM d').format(deadline)}'
          : _firstNonEmpty([item.level, item.location, item.fundingType]);

      activities.add(
        _DashboardActivityEntry(
          dedupeKey: key,
          sortDate: savedAt,
          badgeLabel: isUrgent ? 'Closing soon' : 'Saved scholarship',
          accent: accent,
          icon: isUrgent
              ? Icons.schedule_outlined
              : Icons.emoji_events_outlined,
          title: item.title.trim().isNotEmpty
              ? item.title.trim()
              : 'Saved scholarship',
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
            badgeLabel: 'Saved ${typeLabel.toLowerCase()}',
            accent: accentTeal,
            icon: _savedTrainingActivityIcon(item.type),
            title: item.title.trim().isNotEmpty
                ? item.title.trim()
                : 'Saved resource',
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
            badgeLabel: 'Saved idea',
            accent: const Color(0xFFFF6B6B),
            icon: Icons.lightbulb_outline_rounded,
            title: item.idea.title.trim().isNotEmpty
                ? item.idea.title.trim()
                : 'Saved idea',
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
      'uploaded' => 'Uploaded CV is ready to send',
      'hybrid' => 'Uploaded and builder CV assets are ready',
      _ =>
        cv.hasBuilderContent
            ? 'Builder CV refreshed for faster applications'
            : 'CV is ready for your next application',
    };

    final cvSignals = <String>[
      if (cv.skills.isNotEmpty)
        '${cv.skills.length} ${_pluralizedWord(cv.skills.length, "skill", "skills")}',
      if (cv.experience.isNotEmpty)
        '${cv.experience.length} ${_pluralizedWord(cv.experience.length, "experience block", "experience blocks")}',
      if (cv.languages.isNotEmpty)
        '${cv.languages.length} ${_pluralizedWord(cv.languages.length, "language", "languages")}',
    ];

    return _DashboardActivityEntry(
      dedupeKey: 'cv:${cv.id.isNotEmpty ? cv.id : cv.studentId}',
      sortDate: timestamp,
      badgeLabel: 'CV updated',
      accent: primaryPurple,
      icon: Icons.description_outlined,
      title: cv.hasUploadedCv ? 'Your CV is ready' : 'Builder CV updated',
      subtitle: subtitle,
      metaLabel: cvSignals.isNotEmpty
          ? cvSignals.take(2).join(' - ')
          : (cv.hasUploadedCv
                ? 'Primary file attached'
                : 'Profile data synced'),
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
      if (item.id == normalizedId && !item.isHidden) {
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
        'This saved resource link is not available.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      context.showAppSnackBar(
        'We couldn\'t open this saved resource right now.',
        title: 'Open unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  String _applicationActivityBadge(String status) {
    switch (ApplicationStatus.parse(status)) {
      case ApplicationStatus.accepted:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Update';
      case ApplicationStatus.pending:
      default:
        return 'Applied';
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

  String recentOpportunitySupportingLine(OpportunityModel item) {
    final parts = <String>[
      if (item.location.trim().isNotEmpty) item.location.trim(),
      if (_recentFriendlyDeadline(item) != null) _recentFriendlyDeadline(item)!,
    ];

    if (parts.isEmpty) {
      return OpportunityType.subtitle(item.type);
    }

    return parts.join(' • ');
  }

  String recentTrainingSupportingLine(TrainingModel item) {
    final parts = <String>[
      if (item.duration.trim().isNotEmpty) item.duration.trim(),
      if (item.level.trim().isNotEmpty) _recentCompactLabel(item.level),
    ];

    if (parts.isEmpty) {
      return _recentTrainingTypeLabel(item.type);
    }

    return parts.join(' • ');
  }

  String _recentTrainingTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'book':
        return 'Book';
      case 'course':
        return 'Course';
      case 'video':
        return 'Video';
      case 'file':
        return 'File';
      default:
        return 'Learning';
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
      return 'Closes ${DateFormat('MMM d').format(deadline)}';
    }

    final raw = item.deadlineLabel.trim();
    if (raw.isEmpty) {
      return null;
    }

    return 'Closes $raw';
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
      border: Border.all(color: accent.withValues(alpha: 0.10)),
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
        style: GoogleFonts.poppins(
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
      child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: accent),
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
          style: GoogleFonts.poppins(
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

  String _pluralizedWord(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  bool _isHomeOpportunity(OpportunityModel item) {
    final status = item.status.trim().toLowerCase();
    if (item.isHidden || (status.isNotEmpty && status != 'open')) {
      return false;
    }

    final deadline = _opportunityDeadline(item);
    if (deadline != null && _daysUntil(deadline) < 0) {
      return false;
    }

    return true;
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
        return 'Fits your $compactField focus.';
      }
    }
    if (_matchesRecommendationSignal(level, haystack)) {
      final compactLevel = _compactRecommendationValue(level);
      if (compactLevel.isNotEmpty) {
        return 'Good for $compactLevel students.';
      }
    }
    if (_matchesRecommendationSignal(location, haystack)) {
      return 'Near your location.';
    }
    if (workMode == 'remote') {
      return 'Remote-friendly.';
    }
    if (workMode == 'hybrid') {
      return 'Hybrid schedule.';
    }
    if (item.isPaid == true) {
      return 'Paid opportunity.';
    }
    if (daysLeft != null && daysLeft >= 0 && daysLeft <= 7) {
      return 'Deadline coming up.';
    }
    if (item.isFeatured) {
      return 'Team-highlighted.';
    }

    switch (OpportunityType.parse(item.type)) {
      case OpportunityType.internship:
        return 'Builds real experience.';
      case OpportunityType.sponsoring:
        return 'Clear support path.';
      case OpportunityType.job:
      default:
        return 'Strong next step.';
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

  String _greetingForTime(DateTime currentTime) {
    final hour = currentTime.hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String? _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }
    return '${(difference.inDays / 7).floor()}w';
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
      return 'Add your CV so applications are quicker when the right opportunity appears.';
    }
    if ((user?.academicLevel ?? '').trim().isEmpty ||
        (user?.fieldOfStudy ?? '').trim().isEmpty ||
        (user?.university ?? '').trim().isEmpty) {
      return 'Complete your academic details so opportunities can feel more relevant to your student path.';
    }
    if ((user?.bio ?? '').trim().isEmpty) {
      return 'A short bio will make your profile look more complete and intentional.';
    }
    if ((user?.fullName ?? '').trim().isEmpty ||
        (user?.email ?? '').trim().isEmpty ||
        (user?.location ?? '').trim().isEmpty ||
        (user?.phone ?? '').trim().isEmpty) {
      return 'Tighten your core contact details so your profile feels complete everywhere in the app.';
    }

    return 'Your profile is in good shape for the next opportunity you open.';
  }

  String _profilePrimaryActionLabel(UserModel? user, CvModel? cv) {
    final profileSummary = buildStudentProfileCompletionSummary(user, cv);
    if (!profileSummary.hasReadyCv) {
      return 'Add CV';
    }

    if (!profileSummary.isComplete) {
      return 'Complete profile';
    }

    return 'Review profile';
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
    return item.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(item.deadline);
  }

  String _deadlineCountdown(DateTime deadline) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final normalized = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = normalized.difference(startOfToday).inDays;

    if (difference <= 0) {
      return 'Last day';
    }
    if (difference == 1) {
      return '1 day left';
    }
    return '$difference days left';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    String subtitle;
    Color accentColor;

    switch (title) {
      case 'Closing Soon':
        subtitle = 'Deadlines worth acting on this week.';
        accentColor = accentGold;
        break;
      case 'Recommended':
        subtitle = 'Chosen around your profile, timing, and momentum.';
        accentColor = accentTeal;
        break;
      case 'Quick Access':
        subtitle =
            'Your fastest path back into jobs, funding, tools, and saves.';
        accentColor = accentTeal;
        break;
      case 'Latest Activities':
        subtitle = 'Your recent applications, saves, and CV updates.';
        accentColor = accentTeal;
        break;
      default:
        subtitle = 'Everything important stays one tap away.';
        accentColor = accentTeal;
        break;
    }

    return OpportunitySectionHeader(
      title: title,
      subtitle: subtitle,
      actionLabel: onSeeAll != null ? 'See all' : null,
      onAction: onSeeAll,
      accentColor: accentColor,
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
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: textLight),
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
