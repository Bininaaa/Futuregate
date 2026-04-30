import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../models/admin_application_item_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/document_access_service.dart';
import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';
import '../../utils/application_status.dart';
import '../../utils/document_launch_helper.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/admin/admin_activity_preview_sheet.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/admin_charts.dart';
import '../../widgets/opportunity_type_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import '../../widgets/stat_card.dart';
import '../notifications_screen.dart';
import 'admin_activity_center_screen.dart';
import 'admin_content_center_screen.dart';
import 'users_screen.dart';
import 'admin_home_navigation.dart';
import 'admin_opportunity_editor_screen.dart';
import 'admin_student_profile_sheet.dart';

const int _dashboardPreviewLimit = 5;

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenUsers;
  final void Function(int tab, {String targetId})? onOpenContent;
  final VoidCallback? onOpenActivity;
  final VoidCallback? onOpenLibrary;

  const AdminDashboardScreen({
    super.key,
    this.onOpenUsers,
    this.onOpenContent,
    this.onOpenActivity,
    this.onOpenLibrary,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DocumentAccessService _documentAccessService = DocumentAccessService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (provider.isLoading) {
      return const AppLoadingView(density: AppLoadingDensity.compact);
    }

    if (provider.dashboardError != null) {
      return AdminEmptyState(
        icon: Icons.error_outline_rounded,
        title: l10n.uiDashboardUnavailable,
        message: l10n.uiWeCouldNotLoadAdminAnalyticsRightNow,
        action: FilledButton(
          onPressed: provider.loadDashboardData,
          child: Text(l10n.retryLabel),
        ),
      );
    }

    final stats = provider.stats;
    final monthlyRegistrations =
        (stats['monthlyRegistrations'] as List<dynamic>?) ?? [];
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return RefreshIndicator(
      color: AdminPalette.primary,
      onRefresh: provider.loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminHeroCard(
              title: l10n.uiAdminControlRoom,
              subtitle: l10n
                  .uiReviewCompaniesContentAndPlatformActivityFromOneFocusedWorkspace,
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AdminPalette.secondary,
              actions: [
                AdminActionChip(
                  label: l10n.uiReviewCompanies,
                  icon: Icons.verified_user_outlined,
                  onTap: _openUsers,
                ),
                AdminActionChip(
                  label: l10n.uiReviewContent,
                  icon: Icons.auto_awesome_mosaic_rounded,
                  filled: true,
                  onTap: () =>
                      _openContent(AdminContentCenterScreen.projectIdeasTab),
                ),
                AdminActionChip(
                  label: l10n.uiOpenActivity,
                  icon: Icons.timeline_rounded,
                  onTap: _openActivityCenter,
                ),
                AdminActionChip(
                  label: l10n.uiLibrary,
                  icon: Icons.menu_book_rounded,
                  onTap: _openLibrary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PendingAdminAlert(
              pendingCompanies: _intStat(stats, 'pendingCompanies'),
              pendingIdeas: _intStat(stats, 'pendingIdeas'),
              pendingApplications: _intStat(stats, 'pendingApplications'),
              onOpenCompanies: () => AdminHomeNavigation.switchToUsers(
                context,
                roleFilter: 'company',
                companyApprovalFilter: 'pending',
              ),
              onOpenIdeas: () =>
                  _openContent(AdminContentCenterScreen.projectIdeasTab),
              onOpenApplications: () =>
                  _openContent(AdminContentCenterScreen.opportunitiesTab),
            ),
            const SizedBox(height: 18),
            AdminSectionHeader(
              eyebrow: l10n.uiSnapshot,
              title: l10n.uiPlatformOverview,
              subtitle:
                  l10n.uiTheHighLevelUserAndAccountPictureAdminsUsuallyNeed,
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(
              items: [
                _DashboardMetric(
                  title: l10n.uiTotalUsers,
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.people_alt_outlined,
                  color: AdminPalette.primary,
                ),
                _DashboardMetric(
                  title: l10n.uiActiveUsers,
                  value: '${stats['activeUsers'] ?? 0}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AdminPalette.success,
                ),
                _DashboardMetric(
                  title: l10n.uiStudents,
                  value: '${stats['students'] ?? 0}',
                  icon: Icons.school_outlined,
                  color: AdminPalette.info,
                ),
                _DashboardMetric(
                  title: l10n.uiCompanies,
                  value: '${stats['companies'] ?? 0}',
                  icon: Icons.business_center_outlined,
                  color: AdminPalette.secondary,
                ),
                _DashboardMetric(
                  title: l10n.uiPendingReviews,
                  value: '${stats['pendingCompanies'] ?? 0}',
                  icon: Icons.pending_actions_rounded,
                  color: AdminPalette.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdminSectionHeader(
              eyebrow: l10n.uiStudents,
              title: l10n.uiAcademicBreakdown,
              subtitle:
                  l10n.uiSeeHowTheStudentPopulationIsDistributedByLevelBefore,
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(
              items: [
                _DashboardMetric(
                  title: l10n.uiBac,
                  value: '${stats['bac'] ?? 0}',
                  icon: Icons.menu_book_outlined,
                  color: AdminPalette.accent,
                ),
                _DashboardMetric(
                  title: l10n.academicLevelLicence,
                  value: '${stats['licence'] ?? 0}',
                  icon: Icons.import_contacts_outlined,
                  color: AdminPalette.primary,
                ),
                _DashboardMetric(
                  title: l10n.academicLevelMaster,
                  value: '${stats['master'] ?? 0}',
                  icon: Icons.workspace_premium_outlined,
                  color: AdminPalette.activity,
                ),
                _DashboardMetric(
                  title: l10n.academicLevelDoctorat,
                  value: '${stats['doctorat'] ?? 0}',
                  icon: Icons.science_outlined,
                  color: AdminPalette.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            UsersByLevelBarChart(
              bacCount: (stats['bac'] ?? 0) as int,
              licenceCount: (stats['licence'] ?? 0) as int,
              masterCount: (stats['master'] ?? 0) as int,
              doctoratCount: (stats['doctorat'] ?? 0) as int,
            ),
            const SizedBox(height: 16),
            UsersRolePieChart(
              students: (stats['students'] ?? 0) as int,
              companies: (stats['companies'] ?? 0) as int,
              admins: (stats['admins'] ?? 0) as int,
            ),
            const SizedBox(height: 16),
            MonthlyRegistrationsLineChart(monthlyData: monthlyRegistrations),
            const SizedBox(height: 24),
            AdminSectionHeader(
              eyebrow: l10n.uiContent,
              title: l10n.uiManagedInventory,
              subtitle: l10n.uiAQuickCountOfTheContentTypesHandledInsideThe,
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(
              items: [
                _DashboardMetric(
                  title: l10n.uiOpportunities,
                  value: '${stats['opportunities'] ?? 0}',
                  icon: Icons.work_outline_rounded,
                  color: AdminPalette.accent,
                ),
                _DashboardMetric(
                  title: l10n.uiApplications,
                  value: '${stats['applications'] ?? 0}',
                  icon: Icons.assignment_outlined,
                  color: AdminPalette.activity,
                ),
                _DashboardMetric(
                  title: l10n.uiScholarships,
                  value: '${stats['scholarships'] ?? 0}',
                  icon: Icons.card_giftcard_outlined,
                  color: AdminPalette.danger,
                ),
                _DashboardMetric(
                  title: l10n.uiLibrary,
                  value: '${stats['trainings'] ?? 0}',
                  icon: Icons.cast_for_education_outlined,
                  color: AdminPalette.secondary,
                ),
                _DashboardMetric(
                  title: l10n.uiProjectIdeas,
                  value: '${stats['projectIdeas'] ?? 0}',
                  icon: Icons.lightbulb_outline_rounded,
                  color: AdminPalette.warning,
                ),
                _DashboardMetric(
                  title: l10n.uiConversations,
                  value: '${stats['conversations'] ?? 0}',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AdminPalette.success,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdminSectionHeader(
              eyebrow: l10n.uiPerformance,
              title: l10n.uiEngagementAnalytics,
              subtitle:
                  l10n.uiTheseRatiosHelpAdminsSeeWhetherUsersAreEngagingDeeply,
            ),
            const SizedBox(height: 12),
            _InsightTile(
              icon: Icons.percent_rounded,
              iconColor: AdminPalette.info,
              title: l10n.uiApplicationRate,
              value: l10n.uiAppsPerOpportunity(
                ((stats['applicationRate'] ?? 0.0) as double).toStringAsFixed(
                  1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _InsightTile(
              icon: Icons.description_outlined,
              iconColor: AdminPalette.success,
              title: l10n.uiCvCompletionRate,
              value: l10n.uiCvCompletionRateValue(
                ((stats['cvCompletionRate'] ?? 0.0) as double).toStringAsFixed(
                  0,
                ),
                stats['totalCvs'] ?? 0,
                stats['students'] ?? 0,
              ),
            ),
            const SizedBox(height: 10),
            _InsightTile(
              icon: Icons.pending_actions_outlined,
              iconColor: AdminPalette.warning,
              title: l10n.uiPendingProjectIdeas,
              value: l10n.uiPendingApprovedIdeasValue(
                stats['pendingIdeas'] ?? 0,
                stats['approvedIdeas'] ?? 0,
              ),
            ),
            const SizedBox(height: 24),
            _RankedListCard(
              title: l10n.uiMostAppliedOpportunities,
              icon: Icons.trending_up_rounded,
              color: AdminPalette.activity,
              items: (stats['topApplied'] as List<dynamic>?) ?? [],
              suffixLabel: l10n.uiApplicationsSuffix,
            ),
            const SizedBox(height: 16),
            _RankedListCard(
              title: l10n.uiMostSavedOpportunities,
              icon: Icons.bookmark_outline_rounded,
              color: AdminPalette.accent,
              items: (stats['topSaved'] as List<dynamic>?) ?? [],
              suffixLabel: l10n.uiSavesSuffix,
            ),
            const SizedBox(height: 24),
            AdminSectionHeader(
              eyebrow: l10n.uiActions,
              title: l10n.uiQuickAccess,
              subtitle: l10n.uiJumpStraightIntoTheAdminAreasYouOpenMostOften,
            ),
            const SizedBox(height: 12),
            _QuickAccessGrid(
              unreadCount: unreadCount,
              onOpenContent: _openContent,
              onOpenActivity: _openActivityCenter,
              onOpenLibrary: _openLibrary,
            ),
            const SizedBox(height: 24),
            AdminSectionHeader(
              eyebrow: l10n.uiFeed,
              title: l10n.uiRecentActivity,
              subtitle: l10n.uiUseTheLiveFeedToJumpDirectlyIntoTheRight,
            ),
            const SizedBox(height: 12),
            _RecentActivityCard(
              activities: provider.recentActivity
                  .take(_dashboardPreviewLimit)
                  .toList(),
              onOpenActivity: _openActivityItem,
            ),
            const SizedBox(height: 16),
            _RecentUsersCard(
              users: provider.recentUsers.take(_dashboardPreviewLimit).toList(),
              onOpenUser: _openRecentUser,
            ),
            const SizedBox(height: 16),
            _RecentOpportunitiesCard(
              opportunities: provider.recentOpportunities
                  .take(_dashboardPreviewLimit)
                  .toList(),
              onOpenOpportunity: _openRecentOpportunity,
            ),
          ],
        ),
      ),
    );
  }

  void _openContent(int tab, {String targetId = ''}) {
    if (widget.onOpenContent != null) {
      widget.onOpenContent!(tab, targetId: targetId);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminContentCenterScreen(
          initialTab: tab,
          initialTargetId: targetId,
        ),
      ),
    );
  }

  int _intStat(Map<String, dynamic> stats, String key) {
    final value = stats[key];
    return value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _openActivityCenter() {
    if (widget.onOpenActivity != null) {
      widget.onOpenActivity!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminActivityCenterScreen()),
    );
  }

  void _openLibrary() {
    if (widget.onOpenLibrary != null) {
      widget.onOpenLibrary!();
      return;
    }

    _openContent(AdminContentCenterScreen.libraryTab);
  }

  void _openUsers() {
    if (widget.onOpenUsers != null) {
      widget.onOpenUsers!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AdminPalette.background,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.uiUserManagement),
            backgroundColor: AdminPalette.surface,
            foregroundColor: AdminPalette.textPrimary,
          ),
          body: const SafeArea(child: UsersScreen()),
        ),
      ),
    );
  }

  void _openUserManagementProfile(UserModel user) {
    final roleFilter = user.role.trim().isEmpty ? 'all' : user.role;
    final companyApprovalFilter = roleFilter == 'company'
        ? user.normalizedApprovalStatus
        : 'all';

    if (widget.onOpenUsers != null) {
      AdminHomeNavigation.switchToUsers(
        context,
        targetId: user.uid,
        roleFilter: roleFilter,
        companyApprovalFilter: companyApprovalFilter,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AdminPalette.background,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.uiUserManagement),
            backgroundColor: AdminPalette.surface,
            foregroundColor: AdminPalette.textPrimary,
          ),
          body: SafeArea(
            child: UsersScreen(
              initialRoleFilter: roleFilter,
              initialCompanyApprovalFilter: companyApprovalFilter,
              initialTargetId: user.uid,
            ),
          ),
        ),
      ),
    );
  }

  void _openRecentUser(UserModel user) {
    if (user.role == 'student') {
      showAdminStudentProfileSheet(context, user: user);
      return;
    }

    if (user.role == 'company') {
      _showRecentCompanyDetails(user);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 16),
              ProfileAvatar(user: user, radius: 38),
              const SizedBox(height: 12),
              Text(
                user.fullName.isNotEmpty
                    ? user.fullName
                    : (user.companyName ?? ''),
                textAlign: TextAlign.center,
                style: AppTypography.product(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: AppTypography.product(
                  fontSize: 12.5,
                  color: AdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminPill(
                    label: DisplayText.capitalizeLeadingLabel(user.role),
                    color: _roleColor(user.role),
                    icon: user.role == 'company'
                        ? Icons.business_outlined
                        : Icons.shield_outlined,
                  ),
                  if (user.role == 'company')
                    AdminPill(
                      label: DisplayText.capitalizeLeadingLabel(
                        user.approvalStatus,
                      ),
                      color: user.isCompanyPendingApproval
                          ? AdminPalette.warning
                          : user.isCompanyRejected
                          ? AdminPalette.danger
                          : AdminPalette.success,
                      icon: Icons.verified_user_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (widget.onOpenUsers != null) {
                      Navigator.pop(sheetContext);
                    }
                    _openUserManagementProfile(user);
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.uiOpen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecentCompanyDetails(UserModel user) {
    final companyPostingFuture = loadAdminCompanyOpportunities(user.uid);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.76,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          final l10n = AppLocalizations.of(context)!;
          final provider = context.watch<AdminProvider>();
          final liveUser = _currentDashboardUser(provider, user.uid) ?? user;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: AdminPalette.background,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 16),
                  _buildCompanyProfileHeader(liveUser),
                  const SizedBox(height: 18),
                  AdminSectionHeader(
                    eyebrow: l10n.uiProfile,
                    title: l10n.uiUserDetails,
                    subtitle: l10n
                        .uiReviewContactInfoAccountStatusAndRoleSpecificDetailsInOneCleanProfileView,
                  ),
                  const SizedBox(height: 12),
                  _buildDashboardDetailRow(
                    Icons.email_outlined,
                    l10n.uiEmail,
                    liveUser.email,
                    singleLineValue: true,
                  ),
                  _buildDashboardOptionalDetailRow(
                    Icons.phone_outlined,
                    l10n.uiPhone,
                    liveUser.phone,
                    l10n.uiNotProvided,
                  ),
                  _buildDashboardOptionalDetailRow(
                    Icons.location_on_outlined,
                    l10n.uiLocation,
                    liveUser.location,
                    l10n.uiNotProvided,
                  ),
                  _buildDashboardOptionalDetailRow(
                    Icons.business_outlined,
                    l10n.uiCompanyName,
                    liveUser.companyName,
                    l10n.uiNotProvided,
                  ),
                  _buildDashboardDetailRow(
                    Icons.verified_user_outlined,
                    l10n.uiApprovalStatus,
                    _approvalDisplayLabel(liveUser.normalizedApprovalStatus),
                  ),
                  _buildCompanyModerationPanel(liveUser, provider),
                  _buildDashboardOptionalDetailRow(
                    Icons.category_outlined,
                    l10n.uiSector,
                    liveUser.sector,
                    l10n.uiNotProvided,
                  ),
                  _buildDashboardOptionalDetailRow(
                    Icons.language_outlined,
                    l10n.uiWebsite,
                    liveUser.website,
                    l10n.uiNotProvided,
                  ),
                  if ((liveUser.description ?? '').trim().isNotEmpty)
                    _buildDashboardDetailRow(
                      Icons.description_outlined,
                      l10n.uiDescription,
                      liveUser.description!.trim(),
                    ),
                  _buildCompanyOpportunitiesSection(
                    liveUser,
                    future: companyPostingFuture,
                  ),
                  const SizedBox(height: 6),
                  _buildCompanyCommercialRegisterSummary(liveUser),
                  if (liveUser.bio?.isNotEmpty == true)
                    _buildDashboardDetailRow(
                      Icons.person_outline_rounded,
                      l10n.uiBio,
                      liveUser.bio!,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyProfileHeader(UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = _roleDisplayLabel(user.role);
    final approvalLabel = _approvalDisplayLabel(user.normalizedApprovalStatus);
    final chips = <Widget>[
      AdminPill(
        label: roleLabel,
        color: Colors.white,
        icon: _roleIcon(user.role),
      ),
      AdminPill(
        label: approvalLabel,
        color: Colors.white,
        icon: _approvalDisplayIcon(user.normalizedApprovalStatus),
      ),
      AdminPill(
        label: user.isActive ? l10n.uiActive : l10n.uiBlocked,
        color: Colors.white,
        icon: user.isActive
            ? Icons.check_circle_outline_rounded
            : Icons.block_outlined,
      ),
    ];

    return AdminSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      gradient: AdminPalette.heroGradient(_roleColor(user.role)),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: Column(
        children: [
          Text(
            l10n.uiProfileOverview,
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          _buildOverlayAvatar(user: user, radius: 42),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: AppTypography.product(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.uiReviewIdentityStatusAndSubmittedInformationInOnePlace,
            textAlign: TextAlign.center,
            style: AppTypography.product(
              fontSize: 12.8,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
          const SizedBox(height: 12),
          _buildDashboardSingleLineText(
            user.email,
            textAlign: TextAlign.center,
            style: AppTypography.product(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayAvatar({
    required UserModel user,
    required double radius,
    bool compact = false,
  }) {
    final shellPadding = compact ? 3.5 : 5.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AdminPalette.isDark
            ? AdminPalette.surfaceElevated.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        border: Border.all(
          color: AdminPalette.isDark
              ? AdminPalette.border.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(shellPadding),
        child: ProfileAvatar(user: user, radius: radius),
      ),
    );
  }

  UserModel? _currentDashboardUser(AdminProvider provider, String uid) {
    for (final candidate in provider.rawUsers) {
      if (candidate.uid == uid) {
        return candidate;
      }
    }
    return null;
  }

  Widget _buildCompanyOpportunitiesSection(
    UserModel user, {
    required Future<List<OpportunityModel>> future,
  }) {
    return FutureBuilder<List<OpportunityModel>>(
      future: future,
      builder: (context, snapshot) {
        final opportunities = snapshot.data ?? const <OpportunityModel>[];
        final l10n = AppLocalizations.of(context)!;
        final summaryLabel = switch (snapshot.connectionState) {
          ConnectionState.waiting => l10n.uiLoadingOpportunities,
          _ when snapshot.hasError => l10n.uiOpportunitiesUnavailable,
          _ when opportunities.isEmpty => l10n.uiNoOpportunitiesPostedYet,
          _ when opportunities.length == 1 =>
            '1 ${l10n.uiOpportunities.toLowerCase()}',
          _ => '${opportunities.length} ${l10n.uiOpportunities.toLowerCase()}',
        };

        return AdminSurface(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(title: l10n.uiPostedOpportunities),
              const SizedBox(height: 14),
              Text(
                summaryLabel,
                style: AppTypography.product(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildDocumentButton(
                  label: l10n.uiViewOpportunities,
                  icon: Icons.work_outline_rounded,
                  onPressed: () => _showCompanyPostedOpportunitiesSheet(user),
                  color: AdminPalette.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCompanyPostedOpportunitiesSheet(UserModel user) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AdminCompanyOpportunitiesSheet(
        companyId: user.uid,
        companyName: _companyDisplayName(user),
      ),
    );
  }

  Widget _buildCompanyCommercialRegisterSummary(UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? l10n.uiNotProvided
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());
    final typeLabel = user.commercialRegisterIsPdf
        ? 'PDF'
        : user.commercialRegisterIsImage
        ? 'Image'
        : 'Document';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminPalette.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminPalette.accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminPalette.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.commercialRegisterIsPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: AdminPalette.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.uiCommercialRegister,
                      style: AppTypography.product(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.hasCommercialRegister
                          ? '$typeLabel - ${l10n.uiUploadedUploadedatlabel(uploadedAtLabel)}'
                          : l10n.uiCommercialRegisterMissing,
                      style: AppTypography.product(
                        fontSize: 12,
                        color: user.hasCommercialRegister
                            ? AdminPalette.textSecondary
                            : AdminPalette.danger,
                        fontWeight: user.hasCommercialRegister
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.hasCommercialRegister) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminPalette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AdminPalette.border.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: AdminPalette.success,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.commercialRegisterFileName.isNotEmpty
                          ? user.commercialRegisterFileName
                          : l10n.uiCommercialRegisterUploaded,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.product(
                        fontSize: 12.5,
                        color: AdminPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttons = [
                  FilledButton.icon(
                    onPressed: () => _openCommercialRegister(user.uid),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text('${l10n.uiView} ${l10n.uiCommercialRegister}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminPalette.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openCommercialRegister(user.uid, download: true),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(
                      '${l10n.uiDownload} ${l10n.uiCommercialRegister}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminPalette.accent,
                      side: BorderSide(
                        color: AdminPalette.accent.withValues(alpha: 0.24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ];

                if (constraints.maxWidth < 440) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buttons[0],
                      const SizedBox(height: 10),
                      buttons[1],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 10),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              l10n.uiCommercialRegisterMissing,
              style: AppTypography.product(
                fontSize: 12,
                color: AdminPalette.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyModerationPanel(UserModel user, AdminProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final buttons = <Widget>[
      if (!user.isCompanyApproved)
        _buildDocumentButton(
          label: l10n.uiApproveCompany,
          icon: Icons.verified_rounded,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'approved'),
          color: AdminPalette.success,
        ),
      if (!user.isCompanyRejected)
        _buildDocumentButton(
          label: l10n.uiRejectCompany,
          icon: Icons.gpp_bad_outlined,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'rejected'),
          color: AdminPalette.danger,
          outlined: true,
        ),
    ];

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.uiCompanyReview,
            style: AppTypography.product(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildAdaptiveActionGroup(buttons),
        ],
      ),
    );
  }

  Widget _buildDocumentButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.24)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }

  Widget _buildAdaptiveActionGroup(List<Widget> buttons) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (buttons.isEmpty) {
          return const SizedBox.shrink();
        }

        if (buttons.length == 1) {
          return SizedBox(width: double.infinity, child: buttons.first);
        }

        if (constraints.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                buttons[index],
                if (index < buttons.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < buttons.length; index++) ...[
              Expanded(child: buttons[index]),
              if (index < buttons.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  void _showCompanyApprovalDialog(
    UserModel user,
    AdminProvider provider,
    String nextStatus,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final companyLabel = user.companyName?.trim().isNotEmpty == true
        ? user.companyName!.trim()
        : user.fullName;
    final actionLabel = switch (nextStatus) {
      'approved' => l10n.uiApproveCompany,
      'rejected' => l10n.uiRejectCompany,
      _ => l10n.uiMarkPendingReview,
    };
    final actionColor = switch (nextStatus) {
      'approved' => AdminPalette.success,
      'rejected' => AdminPalette.danger,
      _ => AdminPalette.warning,
    };
    final actionIcon = switch (nextStatus) {
      'approved' => Icons.verified_rounded,
      'rejected' => Icons.gpp_bad_outlined,
      _ => Icons.pending_actions_rounded,
    };
    final message = switch (nextStatus) {
      'approved' => l10n.uiApproveCompanyMessage,
      'rejected' => l10n.uiRejectCompanyMessage,
      _ => l10n.uiMarkPendingCompanyMessage,
    };

    showDialog(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdminPalette.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: actionColor.withValues(alpha: 0.16)),
              boxShadow: AdminPalette.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(actionIcon, color: actionColor, size: 24),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AdminPalette.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.uiCompanyModeration,
                        style: AppTypography.product(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  actionLabel,
                  style: AppTypography.product(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTypography.product(
                    fontSize: 13,
                    height: 1.5,
                    color: AdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AdminPalette.border.withValues(alpha: 0.92),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(actionIcon, color: actionColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.uiSelectedCompany,
                              style: AppTypography.product(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              companyLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AdminPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildAdaptiveActionGroup([
                  _buildDocumentButton(
                    label: l10n.cancelLabel,
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(ctx),
                    color: AdminPalette.textMuted,
                    outlined: true,
                  ),
                  _buildDocumentButton(
                    label: switch (nextStatus) {
                      'approved' => l10n.uiApprove,
                      'rejected' => l10n.uiReject,
                      _ => l10n.uiPending,
                    },
                    icon: actionIcon,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final error = await provider.updateCompanyApprovalStatus(
                        user.uid,
                        nextStatus,
                      );
                      if (!mounted || error == null || !context.mounted) {
                        return;
                      }
                      context.showAppSnackBar(
                        error,
                        title: l10n.updateUnavailableTitle,
                        type: AppFeedbackType.error,
                      );
                    },
                    color: actionColor,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCommercialRegister(
    String companyId, {
    bool download = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final document = await _documentAccessService
          .getCompanyCommercialRegister(companyId: companyId);
      if (!mounted) return;
      await DocumentLaunchHelper.openSecureDocument(
        context,
        document: document,
        download: download,
        requirePdf: false,
        notPdfMessage: l10n.uiThisDocumentIsNotAValidPdfFile,
        notPdfTitle: l10n.uiPreviewUnavailable,
        unavailableMessage: l10n.uiCouldNotOpenTheDocumentRightNow,
        unavailableTitle: l10n.uiDocumentUnavailable,
      );
    } catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        _documentErrorMessage(error, l10n),
        title: l10n.uiDocumentUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  String _documentErrorMessage(Object error, AppLocalizations l10n) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return l10n.uiDocumentPermissionDenied;
    }
    if (message.contains('404') || message.contains('not found')) {
      return l10n.uiRequestedDocumentNoLongerAvailable;
    }

    return l10n.uiCouldNotOpenTheDocumentRightNow;
  }

  Widget _buildDashboardOptionalDetailRow(
    IconData icon,
    String label,
    String? value,
    String placeholder,
  ) {
    final trimmedValue = (value ?? '').trim();

    return _buildDashboardDetailRow(
      icon,
      label,
      trimmedValue.isNotEmpty ? trimmedValue : placeholder,
      mutedValue: trimmedValue.isEmpty,
    );
  }

  Widget _buildDashboardDetailRow(
    IconData icon,
    String label,
    String value, {
    bool mutedValue = false,
    bool singleLineValue = false,
  }) {
    final valueStyle = AppTypography.product(
      fontSize: mutedValue ? 13.2 : 14,
      height: 1.4,
      color: mutedValue ? AdminPalette.textMuted : AdminPalette.textPrimary,
      fontWeight: mutedValue ? FontWeight.w500 : FontWeight.w600,
    );

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AdminPalette.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AdminPalette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.product(
                    fontSize: 11.5,
                    color: AdminPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                singleLineValue
                    ? _buildDashboardSingleLineText(value, style: valueStyle)
                    : Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSingleLineText(
    String value, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.start,
  }) {
    final alignment = switch (textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right => Alignment.centerRight,
      TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: textAlign,
          style: style,
        ),
      ),
    );
  }

  String _companyDisplayName(UserModel user) {
    final companyName = (user.companyName ?? '').trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }

    return user.fullName.trim().isEmpty ? user.email : user.fullName;
  }

  String _roleDisplayLabel(String role) {
    return DisplayText.capitalizeLeadingLabel(role);
  }

  IconData _roleIcon(String role) {
    return switch (role) {
      'student' => Icons.school_outlined,
      'company' => Icons.business_outlined,
      'admin' => Icons.admin_panel_settings_outlined,
      _ => Icons.person_outline_rounded,
    };
  }

  String _approvalDisplayLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'pending' => l10n.uiPendingReview,
      'rejected' => l10n.uiRejected,
      _ => l10n.uiApproved,
    };
  }

  IconData _approvalDisplayIcon(String status) {
    final normalized = status.trim().toLowerCase();

    return switch (normalized) {
      'pending' => Icons.pending_actions_rounded,
      'rejected' => Icons.gpp_bad_outlined,
      _ => Icons.verified_rounded,
    };
  }

  void _openRecentOpportunity(Map<String, dynamic> opportunity) {
    final provider = context.read<AdminProvider>();
    if (!provider.moderationInitialized && !provider.moderationLoading) {
      Future<void>.microtask(provider.loadModerationData);
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Consumer<AdminProvider>(
        builder: (context, liveProvider, _) {
          final l10n = AppLocalizations.of(context)!;
          final liveOpportunity = _dashboardOpportunityFor(
            liveProvider,
            opportunity,
          );
          final model = OpportunityModel.fromMap(liveOpportunity);
          final applications = _dashboardApplicationsForOpportunity(
            liveProvider,
            model.id,
          );
          final isLoadingApplications =
              liveProvider.moderationLoading && applications.isEmpty;
          final adminUser = context.read<AuthProvider>().userModel;
          final adminId = adminUser?.uid.trim() ?? '';
          final canEdit =
              adminUser?.isAdmin == true && model.companyId.trim() == adminId;
          final typeColor = OpportunityType.color(model.type);
          final typeLabel = OpportunityType.label(model.type, l10n);
          final workModeLabel =
              OpportunityMetadata.formatWorkMode(model.workMode) ?? '';
          final employmentLabel =
              OpportunityMetadata.formatEmploymentType(model.employmentType) ??
              '';
          final paidLabel =
              OpportunityMetadata.formatPaidLabel(model.isPaid) ?? '';
          final compensationLabel =
              OpportunityType.parse(model.type) == OpportunityType.sponsoring
              ? model.fundingLabel(preferFundingNote: true)
              : OpportunityMetadata.buildCompensationLabel(
                  salaryMin: model.salaryMin,
                  salaryMax: model.salaryMax,
                  salaryCurrency: model.salaryCurrency,
                  salaryPeriod: model.salaryPeriod,
                  compensationText: model.compensationText,
                  isPaid: model.isPaid,
                  preferCompensationText: true,
                );
          final statusLabel = DisplayText.capitalizeLeadingLabel(
            model.effectiveStatus(),
          );
          final description = DisplayText.capitalizeLeadingLabel(
            model.description,
          );
          final requirements =
              (model.requirementItems.isNotEmpty
                      ? model.requirementItems
                      : <String>[model.requirements])
                  .map(DisplayText.capitalizeLeadingLabel)
                  .where((item) => item.trim().isNotEmpty)
                  .toList(growable: false);
          final benefits = model.benefits
              .map(DisplayText.capitalizeLeadingLabel)
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false);
          final tags = model.tags
              .map(DisplayText.capitalizeWords)
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false);

          return DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.5,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) => ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Material(
                color: AdminPalette.background,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 16),
                    AdminSurface(
                      radius: 24,
                      gradient: AdminPalette.heroGradient(typeColor),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            OpportunityType.icon(model.type),
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            model.title.trim().isEmpty
                                ? l10n.uiUntitledOpportunity
                                : model.title,
                            style: AppTypography.product(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            model.companyName.trim().isEmpty
                                ? l10n.uiUnknownCompany
                                : model.companyName,
                            style: AppTypography.product(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AdminActionChip(
                                label: typeLabel,
                                icon: OpportunityType.icon(model.type),
                              ),
                              AdminActionChip(
                                label: statusLabel,
                                icon: model.effectiveStatus() == 'closed'
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                              ),
                              if (workModeLabel.isNotEmpty)
                                AdminActionChip(
                                  label: workModeLabel,
                                  icon: Icons.lan_outlined,
                                ),
                              if (model.isFeatured)
                                AdminActionChip(
                                  label: l10n.uiFeatured,
                                  icon: Icons.workspace_premium_outlined,
                                ),
                              if (model.isHidden)
                                AdminActionChip(
                                  label: l10n.uiHidden,
                                  icon: Icons.visibility_off_outlined,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentOpportunityHighlights(
                      l10n: l10n,
                      applicationsCount: applications.length,
                      deadlineLabel: model.deadlineLabel,
                      compensationLabel: compensationLabel,
                      workSetupLabel: workModeLabel.isNotEmpty
                          ? workModeLabel
                          : employmentLabel.isNotEmpty
                          ? employmentLabel
                          : typeLabel,
                      typeColor: typeColor,
                    ),
                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildRecentOpportunityTextCard(
                        title: l10n.uiRoleOverview,
                        value: description,
                        icon: Icons.description_outlined,
                        color: typeColor,
                      ),
                    ],
                    const SizedBox(height: 14),
                    AdminSectionHeader(title: l10n.uiLocationLogistics),
                    const SizedBox(height: 10),
                    _buildDashboardOptionalDetailRow(
                      Icons.business_outlined,
                      l10n.uiCompany,
                      model.companyName,
                      l10n.uiUnknownCompany,
                    ),
                    _buildDashboardOptionalDetailRow(
                      Icons.location_on_outlined,
                      l10n.uiLocation,
                      model.location,
                      l10n.uiLocationNotSpecified,
                    ),
                    if (employmentLabel.isNotEmpty)
                      _buildDashboardDetailRow(
                        Icons.badge_outlined,
                        l10n.uiEmployment,
                        employmentLabel,
                      ),
                    if (paidLabel.isNotEmpty)
                      _buildDashboardDetailRow(
                        Icons.account_balance_wallet_outlined,
                        l10n.uiPaidStatus,
                        paidLabel,
                      ),
                    if ((model.duration ?? '').trim().isNotEmpty)
                      _buildDashboardDetailRow(
                        Icons.schedule_outlined,
                        l10n.uiDuration,
                        model.duration!.trim(),
                      ),
                    if (requirements.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _buildRecentOpportunityListCard(
                        title: l10n.requirementsLabel,
                        items: requirements,
                        icon: Icons.checklist_rounded,
                        color: typeColor,
                      ),
                    ],
                    if (benefits.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildRecentOpportunityListCard(
                        title: l10n.uiBenefits,
                        items: benefits,
                        icon: Icons.star_outline_rounded,
                        color: AdminPalette.success,
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildRecentOpportunityTagsCard(
                        l10n.uiOpportunityTags,
                        tags,
                        typeColor,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildRecentOpportunityApplicationsCard(
                      l10n: l10n,
                      applications: applications,
                      isLoading: isLoadingApplications,
                      color: typeColor,
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminOpportunityEditorScreen(
                                initialOpportunity: liveOpportunity,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.uiEditOpportunity),
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminPalette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _dashboardOpportunityFor(
    AdminProvider provider,
    Map<String, dynamic> fallback,
  ) {
    final id = (fallback['id'] ?? '').toString().trim();
    if (id.isNotEmpty) {
      for (final item in provider.allOpportunities) {
        if ((item['id'] ?? '').toString().trim() == id) {
          return {...item, 'id': id};
        }
      }
    }

    return {...fallback, if (id.isNotEmpty) 'id': id};
  }

  List<AdminApplicationItemModel> _dashboardApplicationsForOpportunity(
    AdminProvider provider,
    String opportunityId,
  ) {
    final id = opportunityId.trim();
    if (id.isEmpty) return const <AdminApplicationItemModel>[];

    final matches = provider.allApplications
        .where((application) => application.opportunityId == id)
        .toList();
    matches.sort((a, b) {
      final aTime = a.appliedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.appliedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return matches;
  }

  Widget _buildRecentOpportunityHighlights({
    required AppLocalizations l10n,
    required int applicationsCount,
    required String deadlineLabel,
    required String? compensationLabel,
    required String workSetupLabel,
    required Color typeColor,
  }) {
    final items = <_RecentOpportunityHighlight>[
      _RecentOpportunityHighlight(
        icon: Icons.assignment_outlined,
        label: l10n.uiApplications,
        value: '$applicationsCount',
        color: AdminPalette.activity,
      ),
      if (deadlineLabel.trim().isNotEmpty)
        _RecentOpportunityHighlight(
          icon: Icons.event_outlined,
          label: l10n.uiDeadline,
          value: deadlineLabel,
          color: AdminPalette.primary,
        ),
      if ((compensationLabel ?? '').trim().isNotEmpty)
        _RecentOpportunityHighlight(
          icon: Icons.payments_outlined,
          label: l10n.uiCompensation,
          value: compensationLabel!.trim(),
          color: AdminPalette.success,
        ),
      _RecentOpportunityHighlight(
        icon: Icons.badge_outlined,
        label: l10n.uiWorkSetup,
        value: workSetupLabel.trim().isNotEmpty
            ? workSetupLabel
            : l10n.uiNotProvided,
        color: typeColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: constraints.maxWidth < 420
                      ? constraints.maxWidth
                      : width,
                  child: AdminSurface(
                    radius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.product(
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w700,
                                  color: AdminPalette.textMuted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.product(
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w800,
                                  color: AdminPalette.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildRecentOpportunityTextCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.product(
              fontSize: 13,
              height: 1.55,
              color: AdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOpportunityListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.product(
                        fontSize: 13,
                        height: 1.45,
                        color: AdminPalette.textSecondary,
                      ),
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

  Widget _buildRecentOpportunityTagsCard(
    String title,
    List<String> tags,
    Color color,
  ) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.product(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => AdminPill(
                    label: tag,
                    color: color,
                    icon: Icons.sell_outlined,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOpportunityApplicationsCard({
    required AppLocalizations l10n,
    required List<AdminApplicationItemModel> applications,
    required bool isLoading,
    required Color color,
  }) {
    final preview = applications.take(5).toList();

    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.uiApplications,
                  style: AppTypography.product(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
              if (applications.isNotEmpty)
                AdminPill(
                  label: '${applications.length}',
                  color: AdminPalette.activity,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.uiLoadingVisibleOpportunityApplications,
                  style: AppTypography.product(
                    fontSize: 12.5,
                    color: AdminPalette.textMuted,
                  ),
                ),
              ],
            )
          else if (applications.isEmpty)
            Text(
              l10n.uiNoApplicationsYet,
              style: AppTypography.product(
                fontSize: 12.5,
                color: AdminPalette.textMuted,
              ),
            )
          else
            ...preview.map((application) {
              final status = ApplicationStatus.parse(application.status);
              final statusColor = ApplicationStatus.color(status);
              final appliedAt = application.appliedAt == null
                  ? l10n.uiUnknownTime
                  : DateFormat.yMMMd(
                      l10n.localeName,
                    ).format(application.appliedAt!.toDate());
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AdminPalette.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AdminPalette.border.withValues(alpha: 0.72),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 17,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.studentName.trim().isEmpty
                                ? l10n.uiApplicant
                                : application.studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w800,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appliedAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 11.5,
                              color: AdminPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminPill(
                      label: ApplicationStatus.label(status, l10n),
                      color: statusColor,
                    ),
                  ],
                ),
              );
            }),
          if (applications.length > preview.length)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+${l10n.uiValueApplicants(applications.length - preview.length)}',
                style: AppTypography.product(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openActivityItem(AdminActivityModel activity) {
    if (activity.type == 'user') {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => AdminActivityPreviewSheet(
          activity: activity,
          manageLabel: AppLocalizations.of(context)!.uiUserManagement,
          onManage: () => _openUserActivityTarget(activity),
        ),
      );
      return;
    }

    final targetTab = switch (activity.type) {
      'application' => AdminContentCenterScreen.opportunitiesTab,
      'opportunity' => AdminContentCenterScreen.opportunitiesTab,
      'scholarship' => AdminContentCenterScreen.scholarshipsTab,
      'training' => AdminContentCenterScreen.libraryTab,
      _ => AdminContentCenterScreen.projectIdeasTab,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AdminActivityPreviewSheet(
        activity: activity,
        manageLabel: _manageLabelForActivity(activity),
        onManage: () => _openContent(targetTab, targetId: activity.relatedId),
      ),
    );
  }

  void _openUserActivityTarget(AdminActivityModel activity) {
    final status = activity.status.trim().toLowerCase();
    final companyApprovalFilter =
        status == 'pending' || status == 'approved' || status == 'rejected'
        ? status
        : 'all';

    if (widget.onOpenUsers != null) {
      AdminHomeNavigation.switchToUsers(
        context,
        targetId: activity.relatedId,
        roleFilter: 'all',
        companyApprovalFilter: companyApprovalFilter,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AdminPalette.background,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.uiUserManagement),
            backgroundColor: AdminPalette.surface,
            foregroundColor: AdminPalette.textPrimary,
          ),
          body: SafeArea(
            child: UsersScreen(
              initialRoleFilter: 'all',
              initialCompanyApprovalFilter: companyApprovalFilter,
              initialTargetId: activity.relatedId,
            ),
          ),
        ),
      ),
    );
  }

  String _manageLabelForActivity(AdminActivityModel activity) {
    final l10n = AppLocalizations.of(context)!;
    return switch (activity.type) {
      'application' => l10n.uiManageApplication,
      'opportunity' => l10n.uiManageOpportunity,
      'scholarship' => l10n.uiManageScholarship,
      'training' => l10n.uiManageLibraryResource,
      _ => l10n.uiManageProjectIdea,
    };
  }
}

class _DashboardMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _DashboardMetricGrid extends StatelessWidget {
  final List<_DashboardMetric> items;

  const _DashboardMetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : constraints.maxWidth < 260
            ? 1
            : 2;
        final childAspectRatio = switch (crossAxisCount) {
          1 => 2.7,
          2 =>
            constraints.maxWidth < 360
                ? 1.72
                : constraints.maxWidth < 420
                ? 1.58
                : 1.42,
          3 => 1.28,
          _ => 1.32,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return StatCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              iconColor: item.color,
            );
          },
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 22 : 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 13,
                        color: AdminPalette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      softWrap: true,
                      style: AppTypography.product(
                        fontSize: isCompact ? 15 : 16,
                        fontWeight: FontWeight.bold,
                        color: AdminPalette.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RankedListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;
  final String suffixLabel;

  const _RankedListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.suffixLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              l10n.uiNoHighlightsAvailableYet,
              style: AppTypography.product(color: AdminPalette.textMuted),
            ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final normalizedTitle = (item['title'] ?? '')
                      .toString()
                      .trim();
                  if (normalizedTitle.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final countLabel = DisplayText.capitalizeLeadingLabel(
                    '${item['count']} $suffixLabel',
                  );
                  final badge = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      countLabel,
                      style: AppTypography.product(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                  final typeBadge = OpportunityTypeBadge(
                    type: (item['type'] ?? '').toString(),
                    fontSize: 10.4,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${entry.key + 1}',
                          style: AppTypography.product(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              normalizedTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [typeBadge, badge],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PendingAdminAlert extends StatelessWidget {
  final int pendingCompanies;
  final int pendingIdeas;
  final int pendingApplications;
  final VoidCallback onOpenCompanies;
  final VoidCallback onOpenIdeas;
  final VoidCallback onOpenApplications;

  const _PendingAdminAlert({
    required this.pendingCompanies,
    required this.pendingIdeas,
    required this.pendingApplications,
    required this.onOpenCompanies,
    required this.onOpenIdeas,
    required this.onOpenApplications,
  });

  @override
  Widget build(BuildContext context) {
    final total = pendingCompanies + pendingIdeas + pendingApplications;
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final items = [
      if (pendingCompanies > 0)
        _PendingAlertItem(
          label: l10n.dashboardPendingCompanies,
          count: pendingCompanies,
          icon: Icons.business_center_outlined,
          color: AdminPalette.warning,
          onTap: onOpenCompanies,
        ),
      if (pendingIdeas > 0)
        _PendingAlertItem(
          label: l10n.dashboardPendingIdeas,
          count: pendingIdeas,
          icon: Icons.lightbulb_outline_rounded,
          color: Colors.amber.shade700,
          onTap: onOpenIdeas,
        ),
      if (pendingApplications > 0)
        _PendingAlertItem(
          label: l10n.dashboardPendingApplications,
          count: pendingApplications,
          icon: Icons.assignment_late_outlined,
          color: AdminPalette.activity,
          onTap: onOpenApplications,
        ),
    ];

    return AdminSurface(
      radius: 22,
      padding: const EdgeInsets.all(14),
      border: Border.all(color: AdminPalette.warning.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AdminPalette.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pending_actions_rounded,
                  color: AdminPalette.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total pending item${total == 1 ? '' : 's'} need attention',
                      style: AppTypography.product(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context)!.uiJumpStraightIntoTheQueueThatNeedsReview,
                      style: AppTypography.product(
                        fontSize: 12,
                        color: AdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      items[index],
                      if (index < items.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    Expanded(child: items[index]),
                    if (index < items.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingAlertItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PendingAlertItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 12.3,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: AppTypography.product(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final int unreadCount;
  final void Function(int tab, {String targetId}) onOpenContent;
  final VoidCallback onOpenActivity;
  final VoidCallback onOpenLibrary;

  const _QuickAccessGrid({
    required this.unreadCount,
    required this.onOpenContent,
    required this.onOpenActivity,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _QuickAccessItem(
        title: l10n.uiApplications,
        subtitle: l10n.uiReviewOfferSubmissions,
        icon: Icons.assignment_outlined,
        color: AdminPalette.activity,
        onTap: () => onOpenContent(AdminContentCenterScreen.opportunitiesTab),
      ),
      _QuickAccessItem(
        title: l10n.uiOpportunities,
        subtitle: l10n.uiManageLiveOffers,
        icon: Icons.work_outline_rounded,
        color: AdminPalette.accent,
        onTap: () => onOpenContent(AdminContentCenterScreen.opportunitiesTab),
      ),
      _QuickAccessItem(
        title: l10n.uiScholarships,
        subtitle: l10n.uiReviewFundingQueue,
        icon: Icons.card_giftcard_outlined,
        color: AdminPalette.danger,
        onTap: () => onOpenContent(AdminContentCenterScreen.scholarshipsTab),
      ),
      _QuickAccessItem(
        title: l10n.uiLibrary,
        subtitle: l10n.uiManageLearningResources,
        icon: Icons.cast_for_education_outlined,
        color: AdminPalette.secondary,
        onTap: () => onOpenContent(AdminContentCenterScreen.libraryTab),
      ),
      _QuickAccessItem(
        title: l10n.uiProjectIdeas,
        subtitle: l10n.uiModerateIdeaQueue,
        icon: Icons.lightbulb_outline_rounded,
        color: AdminPalette.warning,
        onTap: () => onOpenContent(AdminContentCenterScreen.projectIdeasTab),
      ),
      _QuickAccessItem(
        title: l10n.uiActivity,
        subtitle: l10n.uiTrackLatestEvents,
        icon: Icons.timeline_rounded,
        color: AdminPalette.info,
        onTap: onOpenActivity,
      ),
      _QuickAccessItem(
        title: l10n.notificationsTitle,
        subtitle: unreadCount > 0
            ? l10n.uiUnreadAlertsCount(unreadCount)
            : l10n.uiOpenAlertCenter,
        icon: Icons.notifications_outlined,
        color: AdminPalette.primary,
        badgeCount: unreadCount,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
      _QuickAccessItem(
        title: l10n.uiLibrary,
        subtitle: l10n.uiCurateResourceHub,
        icon: Icons.menu_book_rounded,
        color: AdminPalette.secondary,
        onTap: onOpenLibrary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : constraints.maxWidth < 250
            ? 1
            : 2;
        final childAspectRatio = switch (crossAxisCount) {
          1 => 2.6,
          2 => constraints.maxWidth < 420 ? 1.22 : 1.26,
          3 => 1.18,
          _ => 1.22,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(24),
                child: AdminSurface(
                  radius: 22,
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
                  child: LayoutBuilder(
                    builder: (context, itemConstraints) {
                      final isCompact = itemConstraints.maxWidth < 172;

                      return Padding(
                        padding: const EdgeInsets.all(1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isCompact ? 8 : 9),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: isCompact ? 16.5 : 18.5,
                                  ),
                                ),
                                const Spacer(),
                                if (item.badgeCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminPalette.accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item.badgeCount > 9
                                          ? '9+'
                                          : '${item.badgeCount}',
                                      style: AppTypography.product(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AdminPalette.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 13 : 15),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: isCompact ? 13.2 : 14.0,
                                fontWeight: FontWeight.w700,
                                color: AdminPalette.textPrimary,
                                height: 1.14,
                              ),
                            ),
                            SizedBox(height: isCompact ? 4 : 5),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: isCompact ? 10.9 : 11.2,
                                color: AdminPalette.textSecondary,
                                height: 1.26,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAccessItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });
}

class _RecentActivityCard extends StatelessWidget {
  final List<AdminActivityModel> activities;
  final ValueChanged<AdminActivityModel> onOpenActivity;

  const _RecentActivityCard({
    required this.activities,
    required this.onOpenActivity,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminSurface(
      radius: 22,
      child: activities.isEmpty
          ? Text(
              l10n.uiNoRecentActivity,
              style: AppTypography.product(color: AdminPalette.textMuted),
            )
          : Column(
              children: activities.asMap().entries.map((entry) {
                final activity = entry.value;
                final color = _activityColor(activity.type);
                final title = DisplayText.capitalizeLeadingLabel(
                  activity.title,
                );
                final description = DisplayText.capitalizeLeadingLabel(
                  activity.description,
                );
                final actorName = activity.actorName.trim();
                final status = DisplayText.capitalizeLeadingLabel(
                  activity.status,
                );
                final dateLabel = _formatActivityDate(activity.createdAt, l10n);

                return Column(
                  children: [
                    if (entry.key > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AdminPalette.border.withValues(alpha: 0.72),
                        ),
                      ),
                    InkWell(
                      onTap: () => onOpenActivity(activity),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Icon(
                                _activityIcon(activity.type),
                                size: 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.product(
                                      fontSize: 13.6,
                                      fontWeight: FontWeight.w700,
                                      color: AdminPalette.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.product(
                                      fontSize: 12,
                                      color: AdminPalette.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (actorName.isNotEmpty)
                                        _ActivityMetaChip(
                                          label: actorName,
                                          color: AdminPalette.primary,
                                          icon: Icons.person_outline_rounded,
                                        ),
                                      if (status.isNotEmpty)
                                        _ActivityMetaChip(
                                          label: status,
                                          color: _activityStatusColor(
                                            activity.status,
                                          ),
                                        ),
                                      Text(
                                        dateLabel,
                                        style: AppTypography.product(
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w500,
                                          color: AdminPalette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  String _formatActivityDate(Timestamp? timestamp, AppLocalizations l10n) {
    if (timestamp == null) {
      return l10n.uiUnknownTime;
    }

    return DateFormat.yMMMd(l10n.localeName).format(timestamp.toDate());
  }
}

class _RecentOpportunityHighlight {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RecentOpportunityHighlight({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ActivityMetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _ActivityMetaChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.product(
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersCard extends StatelessWidget {
  final List<UserModel> users;
  final ValueChanged<UserModel> onOpenUser;

  const _RecentUsersCard({required this.users, required this.onOpenUser});

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AdminPalette.primary),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.uiRecentUsers,
                style: AppTypography.product(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Text(
              AppLocalizations.of(context)!.uiNoRecentUsersYet,
              style: AppTypography.product(color: AdminPalette.textMuted),
            ),
          ...users.asMap().entries.map((entry) {
            final user = entry.value;
            final roleColor = _roleColor(user.role);
            final roleLabel = DisplayText.capitalizeLeadingLabel(user.role);
            final email = (user.email).toString().trim();
            final roleIcon = user.role == 'company'
                ? Icons.business_outlined
                : user.role == 'student'
                ? Icons.school_outlined
                : Icons.shield_outlined;

            return Column(
              children: [
                if (entry.key > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AdminPalette.border.withValues(alpha: 0.72),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpenUser(user),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 360;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: roleColor.withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ProfileAvatar(user: user, radius: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              user.fullName.trim().isNotEmpty
                                                  ? user.fullName
                                                  : (user.companyName ?? ''),
                                              maxLines: user.role == 'company'
                                                  ? 2
                                                  : 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.product(
                                                fontSize: 14.2,
                                                fontWeight: FontWeight.w700,
                                                color: AdminPalette.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isCompact ? 6 : 8),
                                        _ActivityMetaChip(
                                          label: roleLabel,
                                          color: roleColor,
                                          icon: roleIcon,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      email,
                                      maxLines: user.role == 'company' ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.product(
                                        fontSize: 11.8,
                                        color: AdminPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RecentOpportunitiesCard extends StatelessWidget {
  final List<Map<String, dynamic>> opportunities;
  final ValueChanged<Map<String, dynamic>> onOpenOpportunity;

  const _RecentOpportunitiesCard({
    required this.opportunities,
    required this.onOpenOpportunity,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline_rounded, color: AdminPalette.accent),
              SizedBox(width: 8),
              Text(
                l10n.uiRecentOpportunities,
                style: AppTypography.product(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (opportunities.isEmpty)
            Text(
              l10n.uiNoOpportunitiesPublishedYet,
              style: AppTypography.product(color: AdminPalette.textMuted),
            ),
          ...opportunities.asMap().entries.map((entry) {
            final offer = entry.value;
            final type = (offer['type'] ?? '').toString();
            final title = (offer['title'] ?? '').toString().trim();
            final companyName = (offer['companyName'] ?? '').toString().trim();

            return Column(
              children: [
                if (entry.key > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AdminPalette.border.withValues(alpha: 0.72),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpenOpportunity(offer),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: OpportunityType.color(
                                type,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: OpportunityType.color(
                                  type,
                                ).withValues(alpha: 0.14),
                              ),
                            ),
                            child: Icon(
                              OpportunityType.icon(type),
                              size: 18,
                              color: OpportunityType.color(type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          title.isNotEmpty
                                              ? title
                                              : l10n.uiUntitledOpportunity,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.product(
                                            fontSize: 14.2,
                                            fontWeight: FontWeight.w700,
                                            color: AdminPalette.textPrimary,
                                            height: 1.18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OpportunityTypeBadge(
                                      type: type,
                                      fontSize: 10.2,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  companyName.isNotEmpty
                                      ? companyName
                                      : l10n.uiCompanyNameNotAdded,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.product(
                                    fontSize: 11.8,
                                    color: AdminPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'student':
      return AdminPalette.info;
    case 'company':
      return AdminPalette.secondary;
    case 'admin':
      return AdminPalette.accent;
    default:
      return AdminPalette.textMuted;
  }
}

IconData _activityIcon(String type) {
  switch (type) {
    case 'application':
      return Icons.assignment_outlined;
    case 'opportunity':
      return Icons.work_outline;
    case 'scholarship':
      return Icons.card_giftcard_outlined;
    case 'training':
      return Icons.cast_for_education_outlined;
    case 'user':
      return Icons.manage_accounts_outlined;
    default:
      return Icons.lightbulb_outline_rounded;
  }
}

Color _activityColor(String type) {
  switch (type) {
    case 'application':
      return AdminPalette.activity;
    case 'opportunity':
      return AdminPalette.accent;
    case 'scholarship':
      return AdminPalette.danger;
    case 'training':
      return AdminPalette.secondary;
    case 'user':
      return AdminPalette.info;
    default:
      return AdminPalette.warning;
  }
}

Color _activityStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'approved':
    case 'accepted':
    case 'featured':
    case 'active':
    case 'visible':
      return AdminPalette.success;
    case 'pending':
      return AdminPalette.warning;
    case 'rejected':
    case 'blocked':
    case 'hidden':
    case 'deleted':
      return AdminPalette.danger;
    default:
      return AdminPalette.primary;
  }
}
