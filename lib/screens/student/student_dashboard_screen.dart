import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/training_provider.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_type_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications_screen.dart';
import 'cv_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'opportunities_screen.dart';
import 'jobs_screen.dart';
import 'opportunity_detail_screen.dart';
import 'project_ideas_screen.dart';
import 'trainings_screen.dart';
import 'scholarships_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  // ── Premium purple theme palette ──
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color deepPurple = Color(0xFF5A52D5);
  static const Color lightPurple = Color(0xFF8B83FF);
  static const Color softLavender = Color(0xFFEDE9FF);
  static const Color accentBlue = Color(0xFF4DA0FF);
  static const Color bgColor = Color(0xFFF6F5FB);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1E1E2D);
  static const Color textMedium = Color(0xFF6E6E82);
  static const Color textLight = Color(0xFF9E9EB8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OpportunityProvider>().fetchFeaturedOpportunities();
      context.read<OpportunityProvider>().fetchOpportunities();
      context.read<TrainingProvider>().fetchTrainings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final firstName = (user?.fullName ?? 'Student').split(' ').first;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(context, firstName, user),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionTitle('Categories'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildCategoriesGrid(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildSearchBar(context)),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PROFILE / HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(
    BuildContext context,
    String firstName,
    UserModel? user,
  ) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepPurple, primaryPurple, lightPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: avatar + greeting + icons
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
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: ProfileAvatar(user: user, radius: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      firstName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: GoogleFonts.poppins(
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
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          _buildStatsRow(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final oppProvider = context.watch<OpportunityProvider>();
    final trainingProvider = context.watch<TrainingProvider>();

    final jobCount = oppProvider.opportunities.length;
    final trainingCount = trainingProvider.trainings
        .where((t) => t.isApproved)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.work_outline,
            label: 'Opportunities',
            value: '$jobCount',
            color: const Color(0xFF7C4DFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.cast_for_education_outlined,
            label: 'Trainings',
            value: '$trainingCount',
            color: accentBlue,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
        gradient: [const Color(0xFF4DA0FF), const Color(0xFF74B9FF)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OpportunitiesScreen(
              initialFilter: OpportunityType.internship,
            ),
          ),
        ),
      ),
      _CategoryItem(
        title: 'Sponsoring',
        icon: Icons.campaign_outlined,
        gradient: [const Color(0xFFFF9F43), const Color(0xFFFECA57)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OpportunitiesScreen(
              initialFilter: OpportunityType.sponsoring,
            ),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
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
            width: 56,
            height: 56,
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
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OpportunitiesScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: softLavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: primaryPurple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Search jobs, internships, training...',
                style: GoogleFonts.poppins(fontSize: 14, color: textLight),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: softLavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: primaryPurple, size: 18),
            ),
          ],
        ),
      ),
    );
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
      height: 200,
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
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textDark,
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
                          color: textMedium,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogo(String logoUrl, String companyName) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: softLavender,
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryPurple,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => Center(
                child: Text(
                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
                  fontSize: 18,
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
    final isLoading = oppProvider.isLoading || trainingProvider.isLoading;

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

    // Mix recent opportunities and trainings, sorted by recency
    final recentOpps = oppProvider.opportunities.toList();
    recentOpps.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    final recentTrainings = trainingProvider.trainings
        .where((t) => t.isApproved)
        .toList();
    recentTrainings.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    // Build a mixed list: up to 6 total items
    final List<_RecentItem> recentItems = [];

    final oppLimit = recentOpps.length > 4 ? 4 : recentOpps.length;
    for (int i = 0; i < oppLimit; i++) {
      recentItems.add(_RecentItem(opportunity: recentOpps[i]));
    }

    final trainingLimit = recentTrainings.length > (6 - recentItems.length)
        ? (6 - recentItems.length)
        : recentTrainings.length;
    for (int i = 0; i < trainingLimit; i++) {
      recentItems.add(_RecentItem(training: recentTrainings[i]));
    }

    if (recentItems.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(
            icon: Icons.history,
            message: 'Nothing recent yet',
            subtitle: 'New opportunities will appear here',
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCompanyLogo(item.companyLogo, item.companyName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.companyName,
                    style: GoogleFonts.poppins(fontSize: 12, color: textMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: textLight,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
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
            const SizedBox(width: 10),
            OpportunityTypeBadge(type: item.type, showIcon: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrainingCard(BuildContext context, TrainingModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _trainingTypeIcon(item.type),
                color: const Color(0xFF00B894),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.provider.isNotEmpty ? item.provider : 'Training',
                    style: GoogleFonts.poppins(fontSize: 12, color: textMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.type.isNotEmpty
                    ? item.type[0].toUpperCase() + item.type.substring(1)
                    : 'Training',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00B894),
                ),
              ),
            ),
          ],
        ),
      ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryPurple,
              ),
            ),
          ),
      ],
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
