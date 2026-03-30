import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../providers/notification_provider.dart';
import '../notifications_screen.dart';
import 'publish_opportunity_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<CompanyProvider>().loadDashboard(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final provider = context.watch<CompanyProvider>();
    final companyName = user?.companyName ?? user?.fullName ?? 'Company';

    return Scaffold(
      backgroundColor: softGray,
      body: SafeArea(
        child: provider.dashboardLoading
            ? const Center(
                child: CircularProgressIndicator(color: vibrantOrange),
              )
            : provider.dashboardError != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load dashboard',
                      style: GoogleFonts.poppins(
                        color: strongBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        if (user != null) provider.loadDashboard(user.uid);
                      },
                      child: Text(
                        'Retry',
                        style: GoogleFonts.poppins(
                          color: vibrantOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: vibrantOrange,
                onRefresh: () async {
                  if (user != null) await provider.loadDashboard(user.uid);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(companyName),
                      const SizedBox(height: 20),
                      _buildHeroBanner(context),
                      const SizedBox(height: 20),
                      _buildStatsRow(provider.stats),
                      const SizedBox(height: 20),
                      _buildApplicationBreakdown(provider.stats),
                      const SizedBox(height: 24),
                      _buildRecentApplications(provider),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String companyName) {
    final user = context.read<AuthProvider>().userModel;
    return Row(
      children: [
        ProfileAvatar(user: user, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: strongBlue,
                ),
              ),
              Text(
                'Company Dashboard',
                style: GoogleFonts.poppins(fontSize: 13, color: mediumBlue),
              ),
            ],
          ),
        ),
        _buildNotificationBell(context),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.read<AuthProvider>().logout(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.logout, color: strongBlue, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: strongBlue,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: vibrantOrange,
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
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final companyProvider = context.read<CompanyProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [strongBlue, mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: strongBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hire the best\ntalent',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Post opportunities and find\nthe right candidates.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PublishOpportunityScreen(),
                    ),
                  ).then((_) {
                    if (!mounted) {
                      return;
                    }
                    final user = authProvider.userModel;
                    if (user != null) {
                      companyProvider.loadDashboard(user.uid);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: vibrantOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Post Opportunity',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.work,
                size: 40,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Opportunities',
            '${stats['totalOpportunities'] ?? 0}',
            Icons.work_outline,
            vibrantOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Applications',
            '${stats['totalApplications'] ?? 0}',
            Icons.assignment_outlined,
            strongBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: mediumBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationBreakdown(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(
                  'Pending',
                  '${stats['pendingApplications'] ?? 0}',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusChip(
                  'Accepted',
                  '${stats['acceptedApplications'] ?? 0}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusChip(
                  'Rejected',
                  '${stats['rejectedApplications'] ?? 0}',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecentApplications(CompanyProvider provider) {
    final recentApps = provider.applications.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Applications',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: strongBlue,
          ),
        ),
        const SizedBox(height: 12),
        if (recentApps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: mediumBlue),
                const SizedBox(height: 8),
                Text(
                  'No applications yet',
                  style: GoogleFonts.poppins(color: mediumBlue),
                ),
              ],
            ),
          ),
        ...recentApps.map((app) {
          final opp = provider.opportunities
              .where((o) => o.id == app.opportunityId)
              .firstOrNull;
          final oppTitle = opp?.title ?? 'Unknown Opportunity';

          Color statusColor;
          if (app.status == 'accepted') {
            statusColor = Colors.green;
          } else if (app.status == 'rejected') {
            statusColor = Colors.red;
          } else {
            statusColor = Colors.orange;
          }

          final appliedAt = app.appliedAt;
          String dateStr = '';
          if (appliedAt != null) {
            final dt = appliedAt.toDate();
            dateStr = '${dt.day}/${dt.month}/${dt.year}';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ProfileAvatar(
                  radius: 20,
                  userId: app.studentId,
                  fallbackName: app.studentName,
                  role: 'student',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: strongBlue,
                        ),
                      ),
                      Text(
                        oppTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: mediumBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        app.status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
