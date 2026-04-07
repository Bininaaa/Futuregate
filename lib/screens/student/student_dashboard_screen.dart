import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../models/opportunity_model.dart';
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
import '../../providers/training_provider.dart';
import '../../utils/application_status.dart';
import '../../widgets/app_shell_background.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_dashboard_widgets.dart';
import '../../widgets/opportunity_type_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications_screen.dart';
import 'applied_opportunities_screen.dart';
import 'cv_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'opportunities_screen.dart';
import 'jobs_screen.dart';
import 'internships_screen.dart';
import 'opportunity_detail_screen.dart';
import 'project_ideas_screen.dart';
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
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBaseData();
      final studentId = context.read<AuthProvider>().userModel?.uid.trim();
      if (studentId != null && studentId.isNotEmpty) {
        _loadStudentData(studentId);
      }
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

  void _loadBaseData() {
    if (_didLoadBaseData) {
      return;
    }

    _didLoadBaseData = true;
    context.read<OpportunityProvider>().fetchFeaturedOpportunities();
    context.read<OpportunityProvider>().fetchOpportunities();
    context.read<TrainingProvider>().fetchTrainings();
  }

  void _loadStudentData(String studentId) {
    if (_loadedStudentId == studentId) {
      return;
    }

    _loadedStudentId = studentId;
    context.read<SavedOpportunityProvider>().fetchSavedOpportunities(studentId);
    context.read<SavedScholarshipProvider>().fetchSavedScholarships(studentId);
    context.read<TrainingProvider>().fetchSavedTrainings(studentId);
    context.read<ProjectIdeaProvider>().fetchSavedIdeas(studentId);
    context.read<ApplicationProvider>().fetchSubmittedApplications(studentId);
    context.read<CvProvider>().loadCv(studentId);
  }

  void _ensureDashboardData(UserModel? user) {
    final studentId = user?.uid.trim();
    if (_didLoadBaseData &&
        (studentId == null ||
            studentId.isEmpty ||
            _loadedStudentId == studentId)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadBaseData();
      if (studentId != null && studentId.isNotEmpty) {
        _loadStudentData(studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
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
    _ensureDashboardData(user);

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
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpportunitiesScreen(),
                      ),
                    );
                  },
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
                child: _buildQuickAccessSection(
                  context,
                  dashboardSnapshot,
                  profileCompletion: profileCompletion,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Recent',
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpportunitiesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: _buildRecentSection(context),
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
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.42),
                          width: 2,
                        ),
                      ),
                      child: ProfileAvatar(user: user, radius: 25),
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
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OpportunitiesScreen()),
      );
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. QUICK ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickAccessSection(
    BuildContext context,
    _DashboardSnapshot snapshot, {
    required int profileCompletion,
  }) {
    final cards = <_QuickAccessCardItem>[
      _QuickAccessCardItem(
        title: 'Jobs',
        subtitle: snapshot.jobsCount > 0
            ? '${snapshot.jobsCount} open ${_pluralizedWord(snapshot.jobsCount, "role", "roles")} ready to explore.'
            : 'Fresh roles from teams that are hiring.',
        badge: snapshot.jobsCount > 0 ? '${snapshot.jobsCount} open' : null,
        icon: Icons.work_outline_rounded,
        accent: const Color(0xFF6C63FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JobsScreen()),
        ),
      ),
      _QuickAccessCardItem(
        title: 'Internships',
        subtitle: snapshot.internshipsCount > 0
            ? '${snapshot.internshipsCount} open ${_pluralizedWord(snapshot.internshipsCount, "internship", "internships")} for hands-on growth.'
            : 'Hands-on experience built for students.',
        badge: snapshot.internshipsCount > 0
            ? '${snapshot.internshipsCount} open'
            : null,
        icon: Icons.school_outlined,
        accent: const Color(0xFF10B981),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InternshipsScreen()),
        ),
      ),
      _QuickAccessCardItem(
        title: 'Scholarships',
        subtitle: snapshot.savedScholarshipCount > 0
            ? '${snapshot.savedScholarshipCount} saved ${_pluralizedWord(snapshot.savedScholarshipCount, "scholarship", "scholarships")} waiting for a second look.'
            : 'Funding paths for study, mobility, and research.',
        badge: snapshot.savedScholarshipCount > 0
            ? '${snapshot.savedScholarshipCount} saved'
            : 'Funding',
        icon: Icons.emoji_events_outlined,
        accent: const Color(0xFF2ED573),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScholarshipsScreen()),
        ),
      ),
      _QuickAccessCardItem(
        title: 'Learning',
        subtitle: snapshot.learningCount > 0
            ? '${snapshot.learningCount} curated resources to sharpen your skills.'
            : 'Courses, books, and certificates to grow fast.',
        badge: snapshot.learningCount > 0 ? '${snapshot.learningCount}' : null,
        icon: Icons.cast_for_education_outlined,
        accent: const Color(0xFF00B894),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingsScreen()),
        ),
      ),
    ];

    final actions = <_QuickActionItem>[
      _QuickActionItem(
        title: 'Sponsorships',
        icon: Icons.workspace_premium_outlined,
        color: const Color(0xFFFF9F43),
        badge: snapshot.sponsoringCount > 0
            ? '${snapshot.sponsoringCount}'
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SponsoredOpportunitiesScreen(),
          ),
        ),
      ),
      _QuickActionItem(
        title: 'Ideas',
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFFFF6B6B),
        badge: snapshot.savedIdeaCount > 0
            ? '${snapshot.savedIdeaCount}'
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectIdeasScreen()),
        ),
      ),
      _QuickActionItem(
        title: 'CV Builder',
        icon: Icons.description_outlined,
        color: deepPurple,
        badge: profileCompletion == 100 ? 'Ready' : '$profileCompletion%',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CvScreen()),
        ),
      ),
      _QuickActionItem(
        title: 'Saved',
        icon: Icons.bookmark_outline_rounded,
        color: const Color(0xFFE17055),
        badge: snapshot.savedCount > 0 ? '${snapshot.savedCount}' : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;
            const spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
                crossAxisCount;
            final aspectRatio = crossAxisCount >= 4 ? 1.15 : 1.28;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: _buildQuickAccessCard(item),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map((item) => _buildQuickActionPill(item))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(_QuickAccessCardItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.accent.withValues(alpha: 0.16), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: item.accent.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: item.accent.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -12,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.accent, size: 20),
                      ),
                      const Spacer(),
                      if (item.badge != null)
                        _buildQuickAccessBadge(item.badge!, item.accent),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.1,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: textMedium,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionPill(_QuickActionItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: item.color.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: item.color, size: 16),
              const SizedBox(width: 8),
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              if (item.badge != null) ...[
                const SizedBox(width: 8),
                _buildQuickAccessBadge(item.badge!, item.color, compact: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessBadge(
    String label,
    Color color, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: compact ? 9.2 : 9.4,
          fontWeight: FontWeight.w700,
          color: color,
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
          subtitle: 'Closing dates will show here as new opportunities arrive.',
        ),
      );
    }

    return SizedBox(
      height: 182,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        itemCount: items.length > 4 ? 4 : items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildClosingSoonCard(context, items[index]);
        },
      ),
    );
  }

  Widget _buildClosingSoonCard(BuildContext context, OpportunityModel item) {
    final normalizedType = OpportunityType.parse(item.type);
    final accent = OpportunityType.color(normalizedType);
    final deadline = _opportunityDeadline(item);
    final deadlineLabel = deadline == null
        ? 'Deadline soon'
        : _deadlineCountdown(deadline);
    final dateLabel = deadline == null
        ? item.deadlineLabel
        : OpportunityMetadata.formatDateLabel(deadline);
    final urgencyColor = _closingSoonUrgencyColor(deadline);
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
        return 'Internship closes $dateLabel';
      case OpportunityType.sponsoring:
        return 'Program closes $dateLabel';
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

  Widget _buildRecommendedSection(
    BuildContext context,
    UserModel? user,
    _DashboardSnapshot snapshot,
  ) {
    final provider = context.watch<OpportunityProvider>();
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
        message: 'No recommendations yet',
        subtitle: 'Check back soon for curated opportunities.',
      );
    }

    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length > 6 ? 6 : items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _buildRecommendedCard(context, items[index], user);
        },
      ),
    );
  }

  Widget _buildRecommendedCard(
    BuildContext context,
    OpportunityModel item,
    UserModel? user,
  ) {
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
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 268,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(24),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Recommended for you',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: primaryPurple,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (freshness != null)
                    Text(
                      freshness,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildCompanyLogo(item.companyLogo, item.companyName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.companyName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
                              size: 12,
                              color: textLight,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                locationLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
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
              const SizedBox(height: 14),
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _summarize(
                  item.description,
                  fallback: 'A strong opportunity worth a closer look.',
                ),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: textMedium,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        reason,
                        style: GoogleFonts.poppins(
                          fontSize: 10.7,
                          height: 1.35,
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
              const Spacer(),
              Row(
                children: [
                  OpportunityTypeBadge(type: item.type, showIcon: false),
                  const Spacer(),
                  if (deadlineLabel != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 13, color: textLight),
                        const SizedBox(width: 3),
                        Text(
                          deadlineLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textMedium,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: primaryPurple,
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
  // 5. RECENT SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  SliverList _buildRecentSection(BuildContext context) {
    final oppProvider = context.watch<OpportunityProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final recentOpps = oppProvider.opportunities
        .where(_isHomeOpportunity)
        .toList();
    if (recentOpps.isEmpty) {
      recentOpps.addAll(
        oppProvider.featuredOpportunities.where(_isHomeOpportunity),
      );
    }
    recentOpps.sort(
      (a, b) => _recentOpportunityTimestamp(
        b,
      ).compareTo(_recentOpportunityTimestamp(a)),
    );

    final recentTrainings = trainingProvider.trainings
        .where((item) => item.isApproved && !item.isHidden)
        .toList();
    recentTrainings.sort(
      (a, b) =>
          _recentTrainingTimestamp(b).compareTo(_recentTrainingTimestamp(a)),
    );

    final recentItems = <_RecentItem>[
      ...recentOpps.take(6).map((item) => _RecentItem(opportunity: item)),
    ];

    if (recentItems.length < 4) {
      recentItems.addAll(
        recentTrainings
            .take(6 - recentItems.length)
            .map((item) => _RecentItem(training: item)),
      );
    }

    final isLoading =
        recentItems.isEmpty &&
        (oppProvider.isLoading || trainingProvider.isLoading);

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

    if (recentItems.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(
            icon: Icons.history,
            message: 'Nothing recent yet',
            subtitle: 'Latest opportunities will show here first',
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = recentItems[index];
        if (item.opportunity != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecentOpportunityCard(context, item.opportunity!),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecentTrainingCard(context, item.training!),
          );
        }
      }, childCount: recentItems.length),
    );
  }

  Widget _buildRecentOpportunityCard(
    BuildContext context,
    OpportunityModel item,
  ) {
    final normalizedType = OpportunityType.parse(item.type);
    final accent = OpportunityType.color(normalizedType);
    final freshness = _timeAgo(
      item.createdAt?.toDate() ?? item.updatedAt?.toDate(),
    );
    final deadlineLabel = _recentFriendlyDeadline(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          OpportunityDetailScreen.show(context, item);
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: _recentCardDecoration(accent),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  OpportunityType.icon(normalizedType),
                  color: accent,
                  size: 19,
                ),
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
                                label: OpportunityType.label(normalizedType),
                                color: accent,
                              ),
                              if (item.isFeatured)
                                _buildRecentLabelChip(
                                  label: 'Featured',
                                  color: primaryPurple,
                                ),
                            ],
                          ),
                        ),
                        if (freshness != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              freshness,
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
                      item.companyName.isNotEmpty
                          ? item.companyName
                          : OpportunityType.label(normalizedType),
                      style: GoogleFonts.poppins(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w600,
                        color: textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (item.location.trim().isNotEmpty)
                          _buildRecentMetaItem(
                            icon: Icons.location_on_outlined,
                            label: item.location.trim(),
                          ),
                        if (deadlineLabel != null)
                          _buildRecentMetaItem(
                            icon: Icons.schedule_outlined,
                            label: deadlineLabel,
                            color: accentGold,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRecentArrowChip(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTrainingCard(BuildContext context, TrainingModel item) {
    final freshness = _timeAgo(item.createdAt?.toDate());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainingsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: _recentCardDecoration(accentTeal),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _trainingTypeIcon(item.type),
                  color: accentTeal,
                  size: 19,
                ),
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
                                label: _recentTrainingTypeLabel(item.type),
                                color: accentTeal,
                              ),
                            ],
                          ),
                        ),
                        if (freshness != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              freshness,
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
                      item.provider.isNotEmpty ? item.provider : 'Training',
                      style: GoogleFonts.poppins(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w600,
                        color: textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (item.duration.trim().isNotEmpty)
                          _buildRecentMetaItem(
                            icon: Icons.schedule_outlined,
                            label: item.duration.trim(),
                          ),
                        if (item.level.trim().isNotEmpty)
                          _buildRecentMetaItem(
                            icon: Icons.school_outlined,
                            label: _recentCompactLabel(item.level),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRecentArrowChip(accentTeal),
            ],
          ),
        ),
      ),
    );
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

  int _recentTrainingTimestamp(TrainingModel item) {
    return item.createdAt?.millisecondsSinceEpoch ?? 0;
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
    final checks = <bool>[
      (user?.fullName ?? '').trim().isNotEmpty,
      (user?.email ?? '').trim().isNotEmpty,
      (user?.phone ?? '').trim().isNotEmpty,
      (user?.location ?? '').trim().isNotEmpty,
      (user?.academicLevel ?? '').trim().isNotEmpty,
      (user?.university ?? '').trim().isNotEmpty,
      (user?.fieldOfStudy ?? '').trim().isNotEmpty,
      (user?.bio ?? '').trim().isNotEmpty,
      _hasReadyCv(cv),
      cv != null &&
          (cv.skills.isNotEmpty ||
              cv.languages.isNotEmpty ||
              cv.education.isNotEmpty ||
              cv.experience.isNotEmpty),
    ];

    return checks.where((value) => !value).length;
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
      return 'Matches your $field background.';
    }
    if (_matchesRecommendationSignal(level, haystack)) {
      return 'Feels relevant for $level students.';
    }
    if (_matchesRecommendationSignal(location, haystack)) {
      return 'Close to your current location.';
    }
    if (workMode == 'remote') {
      return 'Remote-friendly for a flexible student schedule.';
    }
    if (workMode == 'hybrid') {
      return 'Hybrid setup with flexible on-site time.';
    }
    if (item.isPaid == true) {
      return 'Paid opportunity with clearer value upfront.';
    }
    if (daysLeft != null && daysLeft >= 0 && daysLeft <= 7) {
      return 'Deadline is coming up soon.';
    }
    if (item.isFeatured) {
      return 'Highlighted by our team for extra visibility.';
    }

    switch (OpportunityType.parse(item.type)) {
      case OpportunityType.internship:
        return 'Strong option for building real experience.';
      case OpportunityType.sponsoring:
        return 'Student support with a clear application path.';
      case OpportunityType.job:
      default:
        return 'A solid next-step opportunity to explore.';
    }
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

  IconData _trainingTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'book':
        return Icons.menu_book_outlined;
      case 'course':
        return Icons.cast_for_education_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'file':
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.school_outlined;
    }
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
    if (cv == null) {
      return false;
    }

    return cv.hasUploadedCv || cv.hasExportedPdf || cv.hasBuilderContent;
  }

  int _profileCompletionPercent(UserModel? user, CvModel? cv) {
    final checks = <bool>[
      (user?.fullName ?? '').trim().isNotEmpty,
      (user?.email ?? '').trim().isNotEmpty,
      (user?.phone ?? '').trim().isNotEmpty,
      (user?.location ?? '').trim().isNotEmpty,
      (user?.academicLevel ?? '').trim().isNotEmpty,
      (user?.university ?? '').trim().isNotEmpty,
      (user?.fieldOfStudy ?? '').trim().isNotEmpty,
      (user?.bio ?? '').trim().isNotEmpty,
      _hasReadyCv(cv),
      cv != null &&
          (cv.skills.isNotEmpty ||
              cv.languages.isNotEmpty ||
              cv.education.isNotEmpty ||
              cv.experience.isNotEmpty),
    ];

    final completed = checks.where((value) => value).length;
    return ((completed / checks.length) * 100).round();
  }

  String _profileHint(UserModel? user, CvModel? cv) {
    if (!_hasReadyCv(cv)) {
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

    return 'Your profile is in good shape for the next opportunity you open.';
  }

  String _profilePrimaryActionLabel(UserModel? user, CvModel? cv) {
    if (!_hasReadyCv(cv)) {
      return 'Add CV';
    }

    if ((user?.academicLevel ?? '').trim().isEmpty ||
        (user?.fieldOfStudy ?? '').trim().isEmpty ||
        (user?.university ?? '').trim().isEmpty ||
        (user?.bio ?? '').trim().isEmpty ||
        (user?.location ?? '').trim().isEmpty ||
        (user?.phone ?? '').trim().isEmpty) {
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
      case 'Recent':
        subtitle = 'Fresh opportunities and learning picks added lately.';
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

class _QuickAccessCardItem {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _QuickAccessCardItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}

class _QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.badge,
    required this.onTap,
  });
}

class _RecentItem {
  final OpportunityModel? opportunity;
  final TrainingModel? training;

  _RecentItem({this.opportunity, this.training});
}
