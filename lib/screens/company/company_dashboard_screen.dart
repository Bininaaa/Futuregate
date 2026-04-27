import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/application_status.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/application_status_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_loading.dart';
import '../notifications_screen.dart';
import 'applications_screen.dart';
import 'publish_opportunity_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onOpenApplications;

  const CompanyDashboardScreen({
    super.key,
    this.embedded = false,
    this.onOpenApplications,
  });

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String get _localeName => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    if (!mounted) {
      return;
    }

    final companyId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    if (companyId.isEmpty) {
      return;
    }

    await context.read<CompanyProvider>().loadDashboard(companyId);
  }

  Future<void> _openPublishOpportunity(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PublishOpportunityScreen()));
    if (!mounted) {
      return;
    }
    await _loadDashboard();
  }

  Future<void> _openApplications(
    BuildContext context, {
    String? applicationId,
  }) async {
    if ((applicationId ?? '').trim().isEmpty &&
        widget.onOpenApplications != null) {
      widget.onOpenApplications!();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationsScreen(
          initialApplicationId: applicationId,
          showBackButton: true,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadDashboard();
  }

  int _intStat(Map<String, dynamic> stats, String key, int fallback) {
    final value = stats[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  List<ApplicationModel> _recentApplications(List<ApplicationModel> items) {
    final list = [...items];
    list.sort((a, b) {
      final aTime = a.appliedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.appliedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return list.take(3).toList();
  }

  List<DateTime> _chartDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
  }

  String _dayKey(DateTime value) => '${value.year}-${value.month}-${value.day}';

  String _weekdayLabel(DateTime value) =>
      DateFormat('EEE', _localeName).format(value);

  List<double> _chartPoints(
    List<ApplicationModel> applications,
    List<DateTime> days,
  ) {
    final buckets = <String, int>{for (final day in days) _dayKey(day): 0};

    for (final application in applications) {
      final appliedAt = application.appliedAt?.toDate();
      if (appliedAt == null) {
        continue;
      }

      final day = DateTime(appliedAt.year, appliedAt.month, appliedAt.day);
      final key = _dayKey(day);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + 1;
      }
    }

    return days.map((day) => buckets[_dayKey(day)]!.toDouble()).toList();
  }

  int _expiringSoonCount(List<OpportunityModel> opportunities) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return opportunities.where((opportunity) {
      final deadline = opportunity.effectiveDeadline;
      if (opportunity.effectiveStatus() != 'open' || deadline == null) {
        return false;
      }

      final normalizedDeadline = DateTime(
        deadline.year,
        deadline.month,
        deadline.day,
      );
      final daysUntil = normalizedDeadline.difference(today).inDays;
      return daysUntil >= 0 && daysUntil <= 2;
    }).length;
  }

  String _companyDisplayName(UserModel? user) {
    final companyName = (user?.companyName ?? '').trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }

    final fullName = (user?.fullName ?? '').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return _l10n.uiCompany;
  }

  String _applicationDateLabel(ApplicationModel application) {
    final appliedAt = application.appliedAt?.toDate();
    if (appliedAt == null) {
      return _l10n.uiAppliedDateUnavailable;
    }
    return DateFormat.yMMMd(_localeName).format(appliedAt);
  }

  String _cleanError(String message) {
    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final provider = context.watch<CompanyProvider>();
    final stats = provider.stats;

    Widget wrapScaffold(Widget child) {
      final scaffold = Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.embedded ? child : SafeArea(child: child),
      );
      if (widget.embedded) {
        return scaffold;
      }
      return AppShellBackground(child: scaffold);
    }

    final activeJobPosts = _intStat(
      stats,
      'openOpportunities',
      provider.opportunities
          .where((item) => item.effectiveStatus() == 'open')
          .length,
    );
    final totalApplications = _intStat(
      stats,
      'totalApplications',
      provider.applications.length,
    );
    final pendingApplications = _intStat(
      stats,
      'pendingApplications',
      provider.applications
          .where(
            (item) =>
                ApplicationStatus.parse(item.status) ==
                ApplicationStatus.pending,
          )
          .length,
    );
    final approvedApplications = _intStat(
      stats,
      'approvedApplications',
      _intStat(
        stats,
        'acceptedApplications',
        provider.applications
            .where(
              (item) =>
                  ApplicationStatus.parse(item.status) ==
                  ApplicationStatus.accepted,
            )
            .length,
      ),
    );
    final rejectedApplications = _intStat(
      stats,
      'rejectedApplications',
      provider.applications
          .where(
            (item) =>
                ApplicationStatus.parse(item.status) ==
                ApplicationStatus.rejected,
          )
          .length,
    );
    final recentApplications = _recentApplications(provider.applications);
    final chartDays = _chartDays();
    final chartPoints = _chartPoints(provider.applications, chartDays);
    final chartLabels = chartDays.map(_weekdayLabel).toList();
    final expiringSoonCount = _expiringSoonCount(provider.opportunities);

    final isInitialLoading =
        provider.dashboardLoading &&
        provider.applications.isEmpty &&
        provider.opportunities.isEmpty &&
        provider.stats.isEmpty;

    if (isInitialLoading) {
      return wrapScaffold(
        const AppLoadingView(density: AppLoadingDensity.compact),
      );
    }

    if (provider.dashboardError != null &&
        provider.applications.isEmpty &&
        provider.opportunities.isEmpty &&
        provider.stats.isEmpty) {
      return wrapScaffold(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: CompanyDashboardPalette.error,
                ),
                const SizedBox(height: 12),
                Text(
                  _l10n.uiDashboardUnavailable,
                  style: AppTypography.product(
                    color: CompanyDashboardPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _cleanError(provider.dashboardError!),
                  textAlign: TextAlign.center,
                  style: AppTypography.product(
                    color: CompanyDashboardPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadDashboard,
                  child: Text(
                    _l10n.retryLabel,
                    style: AppTypography.product(
                      color: CompanyDashboardPalette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return wrapScaffold(
      RefreshIndicator(
        color: CompanyDashboardPalette.primary,
        onRefresh: _loadDashboard,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, widget.embedded ? 8 : 14, 20, 32),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            if (!widget.embedded) ...[
              _buildTopBar(context, user, unreadCount),
              const SizedBox(height: 22),
            ],
            _buildHero(
              context,
              activeJobPosts: activeJobPosts,
              pendingApplications: pendingApplications,
            ),
            if (provider.dashboardError != null) ...[
              const SizedBox(height: 14),
              _buildInlineError(provider.dashboardError!),
            ],
            const SizedBox(height: 18),
            _buildStatCard(
              label: _l10n.uiActiveJobPosts,
              value: '$activeJobPosts',
              icon: Icons.work_outline_rounded,
              tone: CompanyDashboardPalette.primary,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              label: _l10n.uiApplicationsReceived,
              value: '$totalApplications',
              icon: Icons.inbox_rounded,
              tone: CompanyDashboardPalette.secondary,
            ),
            const SizedBox(height: 12),
            _buildApplicationStatusSummaryCard(
              pendingApplications: pendingApplications,
              approvedApplications: approvedApplications,
              rejectedApplications: rejectedApplications,
            ),
            const SizedBox(height: 18),
            _buildChartCard(chartPoints: chartPoints, labels: chartLabels),
            const SizedBox(height: 22),
            _buildSectionHeader(context),
            const SizedBox(height: 12),
            if (recentApplications.isEmpty)
              _buildEmptyApplicationsCard()
            else
              ...recentApplications.map((application) {
                OpportunityModel? opportunity;
                for (final item in provider.opportunities) {
                  if (item.id == application.opportunityId) {
                    opportunity = item;
                    break;
                  }
                }
                return _buildApplicantItem(
                  context,
                  application,
                  opportunity: opportunity,
                );
              }),
            const SizedBox(height: 6),
            _buildInsightsCard(
              pendingApplications: pendingApplications,
              approvedApplications: approvedApplications,
              rejectedApplications: rejectedApplications,
              expiringSoonCount: expiringSoonCount,
              totalApplications: totalApplications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, UserModel? user, int unreadCount) {
    final companyName = _companyDisplayName(user);
    final surfaceColor = AppColors.isDark
        ? CompanyDashboardPalette.surfaceElevated.withValues(alpha: 0.94)
        : CompanyDashboardPalette.surface.withValues(alpha: 0.96);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CompanyDashboardPalette.border.withValues(
            alpha: AppColors.isDark ? 0.94 : 0.84,
          ),
        ),
        boxShadow: AppColors.current.softShadow(0.07),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CompanyDashboardPalette.primaryDark,
                  CompanyDashboardPalette.primary,
                  CompanyDashboardPalette.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: CompanyDashboardPalette.primary.withValues(
                    alpha: AppColors.isDark ? 0.30 : 0.20,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CompanyDashboardPalette.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _l10n.companyWorkspaceTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: CompanyDashboardPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildNotificationButton(context, unreadCount),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: CompanyDashboardPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CompanyDashboardPalette.border),
            ),
            child: ProfileAvatar(user: user, radius: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, int unreadCount) {
    return Tooltip(
      message: _l10n.notificationsTooltip,
      child: Material(
        color: CompanyDashboardPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: CompanyDashboardPalette.textPrimary,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CompanyDashboardPalette.accent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: CompanyDashboardPalette.surfaceMuted,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: AppTypography.product(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _buildHero(
    BuildContext context, {
    required int activeJobPosts,
    required int pendingApplications,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            CompanyDashboardPalette.primaryDark,
            CompanyDashboardPalette.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: CompanyDashboardPalette.primary.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -34,
            right: 22,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.uiStrategicDashboard,
                style: AppTypography.product(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _l10n.uiCompanyOverview,
                style: AppTypography.product(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroStat(
                    label: _l10n.uiActiveJobs,
                    value: '$activeJobPosts',
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  _buildHeroStat(
                    label: _l10n.uiPendingApps.toUpperCase(),
                    value: '$pendingApplications',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroAction(
                      label: _l10n.uiPostOpportunity2F1A,
                      icon: Icons.add_rounded,
                      background: CompanyDashboardPalette.surface,
                      foreground: CompanyDashboardPalette.primaryDark,
                      onTap: () => _openPublishOpportunity(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeroAction(
                      label: _l10n.uiReviewApplications,
                      icon: Icons.assignment_rounded,
                      background: CompanyDashboardPalette.surface,
                      foreground: CompanyDashboardPalette.primaryDark,
                      onTap: () => _openApplications(context),
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

  Widget _buildHeroStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.product(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.product(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAction({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: borderColor == null ? null : Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: foreground),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                softWrap: true,
                textAlign: TextAlign.center,
                style: AppTypography.product(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationStatusSummaryCard({
    required int pendingApplications,
    required int approvedApplications,
    required int rejectedApplications,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CompanyDashboardPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: CompanyDashboardPalette.border),
        boxShadow: [
          BoxShadow(
            color: CompanyDashboardPalette.textPrimary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.uiApplicationStatus,
            style: AppTypography.product(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CompanyDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _l10n.uiPendingApprovedAndRejectedCountsFromYourLiveApplications,
            style: AppTypography.product(
              fontSize: 12,
              color: CompanyDashboardPalette.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(
                  _l10n.uiPending,
                  '$pendingApplications',
                  CompanyDashboardPalette.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusChip(
                  _l10n.uiApproved,
                  '$approvedApplications',
                  CompanyDashboardPalette.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusChip(
                  _l10n.uiRejected,
                  '$rejectedApplications',
                  CompanyDashboardPalette.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color tone,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CompanyDashboardPalette.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: CompanyDashboardPalette.border),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: tone, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.product(
                    fontSize: 12.5,
                    color: CompanyDashboardPalette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.product(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CompanyDashboardPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.trending_up_rounded, color: tone, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required List<double> chartPoints,
    required List<String> labels,
  }) {
    final totalThisWeek = chartPoints
        .fold<double>(0, (sum, point) => sum + point)
        .round();
    final peak = chartPoints.fold<double>(0, math.max).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CompanyDashboardPalette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CompanyDashboardPalette.border),
        boxShadow: [
          BoxShadow(
            color: CompanyDashboardPalette.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.uiApplicationActivity,
                      style: AppTypography.product(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CompanyDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _l10n.uiRealApplicationsSubmittedOverTheLast7Days,
                      style: AppTypography.product(
                        fontSize: 12,
                        height: 1.5,
                        color: CompanyDashboardPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                constraints: const BoxConstraints(minWidth: 76),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: CompanyDashboardPalette.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$totalThisWeek',
                      textAlign: TextAlign.center,
                      style: AppTypography.product(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CompanyDashboardPalette.primary,
                      ),
                    ),
                    Text(
                      _l10n.uiThisWeek,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.product(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: CompanyDashboardPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 220, child: _buildChart(chartPoints, labels)),
          const SizedBox(height: 12),
          Text(
            totalThisWeek == 0
                ? _l10n.uiNoApplicationsWereSubmittedInTheLast7Days
                : _l10n.uiPeakActivityReachedCountInASingleDay(peak),
            style: AppTypography.product(
              fontSize: 12,
              color: CompanyDashboardPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> chartPoints, List<String> labels) {
    final maxPoint = chartPoints.fold<double>(0, math.max);
    final maxY = math.max(4, maxPoint.ceil() + 1).toDouble();
    final interval = maxY <= 4 ? 1.0 : (maxY / 4).ceilToDouble();
    final baselineInset = maxY <= 4 ? 0.35 : interval * 0.25;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: labels.isEmpty ? 6 : (labels.length - 1).toDouble(),
        minY: -baselineInset,
        maxY: maxY,
        baselineY: 0,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            if (value < 0) {
              return const FlLine(color: Colors.transparent, strokeWidth: 0);
            }
            return FlLine(
              color: CompanyDashboardPalette.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    value.toInt().toString(),
                    style: AppTypography.product(
                      fontSize: 10,
                      color: CompanyDashboardPalette.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 10,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(
                    meta,
                    distanceFromEdge: 2,
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: AppTypography.product(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: CompanyDashboardPalette.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => CompanyDashboardPalette.textPrimary,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                final label = index >= 0 && index < labels.length
                    ? labels[index]
                    : '';
                final count = spot.y.toInt();
                return LineTooltipItem(
                  '$label\n${_l10n.uiApplications}: $count',
                  AppTypography.product(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.18,
            preventCurveOverShooting: true,
            preventCurveOvershootingThreshold: 1,
            color: CompanyDashboardPalette.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            spots: List.generate(
              chartPoints.length,
              (index) => FlSpot(index.toDouble(), chartPoints[index]),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  CompanyDashboardPalette.primary.withValues(alpha: 0.22),
                  CompanyDashboardPalette.secondary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: CompanyDashboardPalette.primary,
                  strokeWidth: 2,
                  strokeColor: CompanyDashboardPalette.surface,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: AppTypography.product(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.product(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.uiRecentApplications,
                style: AppTypography.product(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CompanyDashboardPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _l10n.uiMostRecentStudentApplicationsFromYourRealData,
                style: AppTypography.product(
                  fontSize: 12,
                  color: CompanyDashboardPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => _openApplications(context),
          style: TextButton.styleFrom(
            foregroundColor: CompanyDashboardPalette.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text(
            _l10n.uiViewAll,
            style: AppTypography.product(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicantItem(
    BuildContext context,
    ApplicationModel application, {
    OpportunityModel? opportunity,
  }) {
    final opportunityTitle = opportunity?.title.trim().isNotEmpty == true
        ? opportunity!.title.trim()
        : _l10n.uiOpportunityUnavailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: CompanyDashboardPalette.surface,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () =>
              _openApplications(context, applicationId: application.id),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: CompanyDashboardPalette.border),
              boxShadow: [
                BoxShadow(
                  color: CompanyDashboardPalette.textPrimary.withValues(
                    alpha: 0.04,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: CompanyDashboardPalette.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ProfileAvatar(
                      userId: application.studentId,
                      fallbackName: application.studentName,
                      role: 'student',
                      radius: 19,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                application.studentName.trim().isNotEmpty
                                    ? application.studentName.trim()
                                    : _l10n.uiStudent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.product(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: CompanyDashboardPalette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ApplicationStatusBadge(
                              status: application.status,
                              fontSize: 10,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opportunityTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: CompanyDashboardPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: CompanyDashboardPalette.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _applicationDateLabel(application),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.product(
                                  fontSize: 11.5,
                                  color: CompanyDashboardPalette.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CompanyDashboardPalette.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: CompanyDashboardPalette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsCard({
    required int pendingApplications,
    required int approvedApplications,
    required int rejectedApplications,
    required int expiringSoonCount,
    required int totalApplications,
  }) {
    final reviewedApplications = approvedApplications + rejectedApplications;
    final reviewSummary = reviewedApplications == 0
        ? _l10n.uiNoReviewedApplicationsYet
        : _l10n.uiReviewedApplicationsBreakdown(
            approvedApplications,
            rejectedApplications,
          );
    final pendingSummary = pendingApplications == 0
        ? _l10n.uiNoApplicationsAreWaitingForReviewRightNow
        : _l10n.uiPendingApplicationsNeedReview(pendingApplications);
    final expirySummary = expiringSoonCount == 0
        ? _l10n.uiNoOpenPostsExpireWithinTwoDays
        : _l10n.uiOpenPostsExpireWithinTwoDays(expiringSoonCount);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: AppColors.isDark
              ? [
                  CompanyDashboardPalette.surfaceElevated,
                  CompanyDashboardPalette.surface,
                ]
              : [Color(0xFFFFFBEB), CompanyDashboardPalette.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.isDark
              ? CompanyDashboardPalette.accent.withValues(alpha: 0.24)
              : const Color(0xFFFDE68A),
        ),
        boxShadow: [
          BoxShadow(
            color: CompanyDashboardPalette.accent.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
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
                  color: CompanyDashboardPalette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: CompanyDashboardPalette.accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.uiHiringInsights,
                      style: AppTypography.product(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CompanyDashboardPalette.textPrimary,
                      ),
                    ),
                    Text(
                      totalApplications == 0
                          ? _l10n.uiYourDashboardIsReadyForIncomingApplicants
                          : _l10n
                                .uiQuickHighlightsPulledFromYourLiveDashboardData,
                      style: AppTypography.product(
                        fontSize: 12,
                        color: CompanyDashboardPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInsightRow(
            icon: Icons.pending_actions_rounded,
            color: CompanyDashboardPalette.warning,
            text: pendingSummary,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            icon: Icons.verified_outlined,
            color: CompanyDashboardPalette.success,
            text: reviewSummary,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            icon: Icons.schedule_rounded,
            color: CompanyDashboardPalette.primary,
            text: expirySummary,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.product(
              fontSize: 12.5,
              height: 1.55,
              color: CompanyDashboardPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyApplicationsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: CompanyDashboardPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: CompanyDashboardPalette.border),
        boxShadow: [
          BoxShadow(
            color: CompanyDashboardPalette.textPrimary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CompanyDashboardPalette.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inbox_rounded,
              color: CompanyDashboardPalette.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _l10n.uiNoApplicationsYet,
            style: AppTypography.product(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CompanyDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _l10n.uiStudentApplicationsAreAddedHereAsTheyComeIn,
            textAlign: TextAlign.center,
            style: AppTypography.product(
              fontSize: 12.5,
              color: CompanyDashboardPalette.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CompanyDashboardPalette.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CompanyDashboardPalette.error.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: CompanyDashboardPalette.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _cleanError(message),
              style: AppTypography.product(
                fontSize: 12,
                height: 1.5,
                color: CompanyDashboardPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
