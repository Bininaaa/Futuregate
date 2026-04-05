import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../models/opportunity_model.dart';
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
  const StudentDashboardScreen({super.key});

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
  static const Color bgColor = OpportunityDashboardPalette.background;
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
    context.read<ProjectIdeaProvider>().fetchSavedIdeas(studentId);
    context.read<ApplicationProvider>().fetchSubmittedApplicationsCount(
      studentId,
    );
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
    final firstName = (user?.fullName ?? 'Student').split(' ').first;
    final profileCompletion = _profileCompletionPercent(user, cv);
    final showProfilePrompt = profileCompletion < 100;
    _ensureDashboardData(user);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildProfileHeader(
                  context,
                  firstName,
                  user,
                  profileCompletion,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionTitle('Categories'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildCategoriesGrid(context),
                ),
              ),
              if (showProfilePrompt)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionHeader('Closing Soon'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildClosingSoonSection(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildRecommendedSection(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PROFILE / HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(
    BuildContext context,
    String firstName,
    UserModel? user,
    int profileCompletion,
  ) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final studentIdentity = _studentIdentityLine(user);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                  profileCompletion < 100
                      ? 'PROFILE $profileCompletion% COMPLETE'
                      : 'CAMPUS TO CAREER',
                  style: GoogleFonts.poppins(
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.45,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Welcome to your future.',
                style: GoogleFonts.poppins(
                  fontSize: 20.5,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (profileCompletion < 100) ...[
                const SizedBox(height: 7),
                Text(
                  'Complete your profile to unlock better matches.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentGold.withValues(alpha: 0.96),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderActionChip(
                      icon: Icons.explore_outlined,
                      label: 'Discover',
                      isPrimary: true,
                      isOnDark: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OpportunitiesScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeaderActionChip(
                      icon: Icons.description_outlined,
                      label: 'Build CV',
                      isOnDark: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CvScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatsRow(context, onDark: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, {bool onDark = false}) {
    final savedCount =
        context.watch<SavedOpportunityProvider>().savedOpportunities.length +
        context.watch<SavedScholarshipProvider>().savedScholarships.length +
        context.watch<ProjectIdeaProvider>().savedIdeas.length;
    final appliedCount = context
        .watch<ApplicationProvider>()
        .submittedApplicationsCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.bookmark_outline_rounded,
            label: 'Saved',
            value: '$savedCount',
            color: accentGold,
            onDark: onDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Applied',
            value: '$appliedCount',
            color: accentTeal,
            onDark: onDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AppliedOpportunitiesScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool onDark = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withValues(alpha: 0.10) : bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: onDark ? Colors.white.withValues(alpha: 0.10) : cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: onDark ? color : color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                      color: onDark ? Colors.white : textDark,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                      color: onDark
                          ? Colors.white.withValues(alpha: 0.75)
                          : textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: isOnDark
                ? (isPrimary
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08))
                : (isPrimary ? textDark : cardWhite),
            borderRadius: BorderRadius.circular(16),
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
                size: isPrimary ? 18 : 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.3,
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
  // 2. CATEGORIES GRID
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoriesGrid(BuildContext context) {
    final categories = [
      _CategoryItem(
        title: 'Jobs',
        icon: Icons.work_outline,
        gradient: [const Color(0xFF6C63FF), const Color(0xFF8B83FF)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JobsScreen()),
        ),
      ),
      _CategoryItem(
        title: 'Internships',
        icon: Icons.school_outlined,
        gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InternshipsScreen()),
        ),
      ),
      _CategoryItem(
        title: 'Sponsoring',
        icon: Icons.campaign_outlined,
        gradient: [const Color(0xFFFF9F43), const Color(0xFFFECA57)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SponsoredOpportunitiesScreen(),
          ),
        ),
      ),
      _CategoryItem(
        title: 'Scholarships',
        icon: Icons.emoji_events_outlined,
        gradient: [const Color(0xFF2ED573), const Color(0xFF7BED9F)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScholarshipsScreen()),
        ),
      ),
      _CategoryItem(
        title: 'Ideas',
        icon: Icons.lightbulb_outline,
        gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectIdeasScreen()),
        ),
      ),
      _CategoryItem(
        title: 'CV Builder',
        icon: Icons.description_outlined,
        gradient: [const Color(0xFF5F27CD), const Color(0xFF8854D0)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CvScreen()),
        ),
      ),
      _CategoryItem(
        title: 'Training',
        icon: Icons.cast_for_education_outlined,
        gradient: [const Color(0xFF00B894), const Color(0xFF55EFC4)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingsScreen()),
        ),
      ),
      _CategoryItem(
        title: 'Saved',
        icon: Icons.bookmark_outline,
        gradient: [const Color(0xFFE17055), const Color(0xFFFAB1A0)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.84,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildCategoryCard(cat);
      },
    );
  }

  Widget _buildCategoryCard(_CategoryItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: item.gradient.first.withValues(alpha: 0.3),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 25),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 24,
            child: Center(
              child: Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 10.2,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. SEARCH BAR
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

  Widget _buildClosingSoonSection(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final items = _closingSoonOpportunities(provider.opportunities);

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
          subtitle: 'Closing dates will show here as new opportunities arrive',
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

  Widget _buildRecommendedSection(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final featured = provider.featuredOpportunities;
    final isLoading = provider.isFeaturedLoading;

    if (isLoading) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    if (featured.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        message: 'No recommendations yet',
        subtitle: 'Check back soon for curated opportunities',
      );
    }

    return SizedBox(
      height: 226,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: featured.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _buildRecommendedCard(context, featured[index]);
        },
      ),
    );
  }

  Widget _buildRecommendedCard(BuildContext context, OpportunityModel item) {
    final freshness = _timeAgo(item.createdAt?.toDate());

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpportunityDetailScreen(opportunity: item),
          ),
        );
      },
      child: Container(
        width: 268,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: OpportunityDashboardPalette.border),
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
                    color: OpportunityType.color(
                      item.type,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Popular with students',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: OpportunityType.color(item.type),
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
                              item.location,
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
            const Spacer(),
            Row(
              children: [
                OpportunityTypeBadge(type: item.type, showIcon: false),
                const Spacer(),
                if (item.deadlineLabel.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: textLight),
                      const SizedBox(width: 3),
                      Text(
                        item.deadlineLabel,
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
        .where((item) => !item.isHidden)
        .toList();
    if (recentOpps.isEmpty) {
      recentOpps.addAll(
        oppProvider.featuredOpportunities.where((item) => !item.isHidden),
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

  Widget _buildSectionTitle(String title) {
    return OpportunitySectionHeader(
      title: title,
      subtitle: 'The essentials, one tap away.',
      accentColor: accentTeal,
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    String subtitle;
    Color accentColor;

    switch (title) {
      case 'Closing Soon':
        subtitle = 'Deadlines you should not miss.';
        accentColor = accentGold;
        break;
      case 'Recommended':
        subtitle = 'Picked to feel more relevant for students right now.';
        accentColor = accentTeal;
        break;
      case 'Recent':
        subtitle = 'Latest updates for you.';
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

class _CategoryItem {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  _CategoryItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _RecentItem {
  final OpportunityModel? opportunity;
  final TrainingModel? training;

  _RecentItem({this.opportunity, this.training});
}
